# encoding: utf-8

require 'date'
require 'json'
require_relative '3d_engine'

class Numeric
  def to_rad
    self * Math::PI / 180
  end
  def to_deg
    self * ( 180 / Math::PI )
  end
  def long_to_ra
    if self < 0
      (self + 360) / 15
    else
      self / 15
    end
  end
end

def testcollection
  collection = MyStars.newstars_from_JSON(File.read('./data/mystars_6.json', :encoding => 'UTF-8'))
  geo = MyStarsGeo.new(-71.5,43.2)
  collection.localize(geo)
  collection
end

module App
  # Running settings
  # :mag is magnification, not magnitude (that was a bad choice, rename
  # it sometime)
  # mag - field of view in degrees N-S
  # vis_mag - dimmest magnitude visible
  # collection - MyStarsStars collection in current database
  # lat - user latitude
  # lon - user longitude
  # in_view - MyStarsStars collection in current viewscreen
  # timer - delay, in seconds, before timer thread attempts to request a
  #   refresh of both collection and in_view
  # selected_id star.id # of the currently selected star.  When we clean up
  #   the input files, a new id unique to this application should probably
  #   get written, as I don't know if id will always be there or be reliable
  #   for tracking every object
  # facing_xz - how many degrees the camera will be rotated around the y-axis (south = 0)
  # facing_y - how many degrees the camera will be rotated around the x-axis (up = 90)
  AppSettings = Struct.new(:mag, :vis_mag, :collection, :lat, :lon, :in_view, :timer, :selected_id, :facing_xz, :facing_y)
  Settings = AppSettings.new(10, 6, nil, nil, nil, nil, 5, nil, 90, -10)

end

class MyStars

  # Pass in a file object with star data and get back an array of MyStarsStar
  # objects.
  # For now I'm going to use the JSON files as-is, converting -180 - 180
  # values of long to RA in decimal hours.
  # This should just get moved to the intialize method of MyStarsStars
  def self.newstars_from_JSON(file)
    stars = MyStarsStars.new
    data = JSON.parse(file)
    data['features'].each do |star|
      newstar = MyStarsStar.new
      newstar.id = star['id']
      newstar.name = star['properties']['name']
      newstar.mag = star['properties']['mag'].to_f
      newstar.desig = star['properties']['desig']
      newstar.con = star['properties']['con'] 
      newstar.ra = star['geometry']['coordinates'][0].long_to_ra.to_f
      newstar.dec = star['geometry']['coordinates'][1].to_f
      stars.members << newstar
    end
    stars
  end

end

class MyStarsGeo < MyStars

  attr_accessor :time, :jd, :jda, :t, :gmst, :gast, :last, :lat
  
  # Initialize method takes the local latitude and longitude (as decimal
  # degrees) as input and using the current time creates an object
  # containing the apparent sidereal time, both local and Greenwich.
  # This calculation is based on the USNO's calculations here:
  # http://aa.usno.navy.mil/faq/docs/GAST.php

  # Need to adjust the jd argument for initialize to a DateTime object,
  # since we are using this to display the current date and tim in the info
  # window.

  def initialize(local_lon, local_lat, time=nil)
    # Local latitude setter, north is positive
    @lat = local_lat
    # Express local_lon as negative for west, positive for east
    @lon = local_lon
    # Current DateTime, either specified else now
    @time = if time then time else DateTime.now end
    # Julian Day, either specified (optional)
    # else current Julian Day, fractional
    @jd = if time then time.ajd.to_f else @time.ajd.to_f end
    # Julian Days since 1 Jan 2000 at 12 UTC
    @jda = @jd - 2451545.0
    # Julian centuries since 1 Jan 2000 at 12 UTC
    # Currently not using this in favor of a quick calculation, w/ loss of 0.1 sec / century.
    @t = @jda / 36525.0
    # Greenwhich Mean Sidereal Time
    # Quick and dirty version, with loss as mentioned above
    @gmst = 18.697374558 + ( 24.06570982441908 * @jda )
    # Reduce to a range of 0 - 24 h
    @gmst = @gmst % 24
    # Greenwich Apparent Sidereal Time
    omega = 125.04 - 0.052954 * @jda
    l = 280.47 + 0.98565 * @jda
    epsilon = 23.4393 - 0.0000004 * @jda
    deltapsi = ( -0.000319 * Math::sin(omega.to_rad) ) - ( 0.000024 * Math::sin( (2*l).to_rad ) )
    eqeq = deltapsi * Math.cos(epsilon.to_rad)
    @gast = @gmst + eqeq
    # Local Apparent Sidereal Time
    @last = @gast + ( local_lon / 15.0 )
  end

  # Altitude and Azimuth methods take the Right Ascension and Declination of a fixed
  # star as decimal hours for RA and decimal degrees for Dec and output the
  # Altitude and Azimuth as decimal degrees.
  # AA method just runs them both and sends a pretty output.
  # This is based on the USNO's calculations here:
  # http://aa.usno.navy.mil/faq/docs/Alt_Az.php
  # Results so far test out within a few minutes of Stellarium.

  def altitude(ra, dec)
    lha = ( @gast - ra ) * 15 + @lon
    a = Math::cos(lha.to_rad)
    b = Math::cos(dec.to_rad)
    c = Math::cos(@lat.to_rad) 
    d = Math::sin(dec.to_rad)
    e = Math::sin(@lat.to_rad)
    Math::asin(a*b*c+d*e).to_deg
  end

  def azimuth(ra, dec)
    lha = ( @gast - ra ) * 15 + @lon
    a = -(Math::sin(lha.to_rad))
    b = Math::tan(dec.to_rad)
    c = Math::cos(@lat.to_rad)
    d = Math::sin(@lat.to_rad)
    e = Math::cos(lha.to_rad)
    # Old incorrect formula, delete this once I'm confident atan 2 is working.
    # Math::atan(a/(b*c-d*e)).to_deg
    az = Math::atan2( a , (b*c - d*e)).to_deg
    if az >= 0
      az
    else
      az += 360
      az
    end
  end

