class_name SmokeSniperLos
## Snipers need line of sight (terrain and castle roofs block it); the enemy builder never
## builds under a castle roof, where nothing can see or reach the structure.


static func run(g) -> void:
	var grid: Grid = g.surface.grid
	var lift := Vector3(0, 1.0, 0)
	var blocked_pair := []
	var open_pair := []
	for z in range(2, grid.h - 2):
		for x in range(2, grid.w - 6):
			var a := grid.cell_ground(x, z)
			var b := grid.cell_ground(x + 4, z)
			var mid := maxf(grid.height[grid.idx(x + 2, z)], grid.height[grid.idx(x + 1, z)])
			var ends := maxf(grid.height[grid.idx(x, z)], grid.height[grid.idx(x + 4, z)])
			if blocked_pair.is_empty() and mid >= ends + 3.0:
				blocked_pair = [a + lift, b + lift]
			if open_pair.is_empty() and absf(a.y - b.y) < 0.01 and mid <= ends:
				open_pair = [a + lift, b + lift]
	SmokeTest._check("sniper los: found a wall to test", not blocked_pair.is_empty())
	if not blocked_pair.is_empty():
		SmokeTest._check("sniper los: wall blocks the shot", not WeaponLogic.sees(grid, blocked_pair[0], blocked_pair[1]))
	if not open_pair.is_empty():
		SmokeTest._check("sniper los: open ground is a clear shot", WeaponLogic.sees(grid, open_pair[0], open_pair[1]))
	var roofed := Vector2i(-1, -1)
	for i in grid.roof.size():
		if grid.roof[i] > 0.0:
			roofed = Vector2i(i % grid.w, i / grid.w)
			break
	if roofed.x >= 0 and g.builder != null:
		SmokeTest._check("enemy builder: never under a castle roof", not EnemyBuildPlan.open(g.builder, roofed, false))
