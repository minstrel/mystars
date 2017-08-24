# encoding: utf-8

require 'date'
require 'json'

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

module App
  # Current settings - this is probably badly named...
  # :mag is magnification, not magnitude (that was a bad choice, rename
  # it sometime)
  # mag - field of view in degrees N-S
  # vis_mag - dimmest magnitude visible
  # centery - N-S location in degrees to center on
  # centerx - E-W location in degrees to center on
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
  AppSettings = Struct.new(:mag, :vis_mag, :centery, :centerx, :collection, :lat, :lon, :in_view, :timer, :selected_id)
  Settings = AppSettings.new(10, 6, 0, 0, nil, nil, nil, nil, 5, nil)

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

  attr_accessor :jd, :jda, :t, :gmst, :gast, :last, :lat
  
  # Initialize method takes the local latitude and longitude (as decimal
  # degrees) as input and using the current time creates an object
  # containing the apparent sidereal time, both local and Greenwich.
  # This calculation is based on the USNO's calculations here:
  # http://aa.usno.navy.mil/faq/docs/GAST.php

  def initialize(local_lon, local_lat, jd=nil)
    # Local latitude setter, north is positive
    @lat = local_lat
    # Express local_lon as negative for west, positive for east
    @lon = local_lon
    # Julian Day, either specified (optional)
    # else current Julian Day, fractional
    @jd = if jd then jd else DateTime.now.ajd.to_f end
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

  def aa(ra,dec)
    puts "Altitude is " + self.altitude(ra,dec).to_s
    puts "Azimuth is " + self.azimuth(ra,dec).to_s
  end

end

class MyStarsStar < MyStars
  # This represents a single star
  attr_accessor :id, :name, :mag, :desig, :con, :ra, :dec, :alt, :az, :circ_x, :circ_y
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
    end
  end
  def plot_on_circle
    self.members.each do |star|
      star.circ_x = Math.sin(star.az.to_rad) * (90 - star.alt)
      star.circ_y = Math.cos(star.az.to_rad) * (90 - star.alt)
    end 
  end
end

