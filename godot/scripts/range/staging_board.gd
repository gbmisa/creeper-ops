class_name StagingBoard
extends Node3D
## F139: the deploy board on the north wall. F deploys with the current kit to the chosen map; L switches the map
## (Skirmish / Skirmish (large) / Town). Deploying is RangeSession.deploy, the same kit-persist path the truck used.

const POS := Vector3(4.0, 0.0, StagingRoom.Z_NORTH + 0.1)
const REACH := 3.0
const MAPS := ["skirmish", "skirmish_large", "town"]
const NAMES := {"skirmish": "SKIRMISH", "skirmish_large": "SKIRMISH (LARGE)", "town": "TOWN"}

## Map id the player picked (the title / truck preselect it through RangeMaps.staging_target).
var target := "skirmish"
## Called with the map id on deploy; the scene points it at the session. Tests replace it.
var launcher: Callable
var weapons: PlayerWeapons
var player: TacticalPlayer
var _lbl: Label3D


func setup(w: PlayerWeapons, p: TacticalPlayer, launch: Callable) -> void:
	weapons = w
	player = p
	launcher = launch
	target = RangeMaps.staging_target if RangeMaps.staging_target in MAPS else "skirmish"
	name = "DeployBoard"
	RangeLayout.box(self, "board", POS + Vector3(0, 1.6, 0.05), Vector3(3.2, 1.6, 0.1), "plywood", 0.1, Color(0.16, 0.2, 0.15))
	for sx in [-1.5, 1.5]:
		RangeLayout.box(self, "board_post", POS + Vector3(sx, 0.9, 0.1), Vector3(0.1, 1.8, 0.1), "plywood", 0.1, Color(0.3, 0.22, 0.13))
	_lbl = Label3D.new()
	_lbl.font_size = 48
	_lbl.pixel_size = 0.0042
	_lbl.outline_size = 8
	_lbl.modulate = Color(0.85, 1.0, 0.8)
	_lbl.position = POS + Vector3(0, 1.6, 0.12)
	add_child(_lbl)
	_refresh()


func _refresh() -> void:
	var rows := PackedStringArray()
	for m in MAPS:
		rows.append("%s %s" % [">" if target == m else " ", NAMES[m]])
	_lbl.text = "DEPLOY\n\n" + "\n".join(rows)


func cycle() -> void:
	target = MAPS[(MAPS.find(target) + 1) % MAPS.size()]
	_refresh()


func deploy() -> void:
	launcher.call(target)


func _process(_dt: float) -> void:
	if player == null or not player.enabled:
		return
	var to := POS - player.global_position
	to.y = 0.0
	if to.length() > REACH:
		return
	weapons.prompt = "%s: Deploy to %s with this kit   %s: switch map" % [Keybinds.short("t_use"), NAMES[target], Keybinds.short("t_deploy_large")]
	if player.input.act("t_use"):
		deploy()
	elif player.input.act("t_deploy_large"):
		cycle()
