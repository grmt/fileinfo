import QtQuick 2.1
import qb.components 1.0

Tile {
	id: fileinfoTile

	function isARoad(name) {
		return name && name.charAt(0) === "A";
	}

	function roadStats(numberOfJams, totalLength, totalDelay, roadworks) {
		var text = roadworks ? (numberOfJams + " wegwerkzaamheden") : (numberOfJams + (numberOfJams === 1 ? " file" : " files"));
		if (totalLength > 0 || totalDelay > 0) {
			text += ", " + totalLength + " km, " + Math.round(totalDelay / 60) + " min";
		}
		return text;
	}

	onClicked: {
		if (app.fileinfoScreen) app.fileinfoScreen.show();
	}

	// Row 1
	Rectangle {
		id: roadTile1Badge
		width: isNxt ? 46 : 38
		height: isNxt ? 24 : 20
		radius: 4
		color: isARoad(app.roadTile1Name) ? "#D0021B" : "#FFD400"
		anchors {
			top: parent.top
			topMargin: isNxt ? 12 : 9
			left: parent.left
			leftMargin: 10
		}
		visible: app.roadTile1

		Text {
			anchors.centerIn: parent
			text: app.roadTile1Name
			textFormat: Text.PlainText
			color: isARoad(app.roadTile1Name) ? "#FFFFFF" : "#000000"
			font.family: qfont.semiBold.name
			font.pixelSize: isNxt ? 15 : 12
		}
	}

	Image {
		id: roadTile1Icon
		source: "qrc:/tsc/fileinfotray.png"
		width: isNxt ? 22 : 18
		height: width
		fillMode: Image.PreserveAspectFit
		anchors {
			left: roadTile1Badge.right
			leftMargin: 8
			verticalCenter: roadTile1Badge.verticalCenter
		}
		visible: app.roadTile1 && !app.roadTile1Roadworks
	}

	Rectangle {
		id: roadTile1RoadworksIcon
		width: isNxt ? 16 : 13
		height: width
		rotation: 45
		radius: 2
		color: "#FF9800"
		anchors {
			left: roadTile1Badge.right
			leftMargin: 12
			verticalCenter: roadTile1Badge.verticalCenter
		}
		visible: app.roadTile1 && app.roadTile1Roadworks
	}

	Text {
		id: roadTile1StatsLabel
		text: roadStats(app.roadTile1NumberOfJams, app.roadTile1TotalLength, app.roadTile1TotalDelay, app.roadTile1Roadworks)
		anchors {
			left: roadTile1Icon.right
			leftMargin: 8
			verticalCenter: roadTile1Badge.verticalCenter
			right: parent.right
			rightMargin: 10
		}
		elide: Text.ElideRight
		font.family: qfont.bold.name
		font.pixelSize: isNxt ? 18 : 14
		color: (typeof dimmableColors !== 'undefined') ? dimmableColors.clockTileColor : colors.clockTileColor
		visible: app.roadTile1
	}

	// Row 2
	Rectangle {
		id: roadTile2Badge
		width: isNxt ? 46 : 38
		height: isNxt ? 24 : 20
		radius: 4
		color: isARoad(app.roadTile2Name) ? "#D0021B" : "#FFD400"
		anchors {
			top: roadTile1Badge.bottom
			topMargin: isNxt ? 13 : 10
			left: parent.left
			leftMargin: 10
		}
		visible: app.roadTile2

		Text {
			anchors.centerIn: parent
			text: app.roadTile2Name
			textFormat: Text.PlainText
			color: isARoad(app.roadTile2Name) ? "#FFFFFF" : "#000000"
			font.family: qfont.semiBold.name
			font.pixelSize: isNxt ? 15 : 12
		}
	}

	Image {
		id: roadTile2Icon
		source: "qrc:/tsc/fileinfotray.png"
		width: isNxt ? 22 : 18
		height: width
		fillMode: Image.PreserveAspectFit
		anchors {
			left: roadTile2Badge.right
			leftMargin: 8
			verticalCenter: roadTile2Badge.verticalCenter
		}
		visible: app.roadTile2 && !app.roadTile2Roadworks
	}

	Rectangle {
		id: roadTile2RoadworksIcon
		width: isNxt ? 16 : 13
		height: width
		rotation: 45
		radius: 2
		color: "#FF9800"
		anchors {
			left: roadTile2Badge.right
			leftMargin: 12
			verticalCenter: roadTile2Badge.verticalCenter
		}
		visible: app.roadTile2 && app.roadTile2Roadworks
	}

	Text {
		id: roadTile2StatsLabel
		text: roadStats(app.roadTile2NumberOfJams, app.roadTile2TotalLength, app.roadTile2TotalDelay, app.roadTile2Roadworks)
		anchors {
			left: roadTile2Icon.right
			leftMargin: 8
			verticalCenter: roadTile2Badge.verticalCenter
			right: parent.right
			rightMargin: 10
		}
		elide: Text.ElideRight
		font.family: qfont.bold.name
		font.pixelSize: isNxt ? 18 : 14
		color: (typeof dimmableColors !== 'undefined') ? dimmableColors.clockTileColor : colors.clockTileColor
		visible: app.roadTile2
	}

	// Row 3
	Rectangle {
		id: roadTile3Badge
		width: isNxt ? 46 : 38
		height: isNxt ? 24 : 20
		radius: 4
		color: isARoad(app.roadTile3Name) ? "#D0021B" : "#FFD400"
		anchors {
			top: roadTile2Badge.bottom
			topMargin: isNxt ? 13 : 10
			left: parent.left
			leftMargin: 10
		}
		visible: app.roadTile3

		Text {
			anchors.centerIn: parent
			text: app.roadTile3Name
			textFormat: Text.PlainText
			color: isARoad(app.roadTile3Name) ? "#FFFFFF" : "#000000"
			font.family: qfont.semiBold.name
			font.pixelSize: isNxt ? 15 : 12
		}
	}

	Image {
		id: roadTile3Icon
		source: "qrc:/tsc/fileinfotray.png"
		width: isNxt ? 22 : 18
		height: width
		fillMode: Image.PreserveAspectFit
		anchors {
			left: roadTile3Badge.right
			leftMargin: 8
			verticalCenter: roadTile3Badge.verticalCenter
		}
		visible: app.roadTile3 && !app.roadTile3Roadworks
	}

	Rectangle {
		id: roadTile3RoadworksIcon
		width: isNxt ? 16 : 13
		height: width
		rotation: 45
		radius: 2
		color: "#FF9800"
		anchors {
			left: roadTile3Badge.right
			leftMargin: 12
			verticalCenter: roadTile3Badge.verticalCenter
		}
		visible: app.roadTile3 && app.roadTile3Roadworks
	}

	Text {
		id: roadTile3StatsLabel
		text: roadStats(app.roadTile3NumberOfJams, app.roadTile3TotalLength, app.roadTile3TotalDelay, app.roadTile3Roadworks)
		anchors {
			left: roadTile3Icon.right
			leftMargin: 8
			verticalCenter: roadTile3Badge.verticalCenter
			right: parent.right
			rightMargin: 10
		}
		elide: Text.ElideRight
		font.family: qfont.bold.name
		font.pixelSize: isNxt ? 18 : 14
		color: (typeof dimmableColors !== 'undefined') ? dimmableColors.clockTileColor : colors.clockTileColor
		visible: app.roadTile3
	}

	// Row 4
	Rectangle {
		id: roadTile4Badge
		width: isNxt ? 46 : 38
		height: isNxt ? 24 : 20
		radius: 4
		color: isARoad(app.roadTile4Name) ? "#D0021B" : "#FFD400"
		anchors {
			top: roadTile3Badge.bottom
			topMargin: isNxt ? 13 : 10
			left: parent.left
			leftMargin: 10
		}
		visible: app.roadTile4

		Text {
			anchors.centerIn: parent
			text: app.roadTile4Name
			textFormat: Text.PlainText
			color: isARoad(app.roadTile4Name) ? "#FFFFFF" : "#000000"
			font.family: qfont.semiBold.name
			font.pixelSize: isNxt ? 15 : 12
		}
	}

	Image {
		id: roadTile4Icon
		source: "qrc:/tsc/fileinfotray.png"
		width: isNxt ? 22 : 18
		height: width
		fillMode: Image.PreserveAspectFit
		anchors {
			left: roadTile4Badge.right
			leftMargin: 8
			verticalCenter: roadTile4Badge.verticalCenter
		}
		visible: app.roadTile4 && !app.roadTile4Roadworks
	}

	Rectangle {
		id: roadTile4RoadworksIcon
		width: isNxt ? 16 : 13
		height: width
		rotation: 45
		radius: 2
		color: "#FF9800"
		anchors {
			left: roadTile4Badge.right
			leftMargin: 12
			verticalCenter: roadTile4Badge.verticalCenter
		}
		visible: app.roadTile4 && app.roadTile4Roadworks
	}

	Text {
		id: roadTile4StatsLabel
		text: roadStats(app.roadTile4NumberOfJams, app.roadTile4TotalLength, app.roadTile4TotalDelay, app.roadTile4Roadworks)
		anchors {
			left: roadTile4Icon.right
			leftMargin: 8
			verticalCenter: roadTile4Badge.verticalCenter
			right: parent.right
			rightMargin: 10
		}
		elide: Text.ElideRight
		font.family: qfont.bold.name
		font.pixelSize: isNxt ? 18 : 14
		color: (typeof dimmableColors !== 'undefined') ? dimmableColors.clockTileColor : colors.clockTileColor
		visible: app.roadTile4
	}

	// Row 5
	Rectangle {
		id: roadTile5Badge
		width: isNxt ? 46 : 38
		height: isNxt ? 24 : 20
		radius: 4
		color: isARoad(app.roadTile5Name) ? "#D0021B" : "#FFD400"
		anchors {
			top: roadTile4Badge.bottom
			topMargin: isNxt ? 13 : 10
			left: parent.left
			leftMargin: 10
		}
		visible: app.roadTile5

		Text {
			anchors.centerIn: parent
			text: app.roadTile5Name
			textFormat: Text.PlainText
			color: isARoad(app.roadTile5Name) ? "#FFFFFF" : "#000000"
			font.family: qfont.semiBold.name
			font.pixelSize: isNxt ? 15 : 12
		}
	}

	Image {
		id: roadTile5Icon
		source: "qrc:/tsc/fileinfotray.png"
		width: isNxt ? 22 : 18
		height: width
		fillMode: Image.PreserveAspectFit
		anchors {
			left: roadTile5Badge.right
			leftMargin: 8
			verticalCenter: roadTile5Badge.verticalCenter
		}
		visible: app.roadTile5 && !app.roadTile5Roadworks
	}

	Rectangle {
		id: roadTile5RoadworksIcon
		width: isNxt ? 16 : 13
		height: width
		rotation: 45
		radius: 2
		color: "#FF9800"
		anchors {
			left: roadTile5Badge.right
			leftMargin: 12
			verticalCenter: roadTile5Badge.verticalCenter
		}
		visible: app.roadTile5 && app.roadTile5Roadworks
	}

	Text {
		id: roadTile5StatsLabel
		text: roadStats(app.roadTile5NumberOfJams, app.roadTile5TotalLength, app.roadTile5TotalDelay, app.roadTile5Roadworks)
		anchors {
			left: roadTile5Icon.right
			leftMargin: 8
			verticalCenter: roadTile5Badge.verticalCenter
			right: parent.right
			rightMargin: 10
		}
		elide: Text.ElideRight
		font.family: qfont.bold.name
		font.pixelSize: isNxt ? 18 : 14
		color: (typeof dimmableColors !== 'undefined') ? dimmableColors.clockTileColor : colors.clockTileColor
		visible: app.roadTile5
	}
}
