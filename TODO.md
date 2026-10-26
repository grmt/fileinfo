# TODO

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
