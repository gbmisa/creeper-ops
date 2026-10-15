class_name RifleFire
extends RefCounted
## The Pulse Rifle's shot: hitscan against world targets with bloom-grown spread,
## tracer + beam + impact effects, coil flare, muzzle flash and the per-shot kick.
## Bloom (spread, degrees) grows per shot while firing and recovers on release.
## Constructed with the OperativeWeapons it fires for (same pattern as
## AdvancedWeapons). ray_sphere is shared by the crossbow, the railgun and a smoke.

var bloom := 0.0  # spread in degrees: grows per shot while firing, recovers on release
var _w: OperativeWeapons

func _init(w: OperativeWeapons) -> void:
	_w = w

func fire(world: World) -> void:
	var grade := AmmoGrades.op_shot("rifle", _w.advanced.stockpile)
	var o := _w.camera.global_position
	var d := -_w.camera.global_transform.basis.z
	var basis := _w.camera.global_transform.basis
	d = spread(d, basis.x, basis.y)  # sustained-fire spread: grows per shot, recovers on release
	grow()
	var reach: float = Config.RIFLE.range
	var best: Dictionary = {}
	var bt := reach
	for t in world.targets:
		if not t.alive.call():
			continue
		var c: Vector3 = (t.node as Node3D).global_position + Vector3(0, t.get("oy", 0.0), 0)
		var hit := ray_sphere(o, d, c, t.radius)
		if hit < bt:
			bt = hit
			best = t
	var ground = world.grid.raycast(o, d, reach)
	var gd: float = o.distance_to(ground) if ground != null else INF
	var start := _w.gun.global_position + (-_w.camera.global_transform.basis.z) * 0.2
	var end := o + d * reach
	if not best.is_empty() and bt < gd:
		end = o + d * bt
		AmmoGrades.shoot(best, Config.RIFLE.damage * OperativeUpgrades.mult("firepower"), grade, world, end)
		_w.confirm(not best.alive.call())
	elif ground != null:
		end = ground
		world.effects.burst(end, Color("ffffaa"), 0.3, 0.12)
	AmmoGrades.impact(world, end, grade)
	world.effects.beam(start, end, AmmoGrades.color(grade), 0.12, 0.035)
	world.effects.tracer(start, end, Color("b8f8ff"), Config.VM_TRACER_SPEED * 1.6, 2.5, 0.08)
	Sfx.play("rifle")
	Sfx.play("rifle_crack")
	Sfx.play("rifle_tail")
	_w._coil_flare = 1.0
	_w.muzzle.flash(Color("9ff6ff"), 0.11, 0.06, 2.0)
	_w.kick("rifle")

## Offset the shot direction by up to bloom degrees around the given axes.
func spread(d: Vector3, x: Vector3, y: Vector3) -> Vector3:
	var b := deg_to_rad(bloom)
	if b > 0.0001:
		d = d.rotated(x, randf_range(-b, b)).rotated(y, randf_range(-b, b)).normalized()
	return d

## A shot was fired: grow bloom toward its cap.
func grow() -> void:
	var rd: Dictionary = RecoilDefs.of("rifle")
	bloom = minf(bloom + rd.bloom_add, rd.bloom_max)

## Bloom recovers only on release; it grows per shot in fire().
func recover(dt: float, firing: bool) -> void:
	if firing:
		return
	var rd: Dictionary = RecoilDefs.of("rifle")
	bloom = maxf(0.0, bloom - rd.bloom_recover * dt)

## Distance along a ray to a sphere, or INF.
static func ray_sphere(o: Vector3, d: Vector3, c: Vector3, r: float) -> float:
	var oc := o - c
	var b := oc.dot(d)
	var disc := b * b - (oc.length_squared() - r * r)
	if disc < 0.0:
		return INF
	var t := -b - sqrt(disc)
	if t > 0.0:
		return t
	return 0.001 if -b + sqrt(disc) > 0.0 else INF  # muzzle inside the target: point-blank hit
