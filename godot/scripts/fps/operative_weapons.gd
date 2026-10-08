class_name OperativeWeapons
extends RefCounted
## Operative loadout: hitscan Pulse Rifle [1], creeper-evaporating Null Sprayer [2] and the
## Rocket Launcher [3] (RocketLauncher) for deep pools.
## Targets are spheres (world.targets: node + oy + radius); no physics bodies needed.

var camera: Camera3D
var current := "rifle"
var cooldown := 0.0
var tank := Config.TANK_MAX
var spraying := false
var hit_marker := 0.0
var gun: Node3D
var coil: MeshInstance3D
var cone: MeshInstance3D
var launcher := RocketLauncher.new()
var advanced: AdvancedWeapons


func _init(cam: Camera3D) -> void:
	camera = cam
	gun = Node3D.new()
	_arbalest(gun)
	gun.scale = Vector3.ONE * 0.4
	gun.position = Vector3(0.18, -0.16, -0.5)
	cam.add_child(gun)
	var cm := CylinderMesh.new()
	cm.top_radius = 0.05
	cm.bottom_radius = 1.8
	cm.height = Config.SPRAYER.range * 0.8
	cone = MeshInstance3D.new()
	cone.mesh = cm
	cone.material_override = Effects.glow_mat(Color(0.62, 0.96, 1.0), 0.16)
	cone.rotation.x = -PI / 2.0
	cone.position = Vector3(0, -0.2, -Config.SPRAYER.range * 0.4 - 0.3)
	cone.visible = false
	cam.add_child(cone)
	advanced = AdvancedWeapons.new(self)


func label() -> String:
	if advanced.handles(current):
		return advanced.label()
	match current:
		"rifle": return "[%s] %s" % [Keybinds.short("rifle"), Config.RIFLE.name]
		"sprayer": return "[%s] %s" % [Keybinds.short("sprayer"), Config.SPRAYER.name]
	return "[%s] %s  %d/%d" % [Keybinds.short("rocket"), Config.ROCKET.name, launcher.loaded, launcher.mag_size()]


## Viewmodel: a wood-and-bronze rune arbalest (looks down -Z). `coil` is the rune crystal
## on top; its own material, because update() recolours it per weapon.
func _arbalest(g: Node3D) -> void:
	var M := StructureMeshes
	M.box(g, Vector3(0.07, 0.08, 0.5), M.pal("oak"), Vector3(0, 0, 0.02))
	M.box(g, Vector3(0.09, 0.07, 0.12), M.pal("bronze"), Vector3(0, 0.01, -0.02))
	M.box(g, Vector3(0.05, 0.13, 0.06), M.pal("oak"), Vector3(0, -0.09, 0.14)).rotation.x = 0.3
	for sx in [-1.0, 1.0]:
		ShapeKit.strut(g, Vector3(sx * 0.02, 0.02, -0.24), Vector3(sx * 0.15, 0.0, -0.19), 0.02, M.pal("bronze_dark"), 0.025)
		ShapeKit.rod(g, Vector3(sx * 0.15, 0.0, -0.19), Vector3(0, 0.03, -0.06), 0.003, M.pal("iron"), 4)
	ShapeKit.rod(g, Vector3(0, 0.05, -0.02), Vector3(0, 0.05, -0.34), 0.01, M.pal("oak"), 6)
	coil = M.crystal(g, 0.03, 0.14, M.mat_new(Color("3fb8f0"), 0.0, 0.3, Color("2a9fd0"), 0.9), Vector3(0, 0.08, 0.06))
	coil.rotation.x = PI / 2.0


