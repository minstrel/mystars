# encoding: utf-8

require 'date'
require 'json'
require 'curses'
require_relative 'stars3d'
require_relative 'helpers'
require_relative 'mystars'
require_relative 'mystars_window'

class MyStarsViewWindow < MyStarsWindow
  def initialize(lines, cols, starty, startx)
    super
  end

  def drawWindow
    # Draws the current viewscreen.
    # Actual drawing mostly done by the objects' methods, while this class
    # exists to put them in the right order and feed them
    # info like the projection view matrix.

    # Get desired viewing range in degrees
    mag = App::Settings.mag
    height = mag.to_rad

    # Create the projection view matrix to pass to all the draw methods.
    view = Stars3D.view(0,0,0,App::Settings.facing_y.to_rad,App::Settings.facing_xz.to_rad,0)
    width = ((@window.maxx.to_f / @window.maxy.to_f) * mag).to_rad

    # Width adjustment to compensate for terminal character size
    # This is pretty arbritrary but I don't see a better way right now
    width = width * 0.5

    # Standard projection matrix
    projection = Stars3D.projection(width, height, 0.25, 1.0)

    # Create projection view matrix
    pv = projection * view

    # Clear the window
    @window.clear

    # Draw in-view constellation lines
    App::Settings.constellation_lines.draw(pv)

    # Clear in-view stars
    App::Settings.in_view = MyStarsFixedObjects.new

    # Draw in-view stars
    App::Settings.collection.draw(pv)

    # Sort the in-view members by screen position
    App::Settings.in_view.members.sort! do |a, b|
      (a.cart_proj[1,0] + 1.0) * 1000 - (a.cart_proj[0,0] + 1.0) <=> (b.cart_proj[1,0] + 1.0) * 1000 - (b.cart_proj[0,0] + 1.0)
    end
    # TODO Sort it better instead of doing this.
    App::Settings.in_view.members.reverse!

    # Draw in-view constellations
    App::Settings.constellation_names.draw(pv)
    
    # Draw the ground, if toggled
    MyStarsDecoration.drawGround(view, width, height)

    # Draw in-view compass points
    MyStarsDecoration.drawCompass(pv)

    @window.refresh

  end 

  # Increment current camera angle
  def move(direction)
    case direction
    when :up
      if App::Settings.facing_y == -90
        nil
      else
        App::Settings.facing_y -= 1
      end
    when :down
      if App::Settings.facing_y == 90
        nil
      else
        App::Settings.facing_y += 1
      end
    when :left
      if App::Settings.facing_xz == 359
        App::Settings.facing_xz = 0
      else
        App::Settings.facing_xz += 1
      end
    when :right
      if App::Settings.facing_xz == 0
        App::Settings.facing_xz = 359
      else
        App::Settings.facing_xz -= 1
      end
    end
  end
  
  def selectID
    # Highlight the currently selected object
    star = App::Settings.in_view.members.find { |object| object.id == App::Settings.selected_id }

    star_selection_index = App::Settings.in_view.members.find_index(star)

    if star
      App::Settings.in_view.selected = star_selection_index
      xpos, ypos = star.screen_coords(@window)
      @window.setpos(ypos,xpos)
      @window.attrset(Curses::A_REVERSE)
      @window.addstr(star.symbol)
      @window.attrset(Curses::A_NORMAL)
      @window.refresh
      App::INFO_WIN.updateTargetInfo
    end 
  end

  def selectNext
    # Highlight the next object in current view
    if App::Settings.in_view.members.empty?
      return nil
    end
    # --- Deselect the previous one
    star = App::Settings.in_view.members[App::Settings.in_view.selected]
    xpos, ypos = star.screen_coords(@window)
    @window.setpos(ypos,xpos)
    @window.attrset(Curses::A_NORMAL)
    @window.addstr(star.symbol)
    # ---
    if App::Settings.in_view.selected == App::Settings.in_view.members.length - 1
      App::Settings.in_view.selected = 0
    else
      App::Settings.in_view.selected += 1
    end
    star = App::Settings.in_view.members[App::Settings.in_view.selected]
    # Set targeted ID so we can highlight it again after refresh
    App::Settings.selected_id = star.id
    xpos, ypos = star.screen_coords(@window)
    @window.setpos(ypos,xpos)
    @window.attrset(Curses::A_REVERSE)
    @window.addstr(star.symbol)
    @window.attrset(Curses::A_NORMAL)
    @window.refresh
    App::INFO_WIN.updateTargetInfo
  end

  def selectPrev
    # Highlight the previous object in current view
    if App::Settings.in_view.members.empty?
      return nil
    end
    # ---Deselect the previous one
    star = App::Settings.in_view.members[App::Settings.in_view.selected]
    xpos, ypos = star.screen_coords(@window)
    @window.setpos(ypos,xpos)
    @window.attrset(Curses::A_NORMAL)
    @window.addstr(star.symbol)
    # ---
    if (App::Settings.in_view.selected == 0) || (App::Settings.in_view.selected == -1)
      App::Settings.in_view.selected = App::Settings.in_view.members.length - 1
    else
      App::Settings.in_view.selected -= 1
    end
    star = App::Settings.in_view.members[App::Settings.in_view.selected]
    # Set targeted ID so we can highlight it again after refresh
    App::Settings.selected_id = star.id
    xpos, ypos = star.screen_coords(@window)
    @window.setpos(ypos,xpos)
    @window.attrset(Curses::A_REVERSE)
    @window.addstr(star.symbol)
    @window.attrset(Curses::A_NORMAL)
    @window.refresh
    App::INFO_WIN.updateTargetInfo
  end

end
