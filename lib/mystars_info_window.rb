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
    # Field of view (2 rows)
    @pos_fov = 1
    # Visible Magnitude (2 rows)
    @pos_mag = 3
    # Current Object header (1 row)
      @pos_chd = 6
      # Current Object Name (2 rows)
      @pos_cna = 7
      # Current Object Designation (2 rows)
      @pos_cde = 9
      # Current Object RA/Dec (2 rows)
      @pos_crd = 11
      # Current Object Alt/Az (2 rows)
      @pos_caa = 13
    # Facing section header (1 row)
      @pos_fhd = 16
      # Facing az (1 row)
      @pos_faz = 17
      # Facing alt (1 row)
      @pos_fal = 18
    # Longitude (2 rows)
      @pos_lon = 20
      # Latitude (2 rows)
      @pos_lat = 22
    # Constellation toggle (2 rows)
      @pos_con = 25
      # Ground toggle (2 rows)
      @pos_gnd = 27
      # Object labels (2 rows)
      @pos_lbl = 29
    # Date (2 rows)
      @pos_dat = 32
      # Time (2 rows)
      @pos_tim = 34
  end

  # TODO
  # To DRY things up, make a method that sets position, color and writes
  # a string

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
    @window.setpos(@pos_lon,0)
    @window.addstr("Longitude:")
    @window.setpos(@pos_lon + 1,0)
    @window.addstr(App::Settings.lon.to_s)
    @window.setpos(@pos_lat,0)
    @window.addstr("Latitude")
    @window.setpos(@pos_lat + 1,0)
    @window.addstr(App::Settings.lat.to_s)
    @window.setpos(@pos_chd,0)
    @window.addstr("Current Object")
    @window.setpos(@pos_cna,0)
    @window.addstr("Name:")
    @window.setpos(@pos_cde,0)
    @window.addstr("Designation:")
    @window.setpos(@pos_crd,0)
    @window.addstr("RA / Dec:")
    @window.setpos(@pos_caa,0)
    @window.addstr("Alt / Az:")
    @window.setpos(@pos_fhd,0)
    @window.addstr("Facing")
    @window.setpos(@pos_faz,0)
    azimuth = 90 - App::Settings.facing_xz
    if azimuth < 0
      azimuth = 360 + azimuth
    end
    @window.addstr("Azimuth: " + azimuth.to_s + " °")
    @window.setpos(@pos_fal,0)
    @window.addstr("Altitude: " + (-App::Settings.facing_y).to_s + " °")
    @window.setpos(@pos_dat,0)
    @window.addstr("Date")
    @window.setpos(@pos_tim,0)
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
    @window.setpos(@pos_faz,0)
    @window.clrtoeol
    azimuth = 90 - App::Settings.facing_xz
    if azimuth < 0
      azimuth = 360 + azimuth
    end
    @window.addstr("Azimuth: " + azimuth.to_s + " °")
    @window.setpos(@pos_fal,0)
    @window.clrtoeol
    @window.addstr("Altitude: " + (-App::Settings.facing_y).to_s + " °")
    @window.refresh
  # facing_xz - how many degrees the camera will be rotated around the y-axis (south = 0)
  # facing_y - how many degrees the camera will be rotated around the x-axis (up = 90)
  end

  def updateTime(geo)
    @window.setpos(@pos_dat + 1,0)
    @window.clrtoeol
    @window.addstr(geo.time.strftime("%Y-%m-%d"))
    @window.setpos(@pos_tim + 1,0)
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
    @window.setpos(@pos_cna + 1,0)
    @window.clrtoeol
    @window.addstr(name)
    @window.setpos(@pos_cde + 1,0)
    @window.clrtoeol
    if star.class == MyStarsStar
      @window.addstr(desig)
    end
    @window.setpos(@pos_crd + 1,0)
    @window.clrtoeol
    @window.addstr(radec)
    @window.setpos(@pos_caa + 1,0)
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
    @window.setpos(@pos_lon + 1,0)
    @window.clrtoeol
    @window.addstr(App::Settings.lon.to_s)
    @window.refresh
  end
  
  def updateLat
    @window.setpos(@pos_lat + 1,0)
    @window.clrtoeol
    @window.addstr(App::Settings.lat.to_s)
    @window.refresh
  end
end
