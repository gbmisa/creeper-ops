class_name PerfProbe
## Per-system CPU time for the performance overlay (PerfOverlay). Code wraps a hot path:
##   var t0 := PerfProbe.t0()  ...  PerfProbe.add("bots.think", t0)
## Totals are microseconds since the overlay last read them (take()). Timing only: changes nothing in play.

static var _acc := {}
static var _calls := {}


static func t0() -> int:
	return Time.get_ticks_usec()


static func add(name: String, start_usec: int) -> void:
	_acc[name] = int(_acc.get(name, 0)) + Time.get_ticks_usec() - start_usec
	_calls[name] = int(_calls.get(name, 0)) + 1


## {name: [usec, calls]} accumulated since the last take(); resets the totals.
static func take() -> Dictionary:
	var out := {}
	for k in _acc:
		out[k] = [_acc[k], _calls[k]]
	_acc.clear()
	_calls.clear()
	return out
