class_name CommandMode
extends Node3D
## Top-down commander. Tools: a structure type (build; stays armed until right-click/Esc,
## like CW3), "@move" (relocate the selected
## structure), "@lance" (orbital strike), "@drop" (Operative drop pod), "@land" (Command Node landing at mission start),
## "@terp" (paint a target level; the drag cancels with the tool).
## Dragging with a structure tool lays a chain or row (DragBuild).
## Selection: click / drag-box units, click structures. Orders: right-click moves units,
## relocates a selected movable structure, or sets a barracks rally point.
## Pointer and hotkeys: CommandInput. Selection orders: CommandSelect. Ghost preview: CommandHover.


var world: World
var structures: StructureManager
var units: UnitManager
var orbital: Orbital
var deploy: OperativeDeploy
var castles: Strongholds = null   # injected: Castle tab turret tools
var level: Dictionary
var cam := CommandCamera.new()
var overlay: CommandOverlay
var tool := ""
var hover: Dictionary = {}        # { cell: Vector2i, point: Vector3 }
var reason := ""
var selected: Structure = null
var group: Array[Structure] = []  # every selected structure (box select); selected is group[0]
var drag_rect := Rect2()          # for the HUD selection box (size 0 = hidden)
var drag_start := Vector2i(-1, -1)  # press cell while a build tool is armed (DragBuild)
var drag_plan: Array[Dictionary] = []  # DragBuild preview while dragging
var on_land := Callable()         # GameFlow: func(cell: Vector2i)


func setup(w: World, sm: StructureManager, um: UnitManager, orb: Orbital, lvl: Dictionary) -> void:
	name = "Command"
	world = w
	structures = sm
	units = um
	orbital = orb
	level = lvl
	add_child(cam)
	cam.bounds = w.grid.world_size()
	overlay = CommandOverlay.new(w)
	Bus.structure_removed.connect(_on_removed)


func set_tool(t: String) -> void:
	if tool == "@land" and t != "@land":
		return  # landing must finish first
	if tool == "@terp" and t != "@terp" and overlay != null and overlay.paint != null:
		overlay.paint.cancel()
		drag_rect = Rect2()
	tool = t
	cancel_drag()
	if t != "" and t != "@move":
		select_structure(null)
		units.select([])
	if t == "":
		overlay.hide_ghost()
	Bus.tool_changed.emit(t)


func cancel_drag() -> void:
	drag_start = Vector2i(-1, -1)
	drag_plan.clear()
	overlay.hide_plan()


func select_structure(s: Structure) -> void:
	selected = s
	group.clear()
	if s:
		group.append(s)
	if s and s.type == "beacon":
		structures.selected_beacon = s
	Bus.selection_changed.emit()


func update(dt: float, input: InputState) -> void:
	if tool == "@move" and (selected == null or selected.is_flying()):
		set_tool("")
	CommandInput.hotkeys(self, input)
	cam.update(dt, input, world.grid)
	Sfx.listener = cam.global_position
	CommandHover.refresh(self, input)
	overlay.show_selection(selected, group, tool != "")
	CastleSocketLook.highlight(castles, CommandHover._turret_type(tool) != "", hover)
	if input.right_clicked:
		CommandInput.right_click(self)
	CommandInput.left_mouse(self, input)


func _on_removed(s: Structure) -> void:
	group.erase(s)
	if s == selected:
		selected = null if group.is_empty() else group[0]
		Bus.selection_changed.emit()


func train(type: String) -> void:
	CommandSelect.train(self, type)


func recycle_selected() -> void:
	CommandSelect.recycle(self)


func begin_move() -> void:
	CommandSelect.begin_move(self)


func toggle_supply() -> void:
	CommandSelect.toggle_supply(self)


func toggle_hold() -> void:
	CommandSelect.toggle_hold(self)


## Smoke places a building by calling this directly.
func _click(shift: bool) -> void:
	CommandInput.click(self, shift)
