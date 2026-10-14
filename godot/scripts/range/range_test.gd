class_name RangeTest
extends Node
## `-- --range-test`: prints [range] PASS/FAIL per check, then [range] OK n / FAILED n.

var passed := 0
var failed := 0
var bal: Ballistics
var _impacts: Array = []
var _hits: Array = []


func check(name: String, ok: bool, why: String = "") -> void:
	if ok:
		passed += 1
		print("[range] PASS ", name)
	else:
		failed += 1
		print("[range] FAIL ", name, ": ", why)


func run() -> void:
	RangeTestLogic.run(self)
	bal = Ballistics.new()
	bal.auto_step = false
	bal.rng.seed = 11
	add_child(bal)
	bal.impact.connect(func(i): _impacts.append(i))
	bal.body_hit.connect(func(h): _hits.append(h))
	await get_tree().physics_frame
	await get_tree().physics_frame
	await RangeTestInv.world(self)
	_zero_checks()
	await _wall_checks()
	await RangeTestTargets.run(self)
	await RangeTestBots.run(self)
	await RangeTestBody.run(self)
	await RangeTestDeploy.run(self)
	RangeTestGuns.run(self)
	RangeTestSound.run(self)
	await RangeTestAttach.run(self)
	if failed == 0:
		print("[range] OK ", passed)
	else:
		print("[range] FAILED ", failed, " (", passed, " passed)")


func _wall(pos: Vector3, size: Vector3, mat: String, thick: float) -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.position = pos
	var cs := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = size
	cs.shape = b
	sb.add_child(cs)
	sb.set_meta("mat", mat)
	sb.set_meta("thick", thick)
	add_child(sb)
	return sb


## Fires one round and steps until it is gone.
func _fly(ammo: String, origin: Vector3, dir: Vector3) -> void:
	_impacts.clear()
	_hits.clear()
	bal.spawn(origin, dir, ammo)
	for i in 900:
		if bal.shots.is_empty():
			break
		bal.step(1.0 / 60.0)


func _zeroed_dir(ammo: String, dist: float) -> Vector3:
	return Vector3(0, 0, -1).rotated(Vector3.RIGHT, Ballistics.zero_angle(ammo, dist))


func _zero_checks() -> void:
	_wall(Vector3(0, 0, -100.25), Vector3(8, 40, 0.5), "steel_target", 0.5)
	_fly("762_ps", Vector3(0, 1.6, 0), _zeroed_dir("762_ps", 100.0))
	var ok := not _impacts.is_empty() and absf(_impacts[0]["pos"].y - 1.6) < 0.03
	check("762x39 PS zeroed at 100 m hits within 3 cm", ok, str(_impacts[0]["pos"].y - 1.6) if not _impacts.is_empty() else "no hit")
	_wall(Vector3(10, 0, -300.25), Vector3(8, 40, 0.5), "steel_target", 0.5)
	_fly("338_fmj", Vector3(10, 1.6, 0), _zeroed_dir("338_fmj", 300.0))
	ok = not _impacts.is_empty() and absf(_impacts[0]["pos"].y - 1.6) < 0.02
	check(".338 zeroed at 300 m is within 2 cm at 300 m", ok, str(_impacts[0]["pos"].y - 1.6) if not _impacts.is_empty() else "no hit")
	_wall(Vector3(20, 0, -300.25), Vector3(8, 40, 0.5), "steel_target", 0.5)
	_fly("762_ps", Vector3(20, 1.6, 0), _zeroed_dir("762_ps", 100.0))
	check("762 PS zeroed at 100 m drops well below the aim point at 300 m", not _impacts.is_empty() and _impacts[0]["pos"].y < 1.6 - 0.3)


func _wall_checks() -> void:
	for lane in [["plywood", 0.02, 30.0, true], ["concrete", 0.15, 40.0, false]]:
		var x: float = lane[2]
		var dummy := Node3D.new()
		dummy.position = Vector3(x, 0, -8)
		add_child(dummy)
		var body := BodyHealth.new()
		HitboxRig.build(dummy, body, dummy)
		_wall(Vector3(x, 1.5, -5), Vector3(4, 3, lane[1]), lane[0], lane[1])
		await get_tree().physics_frame
		await get_tree().physics_frame
		_fly("762_ps", Vector3(x, 1.3, 0), Vector3(0, 0, -1))
		var reached: bool = not _hits.is_empty() and _hits[0]["zone"] == "thorax"
		check("762 PS %s wall %s" % [lane[0], "passes to the body" if lane[3] else "stops"], reached == lane[3])
