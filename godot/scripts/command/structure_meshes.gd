class_name StructureMeshes
## Procedural meshes for every structure: the shared kit (cached materials, primitives) and
## the dispatch. Armed weapons live in weapon_meshes.gd, everything else in support_meshes.gd,
## lathes/struts/arches in world/shape_kit.gd. Animated parts are named children:
## "Spin" (rotates), "Turret" (yaw, aimed by WeaponLogic), "Arm" (pitch), "Core" (nullifier
## charge), "Glow" (Totem pulse), "Muzzle" (where shots leave).
## Art direction "Arcane Forge": pale stone, bronze, dark oak, cloth, cyan rune crystals.

const METAL := Color("8a96a6")
const DARK := Color("2f3540")
const ACCENT := Color("5fd4ff")

## Named player-side materials: [albedo, metallic, roughness, emission energy].
const PALETTE := {
	"stone": [Color("a69d89"), 0.0, 0.9, 0.0],
	"stone_dark": [Color("6f675a"), 0.0, 0.92, 0.0],
	"bronze": [Color("b8843f"), 0.85, 0.38, 0.0],
	"bronze_dark": [Color("7a5428"), 0.8, 0.45, 0.0],
	"iron": [Color("5a554e"), 0.7, 0.45, 0.0],
	"oak": [Color("5b3c22"), 0.0, 0.8, 0.0],
	"cloth": [Color("1f5f86"), 0.0, 0.95, 0.0],
	"slate": [Color("3a4656"), 0.1, 0.65, 0.0],
	"rune": [Color("19b4ff"), 0.0, 0.3, 1.0],
	"rune_soft": [Color("19b4ff"), 0.0, 0.3, 0.6],
	"rune_deep": [Color("0c86d8"), 0.0, 0.25, 0.55],  # big crystals: lower energy keeps the hue
}

static var _mats := {}


## Shared material per colour/style (callers must not mutate it; use mat_new for that).
static func mat(color: Color, metal := 0.6, rough := 0.4, emit := Color.BLACK, emit_e := 0.0) -> StandardMaterial3D:
	var key := "%s|%s|%s|%s|%s" % [color.to_html(), metal, rough, emit.to_html(), emit_e]
	if not _mats.has(key):
		_mats[key] = mat_new(color, metal, rough, emit, emit_e)
	return _mats[key]


