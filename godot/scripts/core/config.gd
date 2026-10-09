class_name Config
## Global tuning constants. Gameplay numbers live here so balancing never means hunting
## through logic. Structure/unit stats live in their def tables (structure_defs, unit_defs).

# ---- world -------------------------------------------------------------------
const CELL := 2.0          # world metres per grid cell
const LEVEL_H := 1.25      # metres per terrain level (1 level == 1 unit of creeper depth)
const MAX_LEVEL := 10      # CW3 terrain runs 0..10
const SPIRE_MAX_LEVEL := 34  # castle spires (indestructible) and raised castle walls may go higher
const DETAIL := 3          # terrain/creeper mesh vertices per cell edge (visual only)
const TERRACE_BAND := 2.0 / 3.0  # share of the centre-to-centre gap a level change ramps over.
                                 # 2/3 with DETAIL 3 puts every ramp knee on a mesh vertex.

# ---- creeper -----------------------------------------------------------------
## CW3 rule (docs/CREEPER_SPEC.md §1): 30 ticks/s; each edge exchanges FLOW_RATE x head
## difference, clamped to FLOW_RATE x the giving cell's own depth (<= 16 %/tick per cell).
const CREEPER_TICK := 1.0 / 30.0
const FLOW_RATE := 0.04
const CREEPER_DRY := 0.001     # thinner films evaporate at the end of a tick
const MIN_DEPTH := 0.02        # below this a cell counts as dry (and isn't drawn)
const MAX_DEPTH := 25.0
const DAMAGE_DEPTH := 0.06     # units take damage above this depth
## CW3 wet damage is flat, whatever the depth: a structure with a health reserve dies after
## `wet_time` seconds in creeper (def key, else WET_TIME). Same rate off build progress.
const WET_TIME := 12.0         # CW3 pulse cannon
const HEAL_TIME := 50.0        # seconds a dry structure takes to heal from 0 to full (CW3)

# ---- economy (CW3: energy IS packets; no launch cap) -----------------------------
const START_ENERGY := 0.0     # the Node lands empty: first packets come from its own output
const NODE_STORAGE := 60.0     # the Command Node's own bank
const OUTPOST_STORAGE := 50.0  # each built Outpost adds this to the shared bank; no income
const OUTPOST_ORE := 60.0      # Ore paid when an Outpost is placed; its packets still have to arrive
const ORE_DEPOSIT := 300.0     # ore in one vein
const MINER_INTERVAL := 4.0    # seconds per ore a Miner extracts
const MINER_BUFFER := 10.0     # ore a Miner holds while its return route is down
const WALL_REPAIR_HP := 10.0   # wall HP restored per 1 Salvage
const NODE_INCOME := 0.8       # packets/s the Command Node generates by itself
const REQ_BUILD := 2.5         # packets/s one structure may request while under construction
const REQ_AMMO := 4.0          # packets/s one weapon may request for ammo
const REQ_UNIT := 2.0          # packets/s a barracks may request for training/supply
const REQ_TERP := 4.0          # packets/s a Terp may request while a dig is unpaid
const TERP_PACKETS := 4        # packets one Terp level-step costs
const TERP_STEP_TIME := 3.0    # seconds of work after those packets arrive
const PACKET_SPEED := 18.0     # metres per second along links
const RECYCLE_REFUND := 0.5
const COLLECT_RADIUS := 3      # half-size of a collector's SQUARE field (7x7 cells, CW3/CW4 style)
const COLLECT_PER_CELL := 0.005 # energy/s per claimed dry cell (a full 49-cell field ~0.25/s)
const STAT_WINDOW := 3.0       # seconds the production/demand readout averages over

# ---- movement of weapons / Command Node -----------------------------------------
const LOB_RANGE_PER_LEVEL := 0.5  # mortar/Bertha: extra cells of reach per level of height advantage (CW4)
const LIFT_HEIGHT := 6.0       # metres above the higher of start/end ground
const LIFT_TIME := 0.8         # seconds to lift off or settle

# ---- orbital -------------------------------------------------------------------
const LANCE_COST := 40.0
const LANCE_COOLDOWN := 60.0
const LANCE_DELAY := 2.0
const LANCE_RADIUS := 4.5      # cells
const LANCE_POWER := 7.0       # creeper removed at the centre

