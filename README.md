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

I think I've worked out the issues with the azimuth calculations.  Using the double argument arctan, I'm getting accurate results so far (vs mistakenly using regular arctan before).

Testing a bunch now to see if I can break it.

Next step if all goes well, figuring out how to import data and batch process multiple stars.

### Data Sources:

1. mystars_6.json - From D3 Celestial by Olaf Frohn, https://github.com/ofrohn/d3-celestial, BSD License.
