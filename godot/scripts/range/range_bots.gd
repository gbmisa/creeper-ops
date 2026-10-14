class_name RangeBots
extends Node3D
## Kill house owner: builds the house + navmesh, the Scav terminal (use key spawns 2 Scavs) and the bots.
## Bot state changes go to the hit log ("Scav 1: TakeCover").

const REACH := 2.2
const COUNT := 2

var house: KillHouse
var player: TacticalPlayer
var weapons: PlayerWeapons
var bal: Ballistics
var log: RangeHitLog
var bots: Array[ScavBot] = []


func setup(p: TacticalPlayer, w: PlayerWeapons, b: Ballistics, l: RangeHitLog) -> void:
	player = p
	weapons = w
	bal = b
	log = l
	BotNoise.reset()
	house = KillHouse.new()
	add_child(house)
	house.build()
	house.bake()
	var t := house.terminal_pos()
	RangeLayout.box(self, "terminal", t + Vector3(0, 0.6, 0), Vector3(0.9, 1.2, 0.5), "sheet_metal", 0.05, Color(0.2, 0.22, 0.25))
	var sign := Label3D.new()
	sign.text = "SCAV TERMINAL"
	sign.font_size = 56
	sign.pixel_size = 0.004
	sign.outline_size = 10
	sign.modulate = Color(1.0, 0.55, 0.45)
	sign.position = t + Vector3(0, 1.5, 0)
	add_child(sign)


func spawn_scavs() -> void:
	for b in bots:
		if is_instance_valid(b):
			b.queue_free()
	bots.clear()
	for i in COUNT:
		var bot := ScavBot.new()
		bot.setup(player, bal, house, "Scav %d" % (i + 1), i * 3)
		add_child(bot)
		bot.global_position = house.spawns[i] + Vector3(0, 0.1, 0)
		bot.state_changed.connect(_on_state)
		bot.died.connect(func(b): log.add("%s: KILLED" % b.label_name))
		bots.append(bot)
	bots[0].ally = bots[1]
	bots[1].ally = bots[0]
	log.add("Scavs spawned in the kill house")


func _on_state(bot: ScavBot, _from: String, to: String) -> void:
	log.add("%s: %s" % [bot.label_name, to])


func _process(_dt: float) -> void:
	if player == null:
		return
	var to := house.terminal_pos() - player.global_position
	to.y = 0.0
	if to.length() < REACH:
		weapons.prompt = "%s: spawn 2 Scavs in the kill house" % Keybinds.short("t_use")
		if player.enabled and player.input.act("t_use"):
			spawn_scavs()
