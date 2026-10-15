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
	# F50: the M1911A1 ADS matches d272c0a (near cap 0.25, ads_pos.y -0.0698, eye = butt); other pistols/rifles keep the P4 values.
	var m19 := WeaponDefs.of("m1911")
	t.check("ADS F50: m1911 near cap 0.25, ads_pos.y -0.0698, eye z = butt",
		absf(float(m19["ads_near"]) - 0.25) < 0.0001 and absf((m19["ads_pos"] as Vector3).y + 0.0698) < 0.0001
		and TacticalViewmodel.ads_eye(m19) == float(m19["butt"]))
	var keep := []
	for id in ["glock18", "ak47"]:
		if WeaponDefs.of(id).has("ads_near"):
			keep.append(id)
	t.check("ADS F50: glock18 and ak47 keep the shared near plane", keep.is_empty(), str(keep))
