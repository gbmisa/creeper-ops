class_name SmokeShotTour
## Brief S: tour-file parser checks (no rendering). Called from SmokeTest.run.
## Must not depend on what earlier smoke files left behind.


static func run(g) -> void:
	var text := """# a comment line

out=/tmp/a.png look=40,74,22,0.9 wait=1.5
out=/tmp/b.png fps=60,62,yaw=1.2,pitch=-0.2 select=cannon
out=/tmp/c.png gallery=anim:wyvern clip=attack t=0.5
out=/tmp/d.png look=1,2 bogus=1
"""
	var shots: Array = ShotTour.parse_text(text)
	SmokeTest._check("tour: 3 shots + 1 bad line, comment/blank skipped", shots.size() == 4)
	var a: Dictionary = shots[0]
	SmokeTest._check("tour: look fields",
		a["out"] == "/tmp/a.png" and a["look"] == "40,74,22,0.9" and float(a["wait"]) == 1.5
		and str(a["error"]) == "")
	var b: Dictionary = shots[1]
	SmokeTest._check("tour: fps/select fields, default wait",
		b["fps"] == "60,62,yaw=1.2,pitch=-0.2" and b["select"] == "cannon"
		and float(b["wait"]) == 1.0 and str(b["error"]) == "")
	var c: Dictionary = shots[2]
	SmokeTest._check("tour: gallery/clip/t fields",
		c["gallery"] == "anim:wyvern" and c["clip"] == "attack" and c["t"] == "0.5"
		and str(c["error"]) == "")
	var d: Dictionary = shots[3]
	SmokeTest._check("tour: unknown key -> error, still a line", str(d["error"]) != "")
	SmokeTest._check("tour: missing out= -> error",
		str((ShotTour.parse_text("look=1,2")[0] as Dictionary)["error"]) != "")
	# Gallery framing: a hovering model's AABB centre is the aim, not the base.
	# Simulates CommandCamera's ground-snap drag, then checks the re-aim tick.
	var holder := Node3D.new()
	holder.position = Vector3(0, 5, 0)  # hovering 5 m up, like a flyer
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(2, 2, 2)
	mi.mesh = bm
	holder.add_child(mi)
	g.get_tree().root.add_child(holder)
	ShotTour._track_gallery(g, holder)
	g.command.cam.target = Vector3(0, 0, 0)  # where the ground-snap drags it
	ShotTour._reframe_tick()
	var got: Vector3 = g.command.cam.target
	ShotTour._untrack_gallery()
	holder.queue_free()
	SmokeTest._check("tour: gallery re-aim targets hovering AABB centre, not ground",
		got.distance_to(Vector3(0, 5, 0)) < 0.05, "(%s)" % got)
