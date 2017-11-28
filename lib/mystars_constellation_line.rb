# encoding: utf-8

#require 'curses'
require_relative 'stars3d'
require_relative 'helpers'
require_relative 'mystars'

class MyStarsConstellationLine < MyStars
  # A set of points of a constellation (the pattern itself, not the bounds)
  # Note that the coordinate sets are arrays of arrays of arrays - multiple
  # lines making up the constellation.
  attr_accessor :id, :coordinates, :cart_world_set, :alt_az_set, :cart_proj_set
  def initialize(attributes)
    @id = attributes[:id]
    @coordinates = attributes[:coordinates]
    @cart_world_set = []
    @alt_az_set = []
    @cart_proj_set = []
  end

  def localize(geo)
    @alt_az_set = []
    @cart_world_set = []
    @coordinates.each do |lines|
      newline = []
      newcartline = []
      lines.each do |point|
        alt = geo.altitude(point[0], point[1])
        az = geo.azimuth(point[0], point[1])
        newline << [alt,az]
        cz = ( Math.cos(alt.to_rad) * Math.sin(az.to_rad) )
        cy = Math.sin(alt.to_rad)
        cx = Math.cos(alt.to_rad) * Math.cos(az.to_rad)
        newcartline << Matrix.column_vector([cx,cy,cz,1])
      end
      @alt_az_set << newline
      @cart_world_set << newcartline
    end
  end

  # TODO this is ugly, screen_coords defined for different classes, this one
  # is using a class method because it's not acting on an instance, just
  # returning some values from input
  def self.screen_coords(win, vector)
    xpos = win.maxx - (((vector[0,0] + 1) / 2.0) * win.maxx).round
    ypos = win.maxy - (((vector[1,0] + 1) / 2.0) * win.maxy).round
    [xpos, ypos]
  end

end
