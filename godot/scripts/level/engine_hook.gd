class_name EngineHook
extends RefCounted
## First-person side of a Salvage Engine socket: the hold-E interactable, the gauntlet cable
## while holding, the permanent cable and its pulse, (a hook is not prey: only losing its anchor relay ends it).


static func register(host: SalvageEngines, e: Dictionary, s: Dictionary) -> void:
	var it := { "pos": s.pos, "radius": EngineDefs.HOOK_RANGE, "hold": EngineDefs.HOOK_TIME,
		"near": func(feet: Vector3) -> bool: return absf(feet.y + 1.2 - float(s.pos.y)) <= EngineDefs.HOOK_REACH_Y,
		"prompt": func() -> String: return prompt(host, e, s),
		"ready": func() -> bool: return ready(host, e, s),
		"progress": func(frac: float, from: Vector3) -> void:
			host.world.effects.beam(from, s.pos, Color("8fe8ff"), 0.06, 0.03 + 0.05 * frac),
		"use": func() -> void:
			if not host.hook(e, s):
				Sfx.play("deny") }
	host.world.interactables.append(it)


static func ready(host: SalvageEngines, e: Dictionary, s: Dictionary) -> bool:
	if bool(s.hooked) or float(e.reserve) <= 0.0:
		return false
	return host.cash_mode or host.anchor_for(s) != null


static func prompt(host: SalvageEngines, e: Dictionary, s: Dictionary) -> String:
	if float(e.reserve) <= 0.0:
		return ""
	if bool(s.hooked):
		return "Hooked (%d left)" % int(ceil(float(e.reserve)))
	if not ready(host, e, s):
		return "No network in reach: build a Relay within %d cells" % int(EngineDefs.LINK)
	var verb := "salvage the cache" if host.cash_mode else "hook the %s" % str(e.name)
	return "[Hold %s] %s" % [Keybinds.short("use"), verb]


## Cave engines have no network: a hooked one pays a share of its reserve at once.
static func cash(host: SalvageEngines, e: Dictionary, s: Dictionary) -> bool:
	var n := float(e.reserve) * EngineDefs.CAVE_CASH
	s.hooked = true
	e.reserve = 0.0
	host.stockpile.add("salvage", n)
	host.shipped += n
	host.world.effects.burst(s.pos, EngineMeshes.HOOKED, 2.0, 0.5)
	Bus.say("%s stripped: Salvage +%d." % [e.name, roundi(n)], "good")
	for q in e.sockets:
		host.tint(q)
	return true


static func link(host: SalvageEngines, s: Dictionary, anchor: Structure) -> void:
	unlink(s)
	if anchor == null:
		return
	var pts := EngineMeshes.cable_points(s.pos, anchor.link_point())
	var cable := MeshInstance3D.new()
	cable.mesh = EngineMeshes.cable_mesh(pts)
	cable.material_override = EngineMeshes.cable_material()
	cable.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	host.world.add_child(cable)
	var bead := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.2
	sph.height = 0.4
	bead.mesh = sph
	bead.material_override = Effects.glow_mat(Color("b8ffe0"))
	bead.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	host.world.add_child(bead)
	s.cable = cable
	s.bead = bead
	s["pts"] = pts


static func unlink(s: Dictionary) -> void:
	for key in ["cable", "bead"]:
		var n: Variant = s.get(key)
		if n != null and is_instance_valid(n):
			(n as Node).queue_free()
		s[key] = null
	s.erase("pts")


## The pulse: a bead slides down the cable while the socket is shipping; sockets glow while hooked.
static func animate(host: SalvageEngines, e: Dictionary, s: Dictionary, t: float) -> void:
	var bead := s.get("bead") as MeshInstance3D
	if bead == null or not s.has("pts") or float(e.reserve) <= 0.0:
		return
	var live: bool = bool(s.hooked) and float(e.reserve) > 0.0 and not host.is_wet(s)
	bead.visible = live
	if live:
		bead.position = EngineMeshes.along(s.pts, fmod(t * 0.3 + float(s.pos.x) * 0.1, 1.0))
	EngineMeshes.tint(s, EngineMeshes.HOOKED if live else Color("5a8a74"), 1.5 + 0.8 * sin(t * 2.0) if live else 0.5)
