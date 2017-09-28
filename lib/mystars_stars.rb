# encoding: utf-8

require 'json'
require 'curses'
require_relative 'stars3d'
require_relative 'helpers'
require_relative 'mystars'

class MyStarsStars < MyStars
  # This represents a collection of stars

  # TODO Now that we're importing two types of data, both of which will be
  # part of the in_view collection, we need a way to merge both.
  # I think the best way is to offload the drawing itself onto the individual
  # objects and have a draw method defined on each type.
  # Then maybe we don't need a separate collection class for each.

  attr_accessor :members, :selected

  def initialize(file=nil)
    @members = []
    @selected = -1
    # Current file uses longitude, converting -180 to 180 long to RA for now.
    # Better later to rewrite the files.
    if file
      data = JSON.parse(File.read(file, :encoding => "utf-8"))['features']
      data.each do |star|
        newstar = MyStarsStar.new
        newstar.id = star['id']
        newstar.name = star['properties']['name']
        newstar.mag = star['properties']['mag'].to_f
        newstar.desig = star['properties']['desig']
        newstar.con = star['properties']['con'] 
        newstar.ra = star['geometry']['coordinates'][0].long_to_ra.to_f
        newstar.dec = star['geometry']['coordinates'][1].to_f
        @members << newstar
      end
    end
  end

  # Update altitude and azimuth with local data from a MyStarsGeo object
  # and add it to the world matrix
  def localize(geo)
    @members.each { |star| star.localize(geo) }
  end

  def draw(pv)
    # Draw current stars in DB to screen.

    # This is probably inefficent as it polls all available stars, but
    # hopefully good enough for now.

    @members.each { |star| star.draw(pv) }

  end

end
