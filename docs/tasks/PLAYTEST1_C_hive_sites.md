# Playtest 1 C: hives that are hard to reach, not slow to kill

**Agent:** Muse Code (first calibration task) or Sonnet `level-builder` as fallback. **Worktree:** `creeper fps td-worktrees/playtest1c` · **Branch:** `fix/playtest1-hive-sites` (from `main` at the Playtest 1 merge).
**Why:** hive cores now die in about 4-6 s (`HIVE_CORE_BASE` 30). The challenge should move from killing the core to *getting there*. The user: "nests need to be in areas that make them hard to get to instead of having a long, boring time to kill."

## Read only
AGENTS.md, CLAUDE.md (Key contracts: terrain, Raider reachability, Castles, Blight), `docs/tasks/LONG_RUN_RULES.md`, this brief, `level/level01.gd`, `level/level02.gd`, `level/level_ramps.gd`, and the smoke files you run. Don't read whole design docs.

## Task
For **every hive on L1 (3) and L2 (4)**, give its site one or more access challenges, built from existing tools only (terrain shaping in the level file, `LevelRamps` stairs, Blight zones, emitter placement):
- **Plateau:** the hive sits 3+ terrace levels up; one stair or ramp is the only way up, and it faces away from the player's likely base.
- **Behind Blight or creeper:** the walk crosses a Blight strip or a low channel an emitter keeps filling, so the player has to time it or clear it.
- **Chokepoint:** one narrow pass (1-2 cells) the hive's own raiders use, so the Operative meets them head-on.
- **Cave mouth / overhang:** only if it falls out of the existing terrain naturally.

Mix them: no two hives on a level use the same main challenge.

## Hard constraints
- **Raiders must still leave.** Hive raiders need a walking route to the player's side (`RaiderField.reachable`). A hive whose raiders can't get out is a bug.
- **The Operative can reach every core on foot** from the landing area (or recall pad). The route may be long or dangerous, but it must exist without Terp.
- No decorative height noise inside the map (CLAUDE.md). Whole terrace levels only.
- Don't move castles, emitters' ids, ore veins or the landing site. If you move a hive, update every Salvage Engine row that names it (`"hive": "<name>"`) so `smoke_placement` stays green: engines more than 7 cells from any hive, at least 3 cells from emitters, clear of castle rects.
- Don't change any `config.gd` number. Balance is a separate task.

## Phases (at most 2 per session, keep `docs/tasks/PLAYTEST1C_progress.md`)
- **P1 L1:** reshape the 3 sites. Add a smoke file `core/smoke_hive_sites.gd` (register it with one line in `smoke_test.gd`). It checks, per hive on L1 and L2: (a) the Operative flood from the landing area reaches a cell within 2 of the core, (b) the raider field reaches the player half of the map from the hive, (c) a written `access` tag on the hive row (`"access": "plateau"` etc.) is one of the allowed kinds and unique per level. Commit.
- **P2 L2:** same for the 4 L2 hives. Commit.
- **P3 verify:** parse, full smoke (0 failures), `--autostart --sim=600` and `--demo --units --sim=900` on both levels, with Node death times before → after. Xvfb screenshots of every hive site from the command view (`--look=x,z`) to the scratch folder. Commit.

## Report (AGENTS.md "When you finish")
Plus a table: hive → access kind → how the Operative gets there → how its raiders get out.
