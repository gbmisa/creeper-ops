class_name SmokePt3cPause
extends RefCounted
## PT3-C: pause button + speed buttons on the top bar (command mode), amber PAUSED
## banner under the bar. Called from SmokeTest.run and --smoke=pt3c.


static func run(g) -> void:
	var top: TopBar = g.hud.top
	# Post-briefing state for the toggle checks (briefing pause itself is untouched).
	g.paused = false
	g.hud.refresh(g, 0.0)

	SmokeTest._check("pt3c: pause button exists", top.pause_btn != null and top.slow_btn != null and top.fast_btn != null)
	SmokeTest._check("pt3c: buttons visible in command mode",
		top.pause_btn.visible and top.slow_btn.visible and top.fast_btn.visible)
	SmokeTest._check("pt3c: pause button shows keybind",
		top.pause_btn.text == "II " + Keybinds.short("pause"), "(%s)" % top.pause_btn.text)

	# The button toggles g.paused through the shared GameFlow function.
	top.pause_btn.pressed.emit()
	SmokeTest._check("pt3c: button pauses", g.paused)
	g.hud.refresh(g, 0.0)
	SmokeTest._check("pt3c: banner shows while paused", g.hud._paused_box.visible)
	SmokeTest._check("pt3c: button label flips to resume",
		top.pause_btn.text == "> " + Keybinds.short("pause"), "(%s)" % top.pause_btn.text)
	top.pause_btn.pressed.emit()
	SmokeTest._check("pt3c: button resumes", not g.paused)
	g.hud.refresh(g, 0.0)
	SmokeTest._check("pt3c: banner hides when unpaused", not g.hud._paused_box.visible)

	# The pause key uses the same shared function.
	g.flow.toggle_pause()
	SmokeTest._check("pt3c: shared toggle pauses", g.paused)
	g.flow.toggle_pause()
	SmokeTest._check("pt3c: shared toggle resumes", not g.paused)

	# Speed buttons call cycle_speed(-1/+1).
	var s0: float = g.speed
	top.slow_btn.pressed.emit()
	var s1: float = g.speed
	top.fast_btn.pressed.emit()
	top.fast_btn.pressed.emit()
	SmokeTest._check("pt3c: << slows, >> speeds", s1 <= s0 and g.speed >= s1,
		"(%.1f -> %.1f -> %.1f)" % [s0, s1, g.speed])

	# Banner never blocks map clicks.
	SmokeTest._check("pt3c: banner is click-through",
		g.hud._paused_box.mouse_filter == Control.MOUSE_FILTER_IGNORE)

	# FPS mode: buttons hidden (Esc already pauses there), banner hidden too.
	var m: String = g.mode
	g.mode = "surface"
	g.hud.refresh(g, 0.0)
	SmokeTest._check("pt3c: buttons hidden in FPS mode",
		not top.pause_btn.visible and not top.slow_btn.visible and not top.fast_btn.visible)
	SmokeTest._check("pt3c: banner hidden in FPS mode", not g.hud._paused_box.visible)
	g.mode = m
	g.hud.refresh(g, 0.0)
	SmokeTest._check("pt3c: buttons return in command mode",
		top.pause_btn.visible and top.slow_btn.visible and top.fast_btn.visible)
