class_name ReloadTimeline
extends RefCounted
## FB-R: plays a ReloadAnims plan over the logic's reload time. Moves the gun's `Mag` node (ReloadMag) and its
## charging bone, and exposes the gun pose offset (TacticalViewmodel) and the left-hand target (FpArms).
## Gun-model space throughout; K maps the Skeleton3D's space into it.

signal mark(name: String)  # phase marks (mag_out, mag_hide, mag_show, mag_in, charged): sound hooks

var mag: MeshInstance3D
var skel: Skeleton3D
var bone := -1
var part: MeshInstance3D  # region-cut slide / bolt (static meshes), null if the rig has a bone or none
var _part_base := Transform3D.IDENTITY
var _part_k := Transform3D.IDENTITY
var _rig := {}
var _def := {}
var _k := Transform3D.IDENTITY
var _bone_rest := Transform3D.IDENTITY
var _base := Transform3D.IDENTITY  # the Mag node seated (ReloadMag)
var _phases: Array = []  # [{t0, t1, from: pose, to: pose, ease, mark}]
var t := 0.0
var len := 0.0
var _next := 0
var _lock := 0.0  # empty reload: the bolt/slide eases from home to `empty_bolt` over this long (plan "empty_lock")
# sampled pose (valid while playing)
var gun_pos := Vector3.ZERO
var gun_rot := Vector3.ZERO
var mag_xf := Transform3D.IDENTITY
var hand_l := Vector3.ZERO  # left wrist target
var hand_f := Vector3(0, 0, -1)  # left fingers / palm-facing directions (FpArms.solve)
var hand_n := Vector3(0, 1, 0)
var bolt := 0.0


## Null unless the gun has a ReloadAnims rig and a magazine that could be split out.
static func make(glb: Node, def: Dictionary) -> ReloadTimeline:
	var r := ReloadAnims.rig(def)
	if r.is_empty() or def["action"] != "detachable":
		return null
	var m := ReloadMag.split(glb, r)
	if m == null:
		return null
	var tl := ReloadTimeline.new()
	tl.mag = m
	tl.skel = m.get_parent() as Skeleton3D  # null for a static mesh cut by region
	tl._base = m.transform
	tl._rig = r
	tl._def = def
	if tl.skel != null:
		tl.bone = tl.skel.find_bone(str(r.get("bone", "")))
	tl._k = ReloadMag.to_gun(m.get_parent(), glb)
	if r.has("bolt_box"):  # static mesh: the slide / bolt is cut out by region and moved as a node
		tl.part = ReloadMag.cut_box(glb, r["bolt_box"], "Slide")
		if tl.part != null:
			tl._part_base = tl.part.transform
			tl._part_k = ReloadMag.to_gun(tl.part.get_parent(), glb)
	return tl


func playing() -> bool:
	return t < len


## Name of the phase at the current time ("" when not playing): labels for frame sheets.
func phase() -> String:
	for ph in _phases:
		if t < float(ph["t1"]):
			return ph["n"]
	return ""


