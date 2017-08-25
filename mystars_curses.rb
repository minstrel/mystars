#!/usr/bin/ruby -w
# encoding: utf-8

require 'curses'
require_relative 'mystars'

# Main queue to receive user requests as well as timers and other input.
main_input = Queue.new
# Queue for main thread to tell timer thread it's ok to send another request.
ok_timer = Queue.new

Curses.init_screen
begin
  # Initialize main display window
  win = Curses::Window.new(Curses.lines,Curses.cols - 18,0,18)
  # Initialize info window
  info_win = Curses::Window.new(Curses.lines,18,0,0)
  MyStarsWindows.drawInfo(info_win)
  # Allow arrow key / keypad input
  win.keypad = true
  # Get the users lon and lat
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
  # Don't echo input
  Curses.noecho
  # No cursor
  Curses.curs_set(0)
  # Trigger initial update
  # Make sure this stays above user input thread, so the screen always gets
  # drawn before anything else happens.
  main_input << "update"
  # User input thread
  user_input = Thread.new do
    begin
    while from_user = win.getch
      if from_user == 'h'
        main_input << from_user
        Thread.stop
      else
      main_input << from_user
      end
    end
    ensure
      Curses.close_screen
    end
  end
  # Timer thread, to automatically update the time and view
  # As soon as main thread reports "OK" that it's finished an update,
  # timer waits selected amount of time, then requests another.  This
  # will result in that time being slightly longer, on average.
  timer = Thread.new do
    loop do
      while ok_timer.pop
        sleep(App::Settings.timer)
        main_input << "update"
      end
    end
  end
  # Main input loop
  while input = main_input.pop
    case input
    when 'update'
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
      # Draw a window centered around the input coords
      MyStarsWindows.drawWindow(win)
      MyStarsWindows.selectID(win, info_win)
      # If we're updating the geospacial date, time has likely changed too,
      # so update that
      MyStarsWindows.updateTime(info_win,geo) 
      ok_timer << "OK"
    when 'q'
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
      MyStarsWindows.selectID(win, info_win)
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
      MyStarsWindows.selectID(win, info_win)
    when 9
      # Tab, cycle through objects
      MyStarsWindows.selectNext(win, info_win)
    when Curses::Key::BTAB
      # Shift-Tab, cycle through objects
      MyStarsWindows.selectPrev(win, info_win)
    when 'm'
      # Decrease magnitude filter (show more)
      App::Settings.vis_mag += 1
      MyStarsWindows.drawWindow(win)
      MyStarsWindows.updateVisMag(info_win)
      MyStarsWindows.selectID(win, info_win)
    when 'M'
      # Increase magnitude filter (show less)
      App::Settings.vis_mag -= 1
      MyStarsWindows.drawWindow(win)
      MyStarsWindows.updateVisMag(info_win)
      MyStarsWindows.selectID(win, info_win)
    when 'h'
      # Help screen
      MyStarsWindows.help
      user_input.wakeup
    when 's'
      # Search screen
      MyStarsWindows.search
    when Curses::Key::LEFT
      App::Settings.centerx -= 1
      MyStarsWindows.drawWindow(win)
      MyStarsWindows.selectID(win, info_win)
    when Curses::Key::RIGHT
      App::Settings.centerx += 1
      MyStarsWindows.drawWindow(win)
      MyStarsWindows.selectID(win, info_win)
    when Curses::Key::UP
      App::Settings.centery -= 1
      MyStarsWindows.drawWindow(win)
      MyStarsWindows.selectID(win, info_win)
    when Curses::Key::DOWN
      App::Settings.centery += 1
      MyStarsWindows.drawWindow(win)
      MyStarsWindows.selectID(win, info_win)
    end
  end
ensure
  user_input.kill
  timer.kill
  Curses.close_screen
end
