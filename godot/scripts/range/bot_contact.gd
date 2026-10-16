class_name BotContact
extends RefCounted
## A bot's memory of the enemy: position, error radius, age, source (sight / hit / shot / ally).
## A contact is a *memory*, not a live fix: seen = exact, lost sight = error grows with age,
## heard shot = fuzzy at hear time, and it is forgotten after CONTACT_FORGET with no new info.

const SRC_SIGHT := "sight"
const SRC_HIT := "hit"
const SRC_SHOT := "shot"
const SRC_ALLY := "ally"

var pos := Vector3.ZERO
var err := 0.0
var age := 999.0
var source := ""
var forgotten := true
var _sight_lost := false


func has() -> bool:
	return not forgotten


## Fresh visual: exact position, zero error.
func sight(p: Vector3) -> void:
	pos = p
	err = 0.0
	age = 0.0
	source = SRC_SIGHT
	forgotten = false
	_sight_lost = false


## Hit, or told by the squad: exact like sight, marked as a hit.
func hit(p: Vector3) -> void:
	sight(p)
	source = SRC_HIT


## Sight broken: from now on the error grows as the player may have moved.
func lose_sight() -> void:
	if source == SRC_SIGHT and not forgotten:
		_sight_lost = true


## Heard shot: never the exact spot. Position is offset randomly within an error that
## grows with distance (HEAR_ERR_FRAC of it, clamped to HEAR_ERR_MIN..MAX).
func shot(p: Vector3, dist: float, rng: RandomNumberGenerator) -> void:
	err = clampf(dist * BotTacticsDefs.HEAR_ERR_FRAC, BotTacticsDefs.HEAR_ERR_MIN, BotTacticsDefs.HEAR_ERR_MAX)
	var a := rng.randf() * TAU
	var r := err * sqrt(rng.randf())
	pos = p + Vector3(cos(a) * r, 0.0, sin(a) * r)
	age = 0.0
	source = SRC_SHOT
	forgotten = false
	_sight_lost = false


## Shared by an ally: take their position and error as-is.
func ally(p: Vector3, e: float) -> void:
	pos = p
	err = e
	age = 0.0
	source = SRC_ALLY
	forgotten = false
	_sight_lost = false


func tick(dt: float) -> void:
	age += dt  # age always advances: it is the calm clock too, even after forgetting
	if forgotten:
		return
	if _sight_lost:
		err = minf(err + BotTacticsDefs.SIGHT_ERR_GROWTH * dt, BotTacticsDefs.SIGHT_ERR_MAX)
	if age >= BotTacticsDefs.CONTACT_FORGET:
		forgotten = true
