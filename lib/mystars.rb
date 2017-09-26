# encoding: utf-8

require 'date'
require 'json'
require 'curses'
require_relative 'stars3d'
require_relative 'helpers'

def testcollection
  collection = MyStarsStars.new('./data/mystars_6.json')
  geo = MyStarsGeo.new(-71.5,43.2)
  collection.localize(geo)
  collection
end

class MyStars

  # Parent class for everything else.
  # Right now it contains creator methods for the different data types.

  # Pass in a file with constellation line vertices and get back an array
  # of MyStarsConstellationLines objects.
  def self.newconstellation_lines(file)
    constellation_lines = []
    constellations = JSON.parse(File.read(file, :encoding => 'utf-8'))['features']
    constellations.each do |constellation|
      # The 'ser' ID is duplicated in the data, we're not using ID yet but
      # keep this note if issues arise later.
      coordset = []
      constellation['geometry']['coordinates'].each do |lines|
        newline = []
        lines.each do |point|
          newline << [point[0].long_to_ra.to_f, point[1].to_f]
        end
        coordset << newline
      end
      newconst = MyStarsConstellationLines.new(:id => constellation['id'], :coordinates => coordset )
      constellation_lines << newconst
    end 
    constellation_lines
  end
end

class MyStarsStar < MyStars
  # a single star
  #
  # cart_world is the cartesian coordinate column vector in the world
  # cart_proj is the cartesian coordinate column_vector in the current
  # projection
  attr_accessor :id, :name, :mag, :desig, :con, :ra, :dec, :alt, :az, :cart_world, :cart_proj

  def screen_coords(win)
    xpos = win.maxx - (((@cart_proj[0,0] + 1) / 2.0) * win.maxx).round
    ypos = win.maxy - (((@cart_proj[1,0] + 1) / 2.0) * win.maxy).round
    [xpos, ypos]
  end

end

class MyStarsConstellation < MyStars
  # a single constellation 
  attr_accessor :name, :genitive, :ra, :dec, :alt, :az, :cart_world, :cart_proj
  def initialize(attributes)
    @name = attributes[:name]
    @genitive = attributes[:genitive]
    @ra = attributes[:ra]
    @dec = attributes[:dec]
  end

  def localize(geo)
    @alt = geo.altitude(@ra, @dec)
    @az = geo.azimuth(@ra, @dec)
    cz = ( Math.cos(@alt.to_rad) * Math.sin(@az.to_rad) )
    cy = Math.sin(@alt.to_rad)
    cx = Math.cos(@alt.to_rad) * Math.cos(@az.to_rad)
    @cart_world = Matrix.column_vector([cx,cy,cz,1])
  end

  def screen_coords(win)
    xpos = win.maxx - (((@cart_proj[0,0] + 1) / 2.0) * win.maxx).round
    ypos = win.maxy - (((@cart_proj[1,0] + 1) / 2.0) * win.maxy).round
    [xpos, ypos]
  end

end

class MyStarsConstellations < MyStars

  # A collection of MyStarsConstellation objects
  attr_accessor :members

  def initialize(file=nil)
    @members = []
    if file
      # Pass in a file with constellation name data and get back an array of
      # MyStarsConstellation objects.
      data = JSON.parse(File.read(file, :encoding => "utf-8"))['features']
      data.each do |con|
        name = con["properties"]["name"]
        genitive = con["properties"]["gen"]
        ra = con['geometry']['coordinates'][0].long_to_ra.to_f
        dec = con['geometry']['coordinates'][1].to_f
        @members << MyStarsConstellation.new({:name => name, :genitive => genitive, :ra => ra, :dec => dec})
      end
    end
  end

end

