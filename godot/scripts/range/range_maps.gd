class_name RangeMaps
## Which map the firing_range scene builds: "range" (default) or "skirmish". Per-session instance
## (MULTIPLAYER.md rule 1); all map switches go through `go()` so a server can broadcast them
## (rule 6). `pending` is the bootstrap: menus outside any session set it, FiringRange consumes
## it once at load into the session's `selected`. It is navigation state, not per-player state.

const SCENE := "res://scenes/firing_range.tscn"

## Maps where the player's reloads never run dry (so reload animations can be watched).
const INFINITE_AMMO := ["range"]

static var pending := "range"

var selected := "range"


## From outside a session (main menus): queue the map, then load the scene.
static func go(map: String) -> void:
	queue(map)
	Engine.get_main_loop().call_deferred("change_scene_to_file", SCENE)


## In-session map change (MP-2: the server broadcasts this instead).
func change(map: String) -> void:
	selected = map
	go(map)


## Sets the next map and lifts the pause (F80: the pause menu's buttons switch maps with the tree
## paused; the new scene inherited paused = true and every node in it stayed frozen for good).
static func queue(map: String) -> void:
	pending = map
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		tree.paused = false
