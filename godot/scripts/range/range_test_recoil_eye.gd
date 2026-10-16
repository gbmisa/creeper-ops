class_name RangeTestRecoilEye
## Playtest 2026-10-16 ("ak47 clips when recoil is active and the gun tilts down"): through an aimed burst the
## drawn gun's bore never pitches below the view line, and the eye (camera origin) keeps
## TacticalConfig.ADS_EYE_CLEAR (F58) from every gun triangle, sampled each 60 Hz step with the real recoil_xform.

const STEP := TacRecoilDefs.STEP
const SHOTS := 6


static func run(t: RangeTest) -> void:
	var r := RangeTestAttach._rig(t)
	await t.get_tree().process_frame
	for id in ["ak47", "mp5"]:
		_burst(t, r, id)
	for k in ["w", "vm", "player", "input", "rack"]:
		r[k].queue_free()


static func _burst(t: RangeTest, r: Dictionary, id: String) -> void:
	var w: PlayerWeapons = r["w"]
	var vm: TacticalViewmodel = r["vm"]
	var cam: Camera3D = (r["player"] as TacticalPlayer).cam
	RangeTestAttach._equip(r, id)
	RangeTestAds._snap_ads(w, vm)
	var tris := _near_tris(vm, cam)
	var rest := _clear(vm, cam, tris)
	var rest_pitch := _bore_pitch(vm, cam)
	w.recoil.set_seed(11)
	w.gun.mode = "auto"
	w.trigger_held = true
	var gap: float = 60.0 / float(w.gun.def["rpm"])
	var worst := rest
	var dip := 0.0
	var since := gap
	var fired := 0
	for i in 150:   # 2.5 s: the burst, then the return and settle
		if fired < SHOTS and since >= gap - 1e-6:
			RangeTestAttach._fire(w)
			fired += 1
			since = 0.0
		if fired >= SHOTS and since > gap:
			w.trigger_held = false
		PlayerRecoil.tick(w, STEP)
		vm._process(STEP)
		since += STEP
		worst = minf(worst, _clear(vm, cam, tris))
		dip = minf(dip, _bore_pitch(vm, cam) - rest_pitch)
	t.check("recoil eye: %s aimed %d-shot burst keeps the eye %.1f cm from the gun (rest %.1f, limit %.1f)"
		% [id, SHOTS, worst * 100.0, rest * 100.0, TacticalConfig.ADS_EYE_CLEAR * 100.0],
		worst >= TacticalConfig.ADS_EYE_CLEAR - 1e-4)
	t.check("recoil eye: %s aimed burst never pitches the muzzle below the view line (worst %.3f deg)" % [id, dip],
		dip > -0.01)


## The eye (camera origin) in the gun model's space, as drawn now.
static func _eye(vm: TacticalViewmodel, cam: Camera3D) -> Vector3:
	return (cam.global_transform.affine_inverse() * vm.model.global_transform).affine_inverse() * Vector3.ZERO


static func _near_tris(vm: TacticalViewmodel, cam: Camera3D) -> PackedVector3Array:
	return RecoilEyeRoom.near_tris(vm.model, _eye(vm, cam))


static func _clear(vm: TacticalViewmodel, cam: Camera3D, tris: PackedVector3Array) -> float:
	return RecoilEyeRoom.clearance(tris, _eye(vm, cam))


## The gun's -Z (bore) pitch in camera space, degrees (+ = muzzle up).
static func _bore_pitch(vm: TacticalViewmodel, cam: Camera3D) -> float:
	var f := (cam.global_transform.basis.inverse() * vm.model.global_transform.basis) * Vector3.FORWARD
	return rad_to_deg(atan2(f.y, Vector2(f.x, f.z).length()))
