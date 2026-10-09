class_name Debug
## Dev/test hooks from command-line user args (after "--"), e.g.
##   godot --path godot -- --demo --units --sim=600 --shot=/tmp/a.png
##   --autostart   skip briefing, land the Node at the suggested site
##   --demo        autostart + scripted base (relay chain to Emitter NW, nullifier, defences);
##                 --demo=slow places it unbuilt so packets must deliver everything.
##                 It also hooks one Salvage Engine (the nearest safe one, every socket, no Operative
##                 walking) after DebugEngines.DEMO_HOOK_AT seconds, with a free relay chain, so the
##                 shipping loop runs in sims
##   --units       autostart + a squad sent at the central nest
##   --surface / --spire   drop the Operative near the Rift / at the Spire ramp
##   --cave        go straight into the cave       --killcore  destroy pylons + Core
##   --fast        8x sim speed                    --nocapture don't capture the mouse
##   --look=x,z[,d[,p]] point the command camera at a cell (d = zoom distance, p = pitch rad)   --rocket  Operative fires a rocket
##                 just before --shot
##   --sim=N       fast-forward N seconds, print a [sim] report
##   --seed=N      seed the global RNG first (deterministic sims)
##   --snipe3      playtest-2 defence script: lean economy at once, 3 snipers by the Node at t=180
##   --raidprobe   during --sim, print [probe] lines every 5 s: raider counts, first contact, per-nest spawns
##   --metrics=PATH  write this run's play metrics (a .json file or a folder)
##   --metrics-report[=N] [--metrics-dir=D]  print the last N recorded missions and per-level averages
##   --smoke       run scripted mechanics checks (smoke_test.gd)
##   --tool=T      hold a build tool (screenshots of the ghost/overlays)
##   --drag=T,x0,z0,x1,z1  drag-build preview of T from one cell to another
##   --salvage=N   set the Salvage stockpile
##   --ore=N       set the Ore stockpile
##   --armoury=id[,id...]  grant those upgrades free (unlock_railgun or railgun).
##                 id "open" shows the first-person Armoury at the Node; "fire" holds
##                 the trigger on an unlocked advanced weapon just before --shot
##   --landing     dismiss the briefing and stop at the landing-site choice
##   --briefing    keep the briefing up (screenshots)  --ended=won|lost  show the end screen before --shot
##   --hover=x,z   put the (fake) cursor over a cell
##   --select=T    select the first structure of type T (T=all-weapons: every movable weapon)
##   --keys        open the Controls (keybind) menu
##   --gpu-parity / --perf-sim=N   GPU creeper sim checks (SimBench; need a display)
##   --cpu-sim     force the CPU creeper sim
##   --level=N     play Level N (1 Hollow Ridge, 2 The Crown Marches); see Levels
##   --raise=x,z,r,by   raise (negative: lower) a disc of terrain through TerrainEdit
##   --unlock=id[,id]  add ids to this level's unlock list (e.g. terp)
##   --paint=x,z,x2,z2,level  paint a Terp target rectangle (whole levels)
##   --terp=x,z   place a finished Terp and give it energy to dig
##   --fpsbuild=T  Operative near the base in first-person build mode holding structure T
##   --turrets=I   castle I held with a Repeater, Lobber and Flak on its first sockets
##   --raid=I[,S]  castle I held; its reprisal raid marches in S seconds (default 20)
##   --castle=I[,spot]  drop the Operative at castle I: climb (pillar route, default), pad
##                 (spire jump pad), top (spire top), gate (outside the gate)
##   --castle2=I[,spot] / --stage=I,N / --held=I   concentric castles (CastleDebug)
##   --guardsfire  every Sentinel is ready to fire now (screenshots of a bolt in flight)
##   --gallery     one of every structure, unit and raider tier in rows (art screenshots)
##   --gallery=anim  every creature model id in a row with labels, cycling animation
##                 clips every 2 s (art screenshots of the .glb work; procedural fallback
##                 when no .glb is present)
##   --gallery=anim:<id>  close-up of one model id, camera on its AABB centre
##   --creatures   one of each raider tier in a row near the command node, idle clips
##                 playing (in-situ art screenshots of the .glb work; A2)
##   --creatures=near  also a row of the six hive part models behind them (A3)
##   --ranged      a Spitter and a Lancer on a flat pad, firing (projectile screenshot)
##   --burrow      a Warden ring and a Burrower dust trail    --mortar  enemy mortar and its shell ring
##   --fire=rifle|sprayer|rocket  (with --surface) hold the trigger so --shot catches the weapon firing
##   --ammo=ap|inc  unlock improved ammo, crossbow loaded with that grade (HUD shows [AP]/[INC])
##   --cheat-guns  unlock every Operative weapon from the start (cheat; testing only)
##   --engine=I[,hold|hooked|top[,S]]  Operative at Salvage Engine I (hold: mid-hook; hooked: all sockets
##                 hooked with a relay chain; top: on its roof). See debug_engines.gd
##   --shot=PATH   save a screenshot after ~1.5 s and quit;  --quit=S  quit after S seconds
##   --tour=PATH   screenshot tour: one framed shot per line of PATH (see
##                 docs/tasks/MUSE_S_shot_tour.md); quits after the last line
##   --tour-orbit=id,N  N shots orbiting gallery model id at 360/N degree steps,
##                 named <dir>/<id>_<k>.png with --shot giving the directory

