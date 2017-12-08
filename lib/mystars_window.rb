# encoding: utf-8

#require 'date'
#require 'json'
#require 'curses'
require_relative 'stars3d'
require_relative 'helpers'
require_relative 'mystars'

class MyStarsWindow < MyStars
  # Master Window class, stores the Curses window object, should be called
  # with super from subclasses.
  # Also for the time being, transient windows will be called from here as
  # class methods.
  attr_accessor :window

  def initialize(lines, cols, starty, startx)
    # Number of lines, columns, upper left corner y and x coordinates
    @window = Curses::Window.new(lines, cols, starty, startx)
  end

  # Draw method with specified window
  def self.draw(win, posy, posx, color, string, clear = true)
    win.setpos(posy, posx)
    win.clrtoeol if clear
    win.color_set(color)
    win.addstr(string)
    win.color_set(0)
  end

  private_class_method :draw

  def self.updateGeo
  # Help screen popup with command key list
    win = Curses.stdscr
    geowin = win.subwin(30,60,win.maxy / 2 - 15, win.maxx / 2 - 30)
    geowin.box("|","-")
    Curses.echo
    Curses.curs_set(1)
    geowin.setpos(2,2)
    geowin.addstr("Enter your longitude as decimal degrees, West is negative")
    geowin.setpos(3,2)
    App::Settings.lon = geowin.getstr.to_f
    while !App::Settings.lon.between?(-180,180)
      geowin.setpos(3,2)
      geowin.clrtoeol
      geowin.setpos(2,2)
      geowin.clrtoeol
      geowin.addstr("Out of bounds, must be between -180 and 180, press any key")
      geowin.getch
      geowin.setpos(2,2)
      geowin.clrtoeol
      geowin.addstr("Enter your longitude as decimal degrees, West is negative")
      geowin.setpos(3,2)
      App::Settings.lon = geowin.getstr.to_f
    end
    App::INFO_WIN.updateLon
    geowin.setpos(4,2)
    geowin.addstr("Enter your latitude as decimal degrees, West is negative")
    geowin.setpos(5,2)
    App::Settings.lat = geowin.getstr.to_f
    while !App::Settings.lat.between?(-90,90)
      geowin.setpos(5,2)
      geowin.clrtoeol
      geowin.setpos(4,2)
      geowin.clrtoeol
      geowin.addstr("Out of bounds, must be between -90 and 90, press any key")
      geowin.getch
      geowin.setpos(4,2)
      geowin.clrtoeol
      geowin.addstr("Enter your latitude as decimal degrees, West is negative")
      geowin.setpos(5,2)
      App::Settings.lat = geowin.getstr.to_f
    end
    # If we have a manual time, get the old offset to use later
    if App::Settings.manual_time
      old_offset = App::Settings.manual_time.offset
    end
    # Update the time zone
    tf = TimezoneFinder.create
    tz = tf.timezone_at(lng: App::Settings.lon, lat: App::Settings.lat)
    if tz == nil
      (1..20).step(2) do |x|
        tz = tf.closest_timezone_at(lng: App::Settings.lon, lat: App::Settings.lat, delta_degree: x)
        break if tz
      end
    end
    # Fall back to EST if we can't find a proper zone
    if tz == nil
      tz = 'America/New_York'
    end
    App::Settings.timezone = TZInfo::Timezone.get(tz)
    # TODO If we update the location, we need to update App::Settings.manual_time to
    # be the same UTC time with the new offset.
    # This means we might need to update App::Settings.timezone now instead of when
    # update is run.

    if App::Settings.manual_time

      # Another kludge to get the resulting DateTime object to have the right offset
      # If tzinfo gets updated, we can just call TZInfo::DataTimezone#utc_to_local

      # Get the current date and time from App::Settings.manual_time
      hour = App::Settings.manual_time.hour
      min = App::Settings.manual_time.min
      sec = App::Settings.manual_time.sec
      year = App::Settings.manual_time.year
      month = App::Settings.manual_time.month
      day = App::Settings.manual_time.day
      
      # Use current date and time to figure out the offset at the new geo location
      period = App::Settings.timezone.period_for_local(Time.new(year,month,day,hour,min,sec))
      new_offset = Rational( (period.utc_offset + period.std_offset) , 86400 )

      # Use the new offset to set App::Settings.manual_time to the right time with
      # the right offset.
      new_time = App::Settings.manual_time - (old_offset - new_offset)
      hour = new_time.hour
      min = new_time.min
      sec = new_time.sec
      year = new_time.year
      month = new_time.month
      day = new_time.day
      App::Settings.manual_time = DateTime.new(year, month, day, hour, min, sec, new_offset)

    end

    App::INFO_WIN.updateLat
    Curses.noecho
    Curses.curs_set(0)
    geowin.refresh
    geowin.clear
    geowin.refresh
    geowin.close
  end

  def self.updateTime
    # Get new date and/or time from user, set as effective datetime
    win = Curses.stdscr
    timewin = win.subwin(30,60,win.maxy / 2 - 15, win.maxx / 2 - 30)
    draw(timewin,2,2,0,"Press (1) to set a new time, (2) to set a new date.")
    draw(timewin,3,2,0,"Enter to confirm or escape to exit")
    timewin.box("|","-")
    timewin.refresh
    if App::Settings.manual_time
      hour = App::Settings.manual_time.hour
      min = App::Settings.manual_time.min
      sec = App::Settings.manual_time.sec
      year = App::Settings.manual_time.year
      month = App::Settings.manual_time.month
      day = App::Settings.manual_time.day
    else
      now = App::Settings.timezone.now.to_datetime
      # now = Time.now
      hour = now.hour
      min = now.min
      sec = now.sec
      year = now.year
      month = now.month
      day = now.day 
    end
    while input = timewin.getch
      case input
      when "1" # New Time
        draw(timewin,5,2,0,"Enter new local time in 24-hour format")
        draw(timewin,6,2,0,"HH-MM-SS")
        draw(timewin,7,4,0,"-")
        draw(timewin,7,7,0,"-")
        timewin.box("|","-")
        Curses.echo
        Curses.curs_set(1)
        timewin.setpos(7,2)
        # TODO put some checks for proper numeric input values here
        hour = (timewin.getch + timewin.getch).to_i
        timewin.setpos(7,5)
        min = (timewin.getch + timewin.getch).to_i
        timewin.setpos(7,8)
        sec = (timewin.getch + timewin.getch).to_i
        Curses.noecho
        Curses.curs_set(0)
        draw(timewin,11,2,0,"New time to set:", false)
        draw(timewin,12,2,0,"#{hour}-#{min}-#{sec}", false)
        draw(timewin,5,2,0,"")
        draw(timewin,6,2,0,"")
        draw(timewin,7,2,0,"")
        timewin.box("|","-")
      when "2" # New Date
        draw(timewin,5,2,0,"Enter new date in YYYY-MM-DD format")
        draw(timewin,6,2,0,"YYYY-MM-DD")
        draw(timewin,7,6,0,"-")
        draw(timewin,7,9,0,"-")
        timewin.box("|","-")
        Curses.echo
        Curses.curs_set(1)
        timewin.setpos(7,2)
        # TODO put some checks for proper numeric input values here
        year = (timewin.getch + timewin.getch + timewin.getch + timewin.getch).to_i
        timewin.setpos(7,7)
        month = (timewin.getch + timewin.getch).to_i
        timewin.setpos(7,10)
        day = (timewin.getch + timewin.getch).to_i
        Curses.noecho
        Curses.curs_set(0)
        draw(timewin,11,24,0,"New date to set:", false)
        draw(timewin,12,24,0,"#{year}-#{month}-#{day}", false)
        draw(timewin,5,2,0,"")
        draw(timewin,6,2,0,"")
        draw(timewin,7,2,0,"")
        timewin.box("|","-")
      when 10 # Enter / confirm
        # Update manual time to the input time
        # TZInfo gem currently (1.4.2) outputs timezone.now as the local time but with 0 offset
        # So the below is necessary.  When that bug is fixed in a future gem, we can just go
        # back to using App::Settings.timezone.now.to_datetime
        period = App::Settings.timezone.period_for_local(Time.new(year,month,day,hour,min,sec))
        offset = Rational( (period.utc_offset + period.std_offset) , 86400 )
        App::Settings.manual_time = DateTime.new(year, month, day, hour, min, sec, offset)
        # Update the last updated time to now, so ticks proceed normally from here
        now = App::Settings.timezone.now.to_datetime
        hour = now.hour
        min = now.min
        sec = now.sec
        year = now.year
        month = now.month
        day = now.day 
        App::Settings.last_time = DateTime.new(year,month,day,hour,min,sec,offset)
        break
      when 27 # Escape / abort
        break
      else
        nil
      end
    end
    timewin.clear
    timewin.close
  end

  def self.search
    win = Curses.stdscr
    searchwin = win.subwin(30,60,win.maxy / 2 - 15, win.maxx / 2 - 30)
    searchwin.box("|","-")
    draw(searchwin,2,2,0,"Enter a name to search for",false)
    searchwin.setpos(3,2)
    Curses.echo
    Curses.curs_set(1)
    searchname = searchwin.getstr
    searchwin.setpos(5,2)
    draw(searchwin,5,2,0,"Showing first 10 results, type number to go to result",false)
    draw(searchwin,6,2,0,"Any other key to exit",false)
    searchwin.setpos(7,2)
    # Match names containing the searched string, case-insensitive
    matches = App::Settings.collection.members.select { |o| o.name.downcase.delete(" ") =~ /#{searchname.downcase.delete("  ")}/ }
    if matches.length == 0
      searchwin.setpos(searchwin.cury+1,2)
      searchwin.addstr("No results found, any key to exit")
    else
      matches[(0..10)].each.with_index do |m, i|
        searchwin.setpos(searchwin.cury+1,2)
        searchwin.addstr("(#{i.to_s})" + " - " + m.name)
      end
    end
    Curses.noecho
    Curses.curs_set(0)
    searchwin.refresh
    # Goto the search number typed, TODO makes this a navigable menu
    goto = searchwin.getch
    if !(goto =~ /\d/) # If -not- a digit
      nil
    else
      App::Settings.facing_y = -(matches[goto.to_i].alt).round
      App::Settings.facing_xz = 90 - matches[goto.to_i].az.round
      if App::Settings.facing_xz < 0
        App::Settings.facing_xz += 360
      end
    end
    searchwin.clear
    searchwin.refresh
    searchwin.close
  end

  def self.help
    # Help screen popup with command key list
    win = Curses.stdscr
    helpwin = win.subwin(30,60,win.maxy / 2 - 15, win.maxx / 2 - 30)
    helpwin.box("|","-")
    draw(helpwin,2,2,0,"Arrow keys move around",false)
    draw(helpwin,3,2,0,"(M) and (m) to filter by magnitude.",false)
    draw(helpwin,4,2,0,"(+) and (-) to zoom in and out",false)
    draw(helpwin,5,2,0,"Tab and Shift-Tab to cycle through visible objects",false)
    draw(helpwin,6,2,0,"(c) to toggle constellation lines",false)
    draw(helpwin,7,2,0,"(g) to toggle ground visibility",false)
    draw(helpwin,8,2,0,"(L) to cycle label visibility level",false)
    draw(helpwin,9,2,0,"(G) to input new geographic location",false)
    draw(helpwin,10,2,0,"(q) to quit",false)
    draw(helpwin,11,2,0,"(t) to change current date and time",false)
    draw(helpwin,12,2,0,"(>) or (<) to fast forward/reverse 10 seconds",false)
    draw(helpwin,13,2,0,"(]) or ([) to fast forward/reverse 10 minutes",false)
    helpwin.refresh
    helpwin.getch
    helpwin.clear
    helpwin.refresh
    helpwin.close
  end

end
