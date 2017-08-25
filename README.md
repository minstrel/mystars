# MyStars

This is a little ncurses based planetarium.

### Requirements

* Ruby 2.1 or later
* The ruby 'curses' gem, installed via:
  `gem install curses`
  or from source at https://github.com/ruby/curses
* Curses, ncurses or PDCurses (some versions may have issues with Unicode characters, in this case the Greek letters).

### Current State & Instructions

MyStars is currently pre-alpha.  My focus is on new features and not UI or bugs.

With the requirements installed, clone the repo and run mystars\_curses.rb.

When prompted, enter longitude and latitude.  The application will show a view centered on the zenith at that location and the current date and time.

Only stars down to 6th magnitude and above the horizon are currently shown.

Pan around with arrow keys or numeric keypad.

Zoom in and out with -/+.

Filter visible stars by magnitude with m/M.

Tab through stars on the current viewport with tab and shift-tab.

Most screens will appear stretched vertically (ie North - South).  This is an artifact of most fonts being rectangular, as spacing is done by row and column count, not font size. Installing a square font will mostly correct for this although line spacing may still cause some stretch.

Hit enter key to exit.

### Features to implement

Some very basic features are now present.  A small and not comprehensive list of what I have in mind next includes:

* Manual input of time, ~~periodic updates~~, fast forward/reverse.
* Additional filters, and moving similar toggleable settings to a popup window.
* Search window.
* ~~Help window.~~
* Drawing constellation lines.
* Adding more stars and non-fixed objects (planets, comets, sun, moon, etc.).
* Beginnings of a nicer "look", including colors and displaying different icons for stars dependant on magnitude range.  Also separate icons for DSOs once those are in.
* Protocols to control Meade and nexStar mounts via serial interface.  This is highly dependant on my actually getting ahold of one to test.  This feels like it should be a "far flung future" feature, but I think I'd like to put it in sooner than later, because I have the feeling that if this application will ever be of use to anyone, it will be as a minimalist, quick and dirty, interface to control mounts that can be run from anywhere with a terminal. 
* Views below the horizon.

Right now, the application draws a flat map, similar to what you'd get at skymaps.com, representing a hemisphere at the latitude and longitude input by the user at the current time of day.

While I originally wanted to get a perspective view going, I think I'm going to stick with the flat map, providing I can get views below the horizon working acceptably.

### Changelog

0.0.2
* Scrolling enabled, moves 1 degree at a time
* Magnification enabled, 1 degree min, 180 max
* Info sidebar created, currently showing field of view in degrees and lat/lon.
* Refactored current settings like magnitide and current center info single settings object.
* No more prompt for a star to initially center on, goes right to zenith
* Can select stars, and get basic info in info panel
* Filter by magnitude with m and M.

0.0.3
* Help window added.
* User input and main program broken into threads to enable automatic timer.
* Timer thread added, default to 5 seconds.
* Currently selected object now stays selected when panning, zooming, filtering and as time progresses.  There might be some bugs here but nothing's jumped out yet.
* Time added to info bar, reflects time as shown in main window
* Help screen no longer hangs application.  Hacky fix that pauses the normal input thread and then resumes it.

### Data Sources:

1. mystars\_6.json - From D3 Celestial by Olaf Frohn, https://github.com/ofrohn/d3-celestial, BSD License.