# ---- operative -----------------------------------------------------------------
const EYE := 1.7
const WALK := 6.0
const SPRINT := 10.0
const JUMP_V := 6.4
const GRAVITY := 18.0
const CLIMB := 1.1             # max terrain levels you can walk up between neighbouring cells
const OP_RADIUS := 0.35
const SUIT_MAX := 100.0
const SUIT_REGEN := 5.0
const REGEN_DELAY := 2.0
const OP_CREEPER_BASE_DPS := 9.0
const OP_CREEPER_DPS := 14.0
const CREEPER_SLOW := 0.5
const TANK_MAX := 100.0
const TANK_REGEN := 9.0
const RECALL_HOLD := 2.0
const TOTEM_FREE_RADIUS := 3.0   # metres: deploy to a Totem, and recall this close, are free and instant
const DROP_BASE := 20.0          # energy to drop on a Totem's own cell
const DROP_PER_CELLS := 4.0      # +1 energy per this many cells from the nearest Totem
const DROP_MAX := 80.0
const DROP_TIME := 3.0           # seconds the pod is visible before the Operative spawns
const RECALL_COOLDOWN_MULT := 2.0  # teleporter cooldown = this × path metres / WALK
const RECALL_NO_PATH_MULT := 1.4   # straight-line factor when no walkable path exists
const RESPAWN_ENERGY := 100.0
const RESPAWN_SALVAGE := 25.0
const RESPAWN_TIME := 45.0
const RESPAWN_GROWTH := 1.5      # each further death this level multiplies both respawn costs
const RIFLE := { "name": "Pulse Rifle", "damage": 1.0, "cooldown": 0.14, "range": 90.0 }
const ROCKET := { "name": "Rocket Launcher", "speed": 30.0, "range": 90.0, "blast": 3.0, "power": 6.0,
	"damage": 5.0, "mag": 4, "reload": 6.0 }  # blast in cells; power = creeper removed at the centre
const CROSSBOW := { "name": "Crossbow", "damage": 4.0, "speed": 75.0, "gravity": 14.0, "reload": 1.2,
	"range": 120.0, "stick_time": 5.0 }  # one physical bolt per shot, 4x a rifle pulse; stuck bolts stay stick_time s
const SPRAYER := { "name": "Null Sprayer", "range": 10.0, "half_angle": 0.45, "remove_per_sec": 5.0, "tank_per_sec": 20.0 }

# ---- First-person feel (Stage 23): viewmodel motion, spray, hit feedback --------
const VM_KICK_BACK := 0.075       # m the weapon snaps back per unit of kick
const VM_KICK_PITCH := 0.12       # rad the muzzle flips up per unit of kick (~7 deg)
const VM_CAM_KICK := 0.016        # rad of camera pitch per unit of kick (~0.9 deg, always returns)
const VM_YAW_KICK := 0.006        # rad of random camera yaw per unit of kick (recovers, never accumulates)
const VM_KICK_MAX := 1.7          # stacked kick cap (rapid fire)
const VM_SPRING_K := 1300.0       # recoil spring stiffness; damping below gives a slight overshoot
const VM_SPRING_DAMP := 34.0
const VM_STRING_SNAP := 0.07      # m the crossbow string jumps forward on a shot
const VM_BREATH := 0.0035         # idle sway amplitude (m)
const VM_BOB := 0.014             # walk bob amplitude (m), scaled by speed
const VM_SPRINT_DROP := 0.06      # m the weapon lowers when sprinting
const VM_SPRINT_TILT := 0.32      # rad of roll/pitch when sprinting
const VM_LAND_DIP := 0.012        # m of weapon dip per m/s of landing speed
const VM_LAG := 0.55              # rad of weapon trail per unit of mouse delta (px * 0.001)
const VM_TRACER_SPEED := 220.0
const SPRAY_MIST := 150           # mist puffs alive at once (hard cap)
const SPRAY_DROPLETS := 60
const FIZZ_POOL := 8              # fizz bursts at once
const FIZZ_PER_BURST := 12
const FIZZ_INTERVAL := 0.05       # s between fizz bursts while spraying
const HIT_MARKER_TIME := 0.18
const KILL_MARKER_TIME := 0.4
const HURT_ARC_TIME := 0.9
const BIG_HIT := 12.0             # damage that earns the screen-edge red vignette
const VIGNETTE_TIME := 0.7

# ---- HUD ------------------------------------------------------------------------
const HUD_OBJ_FLASH := 5.0    # seconds a new or just-completed objective shows its hint
const HUD_LOG_LINES := 5
const HUD_LOG_LIFE := 8.0     # seconds an ordinary log line stays; warn and bad last twice this
const HUD_BANNER_LIFE := 3.0  # centre banner ("COMMAND NODE LANDED" and the rest)
const HUD_BANNER_SIZE := 18   # about 60% of the old 30px banner
const HUD_HINT_SECS := 60.0   # mission seconds the bottom key-help row stays up (it sat on the build menu)

