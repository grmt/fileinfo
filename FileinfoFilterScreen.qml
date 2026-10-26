import QtQuick 2.1
import BasicUIControls 1.0;
import qb.components 1.0

Screen {
	id: fileinfoFilterScreen

	property variant defaultRoadArray : [
		"A1", "A2", "A4", "A6", "A7", "A8", "A9", "A10", "A12", "A13",
		"A15", "A16", "A17", "A18", "A20", "A22", "A27", "A28", "A29", "A30",
		"A31", "A32", "A35", "A37", "A38", "A44", "A50", "A58", "A59", "A65",
		"A67", "A73", "A74", "A76", "A77", "A79", "A200", "A325",
		"N3", "N7", "N9", "N11", "N14", "N18", "N30", "N31", "N32", "N33",
		"N35", "N36", "N44", "N46", "N48", "N50", "N57", "N59", "N61", "N65",
		"N99", "N200", "N434", "N915",
		"Alle\nN-wegen"
	]

	// index 0 = A-wegen page, 1 = N-wegen page
	property int currentPage: 0
	property variant aRoadsArray: []
	property variant nRoadsArray: []

	function effectiveRoadArray() {
		if (app.fileinfoAvailableRoads && app.fileinfoAvailableRoads.length > 0) {
			return app.fileinfoAvailableRoads;
		}
		return defaultRoadArray;
	}

	// Splits the combined road list into an A-wegen and an N-wegen array. Kept as
	// two separate pages (rather than one long grid) because on-screen the combined
	// list has too many columns to fit the display width - entries beyond the visible
	// columns became unreachable, and the fixed Clear button could land on top of a
	// road button.
	function splitRoads(roadArray) {
		var a = [];
		var n = [];
		for (var i = 0; i < roadArray.length; i++) {
			var roadName = roadArray[i];
			if (roadName === "Alle\nN-wegen") continue;
			if (roadName.charAt(0) === "N") {
				n.push(roadName);
			} else {
				a.push(roadName);
			}
		}
		n.push("Alle\nN-wegen");
		return {a: a, n: n};
	}

	function restoreSelection(roadArray, group) {
		var myFilter = app.fileinfoFilterArray;
		var filterArr = myFilter.split(",");
		var selectedIndexArr = [];

		for (var i = 0; i < filterArr.length; i++) {
			var index;
			if (filterArr[i] == "N") {
				index = roadArray.indexOf("Alle\nN-wegen");
			}
			else {
				index = roadArray.indexOf(filterArr[i]);
			}
			if (index != -1) {
				selectedIndexArr.push(index);
			}
		}

		group.clearSelectedControls();
		if (selectedIndexArr.length > 0) {
			group.setSelectedControls(selectedIndexArr);
		}
	}

	function selectedRoadNames(roadArray, group) {
		var selectedIndexArr = group.getSelectedControls();
		var names = [];
		for (var i = 0; i < selectedIndexArr.length; i++) {
			var roadName = roadArray[selectedIndexArr[i]];
			if (roadName === "Alle\nN-wegen")
				roadName = "N"; // Driver expects N instead of "Alle\nN-wegen"
			names.push(roadName);
		}
		return names;
	}

	function updatePageHeader() {
		pageTitle.text = currentPage === 0 ? qsTr("A-wegen") : qsTr("N-wegen");
		fileinfoFilterGridViewA.visible = currentPage === 0;
		fileinfoFilterGridViewN.visible = currentPage === 1;
		leftArrow.enabled = currentPage > 0;
		rightArrow.enabled = currentPage < 1;
	}

	screenTitle: qsTr("Filter")
	isSaveCancelDialog: true

	onShown: {
		var split = splitRoads(effectiveRoadArray());
		aRoadsArray = split.a;
		nRoadsArray = split.n;

		fileinfoFilterModelA.clear();
		for (var i = 0; i < aRoadsArray.length; i++) {
			fileinfoFilterModelA.append({roadName: aRoadsArray[i]});
		}
		fileinfoFilterModelN.clear();
		for (var j = 0; j < nRoadsArray.length; j++) {
			fileinfoFilterModelN.append({roadName: nRoadsArray[j]});
		}

		restoreSelection(aRoadsArray, fileinfoFilterGroupA);
		restoreSelection(nRoadsArray, fileinfoFilterGroupN);

		currentPage = 0;
		updatePageHeader();
	}

	onSaved: {
		var filterArr = selectedRoadNames(aRoadsArray, fileinfoFilterGroupA).concat(
			selectedRoadNames(nRoadsArray, fileinfoFilterGroupN));
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
				if (currentPage < 1) {
					currentPage = currentPage + 1;
					updatePageHeader();
				}
			}
		}
	}

	GridView {
		id: fileinfoFilterGridViewA

		model: fileinfoFilterModelA
		delegate: FileinfoFilterDelegate { targetControlGroup: fileinfoFilterGroupA }

		flow: GridView.TopToBottom
		cellWidth: isNxt ? 132 : 106
		cellHeight: isNxt ? 75 : 60
		interactive: true
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
		delegate: FileinfoFilterDelegate { targetControlGroup: fileinfoFilterGroupN }

		flow: GridView.TopToBottom
		cellWidth: isNxt ? 132 : 106
		cellHeight: isNxt ? 75 : 60
		interactive: true
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
				fileinfoFilterGroupA.clearSelectedControls();
				fileinfoFilterGroupN.clearSelectedControls();
			}
		}
	}
}
