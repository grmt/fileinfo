import QtQuick 2.1
import qb.components 1.0

Rectangle {

	// Create the correct jam length string
	function getLength () {
		return afstand.toString() + " km, ";
	}

	// Create the delay in seconds to string
	function getDelay () {
		var minutes = parseInt(vertraging) / 60;
		return minutes.toString() + " min vertraging"
	}

	// A-roads get a red badge, N-roads a yellow badge (matches Dutch road sign colors)
	function isARoad () {
		return wegnr && wegnr.charAt(0) === "A";
	}

	function isRoadworksJam () {
		return roadworks === "1";
	}

	width: isNxt ? 870 : 646
	height: isNxt ? 94 : 73
	color: colors.background

	Rectangle {
		id: roadBadge
		x: 10
		anchors.top: parent.top
		anchors.topMargin: isNxt ? 8 : 6
		width: isNxt ? 56 : 44
		height: isNxt ? 28 : 22
		radius: 4
		color: isARoad() ? "#D0021B" : "#FFD400"

		Text {
			id: roadLabel
			anchors.centerIn: parent
			text: wegnr
			textFormat: Text.PlainText
			color: isARoad() ? "#FFFFFF" : "#000000"
			font.family: qfont.semiBold.name
			font.pixelSize: isNxt ? 19 : 15
		}
	}

	Text {
		id: wegvakLabel
		anchors.left: roadBadge.right
		anchors.leftMargin: 8
		anchors.verticalCenter: roadBadge.verticalCenter
		width: isNxt ? 520 : 380
		text: wegvak
		textFormat: Text.PlainText
		elide: Text.ElideRight
		font.family: qfont.semiBold.name
		font.pixelSize: isNxt ? 20 : 16
	}

	Text {
		anchors.right: vertragingLabel.left
		anchors.rightMargin: 10
		anchors.verticalCenter: roadBadge.verticalCenter
		text: getLength()
		font.family: qfont.semiBold.name
		font.pixelSize: isNxt ? 22 : 18
	}

	Text {
		id: vertragingLabel
		anchors.verticalCenter: roadBadge.verticalCenter
		anchors.right: parent.right
		anchors.rightMargin: 10
		text: getDelay()
		font.family: qfont.semiBold.name
		font.pixelSize: isNxt ? 22 : 18
	}

	// Icon indicating a traffic jam (same icon as the systray/menu-bar shortcut to this app)
	// or roadworks (amber warning diamond). Only the applicable variant is instantiated
	// (via Loader) to keep this delegate lightweight - FileinfoSimpleList fully recreates
	// all visible delegates on every page scroll, so extra always-present items here add
	// up fast when scrolling.
	Component {
		id: jamIconComponent
		Image {
			width: isNxt ? 24 : 20
			height: width
			fillMode: Image.PreserveAspectFit
			source: "qrc:/tsc/fileinfotray.png"
		}
	}

	Component {
		id: roadworksIconComponent
		Item {
			width: isNxt ? 24 : 20
			height: width

			Rectangle {
				anchors.centerIn: parent
				width: parent.width * 0.72
				height: width
				rotation: 45
				radius: 2
				color: "#FF9800"
			}

			Text {
				anchors.centerIn: parent
				text: "!"
				color: "#000000"
				font.family: qfont.semiBold.name
				font.pixelSize: parent.height * 0.6
			}
		}
	}

	Loader {
		id: reasonIcon
		x: 10
		anchors.top: roadBadge.bottom
		anchors.topMargin: isNxt ? 8 : 5
		sourceComponent: isRoadworksJam() ? roadworksIconComponent : jamIconComponent
	}

	Text {
		id:oorzaak
		anchors.left: reasonIcon.right
		anchors.leftMargin: 8
		anchors.top: roadBadge.bottom
		anchors.topMargin: isNxt ? 6 : 4
		width: isNxt ? parent.width - 125 - 32 : parent.width - 100 - 28
		text: description
		textFormat: Text.PlainText
		wrapMode: Text.WordWrap
		maximumLineCount: 2
		elide: Text.ElideRight
		lineHeight: 0.8
		font.family: qfont.italic.name
		font.pixelSize: isNxt ? 20 : 16
	}
}
