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
    # Draws the current viewscreen.

    # The current screen
    win = App::WIN

    # Get desired viewing range in degrees
    mag = App::Settings.mag

    # Create the projection view matrix to pass to all the draw methods.
    view = Stars3D.view(0,0,0,App::Settings.facing_y.to_rad,App::Settings.facing_xz.to_rad,0)
    width = ((win.maxx.to_f / win.maxy.to_f) * mag).to_rad

    # Width adjustment to compensate for terminal character size
    # This is pretty arbritrary but I don't see a better way right now
    width = width * 0.5

    height = mag.to_rad
    projection = Stars3D.projection(width, height, 0.25, 1.0)
    pv = projection * view

    # Clear the window
    win.clear

    # Draw in-view constellation lines
    App::Settings.constellation_lines.draw(pv)

    # Draw in-view stars
    App::Settings.collection.draw(pv)

    # Draw in-view constellations
    App::Settings.constellation_names.draw(pv)
    
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
          x0, y0 = MyStarsConstellationLine.screen_coords(win,gp) 
          x1, y1 = MyStarsConstellationLine.screen_coords(win,ground_projection[i+1]) 
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

  def self.updateTargetInfo
    info_win = App::INFO_WIN
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
      MyStarsWindows.updateTargetInfo
    end 
  end

  def self.selectNext
    win = App::WIN
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
    MyStarsWindows.updateTargetInfo
  end

  def self.selectPrev
    win = App::WIN
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
    MyStarsWindows.updateTargetInfo
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
