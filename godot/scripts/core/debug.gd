class_name Debug
## Dev/test hooks from command-line user args (after "--"), e.g.
##   godot --path godot -- --demo --units --sim=600 --shot=/tmp/a.png
##   --autostart   skip briefing, land the Node at the suggested site
##   --demo        autostart + scripted base (relay chain to Emitter NW, nullifier, defences);
##                 --demo=slow places it unbuilt so packets must deliver everything
##   --units       autostart + a squad sent at the central nest
##   --surface / --spire   drop the Operative near the Rift / at the Spire ramp
##   --cave        go straight into the cave       --killcore  destroy pylons + Core
##   --fast        8x sim speed                    --nocapture don't capture the mouse
##   --look=x,z[,d[,p]] point the command camera at a cell (d = zoom distance, p = pitch rad)   --rocket  Operative fires a rocket
##                 just before --shot
##   --sim=N       fast-forward N seconds, print a [sim] report
##   --smoke       run scripted mechanics checks (smoke_test.gd)
##   --tool=T      hold a build tool (screenshots of the ghost/overlays)
##   --drag=T,x0,z0,x1,z1  drag-build preview of T from one cell to another
##   --salvage=N   set the Salvage stockpile
##   --ore=N       set the Ore stockpile
##   --armoury=id[,id...]  grant those upgrades free (unlock_railgun or railgun).
##                 id "open" shows the first-person Armoury at the Node; "fire" holds
##                 the trigger on an unlocked advanced weapon just before --shot
##   --landing     dismiss the briefing and stop at the landing-site choice
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
##   --guardsfire  every Sentinel is ready to fire now (screenshots of a bolt in flight)
##   --gallery     one of every structure, unit and raider tier in rows (art screenshots)
##   --ranged      a Spitter and a Lancer on a flat pad, firing (projectile screenshot)
##   --burrow      a Warden ring and a Burrower dust trail    --mortar  enemy mortar and its shell ring
##   --engine=I[,hold|hooked|top[,S]]  Operative at Salvage Engine I (hold: mid-hook; hooked: all sockets
##                 hooked with a relay chain; top: on its roof). See debug_engines.gd
##   --shot=PATH   save a screenshot after ~1.5 s and quit;  --quit=S  quit after S seconds

const DEMO_BUILD := [
	["relay", 34, 58], ["relay", 28, 48], ["relay", 27, 36], ["relay", 24, 24], ["relay", 19, 14], ["nullifier", 17, 14],
	["collector", 34, 63], ["collector", 46, 63], ["collector", 40, 59], ["collector", 35, 70], ["collector", 45, 70],
	["cannon", 33, 56], ["cannon", 47, 57], ["cannon", 40, 55], ["cannon", 29, 50], ["mortar", 37, 59],
	["beam", 44, 60], ["reactor", 43, 62], ["storage", 37, 63], ["barracks", 47, 66],
	["sniper", 36, 56], ["sniper", 44, 56],
]


static func apply(g) -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	if args.is_empty():
		return
	print("[debug] ", args)
	Bus.log_msg.connect(func(t, k): print("[log:%s] %s" % [k, t]))
	if args.has("nocapture") or args.has("shot"):
		g.ignore_capture = true
	var auto := ["autostart", "demo", "units", "surface", "spire", "cave", "castle", "raid", "gallery", "sim", "shot", "smoke", "engine"].any(func(k): return args.has(k))
	if args.has("landing"):
		g.flow.begin()  # stop at the landing-site choice
	elif auto:
		g.flow.begin()
		var hint: Vector2i = g.level.landing_hint
		g.flow.land(hint)
	if args.has("fast"):
		g.time_scale = 8.0
	if args.has("demo"):
		for b in g.level.get("demo", DEMO_BUILD):  # --demo=slow: unbuilt, so every packet must really be delivered
			g.structures.place(b[0], b[1], b[2], args.demo != "slow")
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
		DebugHooks._drop(g, g.level.rift.x + 9, g.level.rift.z, PI / 2.0)
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
	if args.has("ranged"):
		RaiderShots.demo(g)
	if args.has("burrow"):
		RaiderBurrow.demo(g)
	if args.has("mortar"):
		EnemyMortars.demo(g)
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
	if args.has("keys"):
		g.hud.keys.open()
	if args.has("shot"):
		DebugHooks._screenshot_later(g, args.shot)
	elif args.has("quit"):
		g.get_tree().create_timer(float(args.quit)).timeout.connect(func(): g.get_tree().quit())


