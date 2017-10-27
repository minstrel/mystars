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
    # Current Object header (1 row)
      @pos_chd = 1
      # Current Object Name (2 rows)
      @pos_cna = 2
      # Current Object Designation (2 rows)
      @pos_cde = 4
      # Current Object RA/Dec (2 rows)
      @pos_crd = 6
      # Current Object Alt/Az (2 rows)
      @pos_caa = 8
    # Facing section header (1 row)
      @pos_fhd = 11
      # Facing az (1 row)
      @pos_faz = 12
      # Facing alt (1 row)
      @pos_fal = 13
    # Visibility header (1 row)
      @pos_vhd = 15
      # Field of view (2 rows)
      @pos_fov = 16
      # Visible Magnitude (2 rows)
      @pos_mag = 18
    # Settings header (1 row)
      @pos_shd = 21
      # Constellation toggle (2 rows)
      @pos_con = 22
      # Ground toggle (2 rows)
      @pos_gnd = 24
      # Object labels (2 rows)
      @pos_lbl = 26
    # Location / Time header
      @pos_lhd = 29
      # Longitude (2 rows)
      @pos_lon = 30
      # Latitude (2 rows)
      @pos_lat = 32
      # Date (2 rows)
      @pos_dat = 34
      # Time (4 rows)
      # TODO clean up how timezone displays, often spills over rows 
      @pos_tim = 36

    # Colors
      @header_color = 1
      @label_color = 2
  end

  # Private method to set position, clear to end of line, set color
  # and write a string
  # Might need to make another method later without clrtoeol.
  private def draw(posy, posx, color, string)
    @window.setpos(posy, posx)
    @window.clrtoeol
    @window.color_set(color)
    @window.addstr(string)
    @window.color_set(0)
  end

  def drawInfo
    # Initial drawing of info window
    draw(@pos_lhd,0,@header_color,"Location / Time")
    draw(@pos_shd,0,@header_color,"Settings")
    draw(@pos_vhd,0,@header_color,"FOV / Visibility")
    draw(@pos_fov,0,@label_color,"Field of View alt:")
    draw(@pos_fov + 1,0,0,"  " + App::Settings.mag.to_s + " °")
    draw(@pos_mag,0,@label_color,"Visible magnitude")
    draw(@pos_mag + 1,0,0,"  <= " + App::Settings.vis_mag.to_s)
    draw(@pos_con,0,@label_color,"Constellations:")
    draw(@pos_con + 1,0,0,
    case App::Settings.show_constellations
    when true
      "  Shown"
    when false
      "  Hidden"
    end
        )
    draw(@pos_gnd,0,@label_color,"Ground:")
    draw(@pos_gnd + 1,0,0,
    case App::Settings.show_ground
    when true
      "  Shown"
    when false
      "  Hidden"
    end
        )
    draw(@pos_lbl,0,@label_color,"Labels:")
    draw(@pos_lbl + 1,0,0,
    case App::Settings.labels
    when :all
      "  All stars"
    when :named
      "  Named stars only"
    when :none
      "  No star labels"
    end
        )
    draw(@pos_lon,0,@label_color,"Longitude:")
    draw(@pos_lon + 1,0,0,"  " + App::Settings.lon.to_s)
    draw(@pos_lat,0,@label_color,"Latitude:")
    draw(@pos_lat + 1,0,0,"  " + App::Settings.lat.to_s)
    draw(@pos_chd,0,@header_color,"Current Object")
    draw(@pos_cna,0,@label_color,"Name:")
    draw(@pos_cde,0,@label_color,"Designation:")
    draw(@pos_crd,0,@label_color,"RA / Dec:")
    draw(@pos_caa,0,@label_color,"Alt / Az:")
    draw(@pos_fhd,0,@header_color,"Facing")
    azimuth = 90 - App::Settings.facing_xz
    if azimuth < 0
      azimuth = 360 + azimuth
    end
    draw(@pos_faz,0,2,"Azimuth:  ")
    draw(@pos_fal,0,2,"Altitude: ")
    draw(@pos_faz,10,0,azimuth.to_s + " °")
    draw(@pos_fal,10,0,(-App::Settings.facing_y).to_s + " °")
    draw(@pos_dat,0,@label_color,"Date")
    draw(@pos_tim,0,@label_color,"Time")
    @window.refresh
  end

  def updateConstellations
    draw(@pos_con + 1,0,0,
    case App::Settings.show_constellations
    when true
      "  Shown"
    when false
      "  Hidden"
    end
        )
    @window.refresh
  end

  def updateGround
    draw(@pos_gnd + 1,0,0,
    case App::Settings.show_ground
    when true
      "  Shown"
    when false
      "  Hidden"
    end
        )
    @window.refresh
  end

  def updateLabels
    draw(@pos_lbl + 1,0,0,
    case App::Settings.labels
    when :all
      "  All stars"
    when :named
      "  Named stars only"
    when :none
      "  No star labels"
    end
        )
    @window.refresh
  end

  def updateFacing
    azimuth = 90 - App::Settings.facing_xz
    if azimuth < 0
      azimuth = 360 + azimuth
    end
    draw(@pos_faz,10,0,azimuth.to_s + " °")
    draw(@pos_fal,10,0,(-App::Settings.facing_y).to_s + " °")
    @window.refresh
  # facing_xz - how many degrees the camera will be rotated around the y-axis (south = 0)
  # facing_y - how many degrees the camera will be rotated around the x-axis (up = 90)
  end

  def updateTime(geo)
    draw(@pos_dat + 1,0,0,"  " + geo.time.strftime("%Y-%m-%d"))
    draw(@pos_tim + 1,0,0,"  " + geo.time.strftime("%H:%M:%S"))
    draw(@pos_tim + 2,0,0,"  " + App::Settings.timezone.to_s)
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
    draw(@pos_cna + 1,0,0,"  " + name)
    draw(@pos_cde + 1,0,0,"  " + 
    if star.class == MyStarsStar
      desig
    else
      ""
    end
        )
    draw(@pos_crd + 1,0,0,"  " + radec)
    draw(@pos_caa + 1,0,0,"  " + altaz)
    @window.refresh
  end

  def updateMag
    draw(@pos_fov + 1,0,0,"  " + App::Settings.mag.to_s + " °")
    @window.refresh
  end

  def updateVisMag
    draw(@pos_mag + 1,4,0," " + App::Settings.vis_mag.to_s) 
    @window.refresh
  end
  
  def updateLon
    draw(@pos_lon + 1,0,0,"  " + App::Settings.lon.to_s)
    @window.refresh
  end
  
  def updateLat
    draw(@pos_lat + 1,0,0,"  " + App::Settings.lat.to_s)
    @window.refresh
  end
end
