class_name Objectives
extends PanelContainer
## Objective checklist (top-left). Fires Bus.victory when every required one is done.
## Each hint says WHO can do it (Network, Units, Operative) and HOW.

const LIST := [
	{ "id": "spire", "who": "Operative", "text": "Destroy the Spore Spire", "hint": "NE Blight plateau. Drop a Beacon (Orbital tab) near the ramp south of it, press T, climb, press E at the Spire. Beams shoot its volleys down." },
	{ "id": "e1", "who": "Network", "text": "Nullify Emitter NW", "hint": "Push Relays and weapons to it, clear the creeper around it, then build a Nullifier within 4 cells. Creeper destroys it on contact." },
	{ "id": "core", "who": "Operative", "text": "Destroy the Deep Core", "hint": "Walk the Operative into the Rift (west Blight) and press E. Shoot the 3 Shield Pylons, then the Core." },
	{ "id": "e2", "who": "Network", "text": "Nullify Emitter East", "hint": "Shielded until the Deep Core dies (follow the purple link). Then nullify it." },
	{ "id": "nests", "who": "Units", "text": "Destroy all Spore Nests", "hint": "Optional, but the clock is against you: nests raid your base and breed tougher raiders every few minutes. Send units or the Operative.", "optional": true },
]
const WHO_COLORS := { "Operative": "#ffc857", "Network": "#5fd4ff", "Units": "#9dff7a" }

var items: Array[Dictionary] = []
var _text: RichTextLabel


func _init() -> void:
	add_theme_stylebox_override("panel", UiKit.style())
	position = Vector2(10, 64)
	custom_minimum_size.x = 330
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := UiKit.vbox(4)
	add_child(v)
	v.add_child(UiKit.label("OBJECTIVES", 12, UiKit.DIM))
	_text = UiKit.rich(13)
	_text.custom_minimum_size.x = 310
	v.add_child(_text)
	for o in LIST:
		var it: Dictionary = o.duplicate()
		it["done"] = false
		items.append(it)
	Bus.objective_done.connect(complete)
	_render()


func complete(id: String) -> void:
	for o in items:
		if o.id == id and not o.done:
			o.done = true
			_render()
			Sfx.play("good")
			var left := items.filter(func(i): return not i.done and not i.get("optional", false)).size()
			if left == 0:
				Bus.victory.emit()
			else:
				Bus.say("Objective complete: %s.%s" % [o.text, "" if o.get("optional", false) else " %d to go." % left], "good")


func _render() -> void:
	var lines := []
	for o in items:
		var who := "[color=%s][%s][/color] " % [WHO_COLORS[o.who], o.who]
		if o.done:
			lines.append("[color=#5a6a5a][s]%s[/s][/color]" % o.text)
		else:
			lines.append("%s%s%s\n[color=#8899aa][font_size=11]%s[/font_size][/color]" % [who, o.text, " (optional)" if o.get("optional", false) else "", o.hint])
	_text.text = "\n".join(lines)
