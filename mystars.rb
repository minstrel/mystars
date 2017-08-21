# encoding: utf-8

require 'date'
require 'json'

class Numeric
  def to_rad
    self * Math::PI / 180
  end
  def to_deg
    self * ( 180 / Math::PI )
  end
  def long_to_ra
    if self < 0
      (self + 360) / 15
    else
      self / 15
    end
  end
end

class MyStars

  # Pass in a file object with star data and get back an array of MyStarsStar
  # objects.
  # For now I'm going to use the JSON files as-is, converting -180 - 180
  # values of long to RA in decimal hours.
  # This should just get moved to the intialize method of MyStarsStars
  def self.newstars_from_JSON(file)
    stars = MyStarsStars.new
    data = JSON.parse(file)
    data['features'].each do |star|
      newstar = MyStarsStar.new
      newstar.id = star['id']
      newstar.name = star['properties']['name']
      newstar.desig = star['properties']['desig']
      newstar.con = star['properties']['con'] 
      newstar.ra = star['geometry']['coordinates'][0].long_to_ra.to_f
      newstar.dec = star['geometry']['coordinates'][1].to_f
      stars.members << newstar
    end
    stars
  end

end

class MyStarsGeo < MyStars

  attr_accessor :jd, :jda, :t, :gmst, :gast, :last, :lat
  
  # Initialize method takes the local latitude and longitude (as decimal
  # degrees) as input and using the current time creates an object
  # containing the apparent sidereal time, both local and Greenwich.
  # This calculation is based on the USNO's calculations here:
  # http://aa.usno.navy.mil/faq/docs/GAST.php

  def initialize(local_lon, local_lat, jd=nil)
    # Local latitude setter, north is positive
    @lat = local_lat
    # Express local_lon as negative for west, positive for east
    @lon = local_lon
    # Julian Day, either specified (optional)
    # else current Julian Day, fractional
    @jd = if jd then jd else DateTime.now.ajd.to_f end
    # Julian Days since 1 Jan 2000 at 12 UTC
    @jda = @jd - 2451545.0
    # Julian centuries since 1 Jan 2000 at 12 UTC
    # Currently not using this in favor of a quick calculation, w/ loss of 0.1 sec / century.
    @t = @jda / 36525.0
    # Greenwhich Mean Sidereal Time
    # Quick and dirty version, with loss as mentioned above
    @gmst = 18.697374558 + ( 24.06570982441908 * @jda )
    # Reduce to a range of 0 - 24 h
    @gmst = @gmst % 24
    # Greenwich Apparent Sidereal Time
    omega = 125.04 - 0.052954 * @jda
    l = 280.47 + 0.98565 * @jda
    epsilon = 23.4393 - 0.0000004 * @jda
    deltapsi = ( -0.000319 * Math::sin(omega.to_rad) ) - ( 0.000024 * Math::sin( (2*l).to_rad ) )
    eqeq = deltapsi * Math.cos(epsilon.to_rad)
    @gast = @gmst + eqeq
    # Local Apparent Sidereal Time
    @last = @gast + ( local_lon / 15.0 )
  end

  # Altitude and Azimuth methods take the Right Ascension and Declination of a fixed
  # star as decimal hours for RA and decimal degrees for Dec and output the
  # Altitude and Azimuth as decimal degrees.
  # AA method just runs them both and sends a pretty output.
  # This is based on the USNO's calculations here:
  # http://aa.usno.navy.mil/faq/docs/Alt_Az.php
  # Results so far test out within a few minutes of Stellarium.

  def altitude(ra, dec)
    lha = ( @gast - ra ) * 15 + @lon
    a = Math::cos(lha.to_rad)
    b = Math::cos(dec.to_rad)
    c = Math::cos(@lat.to_rad) 
    d = Math::sin(dec.to_rad)
    e = Math::sin(@lat.to_rad)
    Math::asin(a*b*c+d*e).to_deg
  end

  def azimuth(ra, dec)
    lha = ( @gast - ra ) * 15 + @lon
    a = -(Math::sin(lha.to_rad))
    b = Math::tan(dec.to_rad)
    c = Math::cos(@lat.to_rad)
    d = Math::sin(@lat.to_rad)
    e = Math::cos(lha.to_rad)
    # Old incorrect formula, delete this once I'm confident atan 2 is working.
    # Math::atan(a/(b*c-d*e)).to_deg
    az = Math::atan2( a , (b*c - d*e)).to_deg
    if az >= 0
      az
    else
      az += 360
      az
    end
  end

  def aa(ra,dec)
    puts "Altitude is " + self.altitude(ra,dec).to_s
    puts "Azimuth is " + self.azimuth(ra,dec).to_s
  end

end

class MyStarsStar < MyStars
  # This represents a single star
  attr_accessor :id, :name, :desig, :con, :ra, :dec, :alt, :az, :circ_x, :circ_y
end

class MyStarsStars < MyStars
  # This represents a collection of stars
  attr_accessor :members
  def initialize
    @members = []
  end
  # Update altitude and azimuth with local data from a MyStarsGeo object
  def localize(geo)
    self.members.each do |star|
      star.alt = geo.altitude(star.ra, star.dec)
      star.az = geo.azimuth(star.ra, star.dec)
    end
  end
  def plot_on_circle
    self.members.each do |star|
      star.circ_x = Math.sin(star.az.to_rad) * (90 - star.alt)
      star.circ_y = Math.cos(star.az.to_rad) * (90 - star.alt)
    end 
  end
end

class MyStarsWindows < MyStars
  # Methods to use to draw and navigate curses windows
  # This should probably get moved to a new file at some point.

  def self.drawWindow(centery,centerx,collection,win)
    # This is probably inefficent as it polls all available stars, but
    # hopefully good enough for now.
    # Takes a collection, x and y coords to center on and window to act on
    # and draws window.

    # Iterate through visible stars and try to plot on current screen,
    # given 10 degrees FOV N-S (IE y axis) and enough to fill E-W (x axis)
    miny = centery - 5.0
    maxy = centery + 5.0
    xrange = (win.maxx.to_f / win.maxy.to_f) * 10.0
    minx = centerx - (xrange / 2.0)
    maxx = centerx + (xrange / 2.0)
    win.clear
    collection.members.each do |star|
      if (star.circ_y.between?(miny,maxy)) && (star.circ_x.between?(minx,maxx))
        # Figure out the y position on current screen
        ypos = (((star.circ_y - miny) / (maxy - miny)).abs * win.maxy ).round
        # Figure out the x position on current screen
        xpos = (((star.circ_x - minx) / (maxx - minx)).abs * win.maxx ).round
        win.setpos(ypos,xpos)
        win.addstr("*")
        win.setpos(ypos+1,xpos)
        #win.addstr(star.id.to_s)
        #Ruby issue with displaying UTF-8 multibye characters, using ID for now
        win.addstr(star.desig + " " + star.con)
      end
    end
  
  end 

end
