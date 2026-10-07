class_name Cave01
## Level 01 underground: "The Hollow". Edit the ASCII map directly.
##   #  rock wall         0-9  floor height        .  floor height 1
##   P  recall pad / spawn (floor 3)   C  Deep Core (floor 0)   K  Shield Pylon (floor 1)

const MAP := """
########################################
#3333333####.........###################
#33P3333####..........##################
#3333333###.....K......#################
#33333332211...........#######.....#####
###33332211.............#####.......####
####22221111..................K.....####
#####111111.......000.........11....####
######1111......0000000.......111...####
######111......000000000.......11...####
#####1111.....00000C00000........#######
#####111......000000000..........#######
####1111.......0000000...........#######
####111.........00000...........########
###111...........................#######
###11.....##....................########
###1.....####..........######.....######
###1....######........########....######
###11....####.........########.....#####
####11.......K.........######......#####
#####111...........................#####
#######1111.......................######
##########1111.................#########
########################################"""

const WALL := 7.0
## No nests underground yet. Same clock shape as the surface, ready if a cave fight grows them.
const RAID_SCHEDULE := {
	"raid_delay": 300.0,
	"tier_times": [0.0, 480.0, 900.0, 1320.0],
}


static func build() -> Dictionary:
	var rows := MAP.strip_edges().split("\n")
	var w := 0
	for r in rows:
		w = maxi(w, r.length())
	var g := Grid.new(w, rows.size())
	var cave := { "grid": g, "pad": Vector2i.ZERO, "core": Vector2i.ZERO, "pylons": [], "ceiling": 8.0,
		"raid_schedule": RAID_SCHEDULE }
	for z in rows.size():
		var row: String = rows[z]
		for x in w:
			var ch := row[x] if x < row.length() else "#"
			var hh := 1.0
			if ch == "#":
				hh = WALL
			elif ch.is_valid_int():
				hh = ch.to_float()
			elif ch == "P":
				hh = 3.0
				cave.pad = Vector2i(x, z)
			elif ch == "C":
				hh = 0.0
				cave.core = Vector2i(x, z)
			elif ch == "K":
				cave.pylons.append(Vector2i(x, z))
			g.set_height(x, z, hh)
	# The Core floods its pit; the cap rises over time so waiting makes the dive harder.
	cave["core_source"] = { "amount": 1.0, "interval": 1.5, "base_cap": 1.4, "cap_growth": 1.0 / 900.0 }
	return cave
