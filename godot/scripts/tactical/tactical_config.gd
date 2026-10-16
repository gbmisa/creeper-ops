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
## P9: penalties by the number of blacked-out arms (player and bots). Multipliers on aim sway, reload time,
## ADS raise time and recoil; `breath` false = no breath hold. Bots read sway as aim spread and ads as reaction time.
const ARM_LOSS := {
	1: {"sway": 2.0, "reload": 1.25, "ads": 1.25, "recoil": 1.15, "breath": false},
	2: {"sway": 3.5, "reload": 1.6, "ads": 1.5, "recoil": 1.3, "breath": false},
}
const ARMOR_RICOCHET_GLANCE_DEG := 25.0

# Gun handling
const CHAMBER_TIME := 0.4
const ADS_TIME_SLOW := 0.45
const ADS_TIME_FAST := 0.15
const MAG_CHECK_TIME := 1.0
const EXACT_COUNT_MAX_CAP := 8
## [min fraction (inclusive), text], checked top to bottom
const MAG_WORDS := [[1.0, "Full"], [0.75, "Almost full"], [0.4, "About half"], [0.16, "Less than half"], [0.001, "Almost empty"]]

# Recoil / sway. The recoil model's numbers live in tactical/recoil_defs.gd (TacRecoilDefs, Tarkov via TRP).
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
const ADS_RELIEF := {"pistol": 0.25, "pistol_optic": 0.193, "notch": 0.160, "aperture": 0.08, "optic": 0.286, "scope": 0.295}
const ADS_EYE_CLEAR := 0.03  # F58: iron-sight eye keeps this from all gun geometry (eye_clear.py writes relief_min)
const VM_Z_CLIP := 0.3  # z_clip_scale on every viewmodel material, so the gun never clips the near plane

# Ragdoll (FB-A: enemy death; local cosmetic, no multiplayer sync)
const DEATH_IMPULSE := 250.0  # N·s on the hit bone for a killing shot, scaled by bullet damage
const DEATH_IMPULSE_REF_DMG := 57.0  # reference rifle-round damage for the scaling
const RAGDOLL_SLEEP := 4.0  # s after death before ragdoll bones freeze (0 = never)
const RAGDOLL_LIMIT := 0.35  # F77: ragdoll joint ranges (swing/twist/hinge) as a fraction of the anatomical table
const RAGDOLL_LIN_DAMP := 1.0  # per-second linear damping of ragdoll bones (was 0.4)
const RAGDOLL_ANG_DAMP := 4.0  # per-second angular damping of ragdoll bones (was 1.2)
const RAGDOLL_NUDGE := 25.0  # N·s topple nudge on a bleed-out death (no kill impulse)
const DEAD_GUN_MASS := 3.0  # kg, the dropped gun's rigid body
const DEAD_GUN_TOSS := 1.5  # upward impulse (N·s) on the dropped gun

# Skirmish deploy (F90)
const SKIRMISH_SPARE_MAGS := 2  # full spare mags per carried gun at spawn (tube guns: tubes of loose shells)
const END_CLICK_GRACE := 1.0  # F92: s the EXTRACTED / KIA buttons ignore clicks after the screen shows

# Bot unsticking (F91, BotUnstick)
const BOT_STUCK_WINDOW := 0.6  # s per progress check while a bot wants to move
const BOT_STUCK_DIST := 0.25  # m: less ground than this in one window = stuck
const BOT_UNSTICK_TIME := 0.5  # s of sidestep + plain waypoint steering after a stuck window
const BOT_STUCK_GIVE_UP := 3  # stuck windows in a row before the bot drops its move target
