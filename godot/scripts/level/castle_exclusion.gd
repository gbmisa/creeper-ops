class_name CastleExclusion
## Enemy castles claim the land around them: nothing can be placed within BUILD_BAN_RADIUS
## cells of a castle you do not hold (hostile, capturing). Held castles (and sieged ones, still
## owned by you) are free. Wired into Placement.castle_ban by CastlePerks.attach; the zone is
## drawn as red rings on the terrain shader (`bans` uniform).

const REASON := "Enemy castle nearby: clear it first"


static func banned(s: Strongholds, x: int, z: int) -> bool:
	var at := Vector2(x, z)
	for c in s.list:
		if c.owner != "player" and CastlePerks.centre(s.lays[c.id]).distance_to(at) <= CastleDefs.BUILD_BAN_RADIUS:
			return true
	return false


static func reason(s: Strongholds, x: int, z: int) -> String:
	return REASON if banned(s, x, z) else ""


## Ring uniform: xy = world xz of the castle centre, z = radius m, w = on.
static func refresh(s: Strongholds) -> void:
	var mat: ShaderMaterial = s.world.terrain_mat
	if mat == null:
		return
	var packed := PackedVector4Array()
	packed.resize(8)
	var i := 0
	for c in s.list:
		if c.owner == "player" or i >= 8:
			continue
		var m: Vector2 = CastlePerks.centre(s.lays[c.id]) * Config.CELL
		packed[i] = Vector4(m.x, m.y, CastleDefs.BUILD_BAN_RADIUS * Config.CELL, 1.0)
		i += 1
	if packed != s.ban_cache:
		s.ban_cache = packed
		mat.set_shader_parameter("bans", packed)
