#!/usr/bin/ruby -w
# encoding: utf-8 

require_relative 'mystars'

puts "Enter your longitude as decimal degrees, negative is West:"
LON = gets.chomp
puts "Enter your latitude as decimal degrees, negative is South:"
LAT = gets.chomp
@stars = MyStars.new(LON.to_f,LAT.to_f)

def menu
  puts "Enter R to refresh time, S to enter a new star and get its altitude and azimuth, anything else to quit"
  action = gets.chomp.downcase
  if action == 'r'
    @stars = MyStars.new(LON.to_f,LAT.to_f)
    puts "Time Refreshed"
    menu
  elsif action == 's'
    puts "Enter star's Right Ascension as decimal hours:"
    ra = gets.chomp.to_f
    puts "Enter star's Declimation as decimal degrees:" 
    dec = gets.chomp.to_f
    @stars.aa(ra,dec)
    puts ""
    menu
  else
    puts "Bye!"
  end
end

menu