const DEMO_BUILD := [
	["relay", 34, 58], ["relay", 28, 48], ["relay", 27, 36], ["relay", 24, 24], ["relay", 19, 14], ["nullifier", 17, 14],
	["collector", 34, 63], ["collector", 46, 63], ["collector", 40, 59], ["collector", 35, 70], ["collector", 45, 70],
	["cannon", 33, 56], ["cannon", 47, 57], ["cannon", 40, 55], ["cannon", 29, 50], ["mortar", 37, 59],
	["beam", 44, 60], ["reactor", 43, 62], ["storage", 37, 63], ["barracks", 47, 66],
	["sniper", 36, 56], ["sniper", 44, 56],
	["sniper", 40, 57], ["sniper", 32, 58], ["sniper", 48, 58], ["beam", 38, 59], ["beam", 42, 59],
	["sniper", 34, 55], ["sniper", 46, 55], ["beam", 36, 57],
	["cannon", 35, 61], ["cannon", 41, 61], ["cannon", 31, 62], ["cannon", 49, 62],
	["reactor", 36, 66], ["reactor", 40, 66], ["reactor", 44, 66], ["reactor", 36, 69], ["reactor", 44, 69], ["storage", 40, 69],
]


static func apply(g) -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	if args.is_empty():
		return
	print("[debug] ", args)
	PlayMetrics.persist = false  # debug runs never write to the player's metrics folder
	PlayMetrics.out_path = str(args.get("metrics", ""))
	if args.has("seed"):  # --seed=N: deterministic sims (nest timers, spawn picks, shots)
		seed(int(args.seed))
		print("[debug] seed ", int(args.seed))
	if args.has("metrics-report"):
		MetricsReport.run(args)
		g.get_tree().quit()
		return
	Bus.log_msg.connect(func(t, k): print("[log:%s] %s" % [k, t]))
	if args.has("nocapture") or args.has("shot") or args.has("tour") or args.has("tour-orbit"):
		g.ignore_capture = true
	var auto := ["autostart", "demo", "units", "surface", "spire", "cave", "castle", "castle2", "engines", "raid", "gallery", "creatures", "sim", "shot", "tour", "tour-orbit", "smoke", "engine"].any(func(k): return args.has(k))
	if args.has("landing"):
		g.flow.begin()  # stop at the landing-site choice
	elif auto and not args.has("briefing"):
		g.flow.begin()
		var hint: Vector2i = g.level.landing_hint
		g.flow.land(hint)
	if args.has("fast"):
		g.time_scale = 8.0
	if args.has("demo"):
		for b in g.level.get("demo", DEMO_BUILD):  # --demo=slow: unbuilt, so every packet must really be delivered
			g.structures.place(b[0], b[1], b[2], args.demo != "slow")
		DebugEngines.demo(g)  # scripted: hooks the nearest safe Salvage Engine after DEMO_HOOK_AT seconds
	if args.has("snipe3"):  # --snipe3: playtest-2 defence script: working economy now, 3 snipers by the Node at t=180
		var hint3: Vector2i = g.level.landing_hint  # mesa top is ~(80,146) r10: keep everything within 8 cells of it
		for b in [["collector", 74, 146], ["collector", 86, 146], ["collector", 80, 141], ["collector", 80, 151],
				["collector", 76, 143], ["collector", 84, 143], ["collector", 76, 149], ["collector", 84, 149],
				["reactor", 78, 144], ["reactor", 82, 144], ["reactor", 78, 148], ["reactor", 82, 148],
				["storage", 80, 150], ["beam", 78, 140], ["beam", 82, 140]]:
			var s = g.structures.place(b[0], int(b[1]), int(b[2]), true)
		g.set_meta("snipe3", { "placed": false,
			"snipers": [["sniper", 76, 140], ["sniper", 84, 140], ["sniper", 80, 138]] })
	if args.has("units"):
		var p: Vector3 = g.structures.command_node().pos
		var squad := []
		for i in 6:
			var hint: Vector2i = g.level.landing_hint
			var b: Structure = g.structures.nearest_to(hint.x, hint.y, func(s): return s.type == "barracks")
			var u: Unit = g.units.spawn("soldier" if i < 4 else "crawler", p.x - 6 + i * 2.4, p.z - 12)
			u.home = b
			squad.append(u)
		var tgt: Vector2i = g.level.get("demo_target", Vector2i(40, 27))
		var c: Vector3 = g.level.grid.cell_ground(tgt.x, tgt.y)
		g.units.order(squad, Vector2(c.x, c.z), true)
	if args.has("surface"):
		# +16, not +12: rift.x+12 drops the Operative 2.6 m from Engine e5's great
		# bronze gear (faces it point-blank). +16 keeps the Rift in view with clearance.
		DebugHooks._drop(g, g.level.rift.x + 16, g.level.rift.z, PI / 2.0)
	if args.has("spire"):
		var st: Vector2i = g.level.get("spire_totem", Vector2i(61, 37))
		DebugHooks._drop(g, st.x, st.y, 0.0)
	if args.has("fpsbuild"):  # --fpsbuild=T: Operative near the base in build mode holding T
		DebugHooks._drop(g, g.level.landing_hint.x, g.level.landing_hint.y - 4, 0.0)
		g.fps.controller.pitch = -0.45
		g.fps.builder.toggle(true)
		g.fps.builder.tool = args.fpsbuild
	if args.has("castle"):
		DebugHooks._castle(g, args.castle.split(","))
	CastleDebug.apply(g, args)  # Stage 21: --castle2, --stage, --held
	if args.has("turrets"):  # --turrets=I: castle I held, one of each turret type armed
		var c: Dictionary = g.castles.list[int(args.turrets)]
		StrongholdRules.to_held(g.surface, c, g.castles.lays[c.id])
		g.stockpile.salvage = 999.0
		for i in CastleTurrets.ORDER.size():
			CastleTurrets.buy(c, i, CastleTurrets.ORDER[i], g.stockpile)
		StrongholdMeshes.refresh(g.castles.views[c.id], c)
	if args.has("raid"):  # --raid=I[,S]: castle I held, reprisal in S seconds
		var p: PackedStringArray = args.raid.split(",")
		var rc: Dictionary = g.castles.list[int(p[0])]
		StrongholdRules.to_held(g.surface, rc, g.castles.lays[rc.id])
		StrongholdMeshes.refresh(g.castles.views[rc.id], rc)
		g.castle_raids.update(0.0)
		rc.raid.warn = float(p[1]) if p.size() > 1 else 20.0
	if args.has("guardsfire"):
		for s in g.guards.list:
			s.cd = 0.0
	if args.has("cave"):
		Bus.enter_cave.emit()
	if args.has("killcore"):
		g.cave_hazards.kill_all()
	if args.has("gallery"):
		Gallery.run(g, args.gallery)
	if args.has("creatures"):
		CreatureGallery.spawn_near_base(g, str(args.creatures))
	if args.has("ranged"):
		RaiderShots.demo(g)
	if args.has("burrow"):
		RaiderBurrow.demo(g)
	if args.has("mortar"):
		EnemyMortars.demo(g)
	if args.has("noflyers"):
		FlyerLaunch.enabled = false
	if args.has("t0"):  # --t0=S: start the mission clock at S seconds (pressure for balance sims)
		g.hazards.nests.time = float(args.t0)
	if args.has("flyers"):
		FlyerLaunch.demo(g, args.flyers)
	if args.has("ammo"):  # --ammo=ap|inc: unlock improved ammo and select that crossbow grade
		AmmoGrades.unlocked = true
		AmmoGrades.op.rifle = str(args.ammo) if str(args.ammo) in ["ap", "inc"] else "std"
	if args.has("cheat-guns"):  # cheat: every Operative weapon unlocked from the start
		OperativeUpgrades.cheat_guns = true
	if args.has("engine"):
		DebugEngines.apply(g, str(args.engine))
	if args.has("look"):
		var xz: PackedStringArray = args.look.split(",")
		g.command.cam.focus(g.level.grid.cell_ground(int(xz[0]), int(xz[1])))
		g.command.cam.dist = float(xz[2]) if xz.size() > 2 else 55.0
		if xz.size() > 3:
			g.command.cam.pitch = float(xz[3])
	if args.has("gpu-parity") or args.has("perf-sim"):
		SimBench.run(g, args)
		return
	if args.has("raise"):  # --raise=x,z,r,by: TerrainEdit a disc (terrain edit screenshots)
		var p: PackedStringArray = args.raise.split(",")
		var cells: Array[Vector2i] = g.surface.grid.cells_in_radius(int(p[0]), int(p[1]), float(p[2]))
		TerrainEdit.raise(g.surface, cells, float(p[3]), Grid.Mat.EARTH)
	if args.has("salvage"):
		g.stockpile.salvage = float(args.salvage)
	if args.has("ore"):
		g.stockpile.ore = float(args.ore)
	if args.has("unlock"):
		for id in str(args.unlock).split(","):
			StructureDefs.grant_unlock(g.level, id.strip_edges())
	if args.has("paint") or args.has("terp"):
		TerpPaint.debug_scene(g, args)
	if args.has("armoury"):
		DebugHooks._armoury(g, str(args.armoury))
	if args.has("smoke"):
		SmokeTest.only = str(args.smoke)
		SmokeTest.run(g)
	if args.has("sim"):
		DebugHooks._fast_forward(g, float(args.sim))
	if args.has("drag"):  # --drag=T,x0,z0,x1,z1: drag-build preview (DragBuild screenshots)
		var d: PackedStringArray = args.drag.split(",")
		g.command.set_tool(d[0])
		g.command.drag_plan = DragBuild.plan(g.command, Vector2i(int(d[1]), int(d[2])), Vector2i(int(d[3]), int(d[4])))
		g.command.overlay.show_plan(g.command.drag_plan, d[0])
	if args.select == "all-weapons" if args.has("select") else false:
		var all: Array[Structure] = []
		all.assign(g.structures.list.filter(func(x): return x.def.get("movable", false) and x.type != "node"))
		g.command.select_structure(all[0] if not all.is_empty() else null)
		g.command.group = all
	elif args.has("select"):
		var s: Structure = g.structures.nearest_to(0, 0, func(x): return x.type == args.select)
		g.command.select_structure(s)
	if args.has("tool"):
		g.command.set_tool(args.tool)
		for i in StructureDefs.TABS.size():
			if (StructureDefs.MENU[StructureDefs.TABS[i]] as Array).has(args.tool):
				g.hud.build.show_tab(i)
	if args.has("hover"):  # fake the cursor over a cell (ghost/overlay screenshots)
		var hz: PackedStringArray = args.hover.split(",")
		g.get_tree().create_timer(0.3).timeout.connect(func():
			var p: Vector3 = g.level.grid.cell_ground(int(hz[0]), int(hz[1]))
			g.input.mouse = g.command.cam.unproject_position(p))
	if args.has("rocket"):  # Operative fires a rocket just before the screenshot
		g.get_tree().create_timer(1.15).timeout.connect(func():
			if g.fps.world == null:
				return
			var w = g.fps.weapons
			w.current = "rocket"
			var d: Vector3 = -w.camera.global_transform.basis.z
			w.launcher.fire(g.fps.world, w.gun.global_position + d * 0.4, (d + Vector3(0, -0.12, 0)).normalized()))
	if args.has("fire"):  # --autostart --fire=rifle|sprayer|rocket: trigger held for the --shot
		DebugFire.run(g, str(args.fire))
	if args.has("keys"):
		g.hud.keys.open()
	if args.has("ended"):
		g.flow.end_game(args.ended == "won")
	if args.has("tour"):
		ShotTour.start_file(g, str(args.tour))
	elif args.has("tour-orbit"):
		ShotTour.start_orbit(g, str(args["tour-orbit"]), str(args.get("shot", "")))
	elif args.has("shot"):
		DebugHooks._screenshot_later(g, args.shot)
	elif args.has("quit"):
		g.get_tree().create_timer(float(args.quit)).timeout.connect(func(): g.get_tree().quit())
