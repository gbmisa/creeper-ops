class_name RangeArgs
## Command-line flags after `--`: --range-test, --shot=path, --weapon=id, --ads, --look=x,y,z,
## --fire=N, --wait=s, --bots, --god, --engage=x,y,z (shot hook: Scav 1 stands there, alerted). Returns key -> value (true for bare flags).

static func parse() -> Dictionary:
	var out := {}
	for a in OS.get_cmdline_user_args():
		if not a.begins_with("--"):
			continue
		var kv := a.substr(2).split("=", true, 1)
		out[kv[0]] = kv[1] if kv.size() > 1 else true
	return out


static func vec3(text: String, fallback: Vector3 = Vector3.ZERO) -> Vector3:
	var p := text.split(",")
	if p.size() != 3:
		return fallback
	return Vector3(float(p[0]), float(p[1]), float(p[2]))
