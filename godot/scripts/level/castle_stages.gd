class_name CastleStages
## Staged capture of concentric castles (docs/CASTLES2_DESIGN.md §3). Filled in Phase 4.


## Debug and tests: castle hostile with its first n rings taken.
static func set_stage(s: Strongholds, c: Dictionary, n: int) -> void:
	c["stage"] = n
	StrongholdRules.sync_grid(s.world, c, s.lays[c.id])