class MyStarsConstellationLines < MyStars
  # A set of points of a constellation (the pattern itself, not the bounds)
  # Note that the coordinate sets are arrays of arrays of arrays - multiple
  # lines making up the constellation.
  attr_accessor :id, :coordinates, :cart_world_set, :alt_az_set, :cart_proj_set
  def initialize(attributes)
    @id = attributes[:id]
    @coordinates = attributes[:coordinates]
    @cart_world_set = []
    @alt_az_set = []
    @cart_proj_set = []
  end

  def localize(geo)
    @alt_az_set = []
    @cart_world_set = []
    @coordinates.each do |lines|
      newline = []
      newcartline = []
      lines.each do |point|
        alt = geo.altitude(point[0], point[1])
        az = geo.azimuth(point[0], point[1])
        newline << [alt,az]
        cz = ( Math.cos(alt.to_rad) * Math.sin(az.to_rad) )
        cy = Math.sin(alt.to_rad)
        cx = Math.cos(alt.to_rad) * Math.cos(az.to_rad)
        newcartline << Matrix.column_vector([cx,cy,cz,1])
      end
      @alt_az_set << newline
      @cart_world_set << newcartline
    end
  end

  # TODO this is ugly, screen_coords defined for different classes, this one
  # is using a class method because it's not acting on an instance, just
  # returning some values from input
  def self.screen_coords(win, vector)
    xpos = win.maxx - (((vector[0,0] + 1) / 2.0) * win.maxx).round
    ypos = win.maxy - (((vector[1,0] + 1) / 2.0) * win.maxy).round
    [xpos, ypos]
  end

end

