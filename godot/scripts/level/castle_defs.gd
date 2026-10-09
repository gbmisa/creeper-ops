class_name CastleDefs
## Tunables for concentric castles (Stage 21, docs/CASTLES2_DESIGN.md). A def table, so the
## numbers live in one place without crowding config.gd. Heights are whole levels over the yard.

# ---- shape (CastleShape2, CastleStairs, CastleKeepShape) ----------------------------
const OUTER_UP := 3          # outer wall top (the Stage 7 WALL_UP)
const INNER_UP := 4          # inner wall: taller, so the inner ring overlooks the bailey
const TOWER_UP := 6          # outer corner towers and the outer gatehouse roof
const INNER_TOWER_UP := 7    # inner gatehouse roof
const KEEP_UP := 7           # keep walls and roof
const HALL_UP := 1           # keep hall floor sits one level up: shallow ward creeper stays out
const BAILEY := 6            # default bailey width (cells between the walls)
const TOWER_HALF := 2        # towers are 5x5
const KEEP_HALF := 5         # 11x11 keep (with the spire column through the hall)
const KEEP_HALF_SMALL := 4   # 9x9 keep when the ward is narrow (no column)
const MIN_SIZE := 29
const GATEHOUSE_HALF := 6    # outer gatehouse spans n/2 - 6 .. n/2 + 6
const GATE_HALL := 3         # gate hall depth behind the gate cells (k 2..4)
const HEADROOM := 3          # min levels between floor and roof (2 is too low: the head meets the slab walking up a step)

# ---- staged capture (CastleStages) ----------------------------------------------------
const GATE_TIME := 10.0      # seconds in the gate hall
const BAILEY_TIME := 12.0    # seconds at the bailey standard
const RING_RETAKE := 15.0    # raiders on the last ring you took, nobody there: it's theirs again

# ---- 21b detail: stonework, fires, banners (CastleStonework, CastleInteriorMeshes) ----
const SLAB_BEAM_EVERY := 2   # oak beams under roof slabs, one row every N cells
const ARCH_SPRING := 1.7     # tower door-arch spring line above the door floor (m)
const KEEP_ARCH_SPRING := 2.0  # keep door-arch spring line above the hall floor (m)
const BRAZIER_ENERGY := 2.2  # brazier OmniLight energy
const BRAZIER_RANGE := 10.0  # brazier OmniLight range (m)
const TORCH_ENERGY := 0.9    # torch OmniLight energy
const TORCH_RANGE := 5.0     # torch OmniLight range (m)
const STANDARD_H := 6.0      # bailey standard pole height (m)

# ---- war engines: trebuchets on the outer corner towers (CastleEngines) --------------
const ENGINE := {
	"range": 40.0, "min_range": 8.0, "interval": 11.0, "telegraph": 3.0, "whistle": 1.0,
	"blast": 2.5, "dmg_struct": 45.0, "dmg_unit": 25.0, "dmg_operative": 22.0,
	"hp": 140.0, "respawn": 150.0, "sight": 80.0,
}
const ENGINES_DEFAULT := 2   # concentric rows without an "engines" key

# ---- held perks (CastlePerks) ----------------------------------------------------------
const REACH_RADIUS := 28.0   # cells from a held castle's centre
const REACH_BONUS := 0.25    # weapon range bonus inside it
const WARD_DRAIN := 0.03     # creeper depth/s removed per wet cell inside a held castle's outer wall
const WARD_TICK := 0.5
const WARD_HIVE_RADIUS := 30.0
const WARD_HIVE_SLOW := 0.3  # hives this close to a held castle spawn 30% slower
const MUSTER := true         # a held castle gets a free barracks in its ward
