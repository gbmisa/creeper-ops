class_name EnemyMortarSabotage
## Free Operative sabotage of a hive mortar (the enemy-built mortar uses EnemyBuildCrew's
## channel): press use and stay within MORTAR_SABOTAGE_RANGE for MORTAR_SABOTAGE_TIME. No payout.


static func interactable(host, m: Dictionary) -> Dictionary:
	var label := "Enemy Mortar"
	return {
		"pos": m.pos, "radius": Config.MORTAR_SABOTAGE_RANGE,
		"prompt": func() -> String: return EnemyBuildCrew._prompt(m, label),
		"use": func() -> void:
			if bool(m.alive) and float(m.channel) <= 0.0:
				m.channel = Config.MORTAR_SABOTAGE_TIME
				Sfx.play("lift")
				Bus.say("Sabotaging the %s: stay close for %ds — destroys it." % [label, ceili(Config.MORTAR_SABOTAGE_TIME)], "info"),
		"channel_frac": func() -> float: return 1.0 - float(m.channel) / Config.MORTAR_SABOTAGE_TIME,
		"channel_what": label,
	}


static func tick(host, dt: float) -> void:
	var fps = host.operative.call()
	for n in host.nests:
		for item in n.get("mortars", []):
			var m: Dictionary = item
			if not bool(m.alive) or float(m.get("channel", 0.0)) <= 0.0:
				continue
			var feet = fps.controller.pos if fps != null else null
			if feet == null or Vector2(feet.x - m.pos.x, feet.z - m.pos.z).length() > Config.MORTAR_SABOTAGE_RANGE:
				m.channel = 0.0
				Bus.say("Sabotage interrupted: you moved away from the Enemy Mortar.", "warn")
				continue
			m.channel = float(m.channel) - dt
			if float(m.channel) <= 0.0:
				EnemyMortars._kill(host, m)
				Bus.say("Sabotaged the Enemy Mortar.", "good")
