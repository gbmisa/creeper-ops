class_name MaterialDefs
## World materials. resist is compared with bullet pen (scaled by thickness). INF never passes.

const ROWS := {
	"wood_plank": {"resist": 12.0, "ric_angle": 0.0, "ric_chance": 0.0, "color": Color(0.55, 0.38, 0.2), "sound": "thud"},
	"plywood": {"resist": 6.0, "ric_angle": 0.0, "ric_chance": 0.0, "color": Color(0.7, 0.55, 0.32), "sound": "thud"},
	"sheet_metal": {"resist": 28.0, "ric_angle": 20.0, "ric_chance": 0.5, "color": Color(0.5, 0.52, 0.55), "sound": "ping"},
	"brick": {"resist": 48.0, "ric_angle": 0.0, "ric_chance": 0.0, "color": Color(0.55, 0.25, 0.2), "sound": "crack"},
	"concrete": {"resist": 70.0, "ric_angle": 0.0, "ric_chance": 0.0, "color": Color(0.6, 0.6, 0.58), "sound": "crack"},
	"steel_target": {"resist": INF, "ric_angle": 25.0, "ric_chance": 0.6, "color": Color(0.25, 0.27, 0.3), "sound": "ring"},
	"dirt_berm": {"resist": INF, "ric_angle": 0.0, "ric_chance": 0.0, "color": Color(0.3, 0.22, 0.14), "sound": "thud"},
}


static func of(id: String) -> Dictionary:
	return ROWS.get(id, ROWS["dirt_berm"])
