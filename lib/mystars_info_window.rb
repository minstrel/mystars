# encoding: utf-8

require 'date'
require 'json'
require 'curses'
require_relative 'stars3d'
require_relative 'helpers'
require_relative 'mystars'
require_relative 'mystars_window'

class MyStarsInfoWindow < MyStarsWindow
  def initialize
    super
  end

  def drawInfo
    # Initial drawing of info window
    @window.setpos(1,0)
    @window.addstr("Field of View N/S:")
    @window.setpos(2,0)
    @window.addstr(App::Settings.mag.to_s + " degrees")
    @window.setpos(3,0)
    @window.addstr("Visible magnitude")
    @window.setpos(4,0)
    @window.addstr("<= " + App::Settings.vis_mag.to_s)
    @window.setpos(7,0)
    @window.addstr("Constellations:")
    @window.setpos(8,0)
    case App::Settings.show_constellations
    when true
      @window.addstr("Shown")
    when false
      @window.addstr("Hidden")
    end
    @window.setpos(9,0)
    @window.addstr("Ground:")
    @window.setpos(10,0)
    case App::Settings.show_ground
    when true
      @window.addstr("Shown")
    when false
      @window.addstr("Hidden")
    end
    @window.setpos(11,0)
    @window.addstr("Labels:")
    @window.setpos(12,0)
    case App::Settings.labels
    when :all
      @window.addstr("All stars")
    when :named
      @window.addstr("Named stars only")
    when :none
      @window.addstr("No star labels")
    end
    @window.setpos(32,0)
    @window.addstr("Longitude:")
    @window.setpos(33,0)
    @window.addstr(App::Settings.lon.to_s)
    @window.setpos(34,0)
    @window.addstr("Latitude")
    @window.setpos(35,0)
    @window.addstr(App::Settings.lat.to_s)
    @window.setpos(14,0)
    @window.addstr("Current Object")
    @window.setpos(15,0)
    @window.addstr("Name:")
    @window.setpos(17,0)
    @window.addstr("Designation:")
    @window.setpos(19,0)
    @window.addstr("RA / Dec:")
    @window.setpos(21,0)
    @window.addstr("Alt / Az:")
    @window.setpos(38,0)
    @window.addstr("Facing")
    @window.setpos(39,0)
    azimuth = 90 - App::Settings.facing_xz
    if azimuth < 0
      azimuth = 360 + azimuth
    end
    @window.addstr("Azimuth: " + azimuth.to_s + " °")
    @window.setpos(40,0)
    @window.addstr("Altitude: " + (-App::Settings.facing_y).to_s + " °")
    @window.setpos(41,0)
    @window.addstr("Date")
    @window.setpos(43,0)
    @window.addstr("Time")
    @window.refresh
  end

  def updateConstellations
    @window.setpos(8,0)
    @window.clrtoeol
    case App::Settings.show_constellations
    when true
      @window.addstr("Shown")
    when false
      @window.addstr("Hidden")
    end
    @window.refresh
  end

  def updateGround
    @window.setpos(10,0)
    @window.clrtoeol
    case App::Settings.show_ground
    when true
      @window.addstr("Shown")
    when false
      @window.addstr("Hidden")
    end
    @window.refresh
  end

  def updateLabels
    @window.setpos(12,0)
    @window.clrtoeol
    case App::Settings.labels
    when :all
      @window.addstr("All stars")
    when :named
      @window.addstr("Named stars only")
    when :none
      @window.addstr("No star labels")
    end
    @window.refresh
  end

  def updateFacing
    @window.setpos(39,0)
    @window.clrtoeol
    azimuth = 90 - App::Settings.facing_xz
    if azimuth < 0
      azimuth = 360 + azimuth
    end
    @window.addstr("Azimuth: " + azimuth.to_s + " °")
    @window.setpos(40,0)
    @window.clrtoeol
    @window.addstr("Altitude: " + (-App::Settings.facing_y).to_s + " °")
    @window.refresh
  # facing_xz - how many degrees the camera will be rotated around the y-axis (south = 0)
  # facing_y - how many degrees the camera will be rotated around the x-axis (up = 90)
  end

  def updateTime(geo)
    @window.setpos(42,0)
    @window.clrtoeol
    @window.addstr(geo.time.strftime("%Y-%m-%d"))
    @window.setpos(44,0)
    @window.clrtoeol
    @window.addstr(geo.time.strftime("%H:%M:%S"))
    @window.refresh
  end

  def updateTargetInfo
    star = App::Settings.in_view.members[App::Settings.in_view.selected]
    name = star.name.to_s
    desig = star.desig.to_s + " " + star.con
    radec = star.ra.round(2).to_s + + " / " + star.dec.round(2).to_s
    altaz = star.alt.round(2).to_s + " / " + star.az.round(2).to_s
    @window.setpos(16,0)
    @window.clrtoeol
    @window.addstr(name)
    @window.setpos(18,0)
    @window.clrtoeol
    @window.addstr(desig)
    @window.setpos(20,0)
    @window.clrtoeol
    @window.addstr(radec)
    @window.setpos(22,0)
    @window.clrtoeol
    @window.addstr(altaz)
    @window.refresh
  end