static func mat_new(color: Color, metal := 0.6, rough := 0.4, emit := Color.BLACK, emit_e := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metal
	m.roughness = rough
	if emit_e > 0.0:
		m.emission_enabled = true
		m.emission = emit
		m.emission_energy_multiplier = emit_e
	return m


## Palette material by name ("stone", "bronze", "rune", ...).
static func pal(name: String) -> StandardMaterial3D:
	var p: Array = PALETTE[name]
	return mat(p[0], p[1], p[2], p[0] if p[3] > 0.0 else Color.BLACK, p[3])


## Glowing material in any colour (crystals, eyes, embers). Energy is capped so crystals
## keep their hue under bloom instead of washing out white.
const GLOW_CAP := 1.2


static func glow(c: Color, e := 2.0) -> StandardMaterial3D:
	return mat(c, 0.0, 0.3, c, minf(e, GLOW_CAP))


static func cyl(parent: Node3D, top: float, bottom: float, h: float, m: Material, y := 0.0, sides := 16) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = sides
	c.rings = 1
	return _add(parent, c, m, Vector3(0, y + h * 0.5, 0))


static func box(parent: Node3D, size: Vector3, m: Material, at := Vector3.ZERO) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = size
	return _add(parent, b, m, at)


static func ball(parent: Node3D, r: float, m: Material, at := Vector3.ZERO, seg := 16) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = seg
	s.rings = maxi(4, seg / 2)
	return _add(parent, s, m, at)


## Faceted crystal (an octahedron stretched along Y).
static func crystal(parent: Node3D, r: float, h: float, m: Material, at := Vector3.ZERO) -> MeshInstance3D:
	return ShapeKit.lathe(parent, PackedVector2Array([Vector2(0.0, -h * 0.5), Vector2(r, 0.0), Vector2(0.0, h * 0.5)]), m, at, 6)


static func torus(parent: Node3D, inner: float, outer: float, m: Material, at := Vector3.ZERO) -> MeshInstance3D:
	var t := TorusMesh.new()
	t.inner_radius = inner
	t.outer_radius = outer
	t.rings = 24
	t.ring_segments = 8
	return _add(parent, t, m, at)


static func _add(parent: Node3D, mesh: Mesh, m: Material, at: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = at
	parent.add_child(mi)
	return mi


static func _part(parent: Node3D, part_name: String, y := 0.0) -> Node3D:
	var n := Node3D.new()
	n.name = part_name
	n.position.y = y
	parent.add_child(n)
	return n


static func make(type: String) -> Node3D:
	var root := Node3D.new()
	if not WeaponMeshes.build(type, root):
		SupportMeshes.build(type, root)
	_apply_models(root, type)
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return root


## A4 structure models (Opus): cannon/mortar/sniper/beam in 3 parts, collector and
## relay as single .glb files. The procedural tree is built first so Turret, Arm and
## Muzzle keep their transforms and WeaponLogic aims them unchanged; then, when every
## model file exists and CreatureAnim.disabled is off, the procedural MeshInstance3Ds
## are freed and the models attached (base -> root, turret -> Turret, arm -> Arm).
## Falls back to the procedural meshes if any file is missing. Never touches the
## hive, Totem, pod or Command Node (A3's files).
const MODEL_TYPES := ["cannon", "mortar", "sniper", "beam", "collector", "relay"]


static func _apply_models(root: Node3D, type: String) -> void:
	if CreatureAnim.disabled or not MODEL_TYPES.has(type):
		return
	var ids: Array = []
	if type == "collector" or type == "relay":
		ids = [type]
	else:
		ids = [type + "_base", type + "_turret", type + "_arm"]
	for mid in ids:
		if not ResourceLoader.exists(CreatureAnim.MODEL_DIR + mid + ".glb"):
			return  # any part missing: keep the procedural build
	# free() (not queue_free()): the root is detached during make(), and WeaponFx
	# caches MeshInstance3D refs per frame — a deferred free would leave it
	# holding freed meshes.
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).free()
	var glow := _model_glow(type)
	var parts: Array = []
	if ids.size() == 3:
		var base := CreatureAnim.make(ids[0], 1.0, glow)
		var turret := CreatureAnim.make(ids[1], 1.0, glow)
		var arm := CreatureAnim.make(ids[2], 1.0, glow)
		var tur := root.get_node_or_null("Turret")
		var arm_n := tur.get_node_or_null("Arm") if tur != null else null
		if base == null or turret == null or arm == null or tur == null or arm_n == null:
			for n in [base, turret, arm]:
				if n != null:
					n.free()
			return
		root.add_child(base)
		tur.add_child(turret)
		arm_n.add_child(arm)
		parts = [base, turret, arm]
	else:
		var m := CreatureAnim.make(ids[0], 1.0, glow)
		if m == null:
			return
		root.add_child(m)
		parts = [m]
	root.set_meta("_anim_parts", parts)


## Fixed glow per structure (matches the procedural crystals; never tier-swapped).
static func _model_glow(type: String) -> Material:
	if type == "collector":
		return glow(Color("5dff8a"), 1.0)
	return glow(Color("19b4ff"), 1.0)


## Animated-model parts on a structure body, [] on a procedural build.
static func model_parts(s: Structure) -> Array:
	if s == null or s.body == null or not is_instance_valid(s.body):
		return []
	return s.body.get_meta("_anim_parts", [])


static func _part_player(n: Node3D) -> AnimationPlayer:
	if n == null or not n.has_meta("_anim_player"):
		return null
	var p := n.get_meta("_anim_player") as AnimationPlayer
	return p if p != null and is_instance_valid(p) else null


## Weapon fired: `attack` on the arm, rate-limited to the clip length so fast
## weapons restart the swing instead of stacking it. No-op on procedural builds.
static func model_fire(s: Structure) -> void:
	var parts := model_parts(s)
	if parts.size() != 3:
		return
	var arm: Node3D = parts[2]
	var p := _part_player(arm)
	if p == null or not p.has_animation("attack"):
		return
	var now := Time.get_ticks_msec() / 1000.0
	var last: float = float(arm.get_meta("_anim_last_attack", -100.0))
	var len: float = (p.get_animation("attack") as Animation).length
	if now - last < len:
		return
	p.speed_scale = 1.0
	p.play("attack")
	arm.set_meta("_anim_state", CreatureAnim.ST_ATTACK)
	arm.set_meta("_anim_last_attack", now)


## Structure damaged: `hit` on all parts, at most once every 0.3 s.
static func model_hit(s: Structure) -> void:
	var parts := model_parts(s)
	if parts.is_empty():
		return
	var body: Node3D = s.body
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(body.get_meta("_anim_last_hit", -100.0)) < 0.3:
		return
	body.set_meta("_anim_last_hit", now)
	for part in parts:
		CreatureAnim.hit(part)


## Structure destroyed: `die` on all parts, `then` runs when the base clip ends
## (CreatureAnim.die caps the wait at DIE_MAX; fires at once with no model).
static func model_die(s: Structure, then: Callable) -> void:
	var parts := model_parts(s)
	if parts.is_empty():
		then.call()
		return
	for i in range(1, parts.size()):
		var p := _part_player(parts[i])
		if p != null and p.has_animation("die"):
			p.speed_scale = 1.0
			p.play("die")
			(parts[i] as Node3D).set_meta("_anim_state", CreatureAnim.ST_DIE)
	CreatureAnim.die(parts[0], then)


## Relay packet pass-through: `attack`, at most once every 0.5 s.
static func model_packet(s: Structure) -> void:
	var parts := model_parts(s)
	if parts.is_empty():
		return
	var body: Node3D = s.body
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(body.get_meta("_anim_last_packet", -100.0)) < 0.5:
		return
	body.set_meta("_anim_last_packet", now)
	CreatureAnim.attack(parts[0])


## Height of the model's top (metres above its cell), for the HP/ammo bars.
static func top_y(type: String) -> float:
	return { "node": 11.5, "collector": 2.6, "relay": 3.7, "outpost": 5.6, "keep": 5.6, "reactor": 3.0, "storage": 2.6,
		"barracks": 5.0, "nullifier": 4.4, "cannon": 4.0, "mortar": 4.1, "beam": 5.4, "sniper": 4.2,
		"bertha": 8.6, "thor": 5.0, "forge": 8.6, "terp": 7.4, "beacon": 5.4, "miner": 2.4,
		"trebuchet": 4.2 }.get(type, 3.0)


## Translucent copy used as the placement / move ghost.
static func ghost(type: String, ok: bool) -> Node3D:
	var g := make(type)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.45, 1.0, 0.8, 0.7) if ok else Color(1.0, 0.35, 0.35, 0.7)
	for mi in g.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = m
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return g
