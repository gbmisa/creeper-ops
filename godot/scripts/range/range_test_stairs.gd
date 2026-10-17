class_name RangeTestStairs
## F137: every "stairs" ramp in Skirmish 2 can be walked up and back down by the real player controller
## (forward key held, no jumping), and its slope stays under the player's floor_max_angle.


static func _ramps(root: Node) -> Array:
	var out: Array = []
	for n in root.find_children("*", "StaticBody3D", true, false):
		var sb := n as StaticBody3D
		if not sb.has_meta("ramp"):
			continue
		var len := 0.0
		for c in sb.get_children():
			if c is CollisionShape3D and (c as CollisionShape3D).shape is BoxShape3D:
				len = ((c as CollisionShape3D).shape as BoxShape3D).size.z
		if len <= 0.0:
			continue
		var dir := -sb.global_transform.basis.z
		var mid := sb.global_position + sb.global_transform.basis.y * 0.15
		out.append({"lo": mid - dir * len * 0.5, "hi": mid + dir * len * 0.5, "dir": dir})
	return out


## Returns the final position with the highest y reached in .y of `peak` (a ramp that ends in a step down still counts as climbed).
static func _walk(t: RangeTest, p: TacticalPlayer, input: InputState, from: Vector3, dir: Vector3, frames: int) -> Array:
	p.global_position = from
	p.velocity = Vector3.ZERO
	p.rotation.y = atan2(-dir.x, -dir.z)   # forward = -Z of the body
	p.yaw = p.rotation.y
	input.frame._held["t_forward"] = true
	var peak := from.y
	for i in frames:
		await t.get_tree().physics_frame
		peak = maxf(peak, p.global_position.y)
	input.frame._held.clear()
	return [p.global_position, peak]


static func run(t: RangeTest) -> void:
	var game := SkirmishLargeGame.new()
	t.add_child(game)
	game.build_world()
	var session := RangeSession.new(7)
	var input := InputState.new()
	t.add_child(input)
	input.set_process(false)
	var p := TacticalPlayer.new()
	p.input = input
	p.session = session
	session.add_player(1, true).node = p
	t.add_child(p)
	await t.get_tree().physics_frame
	var ramps := _ramps(game)
	var ang := rad_to_deg(p.floor_max_angle)
	for r in ramps:
		var lo: Vector3 = r["lo"]
		var hi: Vector3 = r["hi"]
		var dir: Vector3 = r["dir"]
		var tag := "(%.0f,%.1f,%.0f)->(%.0f,%.1f,%.0f)" % [lo.x, lo.y, lo.z, hi.x, hi.y, hi.z]
		var slope := rad_to_deg(asin(clampf(dir.y, -1.0, 1.0)))
		t.check("stairs %s slope %.1f under floor_max_angle %.0f" % [tag, slope, ang], slope < ang - 8.0)
		var frames := int((hi - lo).length() / 3.0 * 60.0) + 90
		var flat := Vector3(dir.x, 0, dir.z).normalized()
		var up: Array = await _walk(t, p, input, lo - flat * 0.5 + Vector3(0, 0.1, 0), flat, frames)
		t.check("stairs %s walks up (top y %.2f, peak %.2f)" % [tag, hi.y, up[1]], up[1] > hi.y - 0.35)
		var down: Array = await _walk(t, p, input, hi - flat * 0.5 + Vector3(0, 0.1, 0), -flat, frames)
		t.check("stairs %s walks down (reached y %.2f)" % [tag, down[0].y], down[0].y < lo.y + 0.35)
	p.queue_free()
	input.queue_free()
	game.queue_free()
