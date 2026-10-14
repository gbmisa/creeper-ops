class_name RangeTruck
extends Node3D
## Deploy truck beside the spawn: F saves the current kit and loads the Skirmish map.

const POS := Vector3(-6.4, 0.0, 3.0)
const REACH := 3.5

var weapons: PlayerWeapons
var player: TacticalPlayer


func setup(w: PlayerWeapons, p: TacticalPlayer) -> void:
	weapons = w
	player = p
	name = "DeployTruck"
	var green := Color(0.28, 0.34, 0.26)
	var b := func(nm: String, pos: Vector3, size: Vector3, col: Color):
		RangeLayout.box(self, nm, POS + pos, size, "sheet_metal", 0.05, col)
	b.call("bed", Vector3(0, 1.0, 1.0), Vector3(2.4, 1.2, 4.0), green)
	b.call("cab", Vector3(0, 1.3, -1.8), Vector3(2.4, 1.8, 1.6), green.lightened(0.1))
	b.call("glass", Vector3(0, 1.7, -2.62), Vector3(2.0, 0.7, 0.05), Color(0.1, 0.15, 0.2))
	for sx in [-1.0, 1.0]:
		for z in [-1.6, 2.0]:
			var wh := MeshInstance3D.new()
			var m := CylinderMesh.new()
			m.top_radius = 0.45
			m.bottom_radius = 0.45
			m.height = 0.4
			wh.mesh = m
			wh.material_override = RangeLayout.colour(Color(0.08, 0.08, 0.08))
			wh.rotation_degrees.z = 90.0
			wh.position = POS + Vector3(sx * 1.2, 0.45, z)
			add_child(wh)
	var l := Label3D.new()
	l.text = "DEPLOY"
	l.pixel_size = 0.005
	l.font_size = 64
	l.outline_size = 10
	l.rotation_degrees.y = 90.0
	l.position = POS + Vector3(1.25, 1.3, 1.0)
	l.modulate = Color(0.85, 1.0, 0.8)
	add_child(l)


func _process(_dt: float) -> void:
	if player == null or not player.enabled:
		return
	var to := POS - player.global_position
	to.y = 0.0
	if to.length() < REACH:
		weapons.prompt = "%s: Deploy to Skirmish with this kit" % Keybinds.short("t_use")
		if player.input.act("t_use"):
			RangeLoadout.deploy(weapons.inv)
