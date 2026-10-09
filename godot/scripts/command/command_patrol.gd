class_name CommandPatrol
## The Patrol command: select units, press the Patrol key, left-click points, then press the
## key again or right-click to finish (Esc cancels). The loop is handed to UnitPatrol.


static func hint() -> String:
	return "Patrol: click route points, [%s] or right-click to finish, Esc cancels." % Keybinds.short("patrol")


static func toggle(cm: CommandMode) -> void:
	if cm.tool == "@patrol":
		finish(cm)
	elif cm.units.selected.is_empty():
		Bus.say("Select units first, then press [%s] to set a patrol." % Keybinds.short("patrol"), "warn")
		Sfx.play("deny")
	else:
		cm.set_tool("@patrol")
		Bus.say(hint(), "info")


static func add_point(cm: CommandMode, p: Vector3) -> void:
	cm.units.lines.pending.append(Vector2(p.x, p.z))
	Sfx.play("click")


static func finish(cm: CommandMode) -> void:
	var pts: Array = cm.units.lines.pending.duplicate()
	if not pts.is_empty():
		Bus.metric.emit("order", {})
		UnitPatrol.assign(cm.units, cm.units.selected, pts)
		Sfx.play("good")
	cm.set_tool("")
