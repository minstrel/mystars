# encoding: utf-8

require 'date'
require 'json'
require 'curses'
require_relative 'stars3d'
require_relative 'helpers'
require_relative 'mystars'
require_relative 'mystars_window'

class MyStarsInfoWindow < MyStarsWindow
  def initialize(lines, cols, starty, startx)
    super
  end

  def drawInfo
    # Initial drawing of info window
    @window.setpos(1,0)
    @window.addstr("Field of View alt:")
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

  def updateMag
    @window.setpos(2,0)
    @window.clrtoeol
    @window.addstr(App::Settings.mag.to_s + " degrees")
    @window.refresh
  end

  def updateVisMag
    @window.setpos(4,3)
    @window.clrtoeol
    @window.addstr(App::Settings.vis_mag.to_s) 
    @window.refresh
  end
  
  def updateLon
    @window.setpos(33,0)
    @window.clrtoeol
    @window.addstr(App::Settings.lon.to_s)
    @window.refresh
  end
  
  def updateLat
    @window.setpos(35,0)
    @window.clrtoeol
    @window.addstr(App::Settings.lat.to_s)
    @window.refresh
  end
end
