class_name SmokeMetrics
## PlayMetrics checks: events, sample interval, summary, persist=false and --metrics= writes.


static func run(g) -> void:
	var sm: StructureManager = g.structures
	var was_persist := PlayMetrics.persist
	PlayMetrics.persist = false
	PlayMetrics.out_path = ""
	var m := PlayMetrics.new(g)
	var s := sm.place("relay", 30, 70)  # not instant: a "placed" event
	sm.place("relay", 32, 70, true)
	var victim := sm.place("collector", 36, 70, true)
	victim.wet = Config.MIN_DEPTH * 2.0
	sm.remove(victim, "destroyed")
	var d: OperativeDeploy = g.deploy
	var deaths := d.deaths
	Bus.operative_down.emit()
	d.down = false  # undo the real respawn bookkeeping
	d.deaths = deaths
	d.respawn_left = 0.0
	g.flow.to_command("")
	var kinds := m.events.map(func(e): return e.kind)
	SmokeTest._check("metrics: build event", kinds.has("placed"))
	SmokeTest._check("metrics: loss by creeper event", m.events.any(func(e): return e.kind == "structure_lost" and e.type == "collector" and e.wet))
	SmokeTest._check("metrics: operative down event", kinds.has("operative_down"))
	var before := m.samples.size()
	m.tick(Config.METRICS_SAMPLE * 2.5)
	SmokeTest._check("metrics: samples at interval", m.samples.size() - before == 2, "(%d)" % (m.samples.size() - before))
	var smp: Dictionary = m.samples.back()
	SmokeTest._check("metrics: sample fields", smp.has("pressure") and smp.has("creeper_cells") and smp.structures.has("node") and smp.node_hp > 0.0)
	var sum := MetricsSummary.build(m, "node_destroyed")
	SmokeTest._check("metrics: summary sane", sum.result == "lost" and sum.operative_deaths == 1 and sum.lost_to_creeper == 1
		and absf(sum.duration - Config.METRICS_SAMPLE * 2.5) < 0.2 and sum.first_loss >= 0.0 and sum.apm > 0.0)
	var dir := OS.get_cache_dir() + "/creeper_ops_smoke_metrics"
	var n_user := _count("user://metrics")
	m.finish("end")
	SmokeTest._check("metrics: persist=false writes nothing", m.saved_path == "" and _count("user://metrics") == n_user)
	var m2 := PlayMetrics.new(g)
	PlayMetrics.out_path = dir + "/smoke.json"
	m2.tick(30.0)
	m2.finish("end")
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(dir + "/smoke.json"))
	SmokeTest._check("metrics: --metrics= round trip", parsed is Dictionary and parsed.has("summary") and parsed.samples.size() >= 3 and parsed.events is Array)
	PlayMetrics.out_path = ""
	PlayMetrics.persist = was_persist
	sm.remove(s)


static func _count(path: String) -> int:
	var dir := DirAccess.open(path)
	return dir.get_files().size() if dir else 0
