class_name TacticalConfig
## All tuning numbers for the tactical combat module (reusable, no dependency on range/).

# Physics layers (bit values): 1 world, 2 hitboxes (bullet-only), 3 character bodies
const LAYER_WORLD := 1
const LAYER_HITBOX := 2
const LAYER_BODY := 4
const LAYER_ITEM := 8  # dropped inventory items: collide with the world only, bullets pass
const BULLET_MASK := 3

# Ballistics
const GRAVITY := 9.81
const SIM_STEP := 1.0 / 240.0
const MAX_FLIGHT_TIME := 5.0
const MIN_SPEED := 40.0
const MAX_BOUNCES := 2
const RICOCHET_SPEED_MULT := 0.6
const WALL_REF_THICK := 0.02
const WALL_THICK_CAP := 5.0
const PASS_PEN_LOSS := 0.6
const PASS_DMG_MULT := 0.75
const PASS_SPEED_MULT := 0.8
const PASS_DEVIATE_DEG := 1.5

# Damage / armor
const FRAG_MIN_PEN := 20.0
const FRAG_DMG_MULT := 1.5
const LIGHT_BLEED_DPS := 0.8
const HEAVY_BLEED_DPS := 2.4
const FRACTURE_MIN_DMG := 25.0
const FRACTURE_CHANCE := 0.35
const LEG_FRACTURE_SPEED := 0.6
const ARM_FRACTURE_SWAY := 1.0
const ARMOR_RICOCHET_GLANCE_DEG := 25.0

# Gun handling
const HIP_CONE_DEG := 4.0
const MALF_BASE := 0.05
const WEAR_PER_SHOT := 0.0004
const FIX_TIME := {"misfire": 1.0, "feed": 1.8, "jam": 2.5}
const CHAMBER_TIME := 0.4
const ADS_TIME_SLOW := 0.45
const ADS_TIME_FAST := 0.15
const MAG_CHECK_TIME := 1.0
const EXACT_COUNT_MAX_CAP := 8
## [min fraction (inclusive), text], checked top to bottom
const MAG_WORDS := [[1.0, "Full"], [0.75, "Almost full"], [0.4, "About half"], [0.16, "Less than half"], [0.001, "Almost empty"]]

# Recoil / sway
const RECOIL_CAP_SHOTS := 10.0
const RECOIL_RATE_LOW := 2.0
const RECOIL_RATE_HIGH := 6.0
# Tarkov-style recoil (RecoilModel.tarkov): per-shot impulse = up x UP_MULT along the gun's `angle`, side drift is
# low-passed noise; OMEGA = critically damped rise (~60 ms); VM_* = viewmodel follows the bore (visual only).
# Model refs (TRP spec, TRP/docs/spec/weapon-handling.md "Recoil", Apache-2.0): spring shape
# (force -> Velocity, ReturnSpeed pull, Damping), stable/plateau from ~shot 5 (TRP RecoilStableIndexShot = 5
# for the AKM), camera follows a share of the weapon's climb, angle 90 = straight up (TRP AKM 80..90).
# Magnitudes below are this game's tuning, not TRP's measured values.
const RECOIL_T_UP_MULT := 0.7
const RECOIL_T_SIDE_MULT := 0.7
const RECOIL_T_DRIFT := 0.35
const RECOIL_T_OMEGA := 55.0
const RECOIL_T_VM_PITCH := 3.5
const RECOIL_T_VM_YAW := 2.0
const RECOIL_T_VM_ROLL := 0.8
const RECOIL_T_VM_KICK := 0.3
const SWAY_BASE_DEG := 0.12
const SWAY_HOLD_MULT := 0.05
const SWAY_TIRED_MULT := 2.5
const ARM_STAMINA_DRAIN_ADS := 0.04
const ARM_STAMINA_DRAIN_HOLD := 0.18
const ARM_STAMINA_REGEN := 0.12

# Movement (used by the range player)
const WALK := 3.2
const SPRINT := 5.6
const LEG_STAMINA_DRAIN := 0.12
const LEG_STAMINA_REGEN := 0.08
const LEAN_ROLL_DEG := 12.0
const LEAN_OFFSET := 0.35

# Bolt-action cycle (BoltCycle): handle up, bolt back, bolt forward, handle down. Rest of the gun is untouched.
const BOLT_ANGLE_DEG := 85.0  # handle lift about the bore axis (rests pointing right, rises to the top)
const BOLT_TRAVEL := 0.09  # m the bolt and handle slide back (+Z gun space)
const BOLT_SPLIT := [0.2, 0.3, 0.3, 0.2]  # share of the cycle time: handle up, back, forward, handle down
const BOLT_ROLL_DEG := 10.0  # gun rolls toward the working hand at the peak of the stroke
const BOLT_HAND_BLEND := 0.12  # share of the cycle the right hand takes to leave / return to the grip

# ADS (AdsPose): metres from the eye to the rear sight point at full ADS, per sight kind. Starting values are the
# per-kind medians of the pre-FB-H eye-to-rear-sight distances; Opus tunes them from reference frames.
const ADS_RELIEF := {"pistol": 0.138, "pistol_optic": 0.193, "notch": 0.160, "aperture": 0.1465, "optic": 0.286, "scope": 0.295}
const VM_Z_CLIP := 0.3  # z_clip_scale on every viewmodel material, so the gun never clips the near plane
