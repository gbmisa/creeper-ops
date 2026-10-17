class_name RangeSpace
## F110: which space a 3D sound is in. Zones are interior boxes (id = index, -1 = outside) and are per scene (cleared
## when a tactical scene builds). The treatment depends on listener AND source: same room = room reverb, both outside =
## dry, different spaces = low-passed and quieter (plus a light room reverb when the listener is inside).

static var _zones: Array[AABB] = []


static func clear() -> void:
	_zones.clear()


static func count() -> int:
	return _zones.size()


static func add(box: AABB) -> void:
	if not _zones.has(box):
		_zones.append(box)


## Interior box of a building rect (x0, z0, x1, z1): inside the walls, up to the roof of its top floor.
static func add_building(rect: Array, height: float, floors: int) -> void:
	add(AABB(Vector3(rect[0], 0.0, rect[1]), Vector3(rect[2] - rect[0], height * floors + 0.2, rect[3] - rect[1])))


static func zone_of(pos: Vector3) -> int:
	for i in _zones.size():
		if _zones[i].has_point(pos):
			return i
	return -1


## {bus, db} for a sound at src heard from listener.
static func treat(listener: Vector3, src: Vector3) -> Dictionary:
	var ls := zone_of(listener)
	var ss := zone_of(src)
	if ls == ss:
		return {"bus": "Master" if ls < 0 else SoundDefs.ROOM_BUS, "db": 0.0, "room": ls >= 0}
	return {"bus": SoundDefs.MUFFLE_ROOM_BUS if ls >= 0 else SoundDefs.MUFFLE_BUS, "db": SoundDefs.MUFFLE_DB, "room": false}


static func ensure_buses() -> void:
	_bus(SoundDefs.ROOM_BUS, 0.0, 0.0)
	_bus(SoundDefs.MUFFLE_BUS, SoundDefs.MUFFLE_HZ, 0.0)
	_bus(SoundDefs.MUFFLE_ROOM_BUS, SoundDefs.MUFFLE_HZ, SoundDefs.MUFFLE_ROOM_WET)


static func _bus(bus_name: String, cutoff: float, wet: float) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var i := AudioServer.bus_count - 1
	AudioServer.set_bus_name(i, bus_name)
	if cutoff > 0.0:
		var lp := AudioEffectLowPassFilter.new()
		lp.cutoff_hz = cutoff
		AudioServer.add_bus_effect(i, lp)
	if cutoff <= 0.0 or wet > 0.0:
		var rv := AudioEffectReverb.new()
		rv.room_size = 0.55
		rv.damping = 0.5
		rv.wet = 0.3 if cutoff <= 0.0 else wet
		AudioServer.add_bus_effect(i, rv)
