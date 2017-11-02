# encoding: utf-8

require 'date'
require 'json'
require 'curses'
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
  def self.draw(win, posy, posx, color, string)
    win.setpos(posy, posx)
    win.clrtoeol
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
    # Force the next update to update the time zone
    App::Settings.timezone = nil
    App::INFO_WIN.updateLat
    Curses.noecho
    Curses.curs_set(0)
    geowin.refresh
    geowin.clear
    geowin.refresh
    geowin.close
  end

  def self.updateTime
    # TODO finish method, accept user input time and use as new base time
    win = Curses.stdscr
    timewin = win.subwin(30,60,win.maxy / 2 - 15, win.maxx / 2 - 30)
    draw(timewin,2,2,0,"Press (1) to set a new time, (2) to set a new date.")
    draw(timewin,3,2,0,"Enter to confirm or Esc to abort")
    timewin.box("|","-")
    timewin.refresh
    timewin.getch
    timewin.clear
    timewin.close
  end

  def self.search
    win = Curses.stdscr
    searchwin = win.subwin(30,60,win.maxy / 2 - 15, win.maxx / 2 - 30)
    searchwin.box("|","-")
    searchwin.setpos(2,2)
    searchwin.addstr("Enter a name to search for")
    searchwin.setpos(3,2)
    Curses.echo
    Curses.curs_set(1)
    searchname = searchwin.getstr
    searchwin.setpos(5,2)
    searchwin.addstr("Showing first 10 results, type number to go to result")
    searchwin.setpos(6,2)
    searchwin.addstr("Any other key to exit")
    searchwin.setpos(7,2)
    # TODO limit search results, enable selection and goto
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
    helpwin.setpos(2,2)
    helpwin.addstr("Arrow keys move around")
    helpwin.setpos(3,2)
    helpwin.addstr("(M) and (m) to filter by magnitude.")
    helpwin.setpos(4,2)
    helpwin.addstr("(+) and (-) to zoom in and out")
    helpwin.setpos(5,2)
    helpwin.addstr("Tab and Shift-Tab to cycle through visible objects")
    helpwin.setpos(6,2)
    helpwin.addstr("(c) to toggle constellation lines")
    helpwin.setpos(7,2)
    helpwin.addstr("(g) to toggle ground visibility")
    helpwin.setpos(8,2)
    helpwin.addstr("(L) to cycle label visibility level")
    helpwin.setpos(9,2)
    helpwin.addstr("(G) to input new geographic location")
    helpwin.setpos(10,2)
    helpwin.addstr("(q) to quit")
    helpwin.refresh
    helpwin.getch
    helpwin.clear
    helpwin.refresh
    helpwin.close
  end

end
