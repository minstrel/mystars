# MyStars

This is a little ncurses based planetarium.

### Requirements

* Ruby 2.1 or later
* The ruby 'curses' gem, installed via:
  `gem install curses`
  or from source at https://github.com/ruby/curses
* Curses, ncurses or PDCurses (some versions may have issues with Unicode characters, in this case the Greek letters).

### Current State

Right now, running mystars\_curses\_poc.rb will run a little proof of concept program and prompt for a longitude and latitude and then return a screen 10 degrees N-S and correspondingly sized E-W (via the available rows/cols in the terminal), showing stars down to 6th magnitude.

Most screens will appear stretched vertically (ie North - South).  This is an artifact of most fonts being rectangular, as spacing is done by row and column count, not font size.

You can now scroll around with arrow keys and zoom in and out with plus and minus.  Tab will select through stars on current screen (tabbing with no stars visible will crash).

Hit enter key to exit.

### To implement

Basically, the usual planetarium stuff, like:

* ~~Scrolling around~~
* ~~Zooming in~~
* ~~Selecting objects on the current screen and getting info on them~~
* ~~Filtering by magnitude~~ and other properties.
* Drawing constellation lines
* More stars and non-fixed objects (planets, comets, sun, moon, etc.).

Right now, the application draws a flat map, similar to what you'd get at skymaps.com.  It represents a hemisphere at the latitude and longitude input by the user at the current time of day.

I'd really like a perspective view like Stellarium and other software displays, but that's out of my ability range right now and I'd rather make something fun and flesh out main features before diving into 3D to 2D conversions.

### Changelog

0.0.2
* Scrolling enabled, moves 1 degree at a time
* Magnification enabled, 1 degree min, 180 max
* Info sidebar created, currently showing field of view in degrees and lat/lon.
* Refactored current settings like magnitide and current center info single settings object.
* No more prompt for a star to initially center on, goes right to zenith
* Can select stars, and get basic info in info panel
* Filter by magnitude with m and M.

### Data Sources:

1. mystars\_6.json - From D3 Celestial by Olaf Frohn, https://github.com/ofrohn/d3-celestial, BSD License.
