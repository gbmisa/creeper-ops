class_name CastleLancers
## Lancers (beam raiders, range 32) guard hostile castles instead of roaming. A Lancer carries
## `guard_post`, the garrison dict of its castle (its `pos` follows the castle's stage), and
## holds near it, firing at whatever it has a line to. Nest-bred Lancers are posted at the
## nearest hostile castle with room (CastleDefs.LANCERS_PER_CASTLE posted since the last retake;
## killed ones are not replaced, see retaken()); with none free the roll
## becomes a Spitter. When the castle is no longer hostile its Lancers are dismissed. Without
## a castle system (tests, caves) the Lancer simply guards its own nest.


static func is_lancer(tier: Dictionary) -> bool:
	return str(tier.get("attack", "")) == "beam"


## Garrison dicts of hostile castles (Strongholds hands them to Raiders.castle_posts).
static func posts(s: Strongholds) -> Array:
	var out := []
	for c in s.list:
		if c.state == "hostile":
			out.append(s.views[c.id].garrison)
	return out


## The post for a new Lancer: a garrison dict, {} when no castle has room, null when there is
## no castle system at all (it then guards the nest).
static func post(host: Raiders, nest: Dictionary) -> Variant:
	var open: Variant = host.castle_posts.call()
	if open == null:
		return null
	var best := {}
	var bd := INF
	for g in open:
		if nest.has("castle") and g != nest:
			continue
		if int(g.get("lancers_posted", 0)) >= CastleDefs.LANCERS_PER_CASTLE:
			continue
		var d: float = Vector2(g.pos.x - nest.pos.x, g.pos.z - nest.pos.z).length()
		if d < bd:
			bd = d
			best = g
	return best


## The enemy retook the castle: its Lancer slots open again.
static func retaken(g: Dictionary) -> void:
	g.erase("lancers_posted")


static func hold(host: Raiders, r: Dictionary, g: Dictionary) -> void:
	r["guard_post"] = g
	g["lancers_posted"] = int(g.get("lancers_posted", 0)) + 1  # a dead Lancer is not replaced
	r.guard = true
	var a := randf() * TAU
	var p: Vector3 = g.pos + Vector3(cos(a) * 1.5, 0, sin(a) * 1.5)
	p.y = host.world.grid.stand_y(p.x, p.z, Grid.Faction.ENEMY)
	(r.node as Node3D).position = p


## Per-frame upkeep before a Lancer thinks. False when it was dismissed.
static func tend(host: Raiders, r: Dictionary) -> bool:
	var g: Dictionary = r.guard_post
	if g.has("castle") and not host.castle_posts.call().has(g):
		var keep = host.loot_host  # leaves quietly: no loot for a captured castle
		host.loot_host = null
		host.kill(r)
		host.loot_host = keep
		return false
	r.erase("gather")
	r.erase("mission")
	r.erase("overrun")
	return true


## Where an idle Lancer stands: a slow loop around its post.
static func stand(host: Raiders, r: Dictionary) -> Vector2:
	return host._patrol((r.guard_post as Dictionary).pos, r)
