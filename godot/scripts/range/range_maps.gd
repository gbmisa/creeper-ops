class_name RangeMaps
## Which map the firing_range scene builds: "range" (default) or "skirmish". All map switches go through `go()`.

const SCENE := "res://scenes/firing_range.tscn"

static var selected := "range"


static func go(map: String) -> void:
	selected = map
	Engine.get_main_loop().call_deferred("change_scene_to_file", SCENE)
