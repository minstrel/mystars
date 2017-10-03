## Changelog
0.0.5
* Various refactorings
* Added DSOs down to mag 6
* Stars and DSOs now drawn with symbol, indicating type for DSO and rough magnitude for stars
* Very simple search added, just searches names and moves to that location.  I don't want to go too nuts with this right now because I expect the dataset to change eventually and I don't want to rework search if the data structure changes.

0.0.4
* Current facing now displayed in info panel
* NSEW cardinal directions now appear in main window at ground level
* Constellation names displaying
* Constellation lines displaying
* Ground layer available, toggle with g.
* Cycle through label visibility with L.  Will show all stars with designation, only named stars or none.
* Adjusted displayed width to compensate for font ratio (this is pretty arbritrary without a way to actually read the terminal font, but I think it's better than trying to get the user to install a square font)
* Input new geographic location with (G)

0.0.3
* Help window added.
* User input and main program broken into threads to enable automatic timer.
* Timer thread added, default to 5 seconds.
* Currently selected object now stays selected when panning, zooming, filtering and as time progresses.  There might be some bugs here but nothing's jumped out yet.
* Time added to info bar, reflects time as shown in main window
* Help screen no longer hangs application.  Hacky fix that pauses the normal input thread and then resumes it.
* Viewer rewritten using a basic 3d engine.  No more flat map, now an actual perspective view allowing full view above and below the horizon.

0.0.2
* Scrolling enabled, moves 1 degree at a time
* Magnification enabled, 1 degree min, 180 max
* Info sidebar created, currently showing field of view in degrees and lat/lon.
* Refactored current settings like magnitide and current center info single settings object.
* No more prompt for a star to initially center on, goes right to zenith
* Can select stars, and get basic info in info panel
* Filter by magnitude with m and M.
