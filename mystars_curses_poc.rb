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
  # Get the alt and azi of the requested star
  origin = collection.members.find { |x| x.id == id }
  centery = origin.alt
  centerx = origin.az
  win.clear
ensure
  Curses.close_screen
end
