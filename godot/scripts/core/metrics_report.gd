class_name MetricsReport
extends RefCounted
## `--metrics-report[=N] [--metrics-dir=D]`: one line per recorded mission (newest N) plus
## per-level averages. Reads the JSON files PlayMetrics wrote; prints only.


static func run(args: Dictionary) -> void:
	var dir := str(args.get("metrics-dir", "user://metrics"))
	var n := int(args["metrics-report"]) if str(args["metrics-report"]) != "" else 10
	var files := Array(DirAccess.get_files_at(dir)).filter(func(f): return f.ends_with(".json"))
	files.sort()
	files = files.slice(maxi(0, files.size() - n))
	if files.is_empty():
		print("[metrics] no missions in ", dir)
		return
	var by_level := {}
	for f in files:
		var data = JSON.parse_string(FileAccess.get_file_as_string("%s/%s" % [dir, f]))
		if not (data is Dictionary) or not data.has("summary"):
			continue
		var s: Dictionary = data.summary
		print(line(f, s))
		var key := str(s.get("level_name", s.get("level", "?")))
		if not by_level.has(key):
			by_level[key] = []
		by_level[key].append(s)
	for key in by_level:
		print(average(key, by_level[key]))


static func _pct(part: float, whole: float) -> float:
	return 100.0 * part / maxf(whole, 0.001)


static func line(f: String, s: Dictionary) -> String:
	var modes: Dictionary = s.get("time_in_mode", {})
	var dur := float(s.duration)
	var fps_t := float(modes.get("surface", 0.0)) + float(modes.get("cave", 0.0))
	return "[metrics] %s | %s %s | %dm%02ds | first loss %s | deaths %d | lost creeper/other %d/%d | starved %d%% | full bank %d%% | cmd/fps %d%%/%d%%" % [
		f, s.level_name, s.result, floori(dur / 60.0), floori(fmod(dur, 60.0)),
		"none" if float(s.first_loss) < 0.0 else "%ds" % roundi(s.first_loss), s.operative_deaths,
		s.lost_to_creeper, s.lost_to_other, _pct(s.starved_time, dur), _pct(s.full_bank_time, dur),
		_pct(modes.get("command", 0.0), dur), _pct(fps_t, dur)]


static func average(key: String, rows: Array) -> String:
	var dur := 0.0
	var deaths := 0.0
	var creeper := 0.0
	var other := 0.0
	var starved := 0.0
	var full := 0.0
	var wins := 0
	for s in rows:
		dur += float(s.duration)
		deaths += float(s.operative_deaths)
		creeper += float(s.lost_to_creeper)
		other += float(s.lost_to_other)
		starved += _pct(s.starved_time, s.duration)
		full += _pct(s.full_bank_time, s.duration)
		wins += 1 if s.result == "won" else 0
	var c := float(rows.size())
	return "[metrics] AVG %s (%d missions, %d won) | %dm%02ds | deaths %.1f | lost creeper/other %.1f/%.1f | starved %d%% | full bank %d%%" % [
		key, rows.size(), wins, floori(dur / c / 60.0), floori(fmod(dur / c, 60.0)), deaths / c, creeper / c, other / c, starved / c, full / c]
