class_name SmokePt3
## Playtest fixes: raiders stand on top of creeper, and a connected flying Node still sends packets.


static func run(g) -> void:
	_raider_on_creeper(g)
	_flying_node_sends(g)


static func _raider_on_creeper(g) -> void:
	var w: World = g.surface
	var c := Vector2i(60, 60)
	var p := w.grid.cell_ground(c.x, c.y)
	var dry := RaiderPerch.y(w, p.x, p.z)
	w.creeper.set_depth(c.x, c.y, 2.0)
	var wet := RaiderPerch.y(w, p.x, p.z)
	w.creeper.set_depth(c.x, c.y, 0.0)
	SmokeTest._check("raider stands on top of creeper",
		absf((wet - dry) - 2.0 * Config.LEVEL_H) < 0.01, "(dry %.2f wet %.2f)" % [dry, wet])


static func _flying_node_sends(g) -> void:
	var sm: StructureManager = g.structures
	var n := sm.command_node()
	var cz := n.z + 5
	for c in Placement.footprint_cells("collector", n.x - 3, cz):
		g.surface.creeper.set_depth(c.x, c.y, 0.0)
	var job: Structure = sm.place("collector", n.x - 3, cz)
	var saved := n.pos
	n.flight = { "from": n.pos, "to": n.pos, "cruise": n.pos.y + Config.LIFT_HEIGHT, "t": 0.0, "travel": 30.0 }
	sm.dirty = true
	sm.network.rebuild(sm.list)
	var r := sm.network.route(job)
	SmokeTest._check("flying node is a sender", n.is_flying() and n.connected and not r.is_empty()
		and r[0].distance_to(n.link_point()) < 0.01)
	g.economy.energy = 40.0
	var s0 := job.delivered + job.in_flight
	var t := 0.0
	while t < 1.0:
		sm.update(0.05, t)
		t += 0.05
	var s1 := job.delivered + job.in_flight
	SmokeTest._check("flying node launches packets with no outpost", s1 > s0, "(%d -> %d)" % [s0, s1])
	n.flight = null
	n.pos = saved
	n.node.position = saved
	sm.dirty = true
	sm.remove(job)
	sm.update(0.05, 0.0)