# ---- strongholds: castles (level/stronghold.gd, design §3.1 and §3.4) -------------
const CASTLE_WALL_HP := 300.0     # per stone wall segment; at 0 it is breached (TerrainEdit)
const CASTLE_GATE_HP := 200.0
const CASTLE_WINCH_HP := 150.0    # holds a raised castle's drawbridge to its owner
const CROWN_HP := 40.0            # crown nest on the spire top (grows like nests)
const CROWN_RADIUS := 1.2         # solid husk the Operative cannot walk into
const CASTLE_SALVAGE_RATE := 0.1  # Salvage/s from each castle you hold (turrets are bought with it)
const CASTLE_CAPTURE_SALVAGE := 30.0  # Salvage paid on capture: enough for a first turret before the counterattack
const CROWN_REGROW := 0.25        # share of HP the crown regrows with after a retake
const CASTLE_GARRISON := 4        # raiders a hostile castle keeps in its courtyard
const CAPTURE_TIME := 20.0        # seconds the Operative holds the spire top
const CAPTURE_DECAY := 0.02       # progress lost per second while nobody holds it
const CAPTURE_ABANDON := 30.0     # seconds at 0 progress before the crown regrows
const RETAKE_TIME := 15.0         # seconds of raiders in the courtyard to retake it
const CASTLE_AETHER_RATE := 5.0 / 60.0
const CASTLE_COUNTER_BASE := 2    # counterattack size: base + per tier (Stage 8a: pressure)
const CASTLE_COUNTER_PER_TIER := 2
const CASTLE_RAID_SHARE := 0.4    # share of marching raiders sent at castles you hold
const SPIRE_PUMP_RATE := 0.6      # creeper/s drawn per level of average moat depth
const PUMP_DEPTH_CAP := 3.0
const PUMP_JAM_TIME := 60
const PUMP_JAM_RANGE := 3.0
const ENEMY_BUILD_BASE := 1.0 / 180.0  # progress/s; first structure is ~3 min at pressure 0
const PUMP_REF := 1.8                  # full-moat intake (SPIRE_PUMP_RATE x PUMP_DEPTH_CAP)
const ENEMY_MAT_PER := 324.0           # pump stock spent per 1.0 of the intake bonus
const ENEMY_BUILD_REACH := 36.0        # cells from the spire centre a hub may build
const ENEMY_WEAPON_GAP := 10.0         # prefer a site at least this far from a weapon
const ENEMY_SLOTS_PRESSURE := 0.5      # a hub grows two structures at once from here
const ENEMY_WEAVER_SPEED := 3.0
const ENEMY_WEAVER_RESPAWN := 8.0
const ENEMY_LEECH_RANGE := 16.0        # a pump emits while an undenied Leech is this close
const ENEMY_LEECH_MAT := 0.15          # material/s one grown Leech adds to its hub
const ENEMY_BLIGHT_DPS := 1.5          # HP/s a Blight Pylon deals to structures in its radius
const JUMP_PAD_MARGIN := 1.5      # levels above the column top the pad throws you
## Castle stakes (castle_raids.gd). Levels override any key with their CASTLE_RULES.
const CASTLE_RULES := {
	"aggression": 1.0, "held_stack": 0.5,     # raid size and siege rate x aggression x stack
	"reprisal_warn": 60.0, "siege_interval": 240.0, "siege_warn": 45.0,
	"reprisal_base": 8, "reprisal_per_tier": 3, "siege_base": 4, "siege_per_tier": 2,
	"nest_buff": 0.25, "nest_buff_range": 30.0,  # +spawn rate per enemy castle within range (cells)
}
const CASTLE_SIEGE_MIN := 90.0    # sieges never come faster than this (seconds)

## Castle guards (castle_guards.gd): Sentinels on tower tops and the wall walk of hostile castles.
const GUARD_RANGE := 32.0         # cells; longer than a Sniper (26) on purpose
const GUARD_CHARGE := 0.8         # seconds of visible glow before each bolt
const GUARD_INTERVAL := 4.5       # seconds from one bolt to the next, per Sentinel
const GUARD_BOLT_SPEED := 16.0    # metres/s; a 64 m shot takes 4 s, so walking sideways dodges it
const GUARD_BOLT_RADIUS := 2.0    # metres from the impact point that still gets hurt
const GUARD_DMG_OPERATIVE := 14.0 # suit damage (SUIT_MAX is 100)
const GUARD_DMG_UNIT := 18.0
const GUARD_DMG_STRUCT := 20.0
const GUARD_RESPAWN := 90.0       # seconds for a dead Sentinel to regrow from the crown nest
const SENTINEL := { "name": "Sentinel", "hp": 30.0, "dps": 0.0, "speed": 0.0, "size": 1.1, "color": Color("ff4a5a") }

