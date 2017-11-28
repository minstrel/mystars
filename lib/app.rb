# encoding: utf-8

require_relative 'stars3d'
require_relative 'helpers'
#require 'date'

module App
  # Running settings
  LABELS = [:named, :all, :none].cycle
  AppSettings = Struct.new(
    # :mag is magnification, not magnitude (that was a bad choice, rename
    # it sometime)
    # mag - field of view in degrees N-S
    :mag,
    # vis_mag - dimmest magnitude visible
    :vis_mag,
    # collection - MyStarsFixedObjects collection in current database
    :collection,
    # lat - user latitude
    :lat,
    # lon - user longitude
    :lon,
    # Time zone, TZInfo::DataTimezone object representing the time zone at
    # lat/lon
    :timezone,
    # in_view - MyStarsFixedObjects collection in current viewscreen
    :in_view,
    # timer - delay, in seconds, before timer thread attempts to request a
    #   refresh of both collection and in_view
    :timer,
    # selected_id star.id # of the currently selected star.  When we clean up
    #   the input files, a new id unique to this application should probably
    #   get written, as I don't know if id will always be there or be reliable
    #   for tracking every object
    :selected_id,
    # facing_xz - how many degrees the camera will be rotated around the y-axis (south = 0)
    :facing_xz,
    # facing_y - how many degrees the camera will be rotated around the x-axis (up = 90)
    :facing_y,
    # show_constellations - boolean, show constellation names and lines
    :show_constellations,
    # constellation_names - locations and names of floating constellation labels
    :constellation_names,
    # constellation_lines - vertices of line segments for constellation outlines
    :constellation_lines,
    # Display ground (# symbols below 0 alt)
    :show_ground,
    # Possible settings for object labels
    # labels - :named, :all, :none - show only named star labels, all stars, or no labels
    :labels,
    # Local PC time at last update
    :last_time,
    # Manually input effective time at given lat / lon
    :manual_time
  )
  # This is slower than passing everything in to .new, but we're only doing
  # it once and it's more readable.
  Settings = AppSettings.new
  Settings.mag = 10
  Settings.vis_mag = 6
  Settings.timer = 5
  Settings.facing_xz = 90
  Settings.facing_y = -10
  Settings.show_constellations = true
  Settings.show_ground = true
  Settings.labels = LABELS.next
  Settings.last_time = DateTime.now
  COMPASSPOINTS = {"N" => Matrix.column_vector([1,0,0,1]), "S" => Matrix.column_vector([-1,0,0,1]), "E" => Matrix.column_vector([0,0,1,1]), "W" => Matrix.column_vector([0,0,-1,1])}
  GROUNDCOORDS = ((0..359).to_a + [0]).collect { |a| Matrix.column_vector([Math.cos(a.to_rad), 0, Math.sin(a.to_rad), 1]) }

end
