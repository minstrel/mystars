# encoding: utf-8

#require 'json'
#require 'curses'
require_relative 'stars3d'
require_relative 'helpers'
require_relative 'mystars'

class MyStarsConstellationLines < MyStars
  # A collection of MyStarsConstellationLine objects, each representing the
  # lines of a single constellation.
  attr_accessor :members

  def initialize(file=nil)
    @members = []
    if file
      # Pass in a file with constellation line vertices and get back an array
      # of MyStarsConstellationLine objects.
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
        newconst = MyStarsConstellationLine.new(:id => constellation['id'], :coordinates => coordset )
        @members << newconst
      end 
    end
  end

  # TODO
  # Actual drawing should be done by the individual objects instead.
  def draw(pv)
    # Get and draw in-view constellation lines
    win = App::WIN.window
    if App::Settings.show_constellations
    # Project all the line points into projection view
    # code
      @members.each do |con|
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
      @members.each do |con|
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
            x0, y0 = MyStarsConstellationLine.screen_coords(win,point) 
            x1, y1 = MyStarsConstellationLine.screen_coords(win,line[i+1]) 
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
  end

end
