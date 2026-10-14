class_name RangeShot
extends Node
## Screenshot / debug hook: --shot=path [--weapon=id] [--ads] [--look=x,y,z] [--fire=N] [--wait=s] [--pos=x,y,z] [--crouch] [--armor=0..3 dummy loadout] [--reload[=s]] [--fast] (reload mid-way shot).
## Gives the weapon, optionally fires N shots, waits, saves the viewport, quits.


func run(app: FiringRange) -> void:
	var a := app.args
	var w: PlayerWeapons = app.weapons
	if a.has("weapon"):
		w.give(str(a["weapon"]))
	if a.has("pos"):
		app.player.global_position = RangeArgs.vec3(str(a["pos"]), app.player.global_position)
	if a.has("look"):
		app.player.look_at_point(RangeArgs.vec3(str(a["look"])))
	if a.has("armor"):
		app.targets.set_loadout(int(a["armor"]))
	if a.has("crouch"):
		app.player.crouching = true
	w.trigger_ads = a.has("ads")
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
		await app.get_tree().create_timer(60.0 / w.gun.def["rpm"] + 0.1 + w.gun.def["cycle"]).timeout
	if a.has("reload"):
		w.start_reload(a.has("fast"))
		await app.get_tree().create_timer(float(a.get("reload", 0.5)) if str(a["reload"]) != "true" else 0.4).timeout
	await app.get_tree().create_timer(float(a.get("wait", 1.0))).timeout
	for b in app.bots.bots:
		if is_instance_valid(b):
			print("[range] ", b.label_name, " ", b.global_position.snapped(Vector3(0.1, 0.1, 0.1)), " ", b.brain.state, " hp ", snappedf(b.body.total_frac(), 0.01))
	print("[range] fired ", shots, " impacts ", impacts.size(), " mags ", w.gun.mag.count() if w.gun else -1)
	if a.has("shot"):
		await RenderingServer.frame_post_draw
		app.get_viewport().get_texture().get_image().save_png(str(a["shot"]))
		print("[range] shot saved ", a["shot"])
	app.get_tree().quit()
