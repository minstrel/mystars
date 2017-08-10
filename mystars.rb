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

  # OK troubleshooting results here.  So far:
  # @gast and @last agree with online calculators
  # The mesaurement for h below is the same using USNO and the positional astronomy
  # at http://www2.arnes.si/%7Egljsentvid10/sfera/chapter7.htm
  # Now next thing is to re-write the altitude and azimuth equation using USNO's equations
  # OK update, added in the .to_deg step at the end to bring the results back to degrees
  # Altitude is within 5 minutes of the calculation at
  # http://jukaukor.mbnet.fi/star_altitude.html
  # Azimuth is off by 5 degrees though...
  # Let's still try it with the USNO's equations

  # These don't seem to yield the results I want.  Going to try the usno's calculation instead.
  def altitude(ra, dec)
    h = ( @last - ra ) * 15
    Math::asin( Math::sin(dec.to_rad) * Math::sin(@lat.to_rad) + Math::cos(dec.to_rad) * Math::cos(@lat.to_rad) * Math::cos(h.to_rad) ).to_deg
  end

  def azimuth(ra, dec)
    a = altitude(ra, dec)
    h = ( @last - ra ) * 15
    Math::asin( (-(Math::sin(h.to_rad) * Math::cos(@lat.to_rad))) / Math::cos(a.to_rad) ).to_deg
  end

  # USNO's calculation, appears similar but calculates h from gast
  def altitude2(ra, dec)
    lha = ( @gast - ra ) * 15 + @lon
    
  end

  def azumuth2

  end
end
