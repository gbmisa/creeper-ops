class_name RaiderPerch
## Where a ground raider stands: on the terrain, or on top of the creeper where the cell is wet
## (so it never wades invisibly under the surface). Reads creeper depth only.


static func y(world: World, x: float, z: float) -> float:
	var gy := world.grid.stand_y(x, z, Grid.Faction.ENEMY)
	var c := world.grid.world_to_cell(x, z)
	var d := world.creeper.depth_at(c.x, c.y)
	return gy + d * Config.LEVEL_H if d > Config.MIN_DEPTH else gy
