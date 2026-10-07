class_name SpirePump
## The spire pump of an enemy-held castle draws creeper out of its moat (or the cells round
## its base) and turns it into build material for enemy construction (Stage 8c spends
## `pump.material`). Intake = SPIRE_PUMP_RATE x average depth (capped), so a deep moat
## builds fast and a drained one barely at all. It never puts creeper on the spire.
## Idle while the player holds the castle or while the Operative has it jammed.

const TICK := 0.5


static func update(world: World, c: Dictionary, lay: Dictionary, dt: float) -> void:
	var p: Dictionary = c.pump
	p.jam = maxf(0.0, p.jam - dt)
	p["acc"] = p.get("acc", 0.0) + dt
	if p.acc < TICK:
		return
	var step: float = p.acc
	p.acc = 0.0
	if c.owner != "enemy" or p.jam > 0.0:
		p.intake = 0.0
		return
	var cells: Array = lay.pump_cells
	var total := 0.0
	var wet := []
	for cell in cells:
		var d := world.creeper.depth_at(cell.x, cell.y)
		if d > Config.MIN_DEPTH:
			total += d
			wet.append(cell)
	if cells.is_empty() or total <= 0.0:
		p.intake = 0.0
		return
	var avg := minf(Config.PUMP_DEPTH_CAP, total / cells.size())
	p.intake = Config.SPIRE_PUMP_RATE * avg
	var want := minf(total, p.intake * step)
	var drawn := 0.0
	for cell in wet:  # each wet cell gives in proportion to its depth
		drawn += world.creeper.remove(cell.x, cell.y, want * world.creeper.depth_at(cell.x, cell.y) / total)
	p.material += drawn
