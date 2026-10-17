class_name BotHold
extends RefCounted
## How an enemy holds its gun (BotBody). Stocked guns: the butt sits in the right shoulder pocket and the torso is
## bladed (right shoulder back, head turned back to the front) so the left hand reaches the handguard. Pistols: held
## out in front of the chest in both hands. Elbows bend down and out in the bot's own frame, whichever way it faces.
## Offsets are bot-frame metres (+X right, +Y up, -Z forward). Only the look changes: hitboxes and the eye are BotPose's.

## mount: "shoulder" = from the right shoulder joint to the butt; "chest" = from the shoulders' midpoint to the
## pistol's rear. lift: added to the mount's height while engaged (gun up to the eye line). blade: torso yaw (rad).
## head: head pitch down onto the stock while engaged (rad). pole_r / pole_l: elbow directions.
## Lowered (not engaged): low = muzzle-down pitch at the low ready (alerted), carry = the same unalerted (patrol carry,
## muzzle further down and across the body by carry_yaw rad); low_at: the mount's move while lowered. fwd_low / fwd_aim:
## upper-body lean into the gun, lowered / aiming (rad, + forward). Raise / lower times are BotMesh's.
const STOCKED := {"mount": "shoulder", "at": Vector3(-0.07, -0.05, -0.04), "lift": 0.09, "blade": 0.55, "head": 0.24,
	"pole_r": Vector3(0.7, -1.0, 0.25), "pole_l": Vector3(-0.35, -1.0, 0.0),
	"low": -0.55, "carry": -0.62, "carry_yaw": 0.45, "low_at": Vector3(0.03, -0.02, -0.04), "fwd_low": 0.12, "fwd_aim": 0.14}
const PISTOL := {"mount": "chest", "at": Vector3(0.06, -0.06, -0.30), "lift": 0.12, "blade": 0.12, "head": 0.0,
	"pole_r": Vector3(0.5, -1.0, 0.1), "pole_l": Vector3(-0.5, -1.0, 0.1),
	"low": -0.6, "carry": -0.8, "carry_yaw": 0.15, "low_at": Vector3(-0.02, -0.12, 0.1), "fwd_low": 0.1, "fwd_aim": 0.12}


static func of(gun_def: Dictionary) -> Dictionary:
	return PISTOL if gun_def["class"] == "pistol" else STOCKED


## The support hand's target: the grip, or if the shoulder can't reach that far, the nearest point back along the
## gun (toward the stock) that it can (long rifles: the hand sits nearer the receiver).
static func reach_back(grip: Vector3, back: Vector3, shoulder: Vector3, reach: float) -> Vector3:
	var d := grip - shoulder
	if d.length() <= reach:
		return grip
	# |d + back * s| = reach, smallest s >= 0
	var bd := back.dot(d)
	var disc := bd * bd - (d.length_squared() - reach * reach)
	if disc < 0.0:
		return grip - back * bd  # nothing on the line is in reach: the closest point
	return grip + back * (-bd - sqrt(disc))
