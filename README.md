# MyStars

This is a little library to calculate the current position of objects (currently fixed stars) in the sky.

Currently, the output comes within a few minutes of what Stellarium shows at the same geographic coordinates.

### Usage:

```ruby
require_relative 'mystars'
# Create a new MyStars object, passing in local longitude and latitude as
# decimal degrees
mystars = MyStars.new(-71, 43)
# Pass Right Ascension (as decimal hours) and Declination (as decimal degrees)
# to the methods altitude, azimuth and get back the corresponding value,
# as decimal degrees.
# The aa method passes them both back as pretty text.
# Calculating Vega's position below:
mystars.azimuth(18.616666,38.783333)
=> 43.96040907459006
mystars.altitude(18.616666,38.783333)
=> 8.97361521398292
mystars.aa(18.616666,38.783333)
Altitude is 8.97361521398292
Azimuth is 43.96040907459006
```

I'm wondering if there may be issues related to periodicity of the arcsin and arctan functions, but so far I haven't been able to break anything by moving locations into the southern hemisphere or tracking stars below the horizon.
The Azimuth values can return negative (probably between 180 and 360), but are still accurate.