# ---- threats -------------------------------------------------------------------
const SPIRE_INTERVAL := 60.0
const SPIRE_MIN_INTERVAL := 20.0
const SPIRE_SPEEDUP := 0.92
const SPORE_AMOUNT := 14.0
const SPORE_HP := 3.0          # Beams can shoot volleys down
const CHARGE_FUSE := 3.0
const NULLIFY_TIME := 2.0      # CW3: the magazine drains over 2 s, then the emitter dies
const NULLIFY_RANGE := 10.0    # CW3 open disk r 10
const MITE_SPAWN := 6.0
const MITE_MAX := 6
const MITE_SPEED := 4.5
const MITE_DAMAGE := 12.0
const NEST_HP := 40.0
const NEST_HP_GROWTH := 0.1    # nests heal/grow by this share of NEST_HP per minute (max +10%/min)
const NEST_AGGRO := 22.0       # guards attack prey this close (metres)...
const NEST_LEASH := 34.0       # ...as long as it is this close to their nest
# Nests grow with mission time: the clock is the threat (see spore_nests.gd).
const NEST_SPAWN_START := 20.0 # seconds between spawns per nest at minute 0
const NEST_SPAWN_RAMP := 0.94  # interval multiplier per minute
const NEST_SPAWN_MIN := 5.0
const NEST_CAP_START := 3      # live raiders per nest at minute 0
const NEST_CAP_PER_MIN := 0.35
const NEST_CAP_MAX := 10
const NEST_GUARDS := 1         # one stays home; the rest of the opening cap marches (Stage 8 balance)
const NEST_RAID_DELAY := 300.0 # fallback grace period when a level has no RAID_SCHEDULE
## Hives (§3.3). Stage 0 is up at the start; later parts grow in. Mortar bodies are Phase 7.
const HIVE_P1 := 0.55 # spec 0.20; later so the scripted base still holds (Stage 8 balance)
const HIVE_P2 := 0.70
const HIVE_P3 := 0.85
const HIVE_P4 := 0.95
const HIVE_GROW := 20.0
const HIVE_REBUILD_TIME := 30.0
const HIVE_REBUILD_RANGE := 4.0   # cells
const HIVE_REBUILD_NEED := 3
const HIVE_RADIUS := 6.0          # cells; player structures on the site die when a rebuild lands
const HIVE_CORE_BASE := 30.0   # playtest 1: ~4 s of Pulse Rifle (7 dps), was 150 (~21-35 s). Make nests hard to reach, not slow to kill
const HIVE_CORE_PER_P := 15.0   # up to ~6 s at full pressure (was 100)
const HIVE_PIT_HP := 40.0
const HIVE_SPITTER_HP := 50.0
const HIVE_LAUNCHER_HP := 40.0
const HIVE_MORTAR_HP := 80.0
# Flyers (Stage 19; rows live in level/flyer_defs.gd)
const FLYER_ROOST_P := 0.30        # a hive grows its Roost at this pressure (the first flyer unlock)
const FLYER_ROOST_HP := 40.0
const FLYER_FIRST_DELAY := 20.0    # seconds from a Roost growing to its first flock
const FLYER_INTERVAL_START := 50.0 # seconds between flocks per Roost at the first unlock
const FLYER_INTERVAL_MIN := 22.0   # ...at full pressure
const FLYER_MAX := 24              # live flyers across the map
const FLYER_DIVE_RANGE := 4.0      # metres: a bat starts its dive this close to the target
const FLYER_SEAL_REPEAT := 40.0    # seconds between extra flocks while the Node stays sealed
const HIVE_STAGE4_HP := 1.5
const HIVE_SALVAGE := 40.0       # Core pickup (§4.4)
const LOOT_LIFE := 90.0          # seconds a Salvage orb stays
const LOOT_RANGE := 1.5          # metres; only the Operative collects
const LOOT_PART := 5.0           # any hive part other than the Core
const LOOT_CROWN := 15.0         # crown nest on a spire
const HIVE_LANCE_DMG := 100.0     # a Lance hurts the Core; it does not erase a fresh one
const HIVE_SPITTER_DMG := 6.0
const HIVE_SPITTER_INTERVAL := 2.0
const HIVE_SPITTER_RANGE := 20.0  # cells
const HIVE_SPITTER_SPLASH := 1.5  # cells
## Enemy mortars (§4.3). Range is in cells. The Operative takes a fraction of max suit at the centre.
const MORTAR_RANGE := 36.0
const MORTAR_MIN_RANGE := 6.0
const MORTAR_INTERVAL := 6.0
const MORTAR_BLAST := 2.5
const MORTAR_STRUCT := 30.0
const MORTAR_UNIT := 20.0
const MORTAR_OPERATIVE := 0.70
const MORTAR_TELEGRAPH := 2.5
const MORTAR_WHISTLE := 1.0       # last seconds of the telegraph
const MORTAR_SEAL := 60.0         # no walking route to the Node
const MORTAR_SEAL_BUILD := 60.0   # then a mortar is up within this long
const MORTAR_SIGHT := 25.0        # metres, Spotter line of sight
const MORTAR_SABOTAGE_TIME := 3.0
const MORTAR_SABOTAGE_RANGE := 3.0  # metres from an enemy mortar/structure centre to sabotage it (was 2.0: too tight to hit)
const SNIPER_LOS_SLACK := 1.0   # metres: a ray hit this close to the target still counts as a clear shot
const SNIPER_LOS_RETRY := 0.25  # seconds a Sniper waits before looking again when no foe is in sight
const MORTAR_SALVAGE := 5.0
const MORTAR_SPOTTER_RESPAWN := 30.0
## Overrun (§4.1): at pressure 1, every OVERRUN_INTERVAL each active nest sends this many
## straight at the Node. "Tier" is Pressure.legacy_tier (0..3), so a capped wave is 12.
const OVERRUN_INTERVAL := 45.0
const OVERRUN_BASE := 6
const OVERRUN_PER_TIER := 2
const RAIDER_MAX_TOTAL := 60
const RAIDER_AGGRO := 9.0      # metres: a marching raider attacks anything this close
const RAIDER_CLIMB := 1.1      # max terrain levels a raider may step up between cells
const RAIDER_DETOUR_TIME := 2.0  # s a raider blocked on its way to a target follows the flow field
const RAIDER_DROP := RAIDER_CLIMB # one terrace down as well; steeper ground is a wall
const RAIDER_FIELD_INTERVAL := 2.0
const RAIDER_STANDOFF := 0.65  # ranged raiders back up when closer than this share of their range
const RAIDER_SHOT_SPEED := 18.0 # m/s, acid lobs. A 40 m shot takes about 2 s and can be walked out of
const RAIDER_BEAM_SPEED := 32.0 # m/s, Lancer bolts. Still a travel time, so a moving target is missed
const RAIDER_BEAM_RADIUS := 1.2 # metres around the aim point. No splash
const RAIDER_LANCER_GAP := 1.5  # seconds after a Lancer bolt before the next charge (the charge itself is the row interval)
## Mixed groups (§4.2). Below this pressure, nests spawn one weighted raider at a time.
const GROUP_PRESSURE := 0.60 # spec 0.35; blobs start with Ravagers (Stage 8 balance)
const GROUP_GATHER := 10.0    # seconds the group mills at the nest before it marches
const GROUP_FRONT := 0.50     # share of a group that rolls front line
const GROUP_RANGED := 0.35    # then ranged; the rest are support
const GROUP_MIN := 4
const GROUP_MAX := 8
const MORTAR_RAIDER_DMG := 1.2 # mortar/Bertha splash vs one raider; 30% of a Sniper shot (power 4)
## Fallback tier unlock times (seconds) when a level has no RAID_SCHEDULE.
const RAIDER_TIER_TIMES := [0.0, 480.0, 900.0, 1320.0]
## Raider stats live in RaiderDefs (pressure unlocks). RAID_SCHEDULE.tier_times still advances
## the legacy 0..3 index that castle-raid size and the old escalate smoke read.

# ---- play metrics (PlayMetrics) -------------------------------------------------------
const METRICS_ON := true       # record events, samples and a summary per mission
const METRICS_SAMPLE := 10.0   # seconds between samples
const METRICS_MIN_QUIT := 60.0 # a quit/level change writes a partial file only after this long
const METRICS_HIT_GAP := 5.0   # Node-hit events are throttled to one per this many seconds

# ---- units (barracks) --------------------------------------------------------------
const UNITS_PER_BARRACKS := 4  # population cap: more barracks, more (dependent) units
const RESUPPLY_RANGE := 4.0    # metres from a barracks to draw supply
const RESUPPLY_RATE := 8.0     # ammo/s transferred while docked
const UNIT_CREEPER_BASE_DPS := 6.0
const UNIT_CREEPER_DPS := 12.0

# ---- effects (visual only; perf caps) -------------------------------------------------
const FX_MAX_ITEMS := 400  # live fx items; lobs are gameplay-relevant and are never culled
const FX_MAX_DEBRIS := 48  # live debris chunks from structure deaths
