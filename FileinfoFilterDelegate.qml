import QtQuick 2.1
import BasicUIControls 1.0;

Rectangle
{
	width: 106
	height: 60
	color: colors.canvas
	property string kpiPrefix: "fileinfoFilterScreen."
	property ControlGroup targetControlGroup

	StyledButton {
		id: filterButton

		controlGroup: targetControlGroup

		text: roadName
		fontPixelSize: isNxt ? 19 : 15
		radius: 8
		overlayColor: fontColor
		height: isNxt ? 55 : 44
		width: isNxt ? 97 : 78

		leftClickMargin: 14
		rightClickMargin: 14
		topClickMargin: 8
		bottomClickMargin: 8

		selected: false
		state: selected ? "selected" : "up"

		selectionTrigger: "OnPress"
		unselectionTrigger: "OnPress"

		states: [
			State {
				name: "up"
				PropertyChanges { target: filterButton; color: colors.btnUp}
				PropertyChanges { target: filterButton; shadowPixelSize: 1}
				PropertyChanges { target: filterButton; fontFamily: qfont.regular.name}
				PropertyChanges { target: filterButton; fontColor: colors.btnText}
				PropertyChanges { target: filterButton; useOverlayColor: false}
			},
			State {
				name: "selected"
				PropertyChanges { target: filterButton; color: colors.btnSelected}
				PropertyChanges { target: filterButton; shadowPixelSize: 0}
				PropertyChanges { target: filterButton; fontFamily: qfont.semiBold.name}
				PropertyChanges { target: filterButton; fontColor: colors.btnTextSelected}
				PropertyChanges { target: filterButton; useOverlayColor: true}
			}
		]
	}
}


