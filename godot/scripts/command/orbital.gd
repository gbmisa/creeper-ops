class_name Orbital
extends RefCounted
## Orbital tab abilities that aren't structures. The Lance: pay up front, wait LANCE_DELAY
## while a targeting beam warns everyone, then burn creeper in a radius and kill raiders.

var world: World
var economy: Economy
var hazards: SurfaceHazards
var cooldown := 0.0
var _pending: Array[Dictionary] = []


func _init(w: World, eco: Economy) -> void:
	world = w
	economy = eco


func can_fire() -> Dictionary:
	if cooldown > 0.0:
		return { "ok": false, "reason": "Orbital Lance recharging: %ds" % ceili(cooldown) }
	if economy.energy < Config.LANCE_COST:
		return { "ok": false, "reason": "Orbital Lance needs %d energy up front" % Config.LANCE_COST }
	return { "ok": true, "reason": "" }


func fire(at: Vector3) -> void:
	if not can_fire().ok or not economy.spend(Config.LANCE_COST):
		return
	cooldown = Config.LANCE_COOLDOWN
	_pending.append({ "at": at, "t": 0.0, "tick": 0.0 })
	Sfx.play("lance")
	Bus.say("Orbital Lance inbound.", "info")


func update(dt: float) -> void:
	cooldown = maxf(0.0, cooldown - dt)
	for i in range(_pending.size() - 1, -1, -1):
		var p: Dictionary = _pending[i]
		p.t += dt
		p.tick -= dt
		var at: Vector3 = p.at
		if p.tick <= 0.0:  # targeting beam flicker
			p.tick = 0.15
			world.effects.beam(at + Vector3(0, 80, 0), at, Color("ff6a3a"), 0.12, 0.15 + p.t * 0.2)
		if p.t >= Config.LANCE_DELAY:
			_strike(at)
			_pending.remove_at(i)


func _strike(at: Vector3) -> void:
	var c := world.grid.world_to_cell(at.x, at.z)
	world.creeper.remove_radius(c.x, c.y, Config.LANCE_RADIUS, Config.LANCE_POWER)
	world.effects.beam(at + Vector3(0, 80, 0), at, Color("fff0c0"), 0.4, 2.2)
	world.effects.burst(at, Color("ffb070"), Config.LANCE_RADIUS * Config.CELL * 1.3, 0.7)
	Sfx.play("boom", at)
	if hazards:
		var reach := Config.LANCE_RADIUS * Config.CELL
		var foes: Array = hazards.nests.raiders.list.duplicate()
		if hazards.guards:
			foes.append_array(hazards.guards.foes())
		for m in foes:
			if (m.node.position as Vector3).distance_to(at) < reach:
				m.enemy.hit.call(99.0)
