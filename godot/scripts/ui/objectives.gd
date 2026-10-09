class_name Objectives
extends PanelContainer
## Objective checklist (top-left). Compact (open objectives, title only) until
## `objectives_toggle`. Fires Bus.victory when every required one is done.
## Each hint says WHO can do it (Network, Units, Operative) and HOW.

const LIST := [
	{ "id": "spire", "who": "Operative", "text": "Destroy the Spore Spire", "hint": "NE Blight plateau. Drop a Totem (Orbital tab) near the ramp south of it, press T, climb, press E at the Spire. Or use Drop to pod in. Beams shoot its volleys down." },
	{ "id": "e1", "who": "Network", "text": "Nullify Emitter NW", "hint": "Push Relays and weapons to it, clear the creeper around it, then build a Nullifier within 10 cells. Creeper destroys it on contact." },
	{ "id": "core", "who": "Operative", "text": "Destroy the Deep Core", "hint": "Walk the Operative into the Rift (west Blight) and press E. Shoot the 3 Shield Pylons, then the Core." },
	{ "id": "e2", "who": "Network", "text": "Nullify Emitter East", "hint": "Shielded until the Deep Core dies (follow the purple link). Then nullify it." },
	{ "id": "nests", "who": "Units", "text": "Destroy all Spore Nests", "hint": "Optional, but the clock is against you: nests raid your base and breed tougher raiders every few minutes. Send units or the Operative.", "optional": true },
]
const WHO_COLORS := { "Operative": "#ffc857", "Network": "#5fd4ff", "Units": "#9dff7a" }

var items: Array[Dictionary] = []
var expanded := false  # command mode; first person has its own flag and starts closed
var _head: Label
var _text: RichTextLabel
var _fps_open := false
var _in_fps := false
var _full := false
var _seen := {}
var _flash := {}  # id -> seconds of hint still showing


func _init(rows: Array = LIST) -> void:
	add_theme_stylebox_override("panel", UiKit.style())
	position = Vector2(10, 100)  # below the two-row top bar
	custom_minimum_size.x = 330
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := UiKit.vbox(4)
	add_child(v)
	_head = UiKit.label("OBJECTIVES", 12, UiKit.DIM)
	v.add_child(_head)
	_text = UiKit.rich(13)
	_text.custom_minimum_size.x = 310
	v.add_child(_text)
	for o in rows:
		var it: Dictionary = o.duplicate()
		it["done"] = false
		items.append(it)
		_seen[it.id] = true  # the list you start with is not a newly appeared objective
	Bus.objective_done.connect(complete)
	_render()


func complete(id: String) -> void:
	for o in items:
		if o.id == id and not o.done:
			o.done = true
			_flash[id] = Config.HUD_OBJ_FLASH
			_render()
			Sfx.play("good")
			var left := items.filter(func(i): return not i.done and not i.get("optional", false)).size()
			if left == 0:
				Bus.victory.emit()
			else:
				Bus.say("Objective complete: %s.%s" % [o.text, "" if o.get("optional", false) else " %d to go." % left], "good")


func refresh(dt: float, input: InputState, in_fps: bool) -> void:
	var dirty := false
	if in_fps and not _in_fps:
		_fps_open = false
	if in_fps != _in_fps:
		_in_fps = in_fps
		dirty = true
	if input.act("objectives_toggle"):
		if in_fps:
			_fps_open = not _fps_open
		else:
			expanded = not expanded
		dirty = true
	var full := _fps_open if in_fps else expanded
	if full != _full:
		_full = full
		dirty = true
	for id in _flash.keys():
		var left := float(_flash[id]) - dt
		if left <= 0.0:
			_flash.erase(id)
			dirty = true
		else:
			_flash[id] = left
	for o in items:
		if not _seen.has(o.id):
			_seen[o.id] = true
			_flash[o.id] = Config.HUD_OBJ_FLASH
			dirty = true
	if dirty:
		_render()


func _render() -> void:
	_head.text = "OBJECTIVES  [%s]" % Keybinds.short("objectives_toggle")
	var lines: PackedStringArray = []
	for o in items:
		var flashing := float(_flash.get(o.id, 0.0)) > 0.0
		if o.done and not _full and not flashing:
			continue
		if o.done and _full and not flashing:
			lines.append("[color=#5a6a5a][s]%s[/s][/color]" % o.text)
			continue
		var body := _title(o)
		if o.done:
			body = "[color=#5a6a5a][s]%s[/s][/color]" % o.text
		if _full or flashing:
			lines.append("%s\n[color=#8899aa][font_size=11]%s[/font_size][/color]" % [body, o.hint])
		else:
			lines.append(body)
	_text.text = "\n".join(lines)


func _title(o: Dictionary) -> String:
	var who := "[color=%s][%s][/color] " % [WHO_COLORS[o.who], o.who]
	return "%s%s%s" % [who, o.text, " (optional)" if o.get("optional", false) else ""]
