# encoding: utf-8

require 'json'
require 'curses'
require_relative 'stars3d'
require_relative 'helpers'
require_relative 'mystars'

class MyStarsConstellationLabels < MyStars

  # A collection of MyStarsConstellationLabel objects
  attr_accessor :members

  def initialize(file=nil)
    @members = []
    if file
      # Pass in a file with constellation name data and get back an array of
      # MyStarsConstellationName objects.
      data = JSON.parse(File.read(file, :encoding => "utf-8"))['features']
      data.each do |con|
        name = con["properties"]["name"]
        genitive = con["properties"]["gen"]
        ra = con['geometry']['coordinates'][0].long_to_ra.to_f
        dec = con['geometry']['coordinates'][1].to_f
        @members << MyStarsConstellationLabel.new({:name => name, :genitive => genitive, :ra => ra, :dec => dec})
      end
    end
  end

  # TODO
  # Actual drawing should be done by the individual objects instead.
  def draw(pv)
    if App::Settings.show_constellations
    # Get the in-view constellations
      in_view_constellation_names = []
      App::Settings.constellation_names.members.each do |con|
        con.cart_proj = pv * con.cart_world 
        if con.cart_proj[0,0].between?(-1,1) && con.cart_proj[1,0].between?(-1,1) && con.cart_proj[2,0].between?(0,1)
        in_view_constellation_names << con
        end
      end

    # Draw in-view constellations
      win = App::WIN
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
  end

end
