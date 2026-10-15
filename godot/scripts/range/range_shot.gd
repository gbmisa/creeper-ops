class_name RangeShot
extends Node
## Screenshot / debug hook: --shot=path [--weapon=id] [--fit=a,b] [--zoom=lo] [--ads] [--look=x,y,z] [--fire=N] [--bolt=0..1 (with --fire=1: shoot after that share of the bolt cycle)] [--wait=s] [--pos=x,y,z] [--crouch] [--pitch=deg] [--side=right|top|front] [--walk=W+shift] [--armor=0..3 dummy loadout] [--reload[=s]] [--fast] [--fps-report] (reload mid-way shot).
## Gives the weapon, optionally fires N shots, waits, saves the viewport, quits.


func run(app: FiringRange) -> void:
	var a := app.args
	var w: PlayerWeapons = app.weapons
	if a.has("weapon"):
		w.give(str(a["weapon"]))
	if a.has("fit") and w.gun != null:  # --fit=reddot,laser: fit those parts on the gun in hand (--zoom=lo = variable sight at 1x)
		for id in str(a["fit"]).split(","):
			var r := w.inv.request_fit(w.gun_item, w.inv.make(id))
			if not r["ok"]:
				print("[range] fit ", id, " refused: ", r["why"])
		w.gun.zoom_hi = str(a.get("zoom", "hi")) != "lo"
	if a.has("pos"):
		app.player.global_position = RangeArgs.vec3(str(a["pos"]), app.player.global_position)
	if a.has("look"):
		app.player.look_at_point(RangeArgs.vec3(str(a["look"])))
	if a.has("pitch"):
		app.player.pitch = deg_to_rad(float(a["pitch"]))
	if a.has("walk"):  # --walk[=W|A|S|D|shift]: hold keys (e.g. --walk=W) for the whole shot
		for c in (str(a["walk"]) if str(a["walk"]) != "true" else "W").split("+"):
			var ev := InputEventKey.new()
			ev.physical_keycode = OS.find_keycode_from_string(c)
			ev.pressed = true
			Input.parse_input_event(ev)
	if a.has("side"):  # --side[=right|top|front]: debug camera beside the viewmodel (body hidden)
		var sc := Camera3D.new()
		sc.near = 0.02
		var view := str(a["side"])
		app.player.head.add_child(sc)
		var focus := Vector3(0.1, -0.1, -0.45)
		var off: Vector3 = {"right": Vector3(0.7, 0.05, 0.0), "top": Vector3(0.0, 0.7, 0.01), "front": Vector3(0.0, 0.1, -1.0)}.get(view, Vector3(0.7, 0.05, 0.0))
		sc.position = focus + off
		sc.look_at(app.player.head.to_global(focus))
		sc.cull_mask = 0xFFFFF & ~FpBody.HIDDEN_LAYER
		sc.current = true
		app.player.get_node("FpBody").visible = false
	if a.has("armor"):
		app.targets.set_loadout(int(a["armor"]))
	if a.has("crouch"):
		app.player.crouching = true
	w.trigger_ads = a.has("ads")
	if a.has("inventory"):  # --inventory: shot with the inventory screen open
		app.inv_ui.open()
	if a.has("engage") and not app.bots.bots.is_empty():  # --engage: Scav 1 stands 6 m ahead of the player and is alerted
		var bot: ScavBot = app.bots.bots[0]
		bot.global_position = app.player.global_position + Vector3(0, 0, 6) if not a.has("look") else RangeArgs.vec3(str(a["engage"]))
		bot.rotation.y = 0.0
		bot.percept.alert(app.player.global_position)
	var impacts := []
	app.bal.impact.connect(func(i): impacts.append(i))
	await app.get_tree().create_timer(0.8).timeout
	var shots := int(a.get("fire", 0))
	for i in shots:
		w.trigger_down = true
		await app.get_tree().create_timer(0.08).timeout
		w.trigger_down = false
		var gap: float = float(a["bolt"]) * w.gun.def["cycle"] if a.has("bolt") else 60.0 / w.gun.def["rpm"] + 0.1 + w.gun.def["cycle"]
		await app.get_tree().create_timer(gap).timeout
	if a.has("reload"):
		w.start_reload(a.has("fast"))
		await app.get_tree().create_timer(float(a.get("reload", 0.5)) if str(a["reload"]) != "true" else 0.4).timeout
	await app.get_tree().create_timer(0.0 if a.has("bolt") else float(a.get("wait", 1.0))).timeout
	for b in app.bots.bots:
		if is_instance_valid(b):
			print("[range] ", b.label_name, " ", b.global_position.snapped(Vector3(0.1, 0.1, 0.1)), " ", b.brain.state, " hp ", snappedf(b.body.total_frac(), 0.01))
	if a.has("fps-report"):
		print("[range] fps ", Engine.get_frames_per_second())
	print("[range] fired ", shots, " impacts ", impacts.size(), " mags ", w.gun.mag.count() if w.gun else -1)
	if a.has("shot"):
		await RenderingServer.frame_post_draw
		app.get_viewport().get_texture().get_image().save_png(str(a["shot"]))
		print("[range] shot saved ", a["shot"])
	app.get_tree().quit()
