# encoding: utf-8

require 'curses'
require_relative 'stars3d'
require_relative 'helpers'
require_relative 'mystars'

class MyStarsConstellationLabel < MyStars
  # A single constellation label
  attr_accessor :name, :genitive, :ra, :dec, :alt, :az, :cart_world, :cart_proj
  def initialize(attributes)
    @name = attributes[:name]
    @genitive = attributes[:genitive]
    @ra = attributes[:ra]
    @dec = attributes[:dec]
  end

  def localize(geo)
    @alt = geo.altitude(@ra, @dec)
    @az = geo.azimuth(@ra, @dec)
    cz = ( Math.cos(@alt.to_rad) * Math.sin(@az.to_rad) )
    cy = Math.sin(@alt.to_rad)
    cx = Math.cos(@alt.to_rad) * Math.cos(@az.to_rad)
    @cart_world = Matrix.column_vector([cx,cy,cz,1])
  end

  def screen_coords(win)
    xpos = win.maxx - (((@cart_proj[0,0] + 1) / 2.0) * win.maxx).round
    ypos = win.maxy - (((@cart_proj[1,0] + 1) / 2.0) * win.maxy).round
    [xpos, ypos]
  end

end
