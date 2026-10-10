class_name SmokeDeploySites
## Deploy from Totems or the Command Node (pick lists all, one site is immediate, respawn offers it)
## and recall cooldown measured to the nearest site.


static func run(g) -> void:
	g.deploy.down = false
	g.deploy.pods.st = {}
	g.deploy.pick._end()
	g.deploy.pick.last_id = -1
	g.landing = false
	g.paused = false
	for s in g.structures.beacons():
		g.structures.remove(s)
	g.flow.to_command("")
	g.teleport_cooldown = 0.0
	g.command.select_structure(null)
	g.structures.selected_beacon = null
	var pick: DeployPick = g.deploy.pick
	var node: Structure = g.structures.command_node()
	# Node alone: straight away.
	g.deploy.deploy_totem()
	SmokeTest._check("sites: lone Node deploys immediately", not pick.active and g.mode == "surface")
	g.flow.to_command("")
	# Node + one Totem is already a choice.
	var grid: Grid = g.level.grid
	var o := SmokeDeploy._line(grid, 30)
	var a: Structure = g.structures.place("beacon", o.x, o.y, true)
	var b: Structure = g.structures.place("beacon", o.x + 20, o.y, true)
	if a == null or b == null or node == null:
		SmokeTest._check("sites: setup", false)
		return
	g.structures.remove(b)
	g.deploy.deploy_totem()
	SmokeTest._check("sites: Node + 1 Totem opens a choice", pick.active and pick.sites.size() == 2 and pick.sites.has(node) and pick.sites.has(a))
	pick.choose(node)
	SmokeTest._check("sites: choosing the Node deploys there", g.mode == "surface" and not pick.active)
	g.flow.to_command("")
	b = g.structures.place("beacon", o.x + 20, o.y, true)
	g.deploy.deploy_totem()
	SmokeTest._check("sites: 2 Totems + Node all listed", pick.active and pick.sites.size() == 3 and pick.sites.has(node) and pick.sites.has(a) and pick.sites.has(b))
	pick.cancel()
	g.command.select_structure(node)
	g.deploy.deploy_totem()
	SmokeTest._check("sites: selected Node deploys directly", not pick.active and g.mode == "surface")
	g.flow.to_command("")
	g.command.select_structure(null)
	g.deploy.pick.begin_respawn()
	SmokeTest._check("sites: respawn offers the choice", pick.active and pick.respawn and pick.sites.size() == 3)
	pick.cancel()
	# Recall: free beside a far Totem, cheaper near it than the walk to the Node.
	var at: Vector3 = b.pos + Vector3(Config.TOTEM_FREE_RADIUS * 0.5, 0, 0)
	g.fps.world = g.surface
	SmokeTest._check("recall: free beside a far Totem", g.deploy.recall.recall_cooldown_from(at, grid) == 0.0)
	var near := b.pos + Vector3(Config.CELL * 6.0, 0, 0)
	var nc := grid.world_to_cell(near.x, near.z)
	var to_node: float = Config.RECALL_COOLDOWN_MULT * g.deploy.path_metres(grid, nc, Vector2i(node.x, node.z)) / Config.WALK
	var cd: float = g.deploy.recall.recall_cooldown_from(near, grid)
	SmokeTest._check("recall: nearer Totem beats the Node walk", cd > 0.0 and cd < to_node)
	g.structures.remove(a)
	g.structures.remove(b)
	g.structures.selected_beacon = null
