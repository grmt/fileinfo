# TODO

## Include collected roads and cities in a future release

Keep city filters scoped to incidents that ANWB groups under that city name.
Do not expand them to highway segments mentioning the city as an endpoint.

Let the Toon collect more locations, then retrieve `knownRoads` from
`/mnt/data/tsc/fileinfo.userSettings.json` on `toon`. Merge the collected names
into the bundled starting catalog so new installations also get these choices.
Include only location names, not the device's `roadFilter` or `filterEnabled`
preferences. Preserve numeric sorting for A- and N-roads and alphabetical city
sorting, bump the version, and publish a new release with the expanded catalog.

## Support roadworks and speed checks from the ANWB feed

The app currently reads only each segment's `jams` array. The ANWB feed also
provides separate `roadworks` and `radars` arrays, which are currently ignored.

Read and validate these arrays and preserve the incident category explicitly.
Add independent type filters for files, werkzaamheden and flitsers, combined
with the existing road/city selection. Show appropriate labels and icons in
the incident list and tile; do not count roadworks or speed checks as jams.
Keep the existing XML escaping, plain-text rendering and response validation.
Verify category handling and combined filters against saved ANWB responses.

## Look into NDW open data (https://opendata.ndw.nu/)

NDW (Nationaal Dataportaal Wegverkeer) publishes open traffic data feeds, no API key
required. Worth investigating as a source for richer/more reliable roadworks info
than guessing from ANWB's `incidentType === "road-closed"`.

Feed of interest:
- `planningsfeed_wegwerkzaamheden_en_evenementen.xml.gz` — dedicated roadworks and
  events planning feed (XML, ~14MB, updated daily).

Other feeds available (XML/CSV/GeoJSON/Shapefile, DATEX II standard):
- `trafficspeed.xml.gz`, `traveltime.xml.gz`, `actueel_beeld.xml.gz` — current
  traffic speed/situation snapshots.
- `tijdelijke_verkeersmaatregelen_*.xml.gz` — temporary traffic measures (closures,
  speed limits).

Given this project's history of churning through traffic data APIs (ANWB endpoint
changed multiple times already), NDW may be a more stable long-term source since
it's the official Dutch government portal rather than a commercial API.

Not yet evaluated: whether NDW's feeds include human-readable road segment /
location names comparable to ANWB's `from`/`to`/`start`/`end` fields, and how to
match NDW roadworks entries to ANWB jams (probably by road number + location).
