class_name ReloadTimeline
extends RefCounted
## FB-R: plays a ReloadAnims plan over the logic's reload time. Moves the gun's `Mag` node (ReloadMag) and its
## charging bone, and exposes the gun pose offset (TacticalViewmodel) and the left-hand target (FpArms).
## Gun-model space throughout; K maps the Skeleton3D's space into it.

signal mark(name: String)  # phase marks (mag_out, mag_hide, mag_show, mag_in, charged): sound hooks

var mag: MeshInstance3D
var skel: Skeleton3D
var bone := -1
var _rig := {}
var _def := {}
var _k := Transform3D.IDENTITY
var _bone_rest := Transform3D.IDENTITY
var _phases: Array = []  # [{t0, t1, from: pose, to: pose, ease, mark}]
var t := 0.0
var len := 0.0
var _next := 0
# sampled pose (valid while playing)
var gun_pos := Vector3.ZERO
var gun_rot := Vector3.ZERO
var mag_xf := Transform3D.IDENTITY
var hand_l := Vector3.ZERO
var bolt := 0.0


## Null unless the gun has a ReloadAnims rig and a magazine that could be split out.
static func make(glb: Node, def: Dictionary) -> ReloadTimeline:
	var r := ReloadAnims.rig(def)
	if r.is_empty() or def["action"] != "detachable":
		return null
	var m := ReloadMag.split(glb)
	if m == null:
		return null
	var tl := ReloadTimeline.new()
	tl.mag = m
	tl.skel = m.get_parent() as Skeleton3D
	tl._rig = r
	tl._def = def
	tl.bone = tl.skel.find_bone(str(r.get("bone", "")))
	var k := Transform3D.IDENTITY  # skeleton -> glb root (the gun-model node's child), then the flip
	var n: Node = tl.skel
	while n != glb:
		k = (n as Node3D).transform * k
		n = n.get_parent()
	tl._k = glb.transform * k
	return tl


func playing() -> bool:
	return t < len


## secs: the logic's busy time (includes CHAMBER_TIME when empty). empty: chamber was empty at the start.
func start(secs: float, empty: bool, fast: bool) -> void:
	var plan: Dictionary = ReloadAnims.PLANS[_rig["plan"]]
	var extra := TacticalConfig.CHAMBER_TIME if empty else 0.0
	var base := maxf(secs - extra, 0.05)
	var list: Array = (plan["fast"] if fast else plan["plain"]).duplicate()
	var steps := []
	for i in list.size():
		if empty and i == list.size() - 1:
			for p in plan["charge"]:
				steps.append([p, float(p["w"]) * extra])
		steps.append([list[i], float(list[i]["w"]) * base])
	_phases.clear()
	var pose := {"gp": Vector3.ZERO, "gr": Vector3.ZERO, "mag": "seat", "hl": "grip", "bolt": 0.0}
	var at := 0.0
	for s in steps:
		var to := pose.duplicate()
		for key in pose:
			if s[0].has(key):
				to[key] = s[0][key]
		_phases.append({"t0": at, "t1": at + float(s[1]), "from": pose, "to": to, "ease": s[0].get("ease", "io"), "mark": s[0].get("mark", "")})
		at += float(s[1])
		pose = to
	len = at
	t = 0.0
	_next = 0
	if bone >= 0:
		_bone_rest = skel.get_bone_global_pose(bone)
	_sample()


## Jump to the end (logic finished or cancelled): everything back in place.
func stop() -> void:
	if t < len:
		t = len
		_sample()


func update(delta: float) -> void:
	if not playing():
		return
	t = minf(t + delta, len)
	_sample()


func _sample() -> void:
	var i := 0
	while i < _phases.size() - 1 and t >= float(_phases[i]["t1"]):
		i += 1
	while _next < _phases.size() and t >= float(_phases[_next]["t1"]):
		if str(_phases[_next]["mark"]) != "":
			mark.emit(_phases[_next]["mark"])
		_next += 1
	var ph: Dictionary = _phases[i] if not _phases.is_empty() else {}
	if ph.is_empty() or not playing():
		_put_rest()
		return
	var u := clampf((t - float(ph["t0"])) / maxf(float(ph["t1"]) - float(ph["t0"]), 0.0001), 0.0, 1.0)
	match ph["ease"]:
		"in": u = u * u
		"out": u = 1.0 - (1.0 - u) * (1.0 - u)
		_: u = smoothstep(0.0, 1.0, u)
	var a: Dictionary = ph["from"]
	var b: Dictionary = ph["to"]
	gun_pos = (a["gp"] as Vector3).lerp(b["gp"], u)
	gun_rot = (a["gr"] as Vector3).lerp(b["gr"], u)
	bolt = lerpf(a["bolt"], b["bolt"], u)
	var m0 := _mag_off(a["mag"])
	var m1 := _mag_off(b["mag"])
	var pv: Vector3 = _rig["pivot"]
	var q := Quaternion.from_euler(m0[1]).slerp(Quaternion.from_euler(m1[1]), u)
	mag_xf = Transform3D(Basis(q), pv + (m0[0] as Vector3).lerp(m1[0], u)) * Transform3D(Basis.IDENTITY, -pv)
	hand_l = _anchor(a["hl"]).lerp(_anchor(b["hl"]), u)
	_apply()


func _put_rest() -> void:
	gun_pos = Vector3.ZERO
	gun_rot = Vector3.ZERO
	bolt = 0.0
	mag_xf = Transform3D.IDENTITY
	hand_l = _def["grip_l"]
	_apply()


func _mag_off(state: String) -> Array:
	return [Vector3.ZERO, Vector3.ZERO] if state == "seat" else _rig[state]


func _anchor(name: String) -> Vector3:
	match name:
		"mag": return mag_xf * (_rig["hold"] as Vector3)
		"pouch": return _rig["pouch_hand"]
		"charge": return (_rig["charge"] as Vector3) + (_rig["travel"] as Vector3) * bolt
	return _def["grip_l"]


## Gun-model offsets onto the Mag node and the charging bone (both in skeleton space).
func _apply() -> void:
	mag.transform = _k.affine_inverse() * mag_xf * _k
	if bone >= 0:
		var tb := Transform3D(Basis.IDENTITY, (_rig["travel"] as Vector3) * bolt)
		skel.set_bone_global_pose(bone, _k.affine_inverse() * tb * _k * _bone_rest)
