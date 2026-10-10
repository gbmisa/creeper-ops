class_name DeployPick
extends RefCounted
## Choose which site the Operative deploys from. Sites = every finished Totem plus the
## Command Node (StructureManager.deploy_sites). Pressing deploy with 2+ sites and none
## selected enters pick mode in command view: every site gets a marker and a ground beam,
## hovering highlights one, click (or deploy again) confirms, Esc or right-click cancels.
## After a respawn the same pick runs with a timeout that falls back to the last-used site.
## One site deploys straight away; a selected site (info panel Deploy button) too.

var g
var active := false
var respawn := false
var left := 0.0
var hover := -1
var last_id := -1            # id of the last Totem deployed from
var sites: Array[Structure] = []
var _marks: Array[Dictionary] = []
var _beam := 0.0


func _init(game) -> void:
	g = game


## Explicitly selected site, else the lone one; with several unselected this is the last used.
func chosen() -> Structure:
	var all: Array = g.structures.deploy_sites()
	var sel: Structure = g.command.selected
	if sel != null and all.has(sel):
		return sel
	var sb: Structure = g.structures.selected_beacon
	if all.has(sb):
		return sb
	return null if all.is_empty() else (default_site(all) as Structure)


func default_site(list: Array) -> Structure:
	for s in list:
		if s.id == last_id:
			return s
	return list.back()


func remember(b: Structure) -> void:
	last_id = b.id


## True when pick mode took over (several sites, none selected).
func begin_if_needed() -> bool:
	var all: Array = g.structures.deploy_sites()
	if all.size() < 2 or all.has(g.command.selected):
		return false
	begin(false)
	return true


func begin_respawn() -> void:
	if g.structures.deploy_sites().size() > 1:
		begin(true)


func begin(is_respawn: bool) -> void:
	sites.assign(g.structures.deploy_sites())
	if sites.size() < 2:
		return
	active = true
	respawn = is_respawn
	left = Config.RESPAWN_PICK_TIME
	hover = -1
	g.command.set_tool("")
	for i in sites.size():
		var s: Structure = sites[i]
		var m := { "pos": func() -> Vector3: return s.pos + Vector3(0, 3.0, 0), "label": func() -> String: return label(i),
			"color": Color("ffd24a"), "visible": func() -> bool: return active and not s.dead, "pick": true }
		_marks.append(m)
		g.surface.markers.append(m)
	Bus.say("Pick a deploy site: click a Totem or the Command Node (%s confirms the gold one, Esc cancels)." % Keybinds.short("teleport"), "info")


func highlighted() -> int:
	if hover >= 0:
		return hover
	return sites.find(default_site(sites)) if not sites.is_empty() else -1


func label(i: int) -> String:
	if i < 0 or i >= sites.size():
		return ""
	var s: Structure = sites[i]
	var node: Structure = g.structures.command_node()
	var txt := "Command Node"
	if s.type != "node":
		txt = "Totem %d" % (i + 1 - sites.filter(func(o): return o.type == "node").size())
		if node != null:
			txt += "  %dm from Node" % roundi(Vector2(s.pos.x - node.pos.x, s.pos.z - node.pos.z).length())
	if s.id == last_id:
		txt += "  (last used)"
	if creeper_near(s):
		txt += "  CREEPER NEAR"
	if i == highlighted():
		txt = ">> %s <<" % txt
		if respawn:
			txt += "  auto in %ds" % ceili(left)
	return txt


func creeper_near(s: Structure) -> bool:
	var sim: CreeperSim = g.surface.creeper
	for dz in range(-3, 4):
		for dx in range(-3, 4):
			if g.surface.grid.in_bounds(s.x + dx, s.z + dz) and sim.depth_at(s.x + dx, s.z + dz) > Config.MIN_DEPTH:
				return true
	return false


func choose(s: Structure) -> void:
	_end()
	if s != null and not s.dead:
		g.deploy.deploy_from(s)


func confirm() -> void:
	var i := highlighted()
	choose(sites[i] if i >= 0 else null)


func cancel() -> void:
	_end()
	Bus.say("Deploy cancelled.", "info")


func _end() -> void:
	active = false
	for m in _marks:
		g.surface.markers.erase(m)
	_marks.clear()


func update(dt: float) -> void:
	if not active:
		return
	sites = sites.filter(func(s): return not s.dead)
	if sites.size() < 2 or (g.mode != "command" and not respawn):
		_end()
		return
	_beam -= dt
	if _beam <= 0.0:
		_beam = 0.3
		_pulse()
	if respawn and not g.paused:
		left -= dt
		if left <= 0.0:
			choose(default_site(sites))


func _pulse() -> void:
	var hl := highlighted()
	for i in sites.size():
		var at: Vector3 = sites[i].pos
		var on := i == hl
		g.surface.effects.beam(at + Vector3(0, 40, 0), at, Color("ffd24a") if on else Color("9fd4ff"), 0.35, 0.5 if on else 0.15)


## Pointer while picking (CommandMode calls this instead of its normal input).
func handle(cm: CommandMode, input: InputState) -> void:
	hover = -1
	if not cm.hover.is_empty():
		var c: Vector2i = cm.hover.cell
		var best := Config.DEPLOY_PICK_RADIUS
		for i in sites.size():
			var d := Vector2(c.x - sites[i].x, c.y - sites[i].z).length()
			if d <= best:
				best = d
				hover = i
	if input.was_pressed(KEY_ESCAPE) or input.right_clicked:
		cancel()
	elif input.left_pressed and hover >= 0:
		choose(sites[hover])
		Sfx.play("click")
