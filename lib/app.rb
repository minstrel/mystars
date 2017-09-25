# encoding: utf-8

require_relative 'stars3d'
require_relative 'helpers'

module App
  # Running settings
  # :mag is magnification, not magnitude (that was a bad choice, rename
  # it sometime)
  # mag - field of view in degrees N-S
  # vis_mag - dimmest magnitude visible
  # collection - MyStarsStars collection in current database
  # lat - user latitude
  # lon - user longitude
  # in_view - MyStarsStars collection in current viewscreen
  # timer - delay, in seconds, before timer thread attempts to request a
  #   refresh of both collection and in_view
  # selected_id star.id # of the currently selected star.  When we clean up
  #   the input files, a new id unique to this application should probably
  #   get written, as I don't know if id will always be there or be reliable
  #   for tracking every object
  # facing_xz - how many degrees the camera will be rotated around the y-axis (south = 0)
  # facing_y - how many degrees the camera will be rotated around the x-axis (up = 90)
  # show_constellations - boolean, show constellation names and lines
  # constellation_names - locations and names of floating constellation labels
  # constellation_lines - vertices of line segments for constellation outlines
  # labels - :named, :all, :none - show only named star labels, all stars, or no labels
  # Possible settings for object labels
  LABELS = [:named, :all, :none].cycle
  AppSettings = Struct.new(:mag, :vis_mag, :collection, :lat, :lon, :in_view, :timer, :selected_id, :facing_xz, :facing_y, :show_constellations, :constellation_names, :constellation_lines, :show_ground, :labels)
  Settings = AppSettings.new(10, 6, nil, nil, nil, nil, 5, nil, 90, -10, true, nil, nil, true, LABELS.next)
  COMPASSPOINTS = {"N" => Matrix.column_vector([1,0,0,1]), "S" => Matrix.column_vector([-1,0,0,1]), "E" => Matrix.column_vector([0,0,1,1]), "W" => Matrix.column_vector([0,0,-1,1])}
  GROUNDCOORDS = ((0..359).to_a + [0]).collect { |a| Matrix.column_vector([Math.cos(a.to_rad), 0, Math.sin(a.to_rad), 1]) }

end
