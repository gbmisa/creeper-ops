class_name PlayerRecoil
## Wires the Tarkov recoil model (RecoilModel) to the range player each frame (FB-I phase 2): aiming,
## stance and automatic fire in; the camera kick, the view following the muzzle, the camera roll and the
## settled residual (turn_view) out. Bullets leave along `TacticalPlayer.view_basis(recoil.barrel)`.

const AIMED_AT := 0.8          # ads_amt from which the gun counts as shouldered (same as Gun.shot_dirs' ads)
const AUTO_GAP_MULT := 1.5     # a held trigger stays "automatic fire" this many shot intervals after a shot


static func tick(w: PlayerWeapons, delta: float) -> void:
	var rm := w.recoil
	rm.aiming = w.ads_amt > AIMED_AT
	rm.pose = 1 if w.player.crouching else 2
	var gap: float = 60.0 / maxf(1.0, float(w.gun.def["rpm"]))
	rm.auto_fire = w.trigger_held and w.gun.mode == "auto" and w.since_shot <= gap * AUTO_GAP_MULT
	w.since_shot += delta
	rm.update(delta)
	apply_view(w)


## Copies the recoil's view effects onto the player (also called when the hands are empty).
static func apply_view(w: PlayerWeapons) -> void:
	var rm := w.recoil
	if rm.view_fold != Vector2.ZERO:
		w.player.turn_view(rm.view_fold)
		rm.view_fold = Vector2.ZERO
	w.player.recoil_off = rm.view_offset()
	w.player.recoil_roll = rm.camera_rot().z
