import QtQuick 2.1
import qb.components 1.0
import qb.base 1.0;
import FileIO 1.0

App {
	id: fileinfoApp

	property url fullScreenUrl : "FileinfoScreen.qml"
	property url tileUrl : "FileinfoTile.qml"
	property url thumbnailIcon: "qrc:/tsc/traffic.png"
	property url filterScreenUrl : "FileinfoFilterScreen.qml"
	property url fileinfoMenuIconUrl: "qrc:/tsc/traffic.png"
	property url trayUrl : "FileinfoTray.qml";
	property FileinfoFilterScreen fileinfoFilterScreen
	property FileinfoScreen fileinfoScreen

	property string happWeatherUuid;

	// Fileinfo info header information
	property string trafficJams

	// Fileinfo data in XML string format
	property string fileinfoData
	property string fileinfoDataAll
	property string fileinfoDataFiltered

	// Fileinfo filter string and filter enabled indicator
	property bool fileinfoFilterEnabled: false
	property string fileinfoFilterArray
	property variant fileinfoAvailableRoads: []

	// Fileinfo data for Tile max 5 roads
	property string roadTile1Name
	property int roadTile1NumberOfJams
	property real roadTile1TotalLength
	property int roadTile1TotalDelay
	property bool roadTile1Roadworks
	property bool roadTile1

	property string roadTile2Name
	property int roadTile2NumberOfJams
	property real roadTile2TotalLength
	property int roadTile2TotalDelay
	property bool roadTile2Roadworks
	property bool roadTile2

	property string roadTile3Name
	property int roadTile3NumberOfJams
	property real roadTile3TotalLength
	property int roadTile3TotalDelay
	property bool roadTile3Roadworks
	property bool roadTile3

	property string roadTile4Name
	property int roadTile4NumberOfJams
	property real roadTile4TotalLength
	property int roadTile4TotalDelay
	property bool roadTile4Roadworks
	property bool roadTile4

	property string roadTile5Name
	property int roadTile5NumberOfJams
	property real roadTile5TotalLength
	property int roadTile5TotalDelay
	property bool roadTile5Roadworks
	property bool roadTile5

	property bool fileinfoDataRead: false
	property url fileinfoApiUrl: "https://api.anwb.nl/routing/v1/incidents/incidents-desktop"

	// Fileinfo signals, used to update the listview and filter enabled button
	signal fileinfoUpdated()
	signal fileinfoFilterUpdated()

	FileIO {
		id: fileinfoSettingsFile
		source: "file:///mnt/data/tsc/fileinfo.userSettings.json"
 	}

	// Init the fileinfo app by registering the widgets
	function init() {
		registry.registerWidget("tile", tileUrl, this, null, {thumbLabel: qsTr("Verkeer"), thumbIcon: thumbnailIcon, thumbCategory: "general", thumbWeight: 30, baseTileWeight: 10, thumbIconVAlignment: "center"});
		registry.registerWidget("screen", fullScreenUrl, this, "fileinfoScreen");
		registry.registerWidget("screen", filterScreenUrl, this, "fileinfoFilterScreen");
		registry.registerWidget("menuItem", null, this, null, {objectName: "fileinfoMenuItem", label: qsTr("Fileinfo"), image: fileinfoMenuIconUrl, screenUrl: fullScreenUrl, weight: 120});
		registry.registerWidget("systrayIcon", trayUrl, this, "fileinfoTray");
	}

	// Parse the Fileinfo XML message and signal the FileinfoScreen. If there is no info between the <meldingen></meldingen> tags, empty the fileinfoData string


	function saveSettings() {

		// save user settings
		var tmpfileinfoFilterEnabled = "";
		if (fileinfoFilterEnabled == true) {
			tmpfileinfoFilterEnabled = "Yes";
		} else {
			tmpfileinfoFilterEnabled = "No";
		}

 		var tmpUserSettingsJson = {
			"roadFilter": fileinfoFilterArray,
			"filterEnabled": tmpfileinfoFilterEnabled 
		}

  		var doc3 = new XMLHttpRequest();
   		doc3.open("PUT", "file:///mnt/data/tsc/fileinfo.userSettings.json");
		doc3.send(JSON.stringify(tmpUserSettingsJson ));

	}

	function registerRoadTile(msgWegNr, length, delay, roadworks) {
		// A road with both a jam and roadworks gets two separate slots (one per type),
		// since "N file(s)" and "N wegwerkzaamheden" shouldn't be merged into one count.
		for (var i = 1; i <= 5; i++) {
			var nameProp = "roadTile" + i + "Name";
			var roadworksProp = "roadTile" + i + "Roadworks";
			if (fileinfoApp[nameProp] == "") {
				fileinfoApp[nameProp] = msgWegNr;
				fileinfoApp["roadTile" + i + "NumberOfJams"] = 1;
				fileinfoApp["roadTile" + i + "TotalLength"] = length;
				fileinfoApp["roadTile" + i + "TotalDelay"] = delay;
				fileinfoApp[roadworksProp] = roadworks;
				fileinfoApp["roadTile" + i] = true;
				return;
			}
			if (fileinfoApp[nameProp] == msgWegNr && fileinfoApp[roadworksProp] == roadworks) {
				fileinfoApp["roadTile" + i + "NumberOfJams"] = fileinfoApp["roadTile" + i + "NumberOfJams"] + 1;
				fileinfoApp["roadTile" + i + "TotalLength"] = Math.round((fileinfoApp["roadTile" + i + "TotalLength"] + length) * 100) / 100;
				fileinfoApp["roadTile" + i + "TotalDelay"] = fileinfoApp["roadTile" + i + "TotalDelay"] + delay;
				return;
			}
		}
	}

	function jamDescription(jam) {
		var description = "";
		if (jam["from"] == jam["to"]) {
			description = jam["from"];
		} else {
			description = "Van " + jam["from"] + " naar " + jam["to"];
		}
		if (jam["reason"]) {
			description = description + ". " + jam["reason"];
		}
		return description;
	}

	// "incidentType === road-closed" is not a reliable roadworks signal - roads also get
	// closed for accidents, technical problems, border checks, over-height vehicles, etc.
	// The reason text is the accurate source: it always spells out "Wegwerkzaamheden" for
	// genuine roadworks, regardless of incidentType.
	function isRoadworksJam(jam) {
		return !!(jam["reason"] && jam["reason"].indexOf("erkzaamheden") !== -1);
	}

	function jamXml(msgWegNr, jam, length, delay, wegvak) {
		var roadworks = isRoadworksJam(jam) ? "1" : "0";
		return "<melding><wegnr>" + xmlText(msgWegNr) + "</wegnr><wegvak>" + xmlText(wegvak) + "</wegvak><roadworks>" + roadworks + "</roadworks><description>" + xmlText(jamDescription(jam)) + "</description><afstand>" + length + "</afstand><vertraging>" + delay + "</vertraging></melding>";
	}

	function xmlText(value) {
		return String(value)
			.replace(/[\u0000-\u0008\u000b\u000c\u000e-\u001f\ufffe\uffff]/g, "")
			.replace(/[\ud800-\udbff][\udc00-\udfff]|[\ud800-\udfff]/g, function(character) {
				return character.length === 2 ? character : "\ufffd";
			})
			.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
			.replace(/"/g, "&quot;").replace(/'/g, "&apos;");
	}

	// Validate and normalize the complete response before changing the displayed data.
	function parseRoads(responseText) {
		if (responseText.length > 4 * 1024 * 1024) {
			throw new Error("Traffic response is too large");
		}
		var data = JSON.parse(responseText);
		if (!data || typeof data !== "object" || Array.isArray(data)) {
			throw new Error("Invalid traffic response");
		}
		var roads = data["roads"];
		if (!Array.isArray(roads) && data["data"] && typeof data["data"] === "object") {
			roads = data["data"]["roads"];
		}
		if (!Array.isArray(roads) || roads.length > 1024) {
			throw new Error("Invalid roads array");
		}

		function text(value) {
			if (value === undefined || value === null) return "";
			if (typeof value !== "string" || value.length > 4096) {
				throw new Error("Invalid traffic text");
			}
			return value;
		}
		function number(value) {
			if (value === undefined || value === null || value === "") return 0;
			if (typeof value !== "number" && typeof value !== "string") {
				throw new Error("Invalid traffic number");
			}
			var result = Number(value);
			if (!isFinite(result) || result < 0 || result > 2147483647) {
				throw new Error("Invalid traffic number");
			}
			return Math.floor(result);
		}

		var normalized = [];
		var segmentCount = 0;
		var jamCount = 0;
		for (var i = 0; i < roads.length; i++) {
			var road = roads[i];
			if (!road || typeof road !== "object" || Array.isArray(road)
					|| typeof road["road"] !== "string" || !text(road["road"])) {
				throw new Error("Invalid road");
			}
			var segments = road["segments"];
			if (segments === undefined || segments === null) segments = [];
			if (!Array.isArray(segments) || (segmentCount += segments.length) > 10000) {
				throw new Error("Invalid segments array");
			}
			var normalizedSegments = [];
			for (var j = 0; j < segments.length; j++) {
				var segment = segments[j];
				if (!segment || typeof segment !== "object" || Array.isArray(segment)) {
					throw new Error("Invalid segment");
				}
				var jams = segment["jams"];
				if (jams === undefined || jams === null) jams = [];
				if (!Array.isArray(jams) || (jamCount += jams.length) > 10000) {
					throw new Error("Invalid jams array");
				}
				var normalizedJams = [];
				for (var k = 0; k < jams.length; k++) {
					var jam = jams[k];
					if (!jam || typeof jam !== "object" || Array.isArray(jam)) {
						throw new Error("Invalid traffic incident");
					}
					normalizedJams.push({from: text(jam["from"]), to: text(jam["to"]),
						reason: text(jam["reason"]), distance: number(jam["distance"]), delay: number(jam["delay"])});
				}
				normalizedSegments.push({start: text(segment["start"]), end: text(segment["end"]), jams: normalizedJams});
			}
			normalized.push({road: road["road"], segments: normalizedSegments});
		}
		return normalized;
	}

	function updateAvailableRoads(roads) {
		var availableRoads = {};
		var seenRoads = [];

		for (var i = 0; i < roads.length; i++) {
			var road = roads[i];
			var roadName = road["road"];
			if (!roadName || availableRoads[roadName]) {
				continue;
			}
			availableRoads[roadName] = true;
			seenRoads.push(roadName);
		}

		seenRoads.sort();

		var roadOptions = [];
		for (var j = 0; j < seenRoads.length; j++) {
			roadOptions.push(seenRoads[j]);
		}
		roadOptions.push("Alle\nN-wegen");

		fileinfoAvailableRoads = roadOptions;
	}

	function updateFileinfoInfo() {
		fileinfoDataRead = false;

		var xmlhttp = new XMLHttpRequest();
		xmlhttp.onreadystatechange=function() {
			if (xmlhttp.readyState == 4) {
				if (xmlhttp.status != 200) {
					fileinfoUpdated();
					return;
				}

				var roads;
				try {
					roads = parseRoads(xmlhttp.responseText);
				} catch (parseError) {
					fileinfoUpdated();
					return;
				}

					// clear Tile
				for (var t = 1; t <= 5; t++) {
					fileinfoApp["roadTile" + t + "Name"] = "";
					fileinfoApp["roadTile" + t + "NumberOfJams"] = 0;
					fileinfoApp["roadTile" + t + "TotalLength"] = 0;
					fileinfoApp["roadTile" + t + "TotalDelay"] = 0;
					fileinfoApp["roadTile" + t + "Roadworks"] = false;
					fileinfoApp["roadTile" + t] = false;
				}

					// create filtered and normal set of traffic jams

				var length = 0;
				var delay = 0;
				var msgWegNr = "-";
				var searchmsgWegNr = "-";
				var myFilter = fileinfoFilterArray;
				var filterArr = myFilter.split(",");

				fileinfoDataFiltered = "<meldingen>";
				fileinfoDataAll = "<meldingen>";

				updateAvailableRoads(roads);

				for (var i = 0; i < roads.length; i++) {
					var road = roads[i];
					var segments = road["segments"];
					if (!segments || segments.length === undefined) {
						continue;
					}

					msgWegNr = road["road"];
					searchmsgWegNr = msgWegNr;
						// 	lookup roadnr in filter array
					if (msgWegNr.substring(0,1) == "N") {
						searchmsgWegNr = "N"
					}
					var index = filterArr.indexOf(searchmsgWegNr);
					for (var j = 0; j < segments.length; j++) {
						var segment = segments[j];
						var jams = segment["jams"];
						var wegvak = (segment["start"] && segment["end"]) ? (segment["start"] + " - " + segment["end"]) : "";

						if (jams) {

							for (var k = 0; k < jams.length; k++) {
								var jam = jams[k];

									// 	get length if supplied
								if (jam["distance"]) {
									length = parseInt(jam["distance"]) / 1000;
								} else {
									length = 0;
								}
								delay = 0;
								if (jam["delay"]) {
									delay = parseInt(jam["delay"]);
								}
								if ((!fileinfoFilterEnabled) || (index !== -1)) {
									registerRoadTile(msgWegNr, length, delay, isRoadworksJam(jam));
								}
								if (index !== -1) {
									fileinfoDataFiltered = fileinfoDataFiltered + jamXml(msgWegNr, jam, length, delay, wegvak);
								}
								fileinfoDataAll = fileinfoDataAll + jamXml(msgWegNr, jam, length, delay, wegvak);
							}
						}
					}
				}

				fileinfoDataFiltered = fileinfoDataFiltered  + "</meldingen>";
				fileinfoDataAll = fileinfoDataAll  + "</meldingen>";

					//actual data to be displayed on screen

				if (fileinfoFilterEnabled) {
					fileinfoData = fileinfoDataFiltered;
				} else {
					fileinfoData = fileinfoDataAll;
				}
				fileinfoDataRead = true;
				fileinfoUpdated();
			}
		}
		xmlhttp.open("GET", fileinfoApiUrl, true);
		xmlhttp.send();
	}

	Component.onCompleted: {

			// read saved filter and start timer

		try {
			var fileinfoSettingsJson = JSON.parse(fileinfoSettingsFile.read());
			if (fileinfoSettingsJson && typeof fileinfoSettingsJson['roadFilter'] === "string"
					&& fileinfoSettingsJson['roadFilter'].length <= 8192) {
				fileinfoFilterArray = fileinfoSettingsJson['roadFilter'];
			}
			if (fileinfoSettingsJson['filterEnabled'] == "Yes") {
				fileinfoFilterEnabled = true
			} else {
				fileinfoFilterEnabled = false
			}		
		} catch(e) {
		}
		datetimeTimerFiles.running = true;
	}

	Timer {
		id: datetimeTimerFiles
		interval: 600000			//update every 10 mins
		triggeredOnStart: true
		running: false
		repeat: true
		onTriggered: updateFileinfoInfo()
	}
}
