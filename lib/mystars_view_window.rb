# encoding: utf-8

require 'date'
require 'json'
require 'curses'
require_relative 'stars3d'
require_relative 'helpers'
require_relative 'mystars'
require_relative 'mystars_window'

class MyStarsViewWindow < MyStarsWindow
  def initialize(lines, cols, starty, startx)
    super
  end

  def drawWindow
    # Draws the current viewscreen.
    # Actual drawing mostly done by the objects' methods, while this class
    # exists to put them in the right order and feed them
    # info like the projection view matrix.

    # Get desired viewing range in degrees
    mag = App::Settings.mag

    # Create the projection view matrix to pass to all the draw methods.
    view = Stars3D.view(0,0,0,App::Settings.facing_y.to_rad,App::Settings.facing_xz.to_rad,0)
    width = ((@window.maxx.to_f / @window.maxy.to_f) * mag).to_rad

    # Width adjustment to compensate for terminal character size
    # This is pretty arbritrary but I don't see a better way right now
    width = width * 0.5

    height = mag.to_rad
    projection = Stars3D.projection(width, height, 0.25, 1.0)
    pv = projection * view

    # Clear the window
    @window.clear

    # Draw in-view constellation lines
    App::Settings.constellation_lines.draw(pv)

    # Draw in-view stars
    App::Settings.collection.draw(pv)

    # Draw in-view constellations
    App::Settings.constellation_names.draw(pv)
    
    # TODO break ground and compass out into a decoration class
    # and let them draw themselves like the other stuff does.
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
          x0, y0 = MyStarsConstellationLine.screen_coords(@window,gp) 
          x1, y1 = MyStarsConstellationLine.screen_coords(@window,ground_projection[i+1]) 
          horizon_points_to_draw += Stars3D.create_points(x0,y0,x1,y1)
          end
        end
      end
      # Filter uniques.
      horizon_points_to_draw = horizon_points_to_draw.uniq
      # Draw horizon points and fill screen below them
      horizon_points_to_draw.each do |point|
        if (point[:y] < @window.maxy-1) && (point[:x].between?(0,@window.maxx-1))
          (point[:y]).upto(@window.maxy-1) do |y|
            @window.setpos(y,point[:x])
            @window.addstr("#")
          end
        end
      end
    end

    # Draw in-view compass points
    App::COMPASSPOINTS.each do |key, value|
      compass_projection = pv * value 
      if compass_projection[0,0].between?(-1,1) && compass_projection[1,0].between?(-1,1) && compass_projection[2,0].between?(0,1)
        xpos = @window.maxx - (((compass_projection[0,0] + 1) / 2.0) * @window.maxx).round
        ypos = @window.maxy - (((compass_projection[1,0] + 1) / 2.0) * @window.maxy).round
        @window.setpos(ypos,xpos)
        @window.addstr(key)
      end
    end

    @window.refresh

  end 

  # Increment current camera angle
  def move(direction)
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
  
  def selectID
    # Highlight the currently selected object
    star = App::Settings.in_view.members.find { |object| object.id == App::Settings.selected_id }

    star_selection_index = App::Settings.in_view.members.find_index(star)

    if star
      App::Settings.in_view.selected = star_selection_index
      xpos, ypos = star.screen_coords(@window)
      @window.setpos(ypos,xpos)
      @window.attrset(Curses::A_REVERSE)
      @window.addstr("*")
      @window.attrset(Curses::A_NORMAL)
      @window.refresh
      App::INFO_WIN.updateTargetInfo
    end 
  end

  def selectNext
    # Highlight the next object in current view
    if App::Settings.in_view.members.empty?
      return nil
    end
    # --- Deselect the previous one
    star = App::Settings.in_view.members[App::Settings.in_view.selected]
    xpos, ypos = star.screen_coords(@window)
    @window.setpos(ypos,xpos)
    @window.attrset(Curses::A_NORMAL)
    @window.addstr("*")
    # ---
    if App::Settings.in_view.selected == App::Settings.in_view.members.length - 1
      App::Settings.in_view.selected = 0
    else
      App::Settings.in_view.selected += 1
    end
    star = App::Settings.in_view.members[App::Settings.in_view.selected]
    # Set targeted ID so we can highlight it again after refresh
    App::Settings.selected_id = star.id
    xpos, ypos = star.screen_coords(@window)
    @window.setpos(ypos,xpos)
    @window.attrset(Curses::A_REVERSE)
    @window.addstr("*")
    @window.attrset(Curses::A_NORMAL)
    @window.refresh
    App::INFO_WIN.updateTargetInfo
  end

  def selectPrev
    # Highlight the previous object in current view
    if App::Settings.in_view.members.empty?
      return nil
    end
    # ---Deselect the previous one
    star = App::Settings.in_view.members[App::Settings.in_view.selected]
    xpos, ypos = star.screen_coords(@window)
    @window.setpos(ypos,xpos)
    @window.attrset(Curses::A_NORMAL)
    @window.addstr("*")
    # ---
    if (App::Settings.in_view.selected == 0) || (App::Settings.in_view.selected == -1)
      App::Settings.in_view.selected = App::Settings.in_view.members.length - 1
    else
      App::Settings.in_view.selected -= 1
    end
    star = App::Settings.in_view.members[App::Settings.in_view.selected]
    # Set targeted ID so we can highlight it again after refresh
    App::Settings.selected_id = star.id
    xpos, ypos = star.screen_coords(@window)
    @window.setpos(ypos,xpos)
    @window.attrset(Curses::A_REVERSE)
    @window.addstr("*")
    @window.attrset(Curses::A_NORMAL)
    @window.refresh
    App::INFO_WIN.updateTargetInfo
  end

end
