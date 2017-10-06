### Notes related to implementing rgeo in this application so we can lookup time zone offsets offline (IE without resorting to a web api).

* Install the rgeo, ffi-geos, and tzinfo gems
* require 'rgeo'
* Create a factory using factory = RGeo::Geos::FFIFactory.new
* Create points like p1 = factory.point(-71.5,43.2)
* Create a set of points like: pointset = a[0]['geometry']['coordinates'][0].map { |x| factory.point(x[0],x[1]) } }
* Create a ring from them like: ring = factory.linear_ring(pointset)
(Or just pass the points right into #linear_ring - it will take any enumerable or a series of points)
* Create a polygon from the ring like: poly = factory.polygon(ring)
* Check to see if the point is within the polygon like: p1.within?(poly)
* The file timezone_boundaries.json in the data directory contains bounds for all the timezones.
* Match the ['properties']['tzid'] value up to the time zone of the same name using TZInfo::Timezone.get like: TZInfo::Timezone.get("America/New_York")
