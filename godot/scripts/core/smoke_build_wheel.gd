class_name SmokeBuildWheel
## Build wheel (hold B -> category wheel -> item wheel), HoldBar hold feedback,
## keybind-following FPS prompts, and percent-to-fill-bar conversions. Pure logic is
## driven with a fake input so it runs headless; rendering is Opus's visual pass.


## Holds keys for the wheel instead of reading the keyboard.
class FakeInput extends InputState:
	var hold := {}
	var press := {}

	func held(id: String) -> bool:
		return hold.has(id)

	func act(id: String) -> bool:
		return press.has(id)


static func run(g) -> void:
	_wheel(g)
	_holdbar(g)
	_keybind_prompts()
	_sabotage_bar(g)
	_railgun_label(g)


static func _fake() -> FakeInput:
	var f := FakeInput.new()
	f.mouse = Vector2(640, 360)
	return f


static func _new_build(g) -> OperativeBuild:
	var b := OperativeBuild.new(g.structures, g.command.overlay)
	b.wheel.center = Vector2(640, 360)
	b.wheel.radius = BuildWheel.RADIUS
	return b


## Hold B for >0.2s (16 frames at 1/60) with nothing else pressed.
static func _hold_b(build: OperativeBuild, f: FakeInput, frames: int) -> void:
	f.press["op_build"] = true
	f.hold["op_build"] = true
	for i in frames:
		build.wheel.update(f, build, 1.0 / 60.0)
		f.press.clear()
	f.hold.clear()


static func _wheel(g) -> void:
	var build := _new_build(g)
	var wheel := build.wheel
	var f := _fake()
	_hold_b(build, f, 16)
	SmokeTest._check("wheel: hold B opens the category wheel", wheel.is_open())
	SmokeTest._check("wheel: categories match command-mode tabs",
		wheel.categories() == StructureDefs.TABS and wheel.categories().size() == 5,
		str(wheel.categories()))
	# Click the Weapons segment (index 1 of 5; mid-angle 18 deg).
	var mid := deg_to_rad(-90.0 + 360.0 * 1.5 / 5.0)
	f.mouse = wheel.center + Vector2(cos(mid), sin(mid)) * 120.0
	wheel.update(f, build, 1.0 / 60.0)
	SmokeTest._check("wheel: hovering the Weapons segment highlights it", wheel.hover == 1)
	f.left_released = true
	wheel.update(f, build, 1.0 / 60.0)
	f.left_released = false
	SmokeTest._check("wheel: clicking a category opens its item wheel",
		wheel.items_open and wheel.tab == 1)
	SmokeTest._check("wheel: item wheel lists exactly the tab's buildable structures",
		wheel.item_list() == ["cannon", "mortar", "beam", "sniper", "nullifier", "trebuchet"],
		str(wheel.item_list()))
	# Click the top segment (cannon).
	f.mouse = wheel.center + Vector2(0, -120)
	wheel.update(f, build, 1.0 / 60.0)
	f.left_released = true
	wheel.update(f, build, 1.0 / 60.0)
	f.left_released = false
	SmokeTest._check("wheel: clicking an item arms it and enters build mode",
		build.tool == "cannon" and build.active and not wheel.is_open(),
		"tool=%s active=%s" % [build.tool, build.active])
	# Esc cancels without changing the armed tool.
	var build2 := _new_build(g)
	var w2 := build2.wheel
	var f2 := _fake()
	build2.tool = "relay"
	_hold_b(build2, f2, 16)
	f2._pressed[KEY_ESCAPE] = true
	w2.update(f2, build2, 1.0 / 60.0)
	SmokeTest._check("wheel: Esc closes without changing the armed tool",
		not w2.is_open() and build2.tool == "relay" and not build2.active)
	# Quick tap of B keeps the old toggle behavior.
	var build3 := _new_build(g)
	var f3 := _fake()
	f3.press["op_build"] = true
	f3.hold["op_build"] = true
	build3.wheel.update(f3, build3, 1.0 / 60.0)
	f3.press.clear()
	f3.hold.clear()
	build3.wheel.update(f3, build3, 1.0 / 60.0)
	SmokeTest._check("wheel: quick-tap B toggles build mode (old behavior)",
		build3.active and not build3.wheel.is_open())
	# Releasing B after the wheel opened must not cancel it.
	var build4 := _new_build(g)
	var f4 := _fake()
	_hold_b(build4, f4, 16)
	build4.wheel.update(f4, build4, 1.0 / 60.0)
	SmokeTest._check("wheel: releasing B after open keeps the wheel",
		build4.wheel.is_open())
	# Pressing B while open closes it.
	f4.press["op_build"] = true
	build4.wheel.update(f4, build4, 1.0 / 60.0)
	SmokeTest._check("wheel: pressing B while open closes it", not build4.wheel.is_open())


