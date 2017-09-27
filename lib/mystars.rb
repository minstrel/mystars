# encoding: utf-8

require 'date'
require 'json'
require 'curses'
require_relative 'stars3d'
require_relative 'helpers'

def testcollection
  collection = MyStarsStars.new('./data/mystars_6.json')
  geo = MyStarsGeo.new(-71.5,43.2)
  collection.localize(geo)
  collection
end

class MyStars
  # Parent class for everything else.

end

