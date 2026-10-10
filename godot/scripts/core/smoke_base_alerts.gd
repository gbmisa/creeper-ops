class_name SmokeBaseAlerts
## Playtest 4: base alerts. A lost structure counts toward the recent-loss chip, rolls off
## after BASE_LOST_WINDOW, and an attack lights the FPS pulse.


static func run(g) -> void:
	var ba: BaseAlerts = g.flow.base_alerts
	var n0 := ba.recent()
	ba._cd = 0.0
	Bus.base_attacked.emit("cannon")
	SmokeTest._check("base alerts: an attack fires the screen pulse", g.hud.fps._edge_t > 0.0)
	Bus.base_lost.emit("cannon")
	Bus.base_lost.emit("relay")
	SmokeTest._check("base alerts: losses are counted", ba.recent() == n0 + 2)
	ba.update(Config.BASE_LOST_WINDOW + 1.0)
	SmokeTest._check("base alerts: losses roll off after the window", ba.recent() == 0)
