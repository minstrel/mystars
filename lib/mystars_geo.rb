# encoding: utf-8

#require 'date'
#require 'timezone_finder'
#require 'tzinfo'
require_relative 'helpers'
require_relative 'mystars'

class MyStarsGeo < MyStars

  attr_accessor :time, :jd, :jda, :t, :gmst, :gast, :last, :lat
  
  # Initialize method takes the local latitude and longitude (as decimal
  # degrees) as input and using the current time creates an object
  # containing the apparent sidereal time, both local and Greenwich.
  # This calculation is based on the USNO's calculations here:
  # http://aa.usno.navy.mil/faq/docs/GAST.php

  # Need to adjust the jd argument for initialize to a DateTime object,
  # since we are using this to display the current date and tim in the info
  # window.

  def initialize(local_lon, local_lat, time=nil)
    # Local latitude setter, north is positive
    @lat = local_lat
    # Express local_lon as negative for west, positive for east
    @lon = local_lon
    # Closest timezone to @lat and @lon, only update if timezone is nil
    # (on initial load and after updating geo info)
    if App::Settings.timezone == nil
      tf = TimezoneFinder.create
      tz = tf.timezone_at(lng: @lon, lat: @lat)
      if tz == nil
        (1..20).step(2) do |x|
          tz = tf.closest_timezone_at(lng: @lon, lat: @lat, delta_degree: x)
          break if tz
        end
      end
      # Fall back to EST if we can't find a proper zone
      if tz == nil
        tz = 'America/New_York'
      end
      @tz = TZInfo::Timezone.get(tz)
      App::Settings.timezone = @tz
    end
    # Current DateTime, either specified else now
    # @time = if time then time else App::Settings.timezone.now.to_datetime end
    #
    # We're using separate manual_time from current time, because we want
    # current time to always be right now, but if manual_time is put in, we
    # can deal with a little drift from actual timekeeping due to computation
    # times.
    #
    # TZInfo gem currently (1.4.2) outputs timezone.now as the local time but with 0 offset
    # So the below is necessary.  When that bug is fixed in a future gem, we can just go
    # back to using App::Settings.timezone.now.to_datetime without all these
    # shenanegans to get the offset in there.
    now = App::Settings.timezone.now.to_datetime
    year = now.year
    month = now.month
    day = now.day
    hour = now.hour
    min = now.min
    sec = now.sec
    period = App::Settings.timezone.period_for_local(Time.new(year,month,day,hour,min,sec))
    offset = Rational( (period.utc_offset + period.std_offset) , 86400 )
    now = DateTime.new(year, month, day, hour, min, sec, offset)
    @time = if App::Settings.manual_time
              # TODO Check if time is paused.  If it is, use App::Settings.manual_time.
              # Else use the existing code below.
              # It might be a good idea to set App::Settings.manual_time to App::Settings.last_time
              # in the main loop when we pause the time.  That way we don't have to worry about the
              # case of when we're using 'now'.
              # TODO we should probably make a command to reset the time to 'now' and clear
              # App::Settings.manual_time
              #
              # If a manual time is set, use the UTC time at that local time
              # adjusted for the time passed since last time
              App::Settings.manual_time = App::Settings.manual_time + (now - App::Settings.last_time)
              App::Settings.manual_time
            else
              now
            end
    App::Settings.last_time = now
    # Julian Day, either specified (optional)
    # else current Julian Day, fractional
    @jd = if time then time.ajd.to_f else @time.ajd.to_f end
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

end
