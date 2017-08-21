#!/usr/bin/ruby -w
# encoding: utf-8

require 'curses'
require_relative 'mystars'

Curses.init_screen
begin
  win = Curses.stdscr
  # Allow arrow key / keypad input
  win.keypad = true
  # Get the users lon and lat and the hipp. number they want to center on
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
  collection = MyStars.newstars_from_JSON(File.read('./data/mystars_6.json', :encoding => 'UTF-8'))
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
  # Draw a window centered around the input coords
  MyStarsWindows.drawWindow(centery,centerx,collection,win)
  while input = win.getch
    case input
    when 10
      break
    when Curses::Key::LEFT
      centerx -= 1
      MyStarsWindows.drawWindow(centery,centerx,collection,win)
    when Curses::Key::RIGHT
      centerx += 1
      MyStarsWindows.drawWindow(centery,centerx,collection,win)
    when Curses::Key::UP
      centery -= 1
      MyStarsWindows.drawWindow(centery,centerx,collection,win)
    when Curses::Key::DOWN
      centery += 1
      MyStarsWindows.drawWindow(centery,centerx,collection,win)
    end
    if input == 10
      break
    end
  end
ensure
  Curses.close_screen
end
