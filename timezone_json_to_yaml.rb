#!/usr/bin/ruby -w
# encoding: utf-8

# This is the script I used to create the yaml file of timezone boundaries in
# RGeo from the Timezone Boundary Builder credited in the README.
# Save this for future imports to update the dataset.

require 'json'
require 'rgeo'
require 'yaml'

# Create a factory
Factory = RGeo::Geos::FFIFactory.new
# Import the json data
data = JSON.parse(File.read('./combined.json', :encoding => 'utf-8'))['features']
# Define a method to take a json polygon and return a geos polygon
def polygen(source)
## Map through the data - for each |x|, create a factory.point(x[0],x[1])
  pointset = source.map do |x|
    Factory.point(x[0],x[1])
  end
## Create a factory.linear_ring from the point set
  ring = Factory.linear_ring(pointset)
## Create a factory.polygon from the ring, return this
  poly = Factory.polygon(ring)
  return poly
end
# Iterate through the json file and create polygons, place them in an array of hashes, where each hash contains the polygon and the timezone
## Create an array to store stuff in, can't use map b/c we'll be returning multiple polys with each iteration
data.each do |datum|
## Do different things if it's a polygon or multipolygon
## If it's a polygon, iterate through ['geometry']['coordinates'] and runthe polygon generator method on each |x|
  if datum['geometry']['type'] == 'Polygon'
    datum['geometry']['coordinates'].each do |poly|
      newpoly = {:poly => polygen(poly), :zone => datum['properties']['tzid']}
      File.open('./timezones.yaml', 'a') { |file| file.write(newpoly.to_yaml) }
    end
## If it's a multipolygon, iterate through ['geometry']['coordinates'] |x| and then itereate through each x |y| and run the polygon method on each |y|
  elsif datum['geometry']['type'] == 'MultiPolygon'
    datum['geometry']['coordinates'].each do |group|
      group.each do |poly|
        newpoly = {:poly => polygen(poly), :zone => datum['properties']['tzid']}
        File.open('./timezones.yaml', 'a') { |file| file.write(newpoly.to_yaml) }
      end
    end
  else
    nil
  end
end