## secs: the logic's busy time (includes CHAMBER_TIME when empty). empty: chamber was empty at the start.
func start(secs: float, empty: bool, fast: bool) -> void:
	var plan: Dictionary = ReloadAnims.PLANS[_rig["plan"]]
	var extra := TacticalConfig.CHAMBER_TIME if empty else 0.0
	var base := maxf(secs - extra, 0.05)
	var list: Array = []
	var charge_t := extra
	var takes: Dictionary = plan.get("charge_takes", {}) if empty else {}
	for p in (plan["fast"] if fast else plan["plain"]):  # "charge_takes": shares of base phases given to the charge
		var share := float(takes.get(p["n"], 0.0))
		charge_t += share * float(p["w"]) * base
		if share < 1.0:
			list.append(p.merged({"w": float(p["w"]) * (1.0 - share)}, true))
	var steps := []
	if empty:
		for p in plan.get("charge_pre", []):  # charge before the mag change (HK: lock the handle back first)
			steps.append([p, float(p["w"]) * charge_t])
	for i in list.size():
		if empty and i == list.size() - 1:
			for p in plan.get("charge", []):
				steps.append([p, float(p["w"]) * charge_t])
		steps.append([list[i], float(list[i]["w"]) * base])
	_phases.clear()
	var pose := {"gp": Vector3.ZERO, "gr": Vector3.ZERO, "mag": "seat", "hl": "grip", "bolt": float(plan.get("empty_bolt", 0.0)) if empty else 0.0}
	var at := 0.0
	var shift: Array = _rig.get("pose_shift", [Vector3.ZERO, Vector3.ZERO])
	for s in steps:
		var to := pose.duplicate()
		for key in pose:
			if s[0].has(key):
				to[key] = s[0][key]
		for k in 2:  # rig pose_shift moves every reload pose of the plan, never the rest pose
			var key: String = ["gp", "gr"][k]
			if s[0].has(key) and s[0][key] != Vector3.ZERO:
				to[key] = (s[0][key] as Vector3) + (shift[k] as Vector3)
		_phases.append({"n": s[0]["n"], "t0": at, "t1": at + float(s[1]), "from": pose, "to": to, "ease": s[0].get("ease", "io"), "mark": s[0].get("mark", "")})
		at += float(s[1])
		pose = to
	len = at
	_lock = float(plan.get("empty_lock", 0.0)) if empty else 0.0
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
	if t < _lock:
		bolt *= smoothstep(0.0, 1.0, t / _lock)
	var m0 := _mag_off(a["mag"])
	var m1 := _mag_off(b["mag"])
	var pv: Vector3 = _rig["pivot"]
	var q := Quaternion.from_euler(m0[1]).slerp(Quaternion.from_euler(m1[1]), u)
	mag_xf = Transform3D(Basis(q), pv + (m0[0] as Vector3).lerp(m1[0], u)) * Transform3D(Basis.IDENTITY, -pv)
	var h0 := _anchor(a["hl"])
	var h1 := _anchor(b["hl"])
	hand_l = (h0[0] as Vector3).lerp(h1[0], u)
	hand_f = (h0[1] as Vector3).lerp(h1[1], u).normalized()
	hand_n = (h0[2] as Vector3).lerp(h1[2], u).normalized()
	_apply()


func _put_rest() -> void:
	gun_pos = Vector3.ZERO
	gun_rot = Vector3.ZERO
	bolt = 0.0
	mag_xf = Transform3D.IDENTITY
	var h := _anchor("grip")
	hand_l = h[0]
	hand_f = h[1]
	hand_n = h[2]
	_apply()


func _mag_off(state: String) -> Array:
	return [Vector3.ZERO, Vector3.ZERO] if state == "seat" else _rig[state]


## [wrist target, finger dir, palm dir] for a left-hand anchor (gun-model space).
func _anchor(name: String) -> Array:
	var p: Vector3
	match name:
		"mag": p = mag_xf * (_rig["hold"] as Vector3)
		"charge": p = (_rig["charge"] as Vector3) + (_rig["travel"] as Vector3) * bolt
		"grip":
			var pistol: bool = _def["class"] == "pistol"
			return [_def["grip_l"], Vector3(0, 0, -1), Vector3(1, 0, 0) if pistol else Vector3(0, 1, 0)]
		_: p = _rig[name + "_hand"]  # pouch, stop, slap: fixed points per rig
	var hd: Dictionary = _rig.get("hands", {}).get(name, ReloadAnims.HANDS[name])
	var f: Vector3 = (hd["f"] as Vector3).normalized()
	var n: Vector3 = (hd["n"] as Vector3).normalized()
	if name == "mag":
		f = mag_xf.basis * f
		n = mag_xf.basis * n
	return [p - f * ReloadAnims.WRIST_BACK - n * ReloadAnims.WRIST_OFF, f, n]


## Gun-model offsets onto the Mag node and the charging bone or part (each in its parent's space).
func _apply() -> void:
	mag.transform = _k.affine_inverse() * mag_xf * _k * _base
	if bone >= 0:
		var tb := Transform3D(Basis.IDENTITY, (_rig["travel"] as Vector3) * bolt)
		skel.set_bone_global_pose(bone, _k.affine_inverse() * tb * _k * _bone_rest)
	if part != null:
		part.transform = _part_k.affine_inverse() * Transform3D(Basis.IDENTITY, (_rig["travel"] as Vector3) * bolt) * _part_k * _part_base
