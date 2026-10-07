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
const CREEPER_TICK := 1.0 / 15.0
const FLOW_RATE := 0.22        # fraction of head difference moved per neighbour per tick
const MIN_DEPTH := 0.02        # below this a cell counts as dry
const MAX_DEPTH := 25.0
const DAMAGE_DEPTH := 0.06     # structures/units take damage above this depth
const STRUCT_DPS := 14.0       # Command Node: damage per second per unit depth
const STRUCT_BASE_DPS := 6.0   # Command Node: flat damage per second while wet at all
const WEAPON_CREEPER_DPS := 2.5       # built weapons: extra damage per second per unit depth
const WEAPON_CREEPER_BASE_DPS := 5.5  # built weapons: flat per second while wet. Depth 1 is
                                      # 8 HP/s (40 HP cannon lasts 5 s); depth 3 is 13 HP/s.

# ---- economy (CW3: energy IS packets; no launch cap) -----------------------------
const START_ENERGY := 0.0     # the Node lands empty: first packets come from its own output
const NODE_STORAGE := 60.0     # the Command Node's own bank
const OUTPOST_STORAGE := 50.0  # each built Outpost adds this to the shared bank; no income
const NODE_INCOME := 0.8       # packets/s the Command Node generates by itself
const REQ_BUILD := 2.5         # packets/s one structure may request while under construction
const REQ_AMMO := 4.0          # packets/s one weapon may request for ammo
const REQ_UNIT := 2.0          # packets/s a barracks may request for training/supply
const PACKET_SPEED := 18.0     # metres per second along links
const RECYCLE_REFUND := 0.5
const COLLECT_RADIUS := 3      # half-size of a collector's SQUARE field (7x7 cells, CW3/CW4 style)
const COLLECT_PER_CELL := 0.005 # energy/s per claimed dry cell (a full 49-cell field ~0.25/s)
const REPAIR_PER_SEC := 1.5    # HP/s regen when dry and connected
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
const RECALL_COST := 25.0
const KO_PENALTY := 50.0
const TELEPORT_COOLDOWN := 20.0
const RIFLE := { "name": "Pulse Rifle", "damage": 1.0, "cooldown": 0.14, "range": 90.0 }
const ROCKET := { "name": "Rocket Launcher", "speed": 30.0, "range": 90.0, "blast": 3.0, "power": 6.0,
	"damage": 5.0, "mag": 4, "reload": 6.0 }  # blast in cells; power = creeper removed at the centre
const SPRAYER := { "name": "Null Sprayer", "range": 10.0, "half_angle": 0.45, "remove_per_sec": 5.0, "tank_per_sec": 20.0 }

# ---- strongholds: castles (level/stronghold.gd, design §3.1 and §3.4) -------------
const CASTLE_WALL_HP := 300.0     # per stone wall segment; at 0 it is breached (TerrainEdit)
const CASTLE_GATE_HP := 200.0
const CASTLE_WINCH_HP := 150.0    # holds a raised castle's drawbridge to its owner
const CROWN_HP := 60.0            # crown nest on the spire top (grows like nests)
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
const JUMP_PAD_MARGIN := 1.5      # levels above the column top the pad throws you

# ---- threats -------------------------------------------------------------------
const SPIRE_INTERVAL := 60.0
const SPIRE_MIN_INTERVAL := 20.0
const SPIRE_SPEEDUP := 0.92
const SPORE_AMOUNT := 14.0
const SPORE_HP := 3.0          # Beams can shoot volleys down
const CHARGE_FUSE := 3.0
const NULLIFY_TIME := 8.0
const NULLIFY_RANGE := 4.0
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
const NEST_GUARDS := 2         # raiders per nest that stay home once raids start
const NEST_RAID_DELAY := 300.0 # fallback grace period when a level has no RAID_SCHEDULE
const RAIDER_MAX_TOTAL := 60
const RAIDER_AGGRO := 9.0      # metres: a marching raider attacks anything this close
const RAIDER_CLIMB := 1.1      # max terrain levels a raider may step up between cells
const RAIDER_DROP := RAIDER_CLIMB # one terrace down as well; steeper ground is a wall
const RAIDER_FIELD_INTERVAL := 2.0
const MORTAR_RAIDER_DMG := 1.2 # mortar/Bertha splash vs one raider; 30% of a Sniper shot (power 4)
## Fallback tier unlock times (seconds) when a level has no RAID_SCHEDULE.
const RAIDER_TIER_TIMES := [0.0, 480.0, 900.0, 1320.0]
## Raider tier stats. When each tier unlocks lives on the level (RAID_SCHEDULE.tier_times).
const RAIDER_TIERS := [
	{ "name": "Skitter", "hp": 4.0, "dps": 3.0, "speed": 4.2, "size": 0.45, "color": Color("a8ff5a") },
	{ "name": "Brute", "hp": 16.0, "dps": 8.0, "speed": 3.4, "size": 0.75, "color": Color("ffd24a") },
	{ "name": "Ravager", "hp": 40.0, "dps": 16.0, "speed": 4.0, "size": 0.9, "color": Color("ff7a3a") },
	{ "name": "Behemoth", "hp": 120.0, "dps": 35.0, "speed": 2.6, "size": 1.4, "color": Color("ff3355") },
]

# ---- units (barracks) --------------------------------------------------------------
const UNITS_PER_BARRACKS := 4  # population cap: more barracks, more (dependent) units
const RESUPPLY_RANGE := 4.0    # metres from a barracks to draw supply
const RESUPPLY_RATE := 8.0     # ammo/s transferred while docked
const UNIT_CREEPER_BASE_DPS := 6.0
const UNIT_CREEPER_DPS := 12.0
