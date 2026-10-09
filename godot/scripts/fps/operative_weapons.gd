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
var debug_trigger := false  # --fire: hold the trigger for a screenshot
var hit_marker := 0.0
var climb := 0.0          # sustained vertical camera climb (rad): accumulates per shot while held, eases back on release
var climb_yaw := 0.0      # sustained random yaw drift (rad): same lifecycle as climb
var feel := HitFeel.new()
var motion: ViewmodelMotion
var xbow: CrossbowFx
var crossbow := Crossbow.new()
var _coil_flare := 0.0
var spray_fx: SprayFx
var muzzle: MuzzleFlash
var gun: Node3D
var coil: MeshInstance3D
var cone: MeshInstance3D
var launcher := RocketLauncher.new()
var advanced: AdvancedWeapons
var rifle: RifleFire  # the Pulse Rifle's shot (firing + bloom); built in _init like advanced
var models := {}


func _init(cam: Camera3D) -> void:
	camera = cam
	gun = Node3D.new()
	for id in ["rifle", "sprayer", "rocket", "crossbow"]:
		var n := Node3D.new()
		n.name = id
		models[id] = n
		gun.add_child(n)
	coil = RifleModel.build(models["rifle"])
	var xcoil := WeaponModels.crossbow(models["crossbow"])
	WeaponModels.sprayer(models["sprayer"])
	WeaponModels.launcher(models["rocket"])
	for id in ["rifle", "sprayer", "rocket", "crossbow"]:
		ArmModels.add(models[id], id)
	xbow = CrossbowFx.new(models["crossbow"], xcoil)
	crossbow.report = confirm
	spray_fx = SprayFx.new(models["sprayer"])
	muzzle = MuzzleFlash.new(gun, Vector3(0, 0.03, -0.45))
	feel.camera = cam
	launcher.report = confirm
	_show_model()
	gun.scale = Vector3.ONE * 0.4
	gun.position = ViewmodelMotion.BASE
	motion = ViewmodelMotion.new(gun)
	cam.add_child(gun)
	var cm := CylinderMesh.new()  # +Y of the mesh points down -Z: narrow at the nozzle, wide at the reach
	cm.top_radius = tan(deg_to_rad(SprayFx.SPREAD_DEG)) * Config.SPRAYER.range * 0.8
	cm.bottom_radius = 0.03
	cm.height = Config.SPRAYER.range * 0.8
	cone = MeshInstance3D.new()
	cone.mesh = cm
	cm.cap_top = false
	cm.cap_bottom = false
	cone.material_override = Effects.glow_mat(Color(0.62, 0.96, 1.0), 0.09)
	(cone.material_override as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	cone.rotation.x = -PI / 2.0
	cone.position = Vector3(0.19, -0.14, -Config.SPRAYER.range * 0.4 - 0.66)
	cone.visible = false
	cam.add_child(cone)
	advanced = AdvancedWeapons.new(self)
	rifle = RifleFire.new(self)


func label() -> String:
	if advanced.handles(current):
		return advanced.label()
	match current:
		"rifle": return "[%s] %s%s" % [Keybinds.short("rifle"), Config.RIFLE.name, AmmoGrades.op_tag("rifle")]
		"sprayer": return "[%s] %s" % [Keybinds.short("sprayer"), Config.SPRAYER.name]
		"crossbow":
			var p := crossbow.reload_progress()
			return "[%s] %s  %s" % [Keybinds.short("crossbow"), Config.CROSSBOW.name, "ready" if p < 0.0 else "reloading %d%%" % roundi(p * 100.0)]
	return "[%s] %s  %d/%d" % [Keybinds.short("rocket"), Config.ROCKET.name + AmmoGrades.op_tag("rocket"), launcher.loaded, launcher.mag_size()]


## Armoury weapons (railgun, plasma, demo) have no model of their own yet: they show the Pulse Rifle.
func _show_model() -> void:
	var shown: String = current if models.has(current) else "rifle"
	for id in models:
		(models[id] as Node3D).visible = id == shown


func update(dt: float, input: InputState, world: World, feet: Vector3) -> void:
	for w in ["rifle", "sprayer", "rocket", "crossbow"]:
		if input.act(w):
			current = w
	advanced.update(dt, input, world, feet)
	_show_model()
	var held := debug_trigger or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or advanced.firing
	if not held:  # sustained climb eases back after release; tap-fire never accumulates
		var rec := Config.CLIMB_RECOVER * dt
		climb = move_toward(climb, 0.0, rec)
		climb_yaw = move_toward(climb_yaw, 0.0, rec)
	if input.act("ammo_next") and not advanced.handles(current):
		AmmoGrades.cycle_op(current, 1)
	if input.act("ammo_prev") and not advanced.handles(current):
		AmmoGrades.cycle_op(current, -1)
	var m := coil.material_override as StandardMaterial3D
	m.emission = { "rifle": Color("2a9fd0"), "sprayer": Color("3faa22"), "rocket": Color("ff8a1a"),
		"railgun": Color("d7f6ff"), "plasma": Color("c45bff"), "demo": Color("ff8844") }.get(current, Color("2a9fd0"))
	var cone_mat := cone.material_override as StandardMaterial3D
	cone_mat.albedo_color = Color(0.75, 0.35, 1.0, 0.28) if current == "plasma" else Color(0.62, 0.96, 1.0, 0.09)
	launcher.update(dt, world)
	cooldown -= dt
	hit_marker = maxf(0.0, hit_marker - dt)
	feel.update(dt)
	xbow.update(dt)
	crossbow.update(dt)
	xbow.set_reload(crossbow.reload_progress())
	_coil_flare = maxf(0.0, _coil_flare - dt * 9.0)
	m.emission_energy_multiplier = 0.9 + 4.0 * _coil_flare
	muzzle.update(dt)
	if advanced.handles(current):
		spraying = false
		cone.visible = current == "plasma" and advanced.firing
		spray_fx.set_active(false)
		tank = minf(Config.TANK_MAX, tank + Config.TANK_REGEN * dt)
		return
	var trigger := debug_trigger or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	spraying = current == "sprayer" and trigger and tank > 0.0
	cone.visible = spraying
	spray_fx.set_active(spraying)
	if spraying:
		_spray(dt, world, feet)
	else:
		tank = minf(Config.TANK_MAX, tank + Config.TANK_REGEN * dt)
	if current == "rifle" and trigger and cooldown <= 0.0:
		cooldown = Config.RIFLE.cooldown
		rifle.fire(world)
	elif current == "crossbow" and trigger and cooldown <= 0.0:
		var d := -camera.global_transform.basis.z
		if crossbow.fire(world, gun.global_position + d * 0.6, d):
			xbow.shoot()
			kick("crossbow")
			Sfx.play("crossbow")
			Sfx.play("crossbow_clack")
		else:
			Sfx.play("deny")
	elif current == "rocket" and trigger and cooldown <= 0.0:
		cooldown = 0.6
		var d := -camera.global_transform.basis.z
		if launcher.fire(world, gun.global_position + d * 0.4, d, AmmoGrades.op_rocket(advanced.stockpile)):
			kick("rocket")  # heavy recoil
			muzzle.flash(Color("ffb347"), 0.26, 0.12, 5.0)
			Sfx.play("launch")
			Sfx.play("launch_rumble")
		else:
			Sfx.play("deny")
	rifle.recover(dt, current == "rifle" and trigger)  # bloom grows per shot in fire(); recovers on release


## Recoil for any weapon, driven by RecoilDefs (feel only; damage/rate/range untouched).
## Wires RecoilDefs.cam into the camera punch (rifle cam=1.0 keeps today's feel) and
## accumulates the sustained hold-to-fire climb (scaled by cam, capped by climb_max).
func kick(id: String) -> void:
	var r: Dictionary = RecoilDefs.of(id)
	motion.kick(r.kick, r.yaw)
	motion.cam_scale = float(r.cam)
	var inc: float = float(r.climb) * float(r.cam)
	if inc > 0.0:
		climb = minf(climb + inc, float(r.climb_max))
		var yw := inc * 0.35
		var cap := float(r.climb_max) * 0.5
		climb_yaw = clampf(climb_yaw + randf_range(-yw, yw), -cap, cap)


## An enemy was hit by something the Operative fired. Marker + tick, or red cross + crunch.
func confirm(killed: bool) -> void:
	hit_marker = Config.HIT_MARKER_TIME
	feel.confirm(killed)


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
	var steamed: Array[Vector2i] = []
	for c in g.cells_in_radius(here.x, here.y, range_cells):
		var p := g.cell_center(c.x, c.y)
		var dx := p.x - feet.x
		var dz := p.z - feet.z
		var len := Vector2(dx, dz).length()
		if len < Config.CELL * 0.9 or (dx * fwd.x + dz * fwd.z) / len >= cos_a:
			var dist := Vector2(c.x - here.x, c.y - here.y).length()
			if world.creeper.remove(c.x, c.y, Config.SPRAYER.remove_per_sec * dt * (1.0 - 0.5 * dist / range_cells)) > 0.0:
				steamed.append(c)
	spray_fx.fizz(world, steamed, dt)
