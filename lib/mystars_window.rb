# encoding: utf-8

require 'date'
require 'json'
require 'curses'
require_relative 'stars3d'
require_relative 'helpers'
require_relative 'mystars'

class MyStarsWindow < MyStars
  # Master Window class, stores the Curses window object, should be called
  # with super from subclasses.
  attr_accessor :window

  def initialize(lines, cols, starty, startx)
    # Number of lines, columns, upper left corner y and x coordinates
    @window = Curses::Window.new(lines, cols, starty, startx)
  end

end
