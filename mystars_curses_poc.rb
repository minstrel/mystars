# encoding: utf-8

require 'curses'
require_relative 'mystars'

Curses.init_screen
begin
  # Get the users lon and lat and the hipp. number they want to center on
  win = Curses.stdscr
  win.setpos(win.maxy / 2, 5)
  win.addstr("Enter your longitude as decimal degrees, West is negative")
  win.setpos(win.maxy / 2 + 1, 5)
  lon = win.getstr.to_i
  win.setpos(win.maxy / 2 + 2, 5)
  win.addstr("Enter your latitude as decimal degrees, South is negative")
  win.setpos(win.maxy / 2 + 3, 5)
  lat = win.getstr.to_i
  win.setpos(win.maxy / 2 + 4, 5)
  win.addstr("Enter Hipparcos number on which to center")
  win.setpos(win.maxy / 2 + 5, 5)
  id = win.getstr.to_i
  # Create a new collection based on mag 6 and brighter
  collection = MyStars.newstars_from_JSON(File.read('./data/mystars_6.json'))
  # Create a new local geolocation
  geo = MyStarsGeo.new(lon, lat)
  # Add alt and azi data to the collection
  collection.localize(geo)
  # Remove stars below the horizon
  collection.members.select! { |star| star.alt > 0 }
  # Plot them on x and y axis, circular star map style (hopefully!)
  collection.plot_on_circle
  # Get the x and y of the requested origin star
  origin = collection.members.find { |x| x.id == id }
  centery = origin.circ_y
  centerx = origin.circ_x
  # Iterate through visible stars and try to plot on current screen,
  # given 10 degrees FOV N-S (IE y axis) and enough to fill E-W (x axis)
  miny = centery - 5.0
  maxy = centery + 5.0
  xrange = (win.maxx.to_f / win.maxy.to_f) * 10.0
  minx = centerx - (xrange / 2.0) 
  maxx = centerx + (xrange / 2.0)
  win.clear
  collection.members.each do |star|
    if (star.circ_y.between?(miny,maxy)) && (star.circ_x.between?(minx,maxx))
      # Figure out the y position on current screen
      ypos = (((star.circ_y - miny) / (maxy - miny)).abs * win.maxy ).round
      # Figure out the x position on current screen
      xpos = (((star.circ_x - minx) / (maxx - minx)).abs * win.maxx ).round
      win.setpos(ypos,xpos)
      win.addstr("*")
      win.setpos(ypos+1,xpos)
      win.addstr(star.id.to_s)
      #Ruby issue with displaying UTF-8 multibye characters, using ID for now
      #win.addstr(star.desig + " " + star.con)
    end
  end
  win.getch
ensure
  Curses.close_screen
end
