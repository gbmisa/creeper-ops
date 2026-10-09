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
