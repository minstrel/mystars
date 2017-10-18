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
    # Positions of various info blocks and how many rows to allot
    # FOV (2 rows)
    @pos_fov = 1
    # Visible Magnitude (2 rows)
    @pos_mag = 3
    # Constellation toggle (2 rows)
    @pos_con = 7
    # Ground toggle (2 rows)
    @pos_gnd = 9
    # Object labels (2 rows)
    @pos_lbl = 11
  end

  def drawInfo
    # Initial drawing of info window
    @window.setpos(@pos_fov,0)
    @window.addstr("Field of View alt:")
    @window.setpos(@pos_fov + 1,0)
    @window.addstr(App::Settings.mag.to_s + " degrees")
    @window.setpos(@pos_mag,0)
    @window.addstr("Visible magnitude")
    @window.setpos(@pos_mag + 1,0)
    @window.addstr("<= " + App::Settings.vis_mag.to_s)
    @window.setpos(@pos_con,0)
    @window.addstr("Constellations:")
    @window.setpos(@pos_con + 1,0)
    case App::Settings.show_constellations
    when true
      @window.addstr("Shown")
    when false
      @window.addstr("Hidden")
    end
    @window.setpos(@pos_gnd,0)
    @window.addstr("Ground:")
    @window.setpos(@pos_gnd + 1,0)
    case App::Settings.show_ground
    when true
      @window.addstr("Shown")
    when false
      @window.addstr("Hidden")
    end
    @window.setpos(@pos_lbl,0)
    @window.addstr("Labels:")
    @window.setpos(@pos_lbl + 1,0)
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
    @window.setpos(@pos_con + 1,0)
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
    @window.setpos(@pos_gnd + 1,0)
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
    @window.setpos(@pos_lbl + 1,0)
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
    if star.class == MyStarsStar
      desig = star.desig.to_s + " " + star.con
    end
    radec = star.ra.round(2).to_s + + " / " + star.dec.round(2).to_s
    altaz = star.alt.round(2).to_s + " / " + star.az.round(2).to_s
    @window.setpos(16,0)
    @window.clrtoeol
    @window.addstr(name)
    @window.setpos(18,0)
    @window.clrtoeol
    if star.class == MyStarsStar
      @window.addstr(desig)
    end
    @window.setpos(20,0)
    @window.clrtoeol
    @window.addstr(radec)
    @window.setpos(22,0)
    @window.clrtoeol
    @window.addstr(altaz)
    @window.refresh
  end

  def updateMag
    @window.setpos(@pos_fov + 1,0)
    @window.clrtoeol
    @window.addstr(App::Settings.mag.to_s + " degrees")
    @window.refresh
  end

  def updateVisMag
    @window.setpos(@pos_mag + 1,3)
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
