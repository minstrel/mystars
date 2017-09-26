# MyStars

This is a little ncurses based planetarium.

### Requirements

* Ruby 2.1 or later
* The ruby 'curses' gem, installed via:
  `gem install curses`
  or from source at https://github.com/ruby/curses
* Curses, ncurses or PDCurses (some versions may have issues with Unicode characters, in this case the Greek letters and possibly the dot used to draw constellation lines).

### Current State & Instructions

MyStars is currently pre-alpha.  My focus is on new features and not UI or bugs.

With the requirements installed, clone the repo and run mystars\_curses.rb.

When prompted, enter longitude and latitude.  The application will show a view facing north at 10 degrees altitude.

Only stars down to 6th magnitude and above the horizon are currently shown.

Pan around with arrow keys or numeric keypad.

Zoom in and out with -/+.

Filter visible stars by magnitude with m/M.

Tab through stars on the current viewport with tab and shift-tab.

Toggle display of constellation names and lines with c.

Toggle ground visibility with g.

Toggle stab labelling with L.

Input new geographic location with G.

Help window with H or ?.

If you are using a square (16x16, for example) font, the screen may appear stretched horizontally.  This is because I'm making a somewhat arbritray adjustment for typical font h/w ratios.  I'll maybe make this an option you can change at some point if it's needed.  For now, I'm aiming for usability rather than photo-realism.

Hit q to exit.

### Features to implement for 0.0.5+

Some very basic features are now present.  A small and not comprehensive list of what I have in mind next includes:

* Manual input of time, pause, fast forward/reverse.
* Additional filters, and moving similar toggleable settings to a popup window.
* Search window.
* Measurement tool.
* Adding more stars and non-fixed objects (planets, comets, sun, moon, etc.).
* Beginnings of a nicer "look", including colors and displaying different icons for stars dependant on magnitude range.  Also separate icons for DSOs once those are in.
* Smoother scrolling
* Protocols to control Meade and nexStar mounts via serial interface.  This is highly dependant on my actually getting ahold of one to test.  This feels like it should be a "far flung future" feature, but I think I'd like to put it in sooner than later, because I have the feeling that if this application will ever be of use to anyone, it will be as a minimalist, quick and dirty, interface to control mounts that can be run from anywhere with a terminal. 
* Clean up code, break out classes / modules into files, DRY stuff up - I wanted to put this off till later but the main file is getting too big
* Right ascension / declination and altitude / azimuth lines.

### Data Sources:

1. mystars\_6.json, constellations.json, constellations.lines.json - From D3 Celestial by Olaf Frohn, https://github.com/ofrohn/d3-celestial, BSD License.
