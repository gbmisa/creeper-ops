class_name RangeMaps
## Which map the firing_range scene builds: "range" (default) or "skirmish". Per-session instance
## (MULTIPLAYER.md rule 1); all map switches go through `go()` so a server can broadcast them
## (rule 6). `pending` is the bootstrap: menus outside any session set it, FiringRange consumes
## it once at load into the session's `selected`. It is navigation state, not per-player state.

const SCENE := "res://scenes/firing_range.tscn"

static var pending := "range"

## Kit carried across scene reloads (deploy / restart / back-to-range). Written by
## RangeSession.save_kit, cleared by clear_kit (KIA); FiringRange restores it into the
## fresh session. Same bootstrap category as `pending`, not per-player state.
static var carried_kit := {}

var selected := "range"


## From outside a session (main menus): queue the map, then load the scene.
static func go(map: String) -> void:
	pending = map
	Engine.get_main_loop().call_deferred("change_scene_to_file", SCENE)


## In-session map change (MP-2: the server broadcasts this instead).
func change(map: String) -> void:
	selected = map
	go(map)