static func _holdbar(g) -> void:
	var fps: FpsMode = g.fps
	fps.world = g.surface  # _recall gates on world != null (operative not deployed in smoke)
	var f := _fake()
	# R recall: 1.5s of the 2.0s hold drives the bar 0 -> 0.75.
	f.hold["recall"] = true
	for i in 3:
		fps._recall(0.5, f)
	SmokeTest._check("holdbar: holding R drives the bar fraction",
		fps.hold_label == "RECALL [%s]" % Keybinds.short("recall")
		and is_equal_approx(fps.hold_frac, 0.75),
		"%s %.2f" % [fps.hold_label, fps.hold_frac])
	# Full hold fires recall exactly once and resets the timer.
	var fired := [0]
	var old_commit: Callable = fps.commit_recall
	fps.commit_recall = func(): fired[0] += 1
	fps._recall(0.5, f)
	SmokeTest._check("holdbar: full R hold fires recall and resets",
		fired[0] == 1 and fps.recall_hold == 0.0, "fired=%d" % fired[0])
	fps.commit_recall = old_commit
	# Early release resets the timer.
	f.hold["recall"] = true
	fps._recall(0.5, f)
	f.hold.clear()
	fps._recall(0.016, f)
	SmokeTest._check("holdbar: releasing R early resets recall",
		fps.recall_hold == 0.0)
	# E hold interactable: 0.5s of a 2.0s hold -> 0.25, label from the prompt.
	var used := [0]
	var it := {
		"hold": 2.0,
		"ready": func(): return true,
		"progress": func(_frac: float, _from: Vector3): pass,
		"use": func(): used[0] += 1,
		"prompt": func(): return "[Hold E] salvage the cache",
	}
	f.hold["use"] = true
	fps._hold_use(it, f, 0.5)
	SmokeTest._check("holdbar: holding E drives the bar with the prompt label",
		is_equal_approx(fps.hold_frac, 0.25) and fps.hold_label == "SALVAGE THE CACHE [E]",
		"%s %.2f" % [fps.hold_label, fps.hold_frac])
	f.hold.clear()
	fps._hold_use(it, f, 0.016)
	SmokeTest._check("holdbar: releasing E early resets the hold timer",
		fps.hold_t == 0.0 and used[0] == 0)
	# HoldBar control: completion flashes full, then hides; hide is instant otherwise.
	var bar := HoldBar.new()
	bar.show_hold("RECALL [R]", 0.5)
	SmokeTest._check("holdbar: control shows label and fraction",
		bar.visible and is_equal_approx(bar._bar.value, 0.5) and bar._label.text == "RECALL [R]")
	bar.show_hold("RECALL [R]", 1.0)
	bar.hide_hold()
	SmokeTest._check("holdbar: hide during the completion flash is ignored", bar.visible)
	bar._process(0.4)
	SmokeTest._check("holdbar: flash ends hidden", not bar.visible)
	bar.show_hold("RECALL [R]", 0.3)
	bar.hide_hold()
	SmokeTest._check("holdbar: early release hides immediately", not bar.visible)
	bar.queue_free()


static func _keybind_prompts() -> void:
	var p := Keybinds.persist
	Keybinds.persist = false
	Keybinds.bind("use", 0, KEY_F)
	SmokeTest._check("keybinds: short('use') follows the rebind",
		Keybinds.short("use") == "F", Keybinds.short("use"))
	var s := { "alive": true, "channel": 0.0, "kind": "leech" }
	SmokeTest._check("keybinds: sabotage prompt renders the rebound key",
		EnemyBuildCrew._prompt(s, "Leech") == "[F] Sabotage the Leech (destroys it, +5 Salvage)",
		EnemyBuildCrew._prompt(s, "Leech"))
	SmokeTest._check("keybinds: armoury prompt format renders the rebound key",
		"[%s] Armoury" % Keybinds.short("use") == "[F] Armoury")
	Keybinds.reset_all()
	Keybinds.persist = p
	SmokeTest._check("keybinds: rebind restored after the test",
		Keybinds.short("use") == "E", Keybinds.short("use"))


static func _sabotage_bar(g) -> void:
	var fps: FpsMode = g.fps
	var s := { "alive": true, "channel": 1.5, "kind": "spitter" }
	var text := EnemyBuildCrew._prompt(s, "Spitter")
	SmokeTest._check("sabotage: prompt states the effect and shows no countdown/percentage",
		"destroys it" in text and not "Salvage" in text and not "%" in text and not "1.5" in text, text)
	var best := {
		"channel_frac": func() -> float: return 1.0 - 1.5 / Config.MORTAR_SABOTAGE_TIME,
		"channel_what": "Spitter",
	}
	fps._drive_channel_holdbar(best)
	SmokeTest._check("sabotage: active channel drives the HoldBar",
		fps.hold_label == "SABOTAGE SPITTER"
		and is_equal_approx(fps.hold_frac, 1.0 - 1.5 / Config.MORTAR_SABOTAGE_TIME),
		"%s %.2f" % [fps.hold_label, fps.hold_frac])
	var idle := { "channel_frac": func() -> float: return 0.0, "channel_what": "Spitter" }
	fps.hold_label = ""
	fps.hold_frac = -1.0
	fps._drive_channel_holdbar(idle)
	SmokeTest._check("sabotage: no channel means no bar",
		fps.hold_frac < 0.0)


static func _railgun_label(g) -> void:
	var w: OperativeWeapons = g.fps.weapons
	var was: String = w.current
	w.current = "railgun"
	w.advanced.charge = 0.75
	var text: String = w.advanced.label()
	SmokeTest._check("percents: railgun charge shows no percentage (HUD bar covers it)",
		not "%" in text, text)
	w.current = was
	w.advanced.charge = 0.0
