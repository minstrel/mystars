# encoding: utf-8

require 'curses'
require_relative 'stars3d'
require_relative 'helpers'
require_relative 'mystars'

class MyStarsDSO < MyStars
  # A single DSO
  #
  # cart_world is the cartesian coordinate column vector in the world
  # cart_proj is the cartesian coordinate column_vector in the current
  # projection
  attr_accessor :id, :name, :mag, :dim, :type, :ra, :dec, :alt, :az, :cart_world, :cart_proj

  def screen_coords(win)
    xpos = win.maxx - (((@cart_proj[0,0] + 1) / 2.0) * win.maxx).round
    ypos = win.maxy - (((@cart_proj[1,0] + 1) / 2.0) * win.maxy).round
    [xpos, ypos]
  end

  def localize(geo)
    @alt = geo.altitude(@ra, @dec)
    @az = geo.azimuth(@ra, @dec)
    cz = ( Math.cos(@alt.to_rad) * Math.sin(@az.to_rad) )
    cy = Math.sin(@alt.to_rad)
    cx = Math.cos(@alt.to_rad) * Math.cos(@az.to_rad)
    @cart_world = Matrix.column_vector([cx,cy,cz,1])
  end

  def draw(pv)
    # Don't draw if it's below visible threshold
    # 999 is special case, always include for now
    return nil if ((@mag > App::Settings.vis_mag) && (@mag != 999))
    # Project into the world
    @cart_proj = pv * @cart_world
    # Don't draw if it's outside current screen
    return nil if !(@cart_proj[0,0].between?(-1,1) && @cart_proj[1,0].between?(-1,1) && @cart_proj[2,0].between?(0,1))
    # If ground is showing, don't show if it's below the horizon
    return nil if (App::Settings.show_ground && (@alt < 0.0))
    # The view window
    win = App::WIN.window
    # Add it to in view collection for tabbing purposes
    App::Settings.in_view.members << self
    # Draw DSO and label
    xpos, ypos = self.screen_coords(win)
    win.setpos(ypos,xpos)
    # TODO assign symbol per type
    win.addstr(self.symbol)
    win.setpos(ypos+1,xpos)
    # TODO The fix to correct text wrapping needs some tweaking
    case App::Settings.labels
    when :all, :named
      if !@name.empty?
        if (xpos + (@name).length) > win.maxx
        win.setpos(ypos+1, win.maxx - @name.length)
        end
        win.addstr(@name)
      end
    when :none
    end
  end

  def symbol
    case @type
    when "s"
      "@"
    when "oc"
      "◌"
    when "dn"
      "⚈"
    when "gc"
      "○"
    when "en"
      "⁜"
    when "gg"
      "⁙"
    when "snr"
      "※"
    when "rn"
      "⚆"
    when "sfr"
      "⁂"
    when "bn"
      "⚙"
    when "i"
      "∼"
    else
      "*"
    end
  end

  def type_long
    case @type
    when "s"
      "Spiral galaxy"
    when "oc"
      "Open cluster"
    when "dn"
      "Dark nebula"
    when "gc"
      "Globular cluster"
    when "en"
      "Emission nebula" 
    when "gg"
      "Galaxy cluster"
    when "snr"
      "Supernova remnant"
    when "rn"
      "Reflection nebula"
    when "sfr"
      "Star forming region"
    when "bn"
      "Bright nebula"
    when "i"
      "Irregular galaxy"
    else
      "Unknown type"
    end
  end
end
