#!/usr/bin/ruby -w
# encoding: utf-8

require 'date'

class Numeric
  def to_rad
    self * Math::PI / 180
  end
  def to_deg
    self * ( 180 / Math::PI )
  end
end

class MyStars

  attr_accessor :jd, :jda, :t, :gmst, :gast, :last, :lat
  
  # Initialize method takes the local latitude and longitude (as decimal
  # degrees) as input and using the current time creates an object
  # containing the apparent sidereal time, both local and Greenwich.
  # This calculation is based on the USNO's calculations here:
  # http://aa.usno.navy.mil/faq/docs/GAST.php

  def initialize(local_lon, local_lat)
    # Local latitude setter, north is positive
    @lat = local_lat
    # Express local_lon as negative for west, positive for east
    @lon = local_lon
    # Current Julian Day, fractional
    @jd = DateTime.now.ajd.to_f
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
  # star as decimal degrees and output the Altitude and Azimuth as decimal degrees.
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
    Math::atan(a/(b*c-d*e)).to_deg
  end

  def aa(ra,dec)
    puts "Altitude is " + self.altitude(ra,dec).to_s
    puts "Azimuth is " + self.azimuth(ra,dec).to_s
  end

  # The below method produces identical Alt and LHA but an Az off by about
  # -2.5 degrees.  Just retaining it a while to help remind me of how I arrived
  # at the calcs I used.
  # These equations were taken from here:
  # http://www2.arnes.si/%7Egljsentvid10/sfera/chapter7.htm
  
  # def altitude(ra, dec)
  #   h = ( @last - ra ) * 15
  #   Math::asin( Math::sin(dec.to_rad) * Math::sin(@lat.to_rad) + Math::cos(dec.to_rad) * Math::cos(@lat.to_rad) * Math::cos(h.to_rad) ).to_deg
  # end

  # def azimuth(ra, dec)
  #   a = altitude(ra, dec)
  #   h = ( @last - ra ) * 15
  #   Math::asin( (-(Math::sin(h.to_rad) * Math::cos(@lat.to_rad))) / Math::cos(a.to_rad) ).to_deg
  # end

  # def aa(ra,dec)
  #   puts "Altitude is " + self.altitude(ra,dec).to_s
  #   puts "Azimuth is " + self.azimuth(ra,dec).to_s
  # end

  # Altitude and Azimuth methods take the Right Ascension and Declination of a fixed
  # star and output the Altitude and Azimuth.
  # AA method just runs them both and sends a pretty output.
  # This is based on the USNO's calculations here:
  # http://aa.usno.navy.mil/faq/docs/Alt_Az.php

end
