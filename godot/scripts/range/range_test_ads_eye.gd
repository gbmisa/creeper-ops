class_name RangeTestAdsEye
## P4: ADS eye-to-butt distance — cheek weld for stocked guns, arm's-length hold for pistols.

const STOCKED_MIN := 0.28
const STOCKED_MAX := 0.32
const PISTOL_MIN := -0.12
const PISTOL_MAX := -0.08


static func run(t: RangeTest) -> void:
	var bad := []
	for id in WeaponDefs.ORDER:
		var def := WeaponDefs.of(id)
		var lo := STOCKED_MIN
		var hi := STOCKED_MAX
		if def["class"] == "pistol":
			lo = PISTOL_MIN
			hi = PISTOL_MAX
		var d: float = def["butt"]
		if d < lo or d > hi:
			bad.append("%s=%.3f" % [id, d])
	t.check("ADS: eye-to-butt distance within per-class range for all %d guns" % WeaponDefs.ORDER.size(),
		bad.is_empty(), str(bad))
	# base_pos puts the butt plate at -(half - butt) + half = butt behind the eye.
	var def2 := WeaponDefs.of("ak47")
	var pos: Vector3 = TacticalViewmodel.base_pos(def2, 0.45, 1.0)
	t.check("ADS: base_pos places the butt plate `butt` m behind the eye",
		absf(pos.z + 0.45 - def2["butt"]) < 0.001)
	# FB-G: `eye` only ever moves the eye back from the cheek weld (behind a rear sight near the stock).
	var fwd := []
	for id in WeaponDefs.ORDER:
		var d := WeaponDefs.of(id)
		if TacticalViewmodel.ads_eye(d) > float(d["butt"]) + 0.001:
			fwd.append(id)
	t.check("ADS: per-gun eye is never ahead of the cheek weld", fwd.is_empty(), str(fwd))
	var m4 := WeaponDefs.of("m4a1")
	t.check("ADS: base_pos uses the per-gun eye when set (m4a1)",
		absf(TacticalViewmodel.base_pos(m4, 0.42, 1.0).z + 0.42 - float(m4["eye"])) < 0.001)
	t.check("ADS: near plane is low enough not to clip the visible stock",
		TacticalViewmodel.ADS_NEAR <= 0.1)
	_default_sights(t)


## FB-G red dots (Gregory: default red dot on p90/pkm/sr25 — fastest, no model work).
## Half-lengths measured from the gun glbs (gun_profile.gd).
const REDDOT_GUNS := ["p90", "pkm", "sr25"]
const HALF_LEN := {"p90": 0.250, "pkm": 0.595, "sr25": 0.500}
const EYE_MARGIN := 0.03  # the eye stays at least this far behind the sight


static func _default_sights(t: RangeTest) -> void:
	var inv := Inventory.new()
	# fresh player guns ship the default; bare Gun.new (bots, attachment tests) stays clean
	var fitted_bad := []
	var bare_bad := []
	for id in WeaponDefs.ORDER:
		var g := inv.make(id)["gun"] as Gun
		var want := "reddot" if id in REDDOT_GUNS else ""
		if g.fit.get("sight", "") != want:
			fitted_bad.append(id)
		if not Gun.new(id).fit.is_empty():
			bare_bad.append(id)
	t.check("ADS: p90/pkm/sr25 ship with a default red dot, every other gun ships bare",
		fitted_bad.is_empty(), str(fitted_bad))
	t.check("ADS: Gun.new stays bare (bots fit nothing)", bare_bad.is_empty(), str(bare_bad))
	# the eye is behind the red dot; the dot is on screen centre in ADS and ahead of the near plane
	var eye_bad := []
	var proj_bad := []
	for id in REDDOT_GUNS:
		var g := inv.make(id)["gun"] as Gun
		var d := g.def
		var half: float = HALF_LEN[id]
		var eye := TacticalViewmodel.ads_eye(d)
		var m := AttachmentMounts.mount(d, "sight", half)
		if not m.z < half - eye - EYE_MARGIN:
			eye_bad.append(id)
		var eff := g.eff_def()
		var sl := AttachmentMounts.sight_line(d, "reddot")
		var ap: Vector3 = eff["ads_pos"]
		if absf(ap.y + sl) > 0.0001 or absf(m.x + ap.x) > 0.002:
			proj_bad.append(id)
		var rd: Dictionary = AttachmentDefs.ROWS["reddot"]
		var sight_z := half - eye - m.z
		var near := clampf(sight_z - float(rd["depth"]) * 0.5 - 0.04, 0.03, TacticalViewmodel.ADS_NEAR)
		if not half - eye - (m.z + float(rd["depth"]) * 0.5) > near:
			proj_bad.append(id + ":near")
	t.check("ADS: the eye is behind the red dot (3 cm margin) on p90/pkm/sr25",
		eye_bad.is_empty(), str(eye_bad))
	t.check("ADS: each red dot is on screen centre and ahead of the near plane",
		proj_bad.is_empty(), str(proj_bad))
