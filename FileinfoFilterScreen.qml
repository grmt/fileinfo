import QtQuick 2.1
import BasicUIControls 1.0;
import qb.components 1.0

Screen {
	id: fileinfoFilterScreen

	// Pages: A-wegen, N-wegen, Steden.
	property int currentPage: 0
	property variant aRoadsArray: []
	property variant nRoadsArray: []
	property variant citiesArray: []

	function effectiveRoadArray() {
		if (app.fileinfoAvailableRoads && app.fileinfoAvailableRoads.length > 0) {
			return app.fileinfoAvailableRoads;
		}
		return app.defaultRoadArray;
	}

	// Match road numbers, so names such as Nijmegen and Amsterdam remain cities.
	function splitRoads(roadArray) {
		var a = [];
		var n = [];
		var cities = [];
		for (var i = 0; i < roadArray.length; i++) {
			var roadName = roadArray[i];
			if (roadName === "Alle\nN-wegen") continue;
			if (/^N[0-9]+$/.test(roadName)) {
				n.push(roadName);
			} else if (/^A[0-9]+$/.test(roadName)) {
				a.push(roadName);
			} else {
				cities.push(roadName);
			}
		}
		n.push("Alle\nN-wegen");
		return {a: a, n: n, cities: cities};
	}

	function populateRoadModel(model, roadArray) {
		var selected = app.fileinfoFilterArray.split(",");
		model.clear();
		for (var i = 0; i < roadArray.length; i++) {
			var name = roadArray[i];
			var filterName = name === "Alle\nN-wegen" ? "N" : name;
			model.append({roadName: name, roadSelected: selected.indexOf(filterName) !== -1});
		}
	}

	// Store selections in the model, including buttons outside the visible viewport.
	function selectedRoadNames(model) {
		var names = [];
		for (var i = 0; i < model.count; i++) {
			var road = model.get(i);
			if (!road.roadSelected) continue;
			var roadName = road.roadName;
			if (roadName === "Alle\nN-wegen")
				roadName = "N"; // Driver expects N instead of "Alle\nN-wegen"
			names.push(roadName);
		}
		return names;
	}

	function clearRoadSelection(model) {
		for (var i = 0; i < model.count; i++) model.setProperty(i, "roadSelected", false);
	}

	function updatePageHeader() {
		pageTitle.text = currentPage === 0 ? qsTr("A-wegen") :
			(currentPage === 1 ? qsTr("N-wegen") : qsTr("Steden"));
		fileinfoFilterGridViewA.visible = currentPage === 0;
		fileinfoFilterGridViewN.visible = currentPage === 1;
		fileinfoFilterGridViewCities.visible = currentPage === 2;
		noCitiesText.visible = currentPage === 2 && citiesArray.length === 0;
		leftArrow.enabled = currentPage > 0;
		rightArrow.enabled = currentPage < 2;
	}

	screenTitle: qsTr("Filter")
	isSaveCancelDialog: true

	onShown: {
		var split = splitRoads(effectiveRoadArray());
		aRoadsArray = split.a;
		nRoadsArray = split.n;
		citiesArray = split.cities;

		populateRoadModel(fileinfoFilterModelA, aRoadsArray);
		populateRoadModel(fileinfoFilterModelN, nRoadsArray);
		populateRoadModel(fileinfoFilterModelCities, citiesArray);
		fileinfoFilterGridViewA.positionViewAtBeginning();
		fileinfoFilterGridViewN.positionViewAtBeginning();
		fileinfoFilterGridViewCities.positionViewAtBeginning();

		currentPage = 0;
		updatePageHeader();
	}

	onSaved: {
		var filterArr = selectedRoadNames(fileinfoFilterModelA).concat(
			selectedRoadNames(fileinfoFilterModelN), selectedRoadNames(fileinfoFilterModelCities));
		var myFilterStr = filterArr.toString();
		app.fileinfoFilterArray = myFilterStr;
		app.saveSettings();
		app.updateFileinfoInfo();
	}

	ControlGroup {
		id: fileinfoFilterGroupA
		exclusive: false
	}

	ControlGroup {
		id: fileinfoFilterGroupN
		exclusive: false
	}

	ControlGroup {
		id: fileinfoFilterGroupCities
		exclusive: false
	}

	Item {
		id: pageHeader
		height: isNxt ? 40 : 32
		anchors {
			top: parent.top
			topMargin: isNxt ? 8 : 6
			left: parent.left
			leftMargin: isNxt ? 58 : 46
			right: parent.right
			rightMargin: isNxt ? 58 : 46
		}

		IconButton {
			id: leftArrow
			anchors.left: parent.left
			anchors.verticalCenter: parent.verticalCenter
			iconSource: "qrc:/tsc/navArrow-left.png"
			onClicked: {
				if (currentPage > 0) {
					currentPage = currentPage - 1;
					updatePageHeader();
				}
			}
		}

		Text {
			id: pageTitle
			anchors.centerIn: parent
			font.family: qfont.semiBold.name
			font.pixelSize: isNxt ? 22 : 18
		}

		IconButton {
			id: rightArrow
			anchors.right: parent.right
			anchors.verticalCenter: parent.verticalCenter
			iconSource: "qrc:/tsc/navArrow-right.png"
			onClicked: {
				if (currentPage < 2) {
					currentPage = currentPage + 1;
					updatePageHeader();
				}
			}
		}
	}

	GridView {
		id: fileinfoFilterGridViewA

		model: fileinfoFilterModelA
		delegate: FileinfoFilterDelegate { targetControlGroup: fileinfoFilterGroupA; targetModel: fileinfoFilterModelA }

		flow: GridView.LeftToRight
		cellWidth: isNxt ? 132 : 106
		cellHeight: isNxt ? 75 : 60
		interactive: true
		clip: true
		flickableDirection: Flickable.VerticalFlick

		anchors {
			top: pageHeader.bottom
			bottom: parent.bottom
			left: parent.left
			right: parent.right
			topMargin: isNxt ? 11 : 9
			leftMargin: isNxt ? 58 : 46
			rightMargin: (isNxt ? 132 : 106) + 12
		}
	}

	GridView {
		id: fileinfoFilterGridViewN

		model: fileinfoFilterModelN
		delegate: FileinfoFilterDelegate { targetControlGroup: fileinfoFilterGroupN; targetModel: fileinfoFilterModelN }

		flow: GridView.LeftToRight
		cellWidth: isNxt ? 132 : 106
		cellHeight: isNxt ? 75 : 60
		interactive: true
		clip: true
		flickableDirection: Flickable.VerticalFlick

		anchors {
			top: pageHeader.bottom
			bottom: parent.bottom
			left: parent.left
			right: parent.right
			topMargin: isNxt ? 11 : 9
			leftMargin: isNxt ? 58 : 46
			rightMargin: (isNxt ? 132 : 106) + 12
		}
	}

	ListModel {
		id: fileinfoFilterModelA
	}

	GridView {
		id: fileinfoFilterGridViewCities
		model: fileinfoFilterModelCities
		delegate: FileinfoFilterDelegate {
			targetControlGroup: fileinfoFilterGroupCities
			targetModel: fileinfoFilterModelCities
			city: true
		}
		flow: GridView.LeftToRight
		cellWidth: isNxt ? 250 : 200
		cellHeight: isNxt ? 75 : 60
		interactive: true
		clip: true
		flickableDirection: Flickable.VerticalFlick
		anchors {
			top: pageHeader.bottom
			bottom: parent.bottom
			left: parent.left
			right: parent.right
			topMargin: isNxt ? 11 : 9
			leftMargin: isNxt ? 58 : 46
			rightMargin: (isNxt ? 132 : 106) + 12
		}
	}

	Text {
		id: noCitiesText
		anchors.top: pageHeader.bottom
		anchors.topMargin: 20
		anchors.horizontalCenter: parent.horizontalCenter
		text: qsTr("Nog geen steden ontvangen van ANWB.")
		font.family: qfont.regular.name
		font.pixelSize: isNxt ? 20 : 16
	}

	ListModel {
		id: fileinfoFilterModelCities
	}

	ListModel {
		id: fileinfoFilterModelN
	}

	Rectangle {
		width: isNxt ? 132 : 106
		height: isNxt ? 75 : 60
		color: colors.canvas

		anchors {
			bottom: parent.bottom
			bottomMargin: 14
			right: parent.right
			rightMargin: 12
		}

		StandardButton {
			id: fileinfoFilterClearButton

			anchors {
				top: parent.top
				topMargin: 4
				left: parent.left
				leftMargin: 1
			}

			text: qsTr("Clear")

			onPressed: {
				clearRoadSelection(fileinfoFilterModelA);
				clearRoadSelection(fileinfoFilterModelN);
				clearRoadSelection(fileinfoFilterModelCities);
				fileinfoFilterGroupA.clearSelectedControls();
				fileinfoFilterGroupN.clearSelectedControls();
				fileinfoFilterGroupCities.clearSelectedControls();
			}
		}
	}
}