class MyStarsWindows < MyStars
  # Methods to use to draw and navigate curses windows
  # These should probably get moved to a module at some point.

  def self.drawWindow(win)
    # This is probably inefficent as it polls all available stars, but
    # hopefully good enough for now.

    # Takes a collection, x and y coords to center on and window to act on
    # and draws window.

    # Iterate through visible stars and try to plot on current screen,
    # given 10 degrees FOV N-S (IE y axis) and enough to fill E-W (x axis)

    mag = App::Settings.mag
    centery = App::Settings.centery
    centerx = App::Settings.centerx
    collection = App::Settings.collection.members.select { |member| member.mag <= App::Settings.vis_mag }

    miny = centery - (mag / 2.0)
    maxy = centery + (mag / 2.0)
    xrange = (win.maxx.to_f / win.maxy.to_f) * mag.to_f
    minx = centerx - (xrange / 2.0)
    maxx = centerx + (xrange / 2.0)
    win.clear

    # If we're drawing a window, the in_view stars have moved, so clear it
    App::Settings.in_view = MyStarsStars.new

    collection.each do |star|
      if (star.circ_y.between?(miny,maxy)) && (star.circ_x.between?(minx,maxx))
        # Figure out the y position on current screen
        ypos = (((star.circ_y - miny) / (maxy - miny)).abs * win.maxy ).round
        # Figure out the x position on current screen
        xpos = (((star.circ_x - minx) / (maxx - minx)).abs * win.maxx ).round
        win.setpos(ypos,xpos)
        win.addstr("*")
        win.setpos(ypos+1,xpos)
        #Make this more fine grained / toggleable later.  Right now it's
        #useful for making sure we're looking at the right stuff.
        #Text wrapping around was annoying me, so quicky fix in the
        #if statement.
        if (xpos + (star.desig + " " + star.con).length) > win.maxx
          win.setpos(ypos+1, win.maxx - (star.desig + "  " + star.con).length)
        end
        win.addstr(star.desig + " " + star.con)
        # Add it to the stars in_view
        # Use the x,y coords as a key for easy sorting into tab collection.
        App::Settings.in_view.members << star
      end
    end

    # Sort the in_view stars by x, then y for tabbing
    # Might be worth benchmarking later...
    App::Settings.in_view.members.sort! do |a, b|
      a.circ_y * 200 - a.circ_x <=> b.circ_y * 200 - b.circ_x
    end
    
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
    star = App::Settings.in_view.members.find { |object| object.id == App::Settings.selected_id }

    star_selection_index = App::Settings.in_view.members.find_index(star)

    if star
      mag = App::Settings.mag
      centery = App::Settings.centery
      centerx = App::Settings.centerx
      miny = centery - (mag / 2.0)
      maxy = centery + (mag / 2.0)
      xrange = (win.maxx.to_f / win.maxy.to_f) * mag.to_f
      minx = centerx - (xrange / 2.0)
      maxx = centerx + (xrange / 2.0)
      # Set currently selected
      App::Settings.in_view.selected = star_selection_index
      # Figure out the y position on current screen
      ypos = (((star.circ_y - miny) / (maxy - miny)).abs * win.maxy ).round
      # Figure out the x position on current screen
      xpos = (((star.circ_x - minx) / (maxx - minx)).abs * win.maxx ).round
      win.setpos(ypos,xpos)
      # Make highlighting prettier later, use init_pairs and stuff
      win.attrset(Curses::A_REVERSE)
      win.addstr("*")
      win.attrset(Curses::A_NORMAL)
      win.refresh
      MyStarsWindows.updateTargetInfo(info_win)
    end 
  end

  def self.selectNext(win, info_win)
    # I'm repeating a lot of code from drawWindow here, should probably put
    # current objects into some sort of container with x and y positions.
    # Also need to add something here to handle errors, like no stars visible.
    if App::Settings.in_view.members.empty?
      return nil
    end
    mag = App::Settings.mag
    centery = App::Settings.centery
    centerx = App::Settings.centerx
    miny = centery - (mag / 2.0)
    maxy = centery + (mag / 2.0)
    xrange = (win.maxx.to_f / win.maxy.to_f) * mag.to_f
    minx = centerx - (xrange / 2.0)
    maxx = centerx + (xrange / 2.0)
    # --- Deselect the previous one
    star = App::Settings.in_view.members[App::Settings.in_view.selected]
    # Figure out the y position on current screen
    ypos = (((star.circ_y - miny) / (maxy - miny)).abs * win.maxy ).round
    # Figure out the x position on current screen
    xpos = (((star.circ_x - minx) / (maxx - minx)).abs * win.maxx ).round
    win.setpos(ypos,xpos)
    # Make highlighting prettier later, use init_pairs and stuff
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
    # Figure out the y position on current screen
    ypos = (((star.circ_y - miny) / (maxy - miny)).abs * win.maxy ).round
    # Figure out the x position on current screen
    xpos = (((star.circ_x - minx) / (maxx - minx)).abs * win.maxx ).round
    win.setpos(ypos,xpos)
    # Make highlighting prettier later, use init_pairs and stuff
    win.attrset(Curses::A_REVERSE)
    win.addstr("*")
    win.attrset(Curses::A_NORMAL)
    win.refresh
    MyStarsWindows.updateTargetInfo(info_win)
  end

  def self.selectPrev(win, info_win)
    # I'm repeating a lot of code from drawWindow here, should probably put
    # current objects into some sort of container with x and y positions.
    # Also need to add something here to handle errors, like no stars visible.
    if App::Settings.in_view.members.empty?
      return nil
    end
    mag = App::Settings.mag
    centery = App::Settings.centery
    centerx = App::Settings.centerx
    miny = centery - (mag / 2.0)
    maxy = centery + (mag / 2.0)
    xrange = (win.maxx.to_f / win.maxy.to_f) * mag.to_f
    minx = centerx - (xrange / 2.0)
    maxx = centerx + (xrange / 2.0)
    # ---Deselect the previous one
    star = App::Settings.in_view.members[App::Settings.in_view.selected]
    # Figure out the y position on current screen
    ypos = (((star.circ_y - miny) / (maxy - miny)).abs * win.maxy ).round
    # Figure out the x position on current screen
    xpos = (((star.circ_x - minx) / (maxx - minx)).abs * win.maxx ).round
    win.setpos(ypos,xpos)
    # Make highlighting prettier later, use init_pairs and stuff
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
    # Figure out the y position on current screen
    ypos = (((star.circ_y - miny) / (maxy - miny)).abs * win.maxy ).round
    # Figure out the x position on current screen
    xpos = (((star.circ_x - minx) / (maxx - minx)).abs * win.maxx ).round
    win.setpos(ypos,xpos)
    # Make highlighting prettier later, use init_pairs and stuff
    win.attrset(Curses::A_REVERSE)
    win.addstr("*")
    win.attrset(Curses::A_NORMAL)
    win.refresh
    MyStarsWindows.updateTargetInfo(info_win)
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
    helpwin.addstar("(q) to quit")
    helpwin.refresh
    helpwin.getch
    helpwin.clear
    helpwin.refresh
    helpwin.close
  end

end
