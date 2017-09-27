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
    App::INFO_WIN.updateLon
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
    App::INFO_WIN.updateLat
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
      App::INFO_WIN.updateTargetInfo
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
    App::INFO_WIN.updateTargetInfo
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
    App::INFO_WIN.updateTargetInfo
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
