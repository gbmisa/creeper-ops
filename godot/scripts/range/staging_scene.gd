class_name StagingScene
extends TacticalScene
## Scene root for the loadout room (staging.tscn, F139): the waiting room before a Skirmish. Stash = the inventory and
## the supply crate / rack (as on the range), gunsmith + ammo bench, a deploy board, and (F140) the gear mannequins.
## No bots, no targets.

var board: StagingBoard
var mannequins: StagingMannequins


func map_id() -> String:
	return "staging"


func _build() -> void:
	_begin()
	StagingRoom.build(self)
	_add_rack()
	_add_player(StagingRoom.SPAWN)
	add_child(targets)
	_add_feedback()
	_add_items()
	RangeCrate.build(self, world_items)
	_add_inventory()
	var ammo := StagingAmmo.new()
	add_child(ammo)
	ammo.setup(weapons, player)
	var workbench := RangeWorkbench.new()
	add_child(workbench)
	workbench.setup(weapons, player, inv_ui)
	gunsmith = workbench.smith
	board = StagingBoard.new()
	add_child(board)
	board.setup(weapons, player, func(map: String): session.deploy(weapons.inv, map))
	mannequins = StagingMannequins.new()
	add_child(mannequins)
	mannequins.setup(weapons, player, inv_ui)
	_add_hud()
	add_child(bots)
	bots.setup(session, weapons, bal, hit_log)
	_add_menu()


func _process(dt: float) -> void:
	if input != null and mannequins.panel.is_open and input.was_pressed(KEY_ESCAPE):
		mannequins.panel.close()   # Esc closes the mannequin panel first, not the pause menu
		input.end_frame()
		return
	super(dt)
