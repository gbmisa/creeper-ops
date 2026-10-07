class_name Economy
extends RefCounted
## One shared energy bank for every sender. Income comes from the Command Node (while it
## is grounded), collector land and reactors. Outposts add storage and no income. Spending
## happens one packet at a time in packets.gd; spend() is only for lump costs (drop pods,
## orbital strikes, penalties).

var energy := Config.START_ENERGY
var max_energy := Config.NODE_STORAGE
var income := 0.0
var field_cells := 0
var wasted := 0.0   # energy/s lost to a full bank (rolling), so the HUD can say "build more"


func can_afford(n: float) -> bool:
	return energy >= n


func spend(n: float) -> bool:
	if energy < n:
		return false
	energy -= n
	return true


## Penalties can take you to zero but never below.
func drain(n: float) -> void:
	energy = maxf(0.0, energy - n)


func add(n: float) -> void:
	energy = minf(max_energy, energy + n)


func tick(dt: float, node_producing: bool, field_income: float, cells: int, reactor_income: float, storage: float, outpost_storage: float) -> void:
	max_energy = Config.NODE_STORAGE + storage + outpost_storage + Upgrades.bonus("storage")
	field_cells = cells
	income = ((Config.NODE_INCOME if node_producing else 0.0) + field_income + reactor_income) * Upgrades.mult("energy")
	var before := energy
	energy = minf(max_energy, energy + income * dt)
	if dt > 0.0:
		var lost := income * dt - (energy - before)
		wasted = lerpf(wasted, lost / dt, clampf(dt / Config.STAT_WINDOW, 0.0, 1.0))
