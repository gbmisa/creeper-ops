class_name CastleVaults
## Castles as an economy hub (docs/CASTLES2_DESIGN.md §5). The API for Salvage Engines (Stage 9b)
## and castle-only production; this file builds nothing itself.
##  - lay.vaults: ward cells beside the keep reserved for the richest Salvage Engines.
##  - ships(castles, cell): an engine on `cell` may ship Salvage. Inside a castle's outer walls
##    it ships only while you hold that castle; outside every castle it always may.
##  - inside_held(castles, cell): placement test for castle-only titans/units (Stage 21b).


## The castle whose outer walls enclose `cell` (or {}).
static func castle_at(castles: Strongholds, cell: Vector2i) -> Dictionary:
	if castles == null:
		return {}
	for c in castles.list:
		var r: Rect2i = castles.lays[c.id].rect
		if r.has_point(cell):
			return c
	return {}


static func ships(castles: Strongholds, cell: Vector2i) -> bool:
	var c := castle_at(castles, cell)
	return c.is_empty() or c.owner == "player"


static func inside_held(castles: Strongholds, cell: Vector2i) -> bool:
	var c := castle_at(castles, cell)
	return not c.is_empty() and c.owner == "player"


## Every vault cell of every castle, for level authors and the 9b placement pass.
static func vault_cells(castles: Strongholds) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c in castles.list:
		for v in castles.lays[c.id].get("vaults", []):
			out.append(v)
	return out