class MyStarsStars < MyStars
  # This represents a collection of stars

  attr_accessor :members, :selected

  def initialize(file=nil)
    @members = []
    @selected = -1
    # Current file uses longitude, converting -180 to 180 long to RA for now.
    # Better later to rewrite the files.
    if file
      data = JSON.parse(File.read(file, :encoding => "utf-8"))['features']
      data.each do |star|
        newstar = MyStarsStar.new
        newstar.id = star['id']
        newstar.name = star['properties']['name']
        newstar.mag = star['properties']['mag'].to_f
        newstar.desig = star['properties']['desig']
        newstar.con = star['properties']['con'] 
        newstar.ra = star['geometry']['coordinates'][0].long_to_ra.to_f
        newstar.dec = star['geometry']['coordinates'][1].to_f
        @members << newstar
      end
    end
  end

  # Update altitude and azimuth with local data from a MyStarsGeo object
  # and add it to the world matrix
  def localize(geo)
    self.members.each do |star|
      star.alt = geo.altitude(star.ra, star.dec)
      star.az = geo.azimuth(star.ra, star.dec)
      cz = ( Math.cos(star.alt.to_rad) * Math.sin(star.az.to_rad) )
      cy = Math.sin(star.alt.to_rad)
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

  def self.drawWindow
    # This is probably inefficent as it polls all available stars, but
    # hopefully good enough for now.

    # Takes a collection, x and y coords to center on and window to act on
    # and draws window.

    # Iterate through visible stars and try to plot on current screen,
    # given 10 degrees FOV N-S (IE y axis) and enough to fill E-W (x axis)

    win = App::WIN

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
    # Adjust width to compensate for terminal character size
    # This is pretty arbritrary but I don't see a better way right now
    width = width * 0.5
    height = mag.to_rad
    projection = Stars3D.projection(width, height, 0.25, 1.0)
    pv = projection * view
    collection.each do |star|
      star.cart_proj = pv * star.cart_world
      if star.cart_proj[0,0].between?(-1,1) && star.cart_proj[1,0].between?(-1,1) && star.cart_proj[2,0].between?(0,1)
        App::Settings.in_view.members << star
      end
    end

    # If the ground is showing, discard stars below 0 altitude
    if App::Settings.show_ground
      App::Settings.in_view.members = App::Settings.in_view.members.reject { |star| star.alt < 0.0 }
    end

    # Get the in-view constellations
    if App::Settings.show_constellations
      in_view_constellation_names = []
      App::Settings.constellation_names.members.each do |con|
        con.cart_proj = pv * con.cart_world 
        if con.cart_proj[0,0].between?(-1,1) && con.cart_proj[1,0].between?(-1,1) && con.cart_proj[2,0].between?(0,1)
        in_view_constellation_names << con
        end
      end
    end
     
    # Clear the window and draw the in-view members and constellations
    win.clear
    # Get and draw in-view constellation lines
    if App::Settings.show_constellations
    # Project all the line points into projection view
    # code
      App::Settings.constellation_lines.each do |con|
        new_proj_set = []
        con.cart_world_set.each do |line|
          new_proj_line = []
          line.each do |point|
            newpoint = pv * point
            new_proj_line << newpoint
          end
          new_proj_set << new_proj_line
        end
        con.cart_proj_set = new_proj_set
      end
    # Get all the lines containing points that are in the current screen
    # code
      on_screen_lines = []
      App::Settings.constellation_lines.each do |con|
        con.cart_proj_set.each do |line|
          line.each do |point|
            if point[0,0].between?(-1,1) && point[1,0].between?(-1,1) && point[2,0].between?(0,1)
              on_screen_lines << line
            end
          end
        end
      end
      on_screen_lines.uniq!
    # Draw lines between all those points and the previous and next points,
    # if they exist.
    # There's going to be a lot of duplication here, but it's small so clean
    # it up later.
    # Drop any points that have negative x and y values
    # code
    # Iterate through each line, calculate on-screen coords, then run those
    # through the Bresenham algorithm.  Add all those points to another array,
    # dropping any that are negative x and y
      points_to_draw = []
      on_screen_lines.each do |line|
        line.each.with_index do |point, i|
          if line[i+1]
            x0, y0 = MyStarsConstellationLines.screen_coords(win,point) 
            x1, y1 = MyStarsConstellationLines.screen_coords(win,line[i+1]) 
            points_to_draw += Stars3D.create_points(x0,y0,x1,y1)
          end
        end 
      end 
      points_to_draw.uniq!
      points_to_draw.each do |point|
        if (point[:y].between?(0,win.maxy-1)) && (point[:x].between?(0,win.maxx-1))
          win.setpos(point[:y], point[:x])
          win.addstr("·")
        end
      end
    end

    # Draw in-view stars
    App::Settings.in_view.members.each do |star|
      xpos, ypos = star.screen_coords(win)
      win.setpos(ypos,xpos)
      win.addstr("*")
      win.setpos(ypos+1,xpos)
      # This is to fix text wrapping, not great but good enough for now
      case App::Settings.labels
      when :named
        if !star.name.empty?
          if (xpos + (star.name).length) > win.maxx
            win.setpos(ypos+1, win.maxx - star.name.length)
          end
          win.addstr(star.name)
        end
      when :all
        if !star.name.empty?
          if (xpos + (star.name).length) > win.maxx
            win.setpos(ypos+1, win.maxx - star.name.length)
          end
          win.addstr(star.name)
        else
          if (xpos + (star.desig + " " + star.con).length) > win.maxx
            win.setpos(ypos+1, win.maxx - (star.desig + "  " + star.con).length)
          end
          win.addstr(star.desig + " " + star.con)
        end
      when :none
      end
    end

    # Draw in-view constellations
    if App::Settings.show_constellations
      in_view_constellation_names.each do |con|
        xpos, ypos = con.screen_coords(win)
        if (xpos + (con.name).length / 2 + 1) > win.maxx
          win.setpos(ypos, win.maxx - (con.name).length - 1)
        else
          win.setpos(ypos,xpos)
        end
        win.addstr(con.name)
      end
    end


    # Sort the in_view stars by x, then y for tabbing
    # Might be worth benchmarking later...
    App::Settings.in_view.members.sort! do |a, b|
      (a.cart_proj[1,0] + 1.0) * 1000 - (a.cart_proj[0,0] + 1.0) <=> (b.cart_proj[1,0] + 1.0) * 1000 - (b.cart_proj[0,0] + 1.0)
    end
    # Sort it better instead of doing this.
    App::Settings.in_view.members.reverse!
    
    # Draw the ground, if toggled
    if App::Settings.show_ground
      # Put coordinates into projection space
      # Use projection matrix with z range starting at 0 so we don't lose the
      # ground when looking straight down.
      ground_projection = Stars3D.projection(width, height, 0.0, 1.0)
      ground_pv = ground_projection * view
      ground_projection = App::GROUNDCOORDS.collect do |ground|
        ground_pv * ground
      end

      # Create line points between all coords in front of camera
      # A little inefficient because it pulls x and y out of view but doesn't
      # seem to impact performance.
      horizon_points_to_draw = []
      ground_projection.each.with_index do |gp, i|
        if ground_projection[i+1]
          if gp[2,0].between?(0,1)
          x0, y0 = MyStarsConstellationLines.screen_coords(win,gp) 
          x1, y1 = MyStarsConstellationLines.screen_coords(win,ground_projection[i+1]) 
          horizon_points_to_draw += Stars3D.create_points(x0,y0,x1,y1)
          end
        end
      end
      # Filter uniques.
      horizon_points_to_draw = horizon_points_to_draw.uniq
      # Draw horizon points and fill screen below them
      horizon_points_to_draw.each do |point|
        if (point[:y] < win.maxy-1) && (point[:x].between?(0,win.maxx-1))
          (point[:y]).upto(win.maxy-1) do |y|
            win.setpos(y,point[:x])
            win.addstr("#")
          end
        end
      end
    end

    # Draw in-view compass points
    App::COMPASSPOINTS.each do |key, value|
      compass_projection = pv * value 
      if compass_projection[0,0].between?(-1,1) && compass_projection[1,0].between?(-1,1) && compass_projection[2,0].between?(0,1)
        xpos = win.maxx - (((compass_projection[0,0] + 1) / 2.0) * win.maxx).round
        ypos = win.maxy - (((compass_projection[1,0] + 1) / 2.0) * win.maxy).round
        win.setpos(ypos,xpos)
        win.addstr(key)
      end
    end

    win.refresh

  end 

  # We could store locations of info win lines as variables and reference
  # those instead of direct locations.

  def self.drawInfo
    # Initial drawing of info window
    info_win = App::INFO_WIN
    info_win.setpos(1,0)
    info_win.addstr("Field of View N/S:")
    info_win.setpos(2,0)
    info_win.addstr(App::Settings.mag.to_s + " degrees")
    info_win.setpos(3,0)
    info_win.addstr("Visible magnitude")
    info_win.setpos(4,0)
    info_win.addstr("<= " + App::Settings.vis_mag.to_s)
    info_win.setpos(7,0)
    info_win.addstr("Constellations:")
    info_win.setpos(8,0)
    case App::Settings.show_constellations
    when true
      info_win.addstr("Shown")
    when false
      info_win.addstr("Hidden")
    end
    info_win.setpos(9,0)
    info_win.addstr("Ground:")
    info_win.setpos(10,0)
    case App::Settings.show_ground
    when true
      info_win.addstr("Shown")
    when false
      info_win.addstr("Hidden")
    end
    info_win.setpos(11,0)
    info_win.addstr("Labels:")
    info_win.setpos(12,0)
    case App::Settings.labels
    when :all
      info_win.addstr("All stars")
    when :named
      info_win.addstr("Named stars only")
    when :none
      info_win.addstr("No star labels")
    end
    info_win.setpos(32,0)
    info_win.addstr("Longitude:")
    info_win.setpos(33,0)
    info_win.addstr(App::Settings.lon.to_s)
    info_win.setpos(34,0)
    info_win.addstr("Latitude")
    info_win.setpos(35,0)
    info_win.addstr(App::Settings.lat.to_s)
    info_win.setpos(14,0)
    info_win.addstr("Current Object")
    info_win.setpos(15,0)
    info_win.addstr("Name:")
    info_win.setpos(17,0)
    info_win.addstr("Designation:")
    info_win.setpos(19,0)
    info_win.addstr("RA / Dec:")
    info_win.setpos(21,0)
    info_win.addstr("Alt / Az:")
    info_win.setpos(38,0)
    info_win.addstr("Facing")
    info_win.setpos(39,0)
    azimuth = 90 - App::Settings.facing_xz
    if azimuth < 0
      azimuth = 360 + azimuth
    end
    info_win.addstr("Azimuth: " + azimuth.to_s + " °")
    info_win.setpos(40,0)
    info_win.addstr("Altitude: " + (-App::Settings.facing_y).to_s + " °")
    info_win.setpos(41,0)
    info_win.addstr("Date")
    info_win.setpos(43,0)
    info_win.addstr("Time")
    info_win.refresh
  end

  def self.updateConstellations
    info_win = App::INFO_WIN
    info_win.setpos(8,0)
    info_win.clrtoeol
    case App::Settings.show_constellations
    when true
      info_win.addstr("Shown")
    when false
      info_win.addstr("Hidden")
    end
    info_win.refresh
  end

  def self.updateGround
    info_win = App::INFO_WIN
    info_win.setpos(10,0)
    info_win.clrtoeol
    case App::Settings.show_ground
    when true
      info_win.addstr("Shown")
    when false
      info_win.addstr("Hidden")
    end
    info_win.refresh
  end

  def self.updateLabels
    info_win = App::INFO_WIN
    info_win.setpos(12,0)
    info_win.clrtoeol
    case App::Settings.labels
    when :all
      info_win.addstr("All stars")
    when :named
      info_win.addstr("Named stars only")
    when :none
      info_win.addstr("No star labels")
    end
    info_win.refresh
  end

  def self.updateFacing
    info_win = App::INFO_WIN
    info_win.setpos(39,0)
    info_win.clrtoeol
    azimuth = 90 - App::Settings.facing_xz
    if azimuth < 0
      azimuth = 360 + azimuth
    end
    info_win.addstr("Azimuth: " + azimuth.to_s + " °")
    info_win.setpos(40,0)
    info_win.clrtoeol
    info_win.addstr("Altitude: " + (-App::Settings.facing_y).to_s + " °")
    info_win.refresh
  # facing_xz - how many degrees the camera will be rotated around the y-axis (south = 0)
  # facing_y - how many degrees the camera will be rotated around the x-axis (up = 90)
  end

  def self.updateTime(geo)
    info_win = App::INFO_WIN
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
    info_win.setpos(16,0)
    info_win.clrtoeol
    info_win.addstr(name)
    info_win.setpos(18,0)
    info_win.clrtoeol
    info_win.addstr(desig)
    info_win.setpos(20,0)
    info_win.clrtoeol
    info_win.addstr(radec)
    info_win.setpos(22,0)
    info_win.clrtoeol
    info_win.addstr(altaz)
    info_win.refresh
  end

  def self.updateMag
    info_win = App::INFO_WIN
    info_win.setpos(2,0)
    info_win.clrtoeol
    info_win.addstr(App::Settings.mag.to_s + " degrees")
    info_win.refresh
  end

  def self.updateVisMag
    info_win = App::INFO_WIN
    info_win.setpos(4,3)
    info_win.clrtoeol
    info_win.addstr(App::Settings.vis_mag.to_s) 
    info_win.refresh
  end

  def self.updateLon
    info_win = App::INFO_WIN
    info_win.setpos(33,0)
    info_win.clrtoeol
    info_win.addstr(App::Settings.lon.to_s)
    info_win.refresh
  end

  def self.updateLat
    info_win = App::INFO_WIN
    info_win.setpos(35,0)
    info_win.clrtoeol
    info_win.addstr(App::Settings.lat.to_s)
    info_win.refresh
  end

  def self.updateGeo
    # Help screen popup with command key list
    win = Curses.stdscr
    geowin = win.subwin(30,60,win.maxy / 2 - 15, win.maxx / 2 - 30)
    geowin.box("|","-")
    Curses.echo
    Curses.curs_set(1)
    geowin.setpos(2,2)
    geowin.addstr("Enter your longitude as decimal degrees, West is negative")
    geowin.setpos(3,2)
    App::Settings.lon = geowin.getstr.to_f
    while !App::Settings.lon.between?(-180,180)
      geowin.setpos(3,2)
      geowin.clrtoeol
      geowin.setpos(2,2)
      geowin.clrtoeol
      geowin.addstr("Out of bounds, must be between -180 and 180, press any key")
      geowin.getch
      geowin.setpos(2,2)
      geowin.clrtoeol
      geowin.addstr("Enter your longitude as decimal degrees, West is negative")
      geowin.setpos(3,2)
      App::Settings.lon = geowin.getstr.to_f
    end
    MyStarsWindows.updateLon
    geowin.setpos(4,2)
    geowin.addstr("Enter your latitude as decimal degrees, West is negative")
    geowin.setpos(5,2)
    App::Settings.lat = geowin.getstr.to_f
    while !App::Settings.lat.between?(-90,90)
      geowin.setpos(5,2)
      geowin.clrtoeol
      geowin.setpos(4,2)
      geowin.clrtoeol
      geowin.addstr("Out of bounds, must be between -90 and 90, press any key")
      geowin.getch
      geowin.setpos(4,2)
      geowin.clrtoeol
      geowin.addstr("Enter your latitude as decimal degrees, West is negative")
      geowin.setpos(5,2)
      App::Settings.lat = geowin.getstr.to_f
    end
    MyStarsWindows.updateLat
    Curses.noecho
    Curses.curs_set(0)
    geowin.refresh
    geowin.clear
    geowin.refresh
    geowin.close
  end

  def self.selectID
    win = App::WIN
    info_win = App::INFO_WIN
    # Highlight the currently selected object
    star = App::Settings.in_view.members.find { |object| object.id == App::Settings.selected_id }

    star_selection_index = App::Settings.in_view.members.find_index(star)

    if star
      App::Settings.in_view.selected = star_selection_index
      xpos, ypos = star.screen_coords(win)
      win.setpos(ypos,xpos)
      win.attrset(Curses::A_REVERSE)
      win.addstr("*")
      win.attrset(Curses::A_NORMAL)
      win.refresh
      MyStarsWindows.updateTargetInfo(info_win)
    end 
  end

  def self.selectNext
    win = App::WIN
    info_win = App::INFO_WIN
    # Highlight the next object in current view
    if App::Settings.in_view.members.empty?
      return nil
    end
    # --- Deselect the previous one
    star = App::Settings.in_view.members[App::Settings.in_view.selected]
    xpos, ypos = star.screen_coords(win)
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
    xpos, ypos = star.screen_coords(win)
    win.setpos(ypos,xpos)
    win.attrset(Curses::A_REVERSE)
    win.addstr("*")
    win.attrset(Curses::A_NORMAL)
    win.refresh
    MyStarsWindows.updateTargetInfo(info_win)
  end

  def self.selectPrev
    win = App::WIN
    info_win = App::INFO_WIN
    # Highlight the previous object in current view
    if App::Settings.in_view.members.empty?
      return nil
    end
    # ---Deselect the previous one
    star = App::Settings.in_view.members[App::Settings.in_view.selected]
    xpos, ypos = star.screen_coords(win)
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
    xpos, ypos = star.screen_coords(win)
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
    helpwin.setpos(6,2)
    helpwin.addstr("(c) to toggle constellation lines")
    helpwin.setpos(7,2)
    helpwin.addstr("(g) to toggle ground visibility")
    helpwin.setpos(8,2)
    helpwin.addstr("(L) to cycle label visibility level")
    helpwin.setpos(9,2)
    helpwin.addstr("(G) to input new geographic location")
    helpwin.setpos(10,2)
    helpwin.addstr("(q) to quit")
    helpwin.refresh
    helpwin.getch
    helpwin.clear
    helpwin.refresh
    helpwin.close
  end

end
