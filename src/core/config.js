// Global tuning constants. Gameplay numbers live here so balancing never means hunting through logic.

export const WORLD = {
  CELL: 2,          // world metres per grid cell
  LEVEL_H: 1,       // world metres per terrain level (1 level == 1 unit of creeper depth)
  DETAIL: 3,        // terrain mesh vertices per cell edge (visual only)
};

export const CREEPER = {
  TICK: 1 / 15,           // fixed sim step (s)
  FLOW_RATE: 0.22,        // fraction of head difference moved per neighbour per tick
  MIN_DEPTH: 0.02,        // below this a cell is considered dry
  MAX_DEPTH: 25,
  DAMAGE_DEPTH: 0.06,     // structures/units take damage above this depth (CW: any creeper hurts)
  STRUCT_DPS: 14,         // structure damage per second per unit depth
  STRUCT_BASE_DPS: 6,     // flat damage per second while wet at all
};

// Creeper World-style economy: energy is sent as packets along the network.
export const ECONOMY = {
  START_ENERGY: 30,
  BASE_MAX: 80,           // the ship's own storage
  SHIP_INCOME: 0.8,       // per second
  PACKET_RATE: 7,         // packets the ship can launch per second (network throughput)
  PACKET_SPEED: 16,       // metres per second along links
  RECYCLE_REFUND: 0.5,    // fraction of build cost returned when you recycle
  COLLECT_RADIUS: 3,      // cells a collector claims (CW "field")
  COLLECT_PER_CELL: 0.022, // energy/s per claimed dry cell
  REPAIR_PER_SEC: 1.5,    // HP/s regen when dry and connected
};

export const OPERATIVE = {
  EYE: 1.7,
  WALK: 6,
  SPRINT: 10,
  JUMP_V: 6.4,
  GRAVITY: 18,
  CLIMB: 1.1,              // max terrain levels you can walk up between neighbouring cells
  RADIUS: 0.35,
  SUIT_MAX: 100,
  SUIT_REGEN: 5,           // per second when dry (after a short delay)
  REGEN_DELAY: 2,
  CREEPER_BASE_DPS: 9,     // per second just for touching creeper
  CREEPER_DPS: 14,         // extra per second per unit depth at your feet
  CREEPER_SLOW: 0.5,       // movement multiplier while wading
  TANK_MAX: 100,
  TANK_REGEN: 9,
  RECALL_HOLD: 2,
  RECALL_COST: 25,
  KO_PENALTY: 50,
  TELEPORT_COOLDOWN: 20,
};

export const WEAPONS = {
  rifle: { name: 'Pulse Rifle', damage: 1, cooldown: 0.14, range: 90 },
  sprayer: { name: 'Null Sprayer', range: 10, halfAngle: 0.45, removePerSec: 5, tankPerSec: 20 },
};

export const THREATS = {
  SPIRE_INTERVAL: 60,       // seconds between spore volleys at start
  SPIRE_MIN_INTERVAL: 20,
  SPIRE_SPEEDUP: 0.92,      // interval multiplier after each volley
  SPORE_AMOUNT: 14,
  CHARGE_FUSE: 3,
  NULLIFY_TIME: 8,
  NULLIFY_RANGE: 4,
  MITE_SPAWN: 6,            // cave
  MITE_MAX: 6,
  MITE_SPEED: 4.5,
  MITE_DAMAGE: 12,
  NEST_HP: 40,
  NEST_SPAWN: 9,            // seconds between surface mites per nest
  NEST_MAX: 4,              // live mites per nest
  NEST_AGGRO: 22,           // metres: mites leave the nest to chase things this close
  NEST_LEASH: 34,           // metres: mites return if they stray this far from the nest
  SURFACE_MITE_HP: 3,
  SURFACE_MITE_DPS: 10,     // damage per second while touching a unit/structure
};
