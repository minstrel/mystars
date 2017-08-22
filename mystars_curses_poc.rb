#!/usr/bin/ruby -w
# encoding: utf-8

require 'curses'
require_relative 'mystars'

Curses.init_screen
begin
  # Initialize main display window
  win = Curses::Window.new(Curses.lines,Curses.cols - 18,0,18)
  # Initialize info window
  info_win = Curses::Window.new(Curses.lines,18,0,0)
  MyStarsWindows.drawInfo(info_win)
  # Allow arrow key / keypad input
  win.keypad = true
  # Get the users lon and lat and the hipp. number they want to center on
  win.setpos(win.maxy / 2, 5)
  win.addstr("Enter your longitude as decimal degrees, West is negative")
  win.setpos(win.maxy / 2 + 1, 5)
  App::Settings.lon = win.getstr.to_f
  MyStarsWindows.updateLon(info_win)
  win.setpos(win.maxy / 2 + 2, 5)
  win.addstr("Enter your latitude as decimal degrees, South is negative")
  win.setpos(win.maxy / 2 + 3, 5)
  App::Settings.lat = win.getstr.to_f
  MyStarsWindows.updateLat(info_win)
  #win.setpos(win.maxy / 2 + 4, 5)
  #win.addstr("Enter Hipparcos number on which to center")
  #win.setpos(win.maxy / 2 + 5, 5)
  #id = win.getstr.to_i
  # Create a new collection based on mag 6 and brighter
  App::Settings.collection = MyStars.newstars_from_JSON(File.read('./data/mystars_6.json', :encoding => 'UTF-8'))
  # Create a new local geolocation
  geo = MyStarsGeo.new(App::Settings.lon, App::Settings.lat)
  # Add alt and azi data to the collection
  App::Settings.collection.localize(geo)
  # Remove stars below the horizon
  App::Settings.collection.members.select! { |star| star.alt > 0 }
  # Plot them on x and y axis, circular star map style (hopefully!)
  App::Settings.collection.plot_on_circle
  # Get the x and y of the requested origin star
  #origin = App::Settings.collection.members.find { |x| x.id == id }
  App::Settings.centery = 0
  App::Settings.centerx = 0
  # Sets magnification to initial North-South value in degrees
  # Moved to App::Settings
  # mag = 10
  # Draw a window centered around the input coords
  MyStarsWindows.drawWindow(win)
  # Don't echo input
  Curses.noecho
  # No cursor
  Curses.curs_set(0)
  while input = win.getch
    case input
    when 10
      break
    when "+"
      # Plus sign, zooms in
      case App::Settings.mag
      when 1
        # 1 degree max zoom in
      when 2..15
        App::Settings.mag -= 1
      when 20..180
        App::Settings.mag -= 5
      else
        # There shouldn't be an else... 
      end
      MyStarsWindows.drawWindow(win)
      MyStarsWindows.updateMag(info_win)
    when "-"
      # Minus sign, zooms out
      case App::Settings.mag
      when 1..14
        App::Settings.mag += 1
      when 15..175
        App::Settings.mag += 5
      when 180
        # 180 degree max zoom out
      else
        # There shouldn't be an else here either...
      end
      MyStarsWindows.drawWindow(win)
      MyStarsWindows.updateMag(info_win)
    when 9
      MyStarsWindows.selectNext(win, info_win)
    when Curses::Key::BTAB
      MyStarsWindows.selectPrev(win, info_win)
    when Curses::Key::LEFT
      App::Settings.centerx -= 1
      MyStarsWindows.drawWindow(win)
    when Curses::Key::RIGHT
      App::Settings.centerx += 1
      MyStarsWindows.drawWindow(win)
    when Curses::Key::UP
      App::Settings.centery -= 1
      MyStarsWindows.drawWindow(win)
    when Curses::Key::DOWN
      App::Settings.centery += 1
      MyStarsWindows.drawWindow(win)
    end
    if input == 10
      break
    end
  end
ensure
  Curses.close_screen
end