end

# TODO
# Incorporate these methods into this new class, calling them on @window








def self.updateMag
  info_win = App::INFO_WIN
  info_win.setpos(2,0)
  info_win.clrtoeol
  info_win.addstr(App::Settings.mag.to_s + " degrees")
  info_win.refresh
end

def self.updateVisMag
  info_win = App::INFO_WIN
  info_win.setpos(4,3)
  info_win.clrtoeol
  info_win.addstr(App::Settings.vis_mag.to_s) 
  info_win.refresh
end

def self.updateLon
  info_win = App::INFO_WIN
  info_win.setpos(33,0)
  info_win.clrtoeol
  info_win.addstr(App::Settings.lon.to_s)
  info_win.refresh
end

def self.updateLat
  info_win = App::INFO_WIN
  info_win.setpos(35,0)
  info_win.clrtoeol
  info_win.addstr(App::Settings.lat.to_s)
  info_win.refresh
end

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
  MyStarsWindows.updateLon
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
  MyStarsWindows.updateLat
  Curses.noecho
  Curses.curs_set(0)
  geowin.refresh
  geowin.clear
  geowin.refresh
  geowin.close
end

def self.selectID
  win = App::WIN
  # Highlight the currently selected object
  star = App::Settings.in_view.members.find { |object| object.id == App::Settings.selected_id }

  star_selection_index = App::Settings.in_view.members.find_index(star)

  if star
    App::Settings.in_view.selected = star_selection_index
    xpos, ypos = star.screen_coords(win)
    win.setpos(ypos,xpos)
    win.attrset(Curses::A_REVERSE)
    win.addstr("*")
    win.attrset(Curses::A_NORMAL)
    win.refresh
    MyStarsWindows.updateTargetInfo
  end 
end

def self.selectNext
  win = App::WIN
  # Highlight the next object in current view
  if App::Settings.in_view.members.empty?
    return nil
  end
  # --- Deselect the previous one
  star = App::Settings.in_view.members[App::Settings.in_view.selected]
  xpos, ypos = star.screen_coords(win)
  win.setpos(ypos,xpos)
  win.attrset(Curses::A_NORMAL)
  win.addstr("*")
  # ---
  if App::Settings.in_view.selected == App::Settings.in_view.members.length - 1
    App::Settings.in_view.selected = 0
  else
    App::Settings.in_view.selected += 1
  end
  star = App::Settings.in_view.members[App::Settings.in_view.selected]
  # Set targeted ID so we can highlight it again after refresh
  App::Settings.selected_id = star.id
  xpos, ypos = star.screen_coords(win)
  win.setpos(ypos,xpos)
  win.attrset(Curses::A_REVERSE)
  win.addstr("*")
  win.attrset(Curses::A_NORMAL)
  win.refresh
  MyStarsWindows.updateTargetInfo
end

def self.selectPrev
  win = App::WIN
  # Highlight the previous object in current view
  if App::Settings.in_view.members.empty?
    return nil
  end
  # ---Deselect the previous one
  star = App::Settings.in_view.members[App::Settings.in_view.selected]
  xpos, ypos = star.screen_coords(win)
  win.setpos(ypos,xpos)
  win.attrset(Curses::A_NORMAL)
  win.addstr("*")
  # ---
  if (App::Settings.in_view.selected == 0) || (App::Settings.in_view.selected == -1)
    App::Settings.in_view.selected = App::Settings.in_view.members.length - 1
  else
    App::Settings.in_view.selected -= 1
  end
  star = App::Settings.in_view.members[App::Settings.in_view.selected]
  # Set targeted ID so we can highlight it again after refresh
  App::Settings.selected_id = star.id
  xpos, ypos = star.screen_coords(win)
  win.setpos(ypos,xpos)
  win.attrset(Curses::A_REVERSE)
  win.addstr("*")
  win.attrset(Curses::A_NORMAL)
  win.refresh
  MyStarsWindows.updateTargetInfo
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
