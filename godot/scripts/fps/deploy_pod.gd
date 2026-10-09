class_name DeployPod
extends RefCounted
## The falling drop pod: spawn, fall, touchdown (spawns the Operative), linger, sink.

var g
var st := {}


func _init(game) -> void:
	g = game


## Spawn the falling pod node (factored out so the smoke test can drive the lifecycle).
func begin(cell: Vector2i) -> void:
	var prev := st.get("node") as Node3D
	if prev != null and is_instance_valid(prev):
		prev.queue_free()
	var at: Vector3 = g.surface.grid.cell_ground(cell.x, cell.y)
	var pod := CreatureAnim.make("drop_pod", 1.0, null)
	if pod == null:
		pod = Node3D.new()  # no model: beam-only, as before
	g.surface.add_child(pod)
	# The pod's origin is mid-body: rest its lowest point on the ground at touchdown.
	var to := at + Vector3(0, CreatureAnim.ground_offset(pod), 0)
	var from := to + Vector3(0, 60, 0)
	pod.position = from
	CreatureAnim.move(pod, 1.0)  # walk clip: falling, flame on
	st = { "cell": cell, "t": 0.0, "tick": 0.0, "node": pod,
		"from": from, "to": to, "ground": at, "phase": "fall" }


## A drop is in flight (falling). Once it has landed, new drops are allowed even
## while the old pod sits out its linger.
func falling() -> bool:
	return not st.is_empty() and str(st.get("phase", "fall")) == "fall"


func tick(dt: float) -> void:
	if st.is_empty():
		return
	var node := st.get("node") as Node3D
	if node == null or not is_instance_valid(node):
		st = {}
		return
	if str(st.get("phase", "fall")) == "fall":
		st["t"] = float(st["t"]) + dt
		var k := clampf(float(st["t"]) / Config.DROP_TIME, 0.0, 1.0)
		node.position = (st["from"] as Vector3).lerp(st["to"] as Vector3, k * k)  # ease-in: accelerates
		st["tick"] = float(st["tick"]) - dt
		var at: Vector3 = st["ground"]
		if float(st["tick"]) <= 0.0:
			st["tick"] = 0.15
			g.surface.effects.beam(at + Vector3(0, 70, 0), at, Color("9fd4ff"), 0.16, 0.25 + float(st["t"]) * 0.12)
		if k >= 1.0:
			_touchdown()
	else:  # "linger": pod sits, then sinks; "die": wait for the clip's callback
		if str(st.get("phase")) != "linger":
			return
		st["t"] = float(st["t"]) + dt
		if float(st["t"]) >= Config.POD_LINGER:
			st["phase"] = "die"
			CreatureAnim.die(node, func() -> void:
				if is_instance_valid(node):
					node.queue_free()
				st = {})


func _touchdown() -> void:
	var node := st.get("node") as Node3D
	var cell: Vector2i = st["cell"]
	var at: Vector3 = st["ground"]
	st["phase"] = "linger"
	st["t"] = 0.0
	if node != null and is_instance_valid(node):
		CreatureAnim.attack(node)  # touchdown: dust ring, doors open
	g.surface.effects.burst(at, Color("b09a7a"), 3.0, 0.6)  # dust ring
	if g.deploy.down:
		Bus.say("The pod arrived, but the Operative is down.", "warn")
		return
	g.deploy._spawn(cell, 0.0)
	g.surface.effects.burst(at, Color("cfe8ff"), 2.5, 0.5)
	Sfx.play("teleport", at)
	Bus.say("Operative on the ground.", "radio")
