#!/usr/bin/ruby -w
# encoding: utf-8

require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
require 'date'
require 'json'
require 'matrix'
require_relative 'lib/app'
require_relative 'lib/mystars'
require_relative 'lib/mystars_geo'
require_relative 'lib/mystars_constellation_line'
require_relative 'lib/mystars_constellation_lines'
require_relative 'lib/mystars_constellation_label'
require_relative 'lib/mystars_constellation_labels'
require_relative 'lib/mystars_star'
require_relative 'lib/mystars_fixed_objects'
require_relative 'lib/mystars_window'
require_relative 'lib/mystars_info_window'
require_relative 'lib/mystars_view_window'
require_relative 'lib/mystars_decoration'
require_relative 'lib/mystars_dso'

# Main queue to receive user requests as well as timers and other input.
main_input = Queue.new
# Queue for main thread to tell timer thread it's ok to send another request.
ok_timer = Queue.new

Curses.init_screen
begin
  Curses.start_color
  require_relative 'lib/colors'
  # Main display window
  App::WIN = MyStarsViewWindow.new(Curses.lines,Curses.cols - 18,0,18)
  # Info window
  App::INFO_WIN = MyStarsInfoWindow.new(Curses.lines,18,0,0)
  # Initialize main display window
  win = App::WIN.window
  App::INFO_WIN.drawInfo
  # Allow arrow key / keypad input
  win.keypad = true
  # Get the users lon and lat
  win.setpos(win.maxy / 2, 5)
  win.addstr("Enter your longitude as decimal degrees, West is negative")
  win.setpos(win.maxy / 2 + 1, 5)
  App::Settings.lon = win.getstr.to_f
  while !App::Settings.lon.between?(-180,180)
    win.setpos(win.maxy / 2 + 1, 5)
    win.clrtoeol
    win.setpos(win.maxy / 2, 5)
    win.clrtoeol
    win.addstr("Out of bounds, must be between -180 and 180, press any key")
    win.getch
    win.setpos(win.maxy / 2, 5)
    win.clrtoeol
    win.addstr("Enter your longitude as decimal degrees, West is negative")
    win.setpos(win.maxy / 2 + 1, 5)
    App::Settings.lon = win.getstr.to_f
  end
  App::INFO_WIN.updateLon
  win.setpos(win.maxy / 2 + 2, 5)
  win.addstr("Enter your latitude as decimal degrees, South is negative")
  win.setpos(win.maxy / 2 + 3, 5)
  App::Settings.lat = win.getstr.to_f
  while !App::Settings.lat.between?(-90,90)
    win.setpos(win.maxy / 2 + 3, 5)
    win.clrtoeol
    win.setpos(win.maxy / 2 + 2, 5)
    win.clrtoeol
    win.addstr("Out of bounds, must be between -90 and 90, press any key")
    win.getch
    win.setpos(win.maxy / 2 + 2, 5)
    win.clrtoeol
    win.addstr("Enter your longitude as decimal degrees, West is negative")
    win.setpos(win.maxy / 2 + 3, 5)
    App::Settings.lat = win.getstr.to_f
  end
  App::INFO_WIN.updateLat
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
      if (from_user == 'H') || (from_user == '?')
        main_input << from_user
        Thread.stop
      elsif from_user == 'G'
        main_input << from_user
        Thread.stop
      elsif from_user == 't'
        main_input << from_user
        Thread.stop
      elsif (from_user == 's') || (from_user == '/')
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
  # Create a new collection based on mag 6 and brighter
  App::Settings.collection = MyStarsFixedObjects.new('./data/mystars_6.json', :stars)
  # Add the DSO file
  App::Settings.collection.members += MyStarsFixedObjects.new('./data/dsos_6.json', :dsos).members
  # Get constellation names
  App::Settings.constellation_names = MyStarsConstellationLabels.new('./data/constellations.json')
  # Get constellation lines
  App::Settings.constellation_lines = MyStarsConstellationLines.new('./data/constellations.lines.json')
  # Main input loop
  while input = main_input.pop
    case input
    when 'update'
      # Create a new local geolocation
      geo = MyStarsGeo.new(App::Settings.lon, App::Settings.lat)
      # Add alt and azi data to the collection and add it to world matrix
      App::Settings.collection.localize(geo)
      # Add constellation names to the world matrix
      App::Settings.constellation_names.members.each { |con| con.localize(geo) }
      # Add constellation lines to the world martix
      App::Settings.constellation_lines.members.each { |conline| conline.localize(geo) }
      # Draw a window centered around the input coords
      App::WIN.drawWindow
      App::WIN.selectID
      # If we're updating the geospacial date, time has likely changed too,
      # so update that
      App::INFO_WIN.updateTime(geo) 
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
      when 20..90
        App::Settings.mag -= 5
      else
        # There shouldn't be an else... 
      end
      App::WIN.drawWindow
      App::INFO_WIN.updateMag
      App::WIN.selectID
    when "-"
      # Minus sign, zooms out
      case App::Settings.mag
      when 1..14
        App::Settings.mag += 1
      when 15..85
        App::Settings.mag += 5
      when 90
        # 90 degree max zoom out
      else
        # There shouldn't be an else here either...
      end
      App::WIN.drawWindow
      App::INFO_WIN.updateMag
      App::WIN.selectID
    when 9
      # Tab, cycle through objects
      App::WIN.selectNext
    when Curses::Key::BTAB
      # Shift-Tab, cycle through objects
      App::WIN.selectPrev
    when 'm'
      # Decrease magnitude filter (show more)
      App::Settings.vis_mag += 1
      App::WIN.drawWindow
      App::INFO_WIN.updateVisMag
      App::WIN.selectID
    when 'M'
      # Increase magnitude filter (show less)
      App::Settings.vis_mag -= 1
      App::WIN.drawWindow
      App::INFO_WIN.updateVisMag
      App::WIN.selectID
    when 'g'
      # Toggle ground visibility
      App::Settings.show_ground = !App::Settings.show_ground
      App::WIN.drawWindow
      App::INFO_WIN.updateGround
      App::WIN.selectID
    when 'G'
      # Update geographic location
      MyStarsWindow.updateGeo
      main_input << "update"
      user_input.wakeup
    when 'c'
      # Toggle constellation visibility
      App::Settings.show_constellations = !App::Settings.show_constellations
      App::WIN.drawWindow
      App::INFO_WIN.updateConstellations
      App::WIN.selectID
    when 'H', '?'
      # Help screen
      MyStarsWindow.help
      user_input.wakeup
    when 'L'
      # Label visibility
      App::Settings.labels = App::LABELS.next
      App::WIN.drawWindow
      App::INFO_WIN.updateLabels
      App::WIN.selectID
    when 's', "/"
      # Search screen
      MyStarsWindow.search
      App::INFO_WIN.updateFacing
      main_input << "update"
      user_input.wakeup
    when 't'
      # Change the time
      MyStarsWindow.updateTime
      main_input << "update"
      user_input.wakeup
    when '>'
      # Slow forward time
      if App::Settings.manual_time
        App::Settings.manual_time += Rational( 10 , 86400 )
      else
        App::Settings.manual_time = DateTime.now + Rational( 10 , 86400 )
      end
      App::Settings.update_last_time
      #App::Settings.last_time = App::Settings.timezone.now.to_datetime
      main_input << "update"
    when '<'
      # Slow reverse time
      if App::Settings.manual_time
        App::Settings.manual_time -= Rational( 10 , 86400 )
      else
        App::Settings.manual_time = DateTime.now - Rational( 10 , 86400 )
      end
      App::Settings.update_last_time
      #App::Settings.last_time = App::Settings.timezone.now.to_datetime
      main_input << "update"
    when ']'
      # Fast forward time
      if App::Settings.manual_time
        App::Settings.manual_time += Rational( 600 , 86400 )
      else
        App::Settings.manual_time = DateTime.now + Rational( 600 , 86400 )
      end
      App::Settings.update_last_time
      #App::Settings.last_time = App::Settings.timezone.now.to_datetime
      main_input << "update"
    when '['
      # Fast reverse time
      if App::Settings.manual_time
        App::Settings.manual_time -= Rational( 600 , 86400 )
      else
        App::Settings.manual_time = DateTime.now - Rational( 600 , 86400 )
      end
      App::Settings.update_last_time
      #App::Settings.last_time = App::Settings.timezone.now.to_datetime
      main_input << "update"
    when ' '
      # TODO Pause

    when Curses::Key::LEFT
      App::WIN.move(:left)
      App::WIN.drawWindow
      App::INFO_WIN.updateFacing
      App::WIN.selectID
    when Curses::Key::RIGHT
      App::WIN.move(:right)
      App::WIN.drawWindow
      App::INFO_WIN.updateFacing
      App::WIN.selectID
    when Curses::Key::UP
      App::WIN.move(:up)
      App::WIN.drawWindow
      App::INFO_WIN.updateFacing
      App::WIN.selectID
    when Curses::Key::DOWN
      App::WIN.move(:down)
      App::WIN.drawWindow
      App::INFO_WIN.updateFacing
      App::WIN.selectID
    end
  end
ensure
  user_input.kill
  timer.kill
  Curses.close_screen
end
