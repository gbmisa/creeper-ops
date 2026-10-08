class_name Stockpile
extends RefCounted
## Ore and Salvage (design §2). Miners add Ore by return packet. Respawn and wall repair spend Salvage.
## ore_rate / salvage_rate are per-second rolling averages for the HUD.

var ore := 0.0
var earned_ore := 0.0     # everything ever added (sim report: ore_mined)
var earned_salvage := 0.0 # everything ever added (sim report: salvage_earned)
var salvage := 0.0
var ore_rate := 0.0
var salvage_rate := 0.0
var _frame_ore := 0.0
var _frame_salvage := 0.0


func amount(kind: String) -> float:
	if kind == "ore":
		return ore
	if kind == "salvage":
		return salvage
	return 0.0


func can_afford(kind: String, n: float) -> bool:
	return amount(kind) + 0.0001 >= n


func add(kind: String, n: float) -> void:
	if kind != "ore" and kind != "salvage":
		return
	_assign(kind, amount(kind) + n)
	_bump(kind, n)
	if n > 0.0:
		if kind == "ore":
			earned_ore += n
		else:
			earned_salvage += n


func spend(kind: String, n: float) -> bool:
	if not can_afford(kind, n):
		return false
	_assign(kind, amount(kind) - n)
	_bump(kind, -n)
	return true


func tick(dt: float) -> void:
	if dt <= 0.0:
		return
	var k := clampf(dt / Config.STAT_WINDOW, 0.0, 1.0)
	ore_rate = lerpf(ore_rate, _frame_ore / dt, k)
	salvage_rate = lerpf(salvage_rate, _frame_salvage / dt, k)
	_frame_ore = 0.0
	_frame_salvage = 0.0


func _assign(kind: String, n: float) -> void:
	if kind == "ore":
		ore = n
	else:
		salvage = n


func _bump(kind: String, n: float) -> void:
	if kind == "ore":
		_frame_ore += n
	else:
		_frame_salvage += n
