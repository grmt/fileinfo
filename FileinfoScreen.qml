import QtQuick 2.1
import SimpleXmlListModel 1.0
import qb.components 1.0


Screen {
	// Fileinfo loading indicator
	property bool fileinfoLoaded: false
	// for unit test only
	property alias fileinfoSimpleListCount: fileinfoSimpleList.count

	// Function (triggerd by a signal) updates the fileinfo list model and the header text
	function updateFileinfoList() {
		if (!app.fileinfoDataRead) {
			noJamsText.visible = true;
			noJamsText.text = qsTr('Verkeersinformatie ophalen mislukt. Geen internet verbinding?');
		} else {
			 if (app.fileinfoData.length > 0) {
				// Update the fileinfo list model
				noJamsText.visible = false;
				fileinfoModel.xml = app.fileinfoData;
				fileinfoSimpleList.initialView();
			} else {
				noJamsText.visible = true;
				if (app.fileinfoFilterEnabled) {
					noJamsText.text = qsTr("Geen files - filter aan.");
				} else {
					noJamsText.text = qsTr("Geen files");
				}
			}
		}
		fileinfoLoaded = true;

		// Update the header text
		headerText.text = getHeaderText();
		buttonsEnabled(true);
	}

	// Function (triggerd by a signal) updates the header text
	function updateFileinfoFilter() {
		headerText.text = getHeaderText();
		filterButton.selected = app.fileinfoFilterEnabled;
		updateFileinfoList();
	}

	// Function creates the header text using the correct XML nodes
	function getHeaderText() {
		var str = "";
		if(!app.fileinfoDataRead) return str;

		if (app.fileinfoFilterEnabled) {
			str += qsTr("Filter aan") + ": ";
		}
		if (fileinfoModel.count == 1) {
			str += fileinfoModel.count + " melding";
		} else {
			str += fileinfoModel.count + " meldingen";
		}
		return str;
	}

	function buttonsEnabled(enabled) {
		if (enabled) {
			refreshButton.state = 'up'
			filterButton.state = app.fileinfoFilterEnabled ? 'selected' : 'up';
		} else {
			refreshButton.state = 'disabled';
			filterButton.state = 'disabled';
		}
	}

	anchors.fill: parent
	screenTitleIconUrl: "qrc:/tsc/traffic.png"
	screenTitle: qsTr("Fileinfo")

	Component.onCompleted: {
		app.fileinfoUpdated.connect(updateFileinfoList)
		app.fileinfoFilterUpdated.connect(updateFileinfoFilter)
	}

	onShown: {
		buttonsEnabled(false);
		// Initialize new fileinfo data request and clear the list model view
		if (app.fileinfoFilterEnabled) {
			app.fileinfoData = app.fileinfoDataFiltered;
		} else {
			app.fileinfoData = app.fileinfoDataAll;
		}
		updateFileinfoFilter();
		addCustomTopRightButton("Wijzig filter");
	}

	onCustomButtonClicked: {
		if (app.fileinfoFilterScreen) app.fileinfoFilterScreen.show();
	}

	Item {
		id: header
		height: isNxt ? 55 : 45
		anchors.horizontalCenter: parent.horizontalCenter
		width: isNxt ? parent.width - 95 : parent.width - 76

		Text {
			id: headerText
			text: getHeaderText()
			font.family: qfont.semiBold.name
			font.pixelSize: isNxt ? 25 : 20
			anchors {
				left: header.left
				bottom: parent.bottom
			}
		}

		StandardButton {
			id: filterButton
			text: qsTr("Filter")

			anchors {
				right: refreshButton.left
				rightMargin: 5
				bottom: parent.bottom
			}

			rightClickMargin: 2
			bottomClickMargin: 5

			selected: false

			onClicked: {
				if (app.fileinfoFilterEnabled) {
					app.fileinfoFilterEnabled = false
					app.fileinfoData = app.fileinfoDataAll;
				}
				else {
					app.fileinfoFilterEnabled = true;
					app.fileinfoData = app.fileinfoDataFiltered;
				}
				updateFileinfoFilter();
				app.saveSettings();
				app.updateFileinfoInfo(); // to update the tile
			}
		}

		IconButton {
			id: refreshButton
			anchors.right: parent.right
			anchors.bottom: parent.bottom
			leftClickMargin: 3
			bottomClickMargin: 5
			iconSource: "qrc:/tsc/refresh.svg"
			onClicked: {
				// Request new fileinfo data
				requestNewFileinfoData();
			}
		}
	}

	SimpleXmlListModel {
		id: fileinfoModel
		query: "/meldingen/melding"
		roles: ({
			wegnr: "string",
			wegvak: "string",
			roadworks: "string",
			oorzaak: "string",
			gevolg: "string",
			description: "string",
			afstand: "number",
			vertraging: "string"
		})
	}

	Rectangle {
		id: content
		anchors.horizontalCenter: parent.horizontalCenter
		width: isNxt ? parent.width - 95 : parent.width - 76
		height: isNxt ? parent.height - 94 : parent.height - 75
		y: isNxt ? 64 : 51
		radius: 3

		FileinfoSimpleList {
			id: fileinfoSimpleList
			delegate: FileinfoDelegate{}
			dataModel: fileinfoModel
			itemHeight: isNxt ? 91 : 73
			itemsPerPage: 4
			anchors.top: parent.top
			downIcon: "qrc:/tsc/arrowScrolldown.png"
			buttonsHeight: isNxt ? 180 : 144
			buttonsVisible: true
			scrollbarVisible: true
		}

		Throbber {
			id: refreshThrobber
			anchors.centerIn: parent
			visible: !fileinfoLoaded
		}

		Text {
			id: noJamsText
			visible: false
			anchors.centerIn: parent
			font.family: qfont.italic.name
			font.pixelSize: isNxt ? 18 : 15
		}
	}

	Text {
		id: footer
		text: "Bron: anwb.nl"
		anchors {
			baseline: parent.bottom
			baselineOffset: -5
			right: parent.right
			rightMargin: 5
		}
		font {
			pixelSize: isNxt ? 18 : 15
			family: qfont.italic.name
		}
	}
}
