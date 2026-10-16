class_name RangeTestAnim
## N2 section D probe/checks: F73 sustained Glock 18 auto fire (hip and ADS) keeps the drawn gun clear of the eye.

const STEP := TacRecoilDefs.STEP


static func run(t: RangeTest) -> void:
	var r := RangeTestAttach._rig(t)
	await t.get_tree().process_frame
	for ads in [false, true]:
		_sustained(t, r, "glock18", ads, 16)
	for k in ["w", "vm", "player", "input", "rack"]:
		r[k].queue_free()


static func _sustained(t: RangeTest, r: Dictionary, id: String, ads: bool, shots: int) -> void:
	var w: PlayerWeapons = r["w"]
	var vm: TacticalViewmodel = r["vm"]
	var cam: Camera3D = (r["player"] as TacticalPlayer).cam
	for sl in PlayerWeapons.HAND_SLOTS:
		var have = w.inv.equipped(sl)
		if have != null:
			w.inv.remove(have)
	w.sync()
	w.give(id)
	w.draw_t = 0.0
	if ads:
		RangeTestAds._snap_ads(w, vm)
	else:
		w.ads_amt = 0.0
	for i in 20:
		vm._process(STEP)
	var tris := RangeTestRecoilEye._near_tris(vm, cam)
	var rest := RangeTestRecoilEye._clear(vm, cam, tris)
	assert(w.gun.def["id"] == id)
	w.recoil.set_seed(11)
	PlayerRecoil.tick(w, STEP)
	w.gun.mode = "auto"
	w.trigger_held = true
	var gap: float = 60.0 / float(w.gun.def["rpm"])
	var worst := rest
	var maxback := 0.0
	var climb := []
	var since := gap
	var fired := 0
	for i in int((shots * gap + 1.0) / STEP):
		if fired < shots and since >= gap - 1e-6:
			RangeTestAttach._fire(w)
			fired += 1
			since = 0.0
			climb.append(snappedf(w.recoil.view_offset().length(), 0.01))
		PlayerRecoil.tick(w, STEP)
		vm._process(STEP)
		since += STEP
		var back: float = vm.model.position.z - vm._base_pos.z
		maxback = maxf(maxback, absf(back))
		worst = minf(worst, RangeTestRecoilEye._clear(vm, cam, tris))
	w.trigger_held = false
	print("[range] climb ", id, " ads=", ads, " ", climb)
	if not ads:
		t.check("anim: %s hip drawn kick back stays near the hands (max %.1f cm <= 5)" % [id, maxback * 100.0], maxback <= 0.05)
	t.check("anim: %s %s %d-shot auto keeps the eye %.1f cm clear (rest %.1f, max back %.1f cm)"
		% [id, "ADS" if ads else "hip", shots, worst * 100.0, rest * 100.0, maxback * 100.0],
		worst >= TacticalConfig.ADS_EYE_CLEAR - 1e-4)


## F70: every Garand shot, at its own rate of fire, starts the fire clip from the start (it used to carry on
## when the clip was still playing, so the bolt moved every other shot and snapped).
static func garand(t: RangeTest) -> void:
	var r := RangeTestAttach._rig(t)
	await t.get_tree().process_frame
	var w: PlayerWeapons = r["w"]
	var vm: TacticalViewmodel = r["vm"]
	RangeTestAttach._equip(r, "garand")
	RangeTestAds._snap_ads(w, vm)
	var gap: float = 60.0 / float(w.gun.def["rpm"])
	var starts := 0
	var fired := 0
	var worst := 0.0   # largest clip position left after a shot (s): 0 = restarted
	for n in 5:
		if RangeTestAttach._fire(w):
			fired += 1
			worst = maxf(worst, vm.anim.current_animation_position)
			starts += 1 if vm.anim.is_playing() else 0
		for i in int(gap / (1.0 / 60.0)):
			vm.anim.advance(1.0 / 60.0)
	t.check("anim: garand %d shots at %.0f rpm each restart the fire clip (start pos %.2f s, playing %d)" % [fired, 60.0 / gap, worst, starts],
		fired == 5 and worst < 0.01 and starts == 5)
	for k in ["w", "vm", "player", "input", "rack"]:
		r[k].queue_free()
