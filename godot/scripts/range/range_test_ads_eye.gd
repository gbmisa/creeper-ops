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
	t.check("ADS: near plane is low enough not to clip the visible stock",
		TacticalViewmodel.ADS_NEAR <= 0.1)
