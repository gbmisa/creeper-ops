class_name RangeTestSound
## Sound table checks for `--range-test`: every gun, calibre, class, attachment, utility item and inventory kind has all
## its events mapped to a sample that exists and loads (assets/audio/range/).

## Attachment and utility ids from the RANGE5 brief (SoundDefs must cover every one).
const ATTACHMENTS := ["reddot", "holo", "acog3x", "lpvo", "scope8x", "suppressor", "compensator", "flashhider", "vgrip", "agrip", "laser", "extmag"]
const UTIL_EVENTS := {"grapple": ["fire", "reel", "impact"], "frag": ["pin", "throw", "bounce", "blast"],
	"smoke": ["throw", "bounce", "hiss"], "flash": ["throw", "bounce", "bang", "tinnitus"], "stim": ["use"],
	"binoculars": ["raise", "lower", "zoom"]}
const KINDS := ["gun", "mag", "ammo", "armor", "rig", "backpack", "med", "attachment", "utility"]


static func run(t: RangeTest) -> void:
	var bad := []
	for id in WeaponDefs.ORDER:
		var d := WeaponDefs.of(id)
		for ev in SoundDefs.GUN_EVENTS:
			_need(bad, SoundDefs.gun_event(id, ev, d["cal"], d["class"]), "%s.%s" % [id, ev])
	t.check("sound: every gun maps all %d events" % SoundDefs.GUN_EVENTS.size(), bad.is_empty(), str(bad.slice(0, 4)))
	bad = []
	for cal in TacAmmoDefs.CALIBERS:
		for ev in ["shot", "shot_suppressed", "tail"]:
			_need(bad, SoundDefs.gun_event("", ev, cal, ""), "%s.%s" % [cal, ev])
	t.check("sound: every calibre maps shot, suppressed and tail", bad.is_empty() and SoundDefs.CAL_PROFILE.size() >= TacAmmoDefs.CALIBERS.size(), str(bad.slice(0, 4)))
	bad = []
	for cls in ["pistol", "smg", "assault rifle", "shotgun", "marksman", "bolt-action", "lmg"]:
		for ev in SoundDefs.GUN_EVENTS:
			_need(bad, SoundDefs.gun_event("", ev, "", cls), "%s.%s" % [cls, ev])
	t.check("sound: every gun class falls back to a full event set", bad.is_empty(), str(bad.slice(0, 4)))
	bad = []
	for a in ATTACHMENTS:
		for ev in ["fit", "remove"]:
			_need(bad, SoundDefs.ATTACH.get(a, {}).get(ev, ""), "%s.%s" % [a, ev])
	t.check("sound: every attachment has fit and remove", bad.is_empty(), str(bad.slice(0, 4)))
	bad = []
	for u in UTIL_EVENTS:
		for ev in UTIL_EVENTS[u]:
			_need(bad, SoundDefs.UTILITY.get(u, {}).get(ev, ""), "%s.%s" % [u, ev])
	t.check("sound: every utility item has its events", bad.is_empty(), str(bad.slice(0, 4)))
	bad = []
	for k in KINDS:
		for ev in ["pick", "drop", "move"]:
			_need(bad, SoundDefs.INVENTORY.get(k, {}).get(ev, ""), "%s.%s" % [k, ev])
	t.check("sound: inventory pick/drop/move per item kind", bad.is_empty(), str(bad.slice(0, 4)))
	t.check("sound: suppressed shots differ from unsuppressed", SoundDefs.gun_event("ak47", "shot") != SoundDefs.gun_event("ak47", "shot_suppressed"))
	t.check("sound: .44 and 12 ga have their own reports", SoundDefs.gun_event("revolver", "shot") != SoundDefs.gun_event("m1911", "shot") and SoundDefs.gun_event("shotgun", "shot") != SoundDefs.gun_event("sniper", "shot"))

	var pings := 0
	for g in WeaponDefs.ROWS:
		for ev in ["mag_out", "mag_in", "action", "dry", "mode"]:
			if SoundDefs.gun_event(g, ev, WeaponDefs.of(g)["cal"], WeaponDefs.of(g)["class"]) == "garand_ping":
				pings += 1
	t.check("sound: garand_ping is never a reload/mechanical sound; only the Garand pings on the last shot", pings == 0 and SoundDefs.PING_GUNS == ["garand"] and not "revolver" in SoundDefs.PING_GUNS)
	var tp: AudioStream = RangeAudio.stream(SoundDefs.PROFILES["smg57"]["tail"])
	var gp: AudioStream = RangeAudio.stream("garand_ping")
	t.check("sound: P90 tail is one report (no baked burst); Garand ping is short", tp != null and tp.get_length() < 0.15 and gp != null and gp.get_length() < 0.3)


static func _need(bad: Array, stem: String, label: String) -> void:
	if stem == "" or RangeAudio.stream(stem) == null:
		bad.append("%s -> '%s'" % [label, stem])