func update(dt: float, input: InputState, world: World, feet: Vector3) -> void:
	for w in ["rifle", "sprayer", "rocket"]:
		if input.act(w):
			current = w
	advanced.update(dt, input, world, feet)
	var m := coil.material_override as StandardMaterial3D
	m.emission = { "rifle": Color("2a9fd0"), "sprayer": Color("3faa22"), "rocket": Color("ff8a1a"),
		"railgun": Color("d7f6ff"), "plasma": Color("c45bff"), "demo": Color("ff8844") }.get(current, Color("2a9fd0"))
	var cone_mat := cone.material_override as StandardMaterial3D
	cone_mat.albedo_color = Color(0.75, 0.35, 1.0, 0.28) if current == "plasma" else Color(0.62, 0.96, 1.0, 0.16)
	launcher.update(dt, world)
	cooldown -= dt
	hit_marker = maxf(0.0, hit_marker - dt)
	gun.position.z = lerpf(gun.position.z, -0.5, minf(1.0, dt * 18.0))  # recoil recovery
	if advanced.handles(current):
		spraying = false
		cone.visible = current == "plasma" and advanced.firing
		tank = minf(Config.TANK_MAX, tank + Config.TANK_REGEN * dt)
		return
	var trigger := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	spraying = current == "sprayer" and trigger and tank > 0.0
	cone.visible = spraying
	if spraying:
		_spray(dt, world, feet)
	else:
		tank = minf(Config.TANK_MAX, tank + Config.TANK_REGEN * dt)
	if current == "rifle" and trigger and cooldown <= 0.0:
		cooldown = Config.RIFLE.cooldown
		_fire(world)
	elif current == "rocket" and trigger and cooldown <= 0.0:
		cooldown = 0.6
		var d := -camera.global_transform.basis.z
		if launcher.fire(world, gun.global_position + d * 0.4, d):
			gun.position.z = -0.38  # heavy recoil
		else:
			Sfx.play("deny")


## Distance along a ray to a sphere, or INF.
static func ray_sphere(o: Vector3, d: Vector3, c: Vector3, r: float) -> float:
	var oc := o - c
	var b := oc.dot(d)
	var disc := b * b - (oc.length_squared() - r * r)
	if disc < 0.0:
		return INF
	var t := -b - sqrt(disc)
	if t > 0.0:
		return t
	return 0.001 if -b + sqrt(disc) > 0.0 else INF  # muzzle inside the target: point-blank hit


func _fire(world: World) -> void:
	var o := camera.global_position
	var d := -camera.global_transform.basis.z
	var reach: float = Config.RIFLE.range
	var best: Dictionary = {}
	var bt := reach
	for t in world.targets:
		if not t.alive.call():
			continue
		var c: Vector3 = (t.node as Node3D).global_position + Vector3(0, t.get("oy", 0.0), 0)
		var hit := ray_sphere(o, d, c, t.radius)
		if hit < bt:
			bt = hit
			best = t
	var ground = world.grid.raycast(o, d, reach)
	var gd: float = o.distance_to(ground) if ground != null else INF
	var start := gun.global_position + (-camera.global_transform.basis.z) * 0.2
	var end := o + d * reach
	if not best.is_empty() and bt < gd:
		end = o + d * bt
		best.on_hit.call(Config.RIFLE.damage * OperativeUpgrades.mult("firepower"), end)
		hit_marker = 0.15
		Sfx.play("hit")
	elif ground != null:
		end = ground
		world.effects.burst(end, Color("ffffaa"), 0.3, 0.12)
	world.effects.beam(start, end, Color("9ff6ff"), 0.06, 0.025)
	Sfx.play("rifle")
	gun.position.z = -0.45  # recoil kick


func _spray(dt: float, world: World, feet: Vector3) -> void:
	tank = maxf(0.0, tank - Config.SPRAYER.tank_per_sec * dt)
	Sfx.play("spray")
	var g := world.grid
	var fwd := -camera.global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var here := g.world_to_cell(feet.x, feet.z)
	var range_cells: float = Config.SPRAYER.range / Config.CELL
	var cos_a := cos(Config.SPRAYER.half_angle)
	for c in g.cells_in_radius(here.x, here.y, range_cells):
		var p := g.cell_center(c.x, c.y)
		var dx := p.x - feet.x
		var dz := p.z - feet.z
		var len := Vector2(dx, dz).length()
		if len < Config.CELL * 0.9 or (dx * fwd.x + dz * fwd.z) / len >= cos_a:
			var dist := Vector2(c.x - here.x, c.y - here.y).length()
			world.creeper.remove(c.x, c.y, Config.SPRAYER.remove_per_sec * dt * (1.0 - 0.5 * dist / range_cells))