end

class MyStarsStar < MyStars
  # This represents a single star
  #
  # cart_world is the cartesian coordinate column vector in the world
  # cart_proj is the cartesian coordinate column_vector in the current
  # projection
  attr_accessor :id, :name, :mag, :desig, :con, :ra, :dec, :alt, :az, :cart_world, :cart_proj
end

class MyStarsStars < MyStars
  # This represents a collection of stars
  attr_accessor :members, :selected
  def initialize
    @members = []
    @selected = -1
  end
  # Update altitude and azimuth with local data from a MyStarsGeo object
  def localize(geo)
    self.members.each do |star|
      star.alt = geo.altitude(star.ra, star.dec)
      star.az = geo.azimuth(star.ra, star.dec)
      cz = ( Math.cos(star.alt.to_rad) * Math.sin(star.az.to_rad) )
      cy = Math.sin(star.alt.to_rad) #
      cx = Math.cos(star.alt.to_rad) * Math.cos(star.az.to_rad)
      star.cart_world = Matrix.column_vector([cx,cy,cz,1])
    end
  end
end

class MyStarsWindows < MyStars
  # Methods to use to draw and navigate curses windows
  # These should probably get moved to a module at some point.

  # Increment current camera angle
  def self.move(direction)
    case direction
    when :up
      if App::Settings.facing_y == -90
        nil
      else
        App::Settings.facing_y -= 1
      end
    when :down
      if App::Settings.facing_y == 90
        nil
      else
        App::Settings.facing_y += 1
      end
    when :left
      if App::Settings.facing_xz == 359
        App::Settings.facing_xz = 0
      else
        App::Settings.facing_xz += 1
      end
    when :right
      if App::Settings.facing_xz == 0
        App::Settings.facing_xz = 359
      else
        App::Settings.facing_xz -= 1
      end
    end
  end

  def self.drawWindow(win)
    # This is probably inefficent as it polls all available stars, but
    # hopefully good enough for now.

    # Takes a collection, x and y coords to center on and window to act on
    # and draws window.

    # Iterate through visible stars and try to plot on current screen,
    # given 10 degrees FOV N-S (IE y axis) and enough to fill E-W (x axis)

    # Filter out stars below visible magnitude
    collection = App::Settings.collection.members.select { |member| member.mag <= App::Settings.vis_mag }

    # Get desired viewing range in degrees
    mag = App::Settings.mag

    # If we're drawing a window, the in_view stars have moved, so clear it
    App::Settings.in_view = MyStarsStars.new

    # Multiply each star by the view and projection matrix, add in-view stars
    # to in_view collection
    view = Stars3D.view(0,0,0,App::Settings.facing_y.to_rad,App::Settings.facing_xz.to_rad,0)
    width = ((win.maxx.to_f / win.maxy.to_f) * mag).to_rad
    height = mag.to_rad
    projection = Stars3D.projection(width, height, 0.25, 1.0)
    pv = projection * view
    collection.each do |star|
      star.cart_proj = pv * star.cart_world
      if star.cart_proj[0,0].between?(-1,1) && star.cart_proj[1,0].between?(-1,1) && star.cart_proj[2,0].between?(0,1)
        App::Settings.in_view.members << star
      end
    end

    # Clear the window and draw the in-view members
    win.clear
    App::Settings.in_view.members.each do |star|
      xpos = win.maxx - (((star.cart_proj[0,0] + 1) / 2.0) * win.maxx).round
      ypos = win.maxy - (((star.cart_proj[1,0] + 1) / 2.0) * win.maxy).round
      win.setpos(ypos,xpos)
      win.addstr("*")
      win.setpos(ypos+1,xpos)
      # This is to fix text wrapping, not great but good enough for now
      if (xpos + (star.desig + " " + star.con).length) > win.maxx
        win.setpos(ypos+1, win.maxx - (star.desig + "  " + star.con).length)
      end
      win.addstr(star.desig + " " + star.con)
    end

    # Sort the in_view stars by x, then y for tabbing
    # Might be worth benchmarking later...
    App::Settings.in_view.members.sort! do |a, b|
      (a.cart_proj[1,0] + 1.0) * 1000 - (a.cart_proj[0,0] + 1.0) <=> (b.cart_proj[1,0] + 1.0) * 1000 - (b.cart_proj[0,0] + 1.0)
    end
    # Sort it better instead of doing this.
    App::Settings.in_view.members.reverse!
    
    win.refresh

  end 

  # We could store locations of info win lines as variables and reference
  # those instead of direct locations.

  def self.drawInfo(info_win)
    # Initial drawing of info window
    info_win.setpos(1,0)
    info_win.addstr("Field of View N/S:")
    info_win.setpos(2,0)
    info_win.addstr(App::Settings.mag.to_s + " degrees")
    info_win.setpos(3,0)
    info_win.addstr("Visible magnitude")
    info_win.setpos(4,0)
    info_win.addstr("<= " + App::Settings.vis_mag.to_s)
    info_win.setpos(36,0)
    info_win.addstr("Longitude:")
    info_win.setpos(37,0)
    info_win.addstr(App::Settings.lon.to_s)
    info_win.setpos(38,0)
    info_win.addstr("Latitude")
    info_win.setpos(39,0)
    info_win.addstr(App::Settings.lat.to_s)
    info_win.setpos(12,0)
    info_win.addstr("Current Object")
    info_win.setpos(13,0)
    info_win.addstr("Name:")
    info_win.setpos(15,0)
    info_win.addstr("Designation:")
    info_win.setpos(17,0)
    info_win.addstr("RA / Dec:")
    info_win.setpos(19,0)
    info_win.addstr("Alt / Az:")
    info_win.setpos(41,0)
    info_win.addstr("Date")
    info_win.setpos(43,0)
    info_win.addstr("Time")
    info_win.refresh
  end

  def self.updateTime(info_win,geo)
    info_win.setpos(42,0)
    info_win.clrtoeol
    info_win.addstr(geo.time.strftime("%Y-%m-%d"))
    info_win.setpos(44,0)
    info_win.clrtoeol
    info_win.addstr(geo.time.strftime("%H:%M:%S"))
    info_win.refresh
  end

  def self.updateTargetInfo(info_win)
    star = App::Settings.in_view.members[App::Settings.in_view.selected]
    name = star.name.to_s
    desig = star.desig.to_s + " " + star.con
    radec = star.ra.round(2).to_s + + " / " + star.dec.round(2).to_s
    altaz = star.alt.round(2).to_s + " / " + star.az.round(2).to_s
    info_win.setpos(14,0)
    info_win.clrtoeol
    info_win.addstr(name)
    info_win.setpos(16,0)
    info_win.clrtoeol
    info_win.addstr(desig)
    info_win.setpos(18,0)
    info_win.clrtoeol
    info_win.addstr(radec)
    info_win.setpos(20,0)
    info_win.clrtoeol
    info_win.addstr(altaz)
    info_win.refresh
  end

  def self.updateMag(info_win)
    info_win.setpos(2,0)
    info_win.clrtoeol
    info_win.addstr(App::Settings.mag.to_s + " degrees")
    info_win.refresh
  end

  def self.updateVisMag(info_win)
    info_win.setpos(4,3)
    info_win.clrtoeol
    info_win.addstr(App::Settings.vis_mag.to_s) 
    info_win.refresh
  end

  def self.updateLon(info_win)
    info_win.setpos(37,0)
    info_win.clrtoeol
    info_win.addstr(App::Settings.lon.to_s)
    info_win.refresh
  end

  def self.updateLat(info_win)
    info_win.setpos(39,0)
    info_win.clrtoeol
    info_win.addstr(App::Settings.lat.to_s)
    info_win.refresh
  end

  def self.selectID(win, info_win)
    # Highlight the currently selected object
    star = App::Settings.in_view.members.find { |object| object.id == App::Settings.selected_id }

    star_selection_index = App::Settings.in_view.members.find_index(star)

    if star
      App::Settings.in_view.selected = star_selection_index
      xpos = win.maxx - (((star.cart_proj[0,0] + 1) / 2.0) * win.maxx).round
      ypos = win.maxy - (((star.cart_proj[1,0] + 1) / 2.0) * win.maxy).round
      win.setpos(ypos,xpos)
      win.attrset(Curses::A_REVERSE)
      win.addstr("*")
      win.attrset(Curses::A_NORMAL)
      win.refresh
      MyStarsWindows.updateTargetInfo(info_win)
    end 
  end

  def self.selectNext(win, info_win)
    # Highlight the next object in current view
    if App::Settings.in_view.members.empty?
      return nil
    end
    # --- Deselect the previous one
    star = App::Settings.in_view.members[App::Settings.in_view.selected]
    xpos = win.maxx - (((star.cart_proj[0,0] + 1) / 2.0) * win.maxx).round
    ypos = win.maxy - (((star.cart_proj[1,0] + 1) / 2.0) * win.maxy).round
    win.setpos(ypos,xpos)
    win.attrset(Curses::A_NORMAL)
    win.addstr("*")
    # ---
    if App::Settings.in_view.selected == App::Settings.in_view.members.length - 1
      App::Settings.in_view.selected = 0
    else
      App::Settings.in_view.selected += 1
    end
    star = App::Settings.in_view.members[App::Settings.in_view.selected]
    # Set targeted ID so we can highlight it again after refresh
    App::Settings.selected_id = star.id
    xpos = win.maxx - (((star.cart_proj[0,0] + 1) / 2.0) * win.maxx).round
    ypos = win.maxy - (((star.cart_proj[1,0] + 1) / 2.0) * win.maxy).round
    win.setpos(ypos,xpos)
    win.attrset(Curses::A_REVERSE)
    win.addstr("*")
    win.attrset(Curses::A_NORMAL)
    win.refresh
    MyStarsWindows.updateTargetInfo(info_win)
  end

  def self.selectPrev(win, info_win)
    # Highlight the previous object in current view
    if App::Settings.in_view.members.empty?
      return nil
    end
    # ---Deselect the previous one
    star = App::Settings.in_view.members[App::Settings.in_view.selected]
    xpos = win.maxx - (((star.cart_proj[0,0] + 1) / 2.0) * win.maxx).round
    ypos = win.maxy - (((star.cart_proj[1,0] + 1) / 2.0) * win.maxy).round
    win.setpos(ypos,xpos)
    win.attrset(Curses::A_NORMAL)
    win.addstr("*")
    # ---
    if (App::Settings.in_view.selected == 0) || (App::Settings.in_view.selected == -1)
      App::Settings.in_view.selected = App::Settings.in_view.members.length - 1
    else
      App::Settings.in_view.selected -= 1
    end
    star = App::Settings.in_view.members[App::Settings.in_view.selected]
    # Set targeted ID so we can highlight it again after refresh
    App::Settings.selected_id = star.id
    xpos = win.maxx - (((star.cart_proj[0,0] + 1) / 2.0) * win.maxx).round
    ypos = win.maxy - (((star.cart_proj[1,0] + 1) / 2.0) * win.maxy).round
    win.setpos(ypos,xpos)
    win.attrset(Curses::A_REVERSE)
    win.addstr("*")
    win.attrset(Curses::A_NORMAL)
    win.refresh
    MyStarsWindows.updateTargetInfo(info_win)
  end

  def self.search
    # Deactivate this for now
    # win = Curses.stdscr
    # searchwin = win.subwin(30,60,win.maxy / 2 - 15, win.maxx / 2 - 30)
    # searchwin.box("|","-")
    # searchwin.refresh
    # sleep(5)
    # searchwin.clear
    # searchwin.refresh
    # searchwin.close
  end

  def self.help
    # Help screen popup with command key list
    win = Curses.stdscr
    helpwin = win.subwin(30,60,win.maxy / 2 - 15, win.maxx / 2 - 30)
    helpwin.box("|","-")
    helpwin.setpos(2,2)
    helpwin.addstr("Arrow keys move around")
    helpwin.setpos(3,2)
    helpwin.addstr("(M) and (m) to filter by magnitude.")
    helpwin.setpos(4,2)
    helpwin.addstr("(+) and (-) to zoom in and out")
    helpwin.setpos(5,2)
    helpwin.addstr("Tab and Shift-Tab to cycle through visible objects")
    helpwin.setpos(10,2)
    helpwin.addstr("(q) to quit")
    helpwin.refresh
    helpwin.getch
    helpwin.clear
    helpwin.refresh
    helpwin.close
  end

end
