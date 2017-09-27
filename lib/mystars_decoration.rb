# encoding: utf-8

require 'date'
require 'json'
require 'curses'
require_relative 'stars3d'
require_relative 'helpers'
require_relative 'mystars'

class MyStarsDecoration < MyStars
  # Misc objects to draw on the window.

  def self.drawGround(view, width, height)
    # Draw the ground, if toggled
    win = App::WIN.window
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
  end

  def self.drawCompass(pv)
    # Draw in-view compass points
    win = App::WIN.window
    App::COMPASSPOINTS.each do |key, value|
      compass_projection = pv * value 
      if compass_projection[0,0].between?(-1,1) && compass_projection[1,0].between?(-1,1) && compass_projection[2,0].between?(0,1)
        xpos = (win.maxx - 1) - (((compass_projection[0,0] + 1) / 2.0) * win.maxx).round
        ypos = (win.maxy - 1) - (((compass_projection[1,0] + 1) / 2.0) * win.maxy).round
        win.setpos(ypos,xpos)
        win.addstr(key)
      end
    end
  end

end
