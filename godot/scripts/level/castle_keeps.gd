class_name CastleKeeps
extends RefCounted
## A castle you hold launches packets: its courtyard gets a Castle Keep (structure id "keep"),
## a packet sender and relay like an Outpost that you never build or pay for. It appears when
## the castle is held, comes back once a siege is beaten if raiders destroyed it, and goes
## when the castle falls (Strongholds.on_lost clears the courtyard).
## Stage 21 muster: a held castle also gets a free, finished Castle Barracks in its ward
## (units train and resupply at the front), with the same lifetime as the keep.

var castles: Strongholds
var structures: StructureManager
var keeps := {}  # castle id -> Structure
var musters := {}  # castle id -> the free barracks


func _init(c: Strongholds, s: StructureManager) -> void:
	castles = c
	structures = s


func update() -> void:
	for c in castles.list:
		var s: Structure = keeps.get(c.id)
		var alive := s != null and not s.dead
		if c.state == "held" and not alive:
			s = _place(castles.lays[c.id])
			if s:
				keeps[c.id] = s
				Bus.say("%s now launches packets to your network." % c.name, "good")
		elif c.owner != "player" and alive:
			structures.remove(s, "destroyed")
		_muster(c)


func _muster(c: Dictionary) -> void:
	var b: Structure = musters.get(c.id)
	var alive := b != null and not b.dead
	if c.owner != "player":
		if alive:
			structures.remove(b, "destroyed")
		return
	if alive or c.state != "held" or not CastleDefs.MUSTER:
		return
	b = _place_muster(castles.lays[c.id])
	if b:
		musters[c.id] = b
		Bus.say("%s musters a Castle Barracks: train and resupply units there." % c.name, "good")


## The free barracks: the courtyard cell nearest the keep where it fits on level ground (the ward
## first; a compact castle's ward is too narrow, so then the bailey).
func _place_muster(lay: Dictionary) -> Structure:
	var home: Vector2i = lay.rect.position + lay.rect.size / 2
	var cells: Array = lay.courtyard.duplicate()
	cells.sort_custom(func(a, b): return (a - home).length_squared() < (b - home).length_squared())
	for cell in cells:
		if Placement._ground_rules(structures, "barracks", cell.x, cell.y, null) == "":
			return structures.place("barracks", cell.x, cell.y, true)
	return null


## On the free courtyard cell nearest the castle's centre (beside the spire), so it never
## blocks a gateway.
func _place(lay: Dictionary) -> Structure:
	var r: Rect2i = lay.rect
	var home := r.position + r.size / 2
	var cells: Array = lay.courtyard.duplicate()
	cells.sort_custom(func(a, b): return (a - home).length_squared() < (b - home).length_squared())
	var g := structures.world.grid
	for cell in cells:
		if not structures.occupied.has(g.idx(cell.x, cell.y)):
			return structures.place("keep", cell.x, cell.y, true)
	return null
