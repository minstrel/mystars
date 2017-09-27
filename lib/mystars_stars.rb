# encoding: utf-8

require 'json'
require 'curses'
require_relative 'stars3d'
require_relative 'helpers'
require_relative 'mystars'

class MyStarsStars < MyStars
  # This represents a collection of stars

  # TODO Now that we're importing two types of data, both of which will be
  # part of the in_view collection, we need a way to merge both.
  # I think the best way is to offload the drawing itself onto the individual
  # objects and have a draw method defined on each type.
  # Then maybe we don't need a separate collection class for each.

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
  # TODO I don't think @cart_world gets used after this, so maybe it would be
  # better to just draw it here or mesh this with the draw method?
  def localize(geo)
    @members.each do |star|
      star.localize(geo)
    end
  end

  def draw(pv)
    # Draw current stars in DB to screen.

    # This is probably inefficent as it polls all available stars, but
    # hopefully good enough for now.

    win = App::WIN.window

    # Filter out stars below visible magnitude
    collection = @members.select { |member| member.mag <= App::Settings.vis_mag }

    # If we're drawing a window, the in_view stars have moved, so clear it
    App::Settings.in_view = MyStarsStars.new

    # Add visible stars to in view collection
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

    # This should get outsourced to the MyStarsStar instead
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

    # Sort the in_view stars by x, then y for tabbing
    # Might be worth benchmarking later...
    App::Settings.in_view.members.sort! do |a, b|
      (a.cart_proj[1,0] + 1.0) * 1000 - (a.cart_proj[0,0] + 1.0) <=> (b.cart_proj[1,0] + 1.0) * 1000 - (b.cart_proj[0,0] + 1.0)
    end
    # Sort it better instead of doing this.
    App::Settings.in_view.members.reverse!

  end

end
