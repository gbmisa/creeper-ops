class_name CastleStages
## Staged capture of concentric castles (docs/CASTLES2_DESIGN.md §3). `lay.stages` lists the
## rings in order (["gate", "bailey", "keep"]; Stage 7 rows only ["keep"]). `c.stage` is the
## index of the first ring the enemy still holds. While the castle is hostile:
##   gate    hold the gate hall GATE_TIME: the outer gates (and drawbridge) are yours
##   bailey  every trebuchet dead, then hold the bailey standard BAILEY_TIME: build in the bailey
##   keep    the crown nest in the keep hall can be hurt; kill it, then hold the hall (Strongholds)
## Raiders in a zone contest it (no progress). Raiders on the last ring you took for
## RING_RETAKE with nobody there take it back. State: c.stage, c.ring { progress, away, retake }.


static func new_state() -> Dictionary:
	return { "progress": 0.0, "away": 0.0, "retake": 0.0 }


static func current(c: Dictionary, lay: Dictionary) -> String:
	var i := int(c.get("stage", 0))
	return lay.stages[i] if i < lay.stages.size() else "held"


## The crown nest only takes damage once every outer ring is yours.
static func crown_open(c: Dictionary, lay: Dictionary) -> bool:
	return current(c, lay) == "keep"


## Who holds a ring's gates: the outer ring is yours once its gate stage is taken.
static func ring_owner(c: Dictionary, lay: Dictionary, ring: String) -> String:
	if c.owner == "player":
		return "player"
	if ring == "outer" and lay.stages.size() > 1 and int(c.get("stage", 0)) >= 1:
		return "player"
	return "enemy"


## Bailey ground is buildable for you once its stage is taken (or the castle is yours).
static func bailey_open(c: Dictionary, lay: Dictionary) -> bool:
	return c.owner == "player" or (lay.stages.size() > 1 and int(c.get("stage", 0)) >= 2)


static func tick(s: Strongholds, c: Dictionary, lay: Dictionary, p: Variant, dt: float) -> void:
	var ring: Dictionary = c.ring
	var stage := current(c, lay)
	_retake(s, c, lay, p, dt)
	if stage == "keep" or stage == "held":
		return
	var here := StrongholdRules.in_zone(lay, p, stage)
	var raided := _raiders_in(s, lay, stage)
	if stage == "bailey" and here and CastleEngines.alive_count(c) > 0:
		_nag(s, c, "Destroy the %d trebuchets on the corner towers before raising the standard." % CastleEngines.alive_count(c))
		return
	if here and raided:
		_nag(s, c, "Raiders contest the %s. Clear them." % _label(stage))
		return
	if not here:
		ring.progress = maxf(0.0, ring.progress - Config.CAPTURE_DECAY * dt)
		return
	ring.progress = minf(1.0, ring.progress + dt / (CastleDefs.GATE_TIME if stage == "gate" else CastleDefs.BAILEY_TIME))
	if ring.progress < 1.0:
		return
	set_stage(s, c, int(c.stage) + 1)
	Sfx.play("good")
	if stage == "gate":
		Bus.say("%s: the gatehouse is yours. The outer gate opens for your units." % c.name, "good")
	else:
		Bus.say("%s: the bailey is yours: build in it. The crown nest in the keep is exposed." % c.name, "good")


## Raiders back on the last ring you took, with nobody to stop them, take it back.
static func _retake(s: Strongholds, c: Dictionary, lay: Dictionary, p: Variant, dt: float) -> void:
	var i := int(c.get("stage", 0)) - 1
	if i < 0 or i >= lay.stages.size() - 1:
		c.ring.retake = 0.0
		return
	var last: String = lay.stages[i]
	if not _raiders_in(s, lay, last) or StrongholdRules.in_zone(lay, p, last):
		c.ring.retake = maxf(0.0, c.ring.retake - dt)
		return
	c.ring.retake += dt
	if c.ring.retake < CastleDefs.RING_RETAKE:
		return
	set_stage(s, c, i)
	if last == "bailey":
		s.on_lost.call(lay.bailey)
	Sfx.play("lost")
	Bus.say("%s: raiders retook the %s." % [c.name, _label(last)], "bad")


static func _raiders_in(s: Strongholds, lay: Dictionary, zone: String) -> bool:
	for r in s.nests.raiders.list:
		var cell := s.world.grid.world_to_cell(r.node.position.x, r.node.position.z)
		if cell in lay.zones[zone].cells:
			return true
	return false


## Sets the stage, re-hangs gates and the bailey's build rights, and moves the garrison home.
static func set_stage(s: Strongholds, c: Dictionary, n: int) -> void:
	var lay: Dictionary = s.lays[c.id]
	c["stage"] = clampi(n, 0, lay.stages.size())
	c.ring = new_state()
	StrongholdRules.sync_grid(s.world, c, lay)
	var v: Dictionary = s.views.get(c.id, {})
	if v.has("garrison"):
		v.garrison.pos = s.world.grid.cell_ground(home(c, lay).x, home(c, lay).y)
	if v.has("root"):
		StrongholdMeshes.refresh(v, c)


## Where the garrison gathers: the bailey standard, then the keep door once the bailey falls.
static func home(c: Dictionary, lay: Dictionary) -> Vector2i:
	if lay.stages.size() > 1 and int(c.get("stage", 0)) >= 2:
		return lay.spire.entry
	return lay.home


static func _label(stage: String) -> String:
	return { "gate": "gatehouse", "bailey": "bailey", "keep": "keep" }.get(stage, stage)


static func _nag(s: Strongholds, c: Dictionary, msg: String) -> void:
	var t: float = c.ring.get("nag", -99.0)
	if s.time - t < 6.0:
		return
	c.ring["nag"] = s.time
	Bus.say(msg, "warn")


## Label for the castle marker while it is hostile.
static func marker(c: Dictionary, lay: Dictionary) -> String:
	match current(c, lay):
		"gate": return "%s: take the gatehouse %d%%" % [c.name, roundi(c.ring.progress * 100.0)]
		"bailey":
			var n := CastleEngines.alive_count(c)
			if n > 0:
				return "%s: destroy %d trebuchet%s" % [c.name, n, "" if n == 1 else "s"]
			return "%s: raise the bailey standard %d%%" % [c.name, roundi(c.ring.progress * 100.0)]
	if lay.stages.size() > 1:
		return "%s: kill the crown nest in the keep hall" % c.name
	return "%s: climb the spire, kill the crown nest" % c.name
