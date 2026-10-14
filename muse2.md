# Muse: gdflow ideas I-001..I-006 (2026-10-14)

One **long run** for Muse (Opus 5-class): build all six ideas Gregory approved on the
[idea board](docs/design/IDEAS.md), one phase per idea, on **one branch**, for Opus 5.5 to review.
Briefs: `docs/tasks/I00*.md` (one per idea, written by `gdflow brief`). Rules: AGENTS.md +
[LONG_RUN_RULES.md](docs/tasks/LONG_RUN_RULES.md). Progress log: `docs/tasks/IDEAS_progress.md`.

## Order (least risky first; later phases may read earlier ones' metrics)
| Phase | Idea | Brief | Main files |
|---|---|---|---|
| P0 | prep | (below) | `core/smoke_test.gd` (251 lines: move the registration list to a new `core/smoke_registry.gd` first), new `smoke_ideas.gd` |
| P1 | I-001 loss debrief | `I001_Why_you_lost_a_metrics_debrief.md` | new `metrics_turning_points.gd`, `play_metrics.gd` |
| P2 | I-006 last-stand overdrive | `I006_Last_stand_overdrive.md` | new `overdrive.gd`, `weapon_logic.gd` (fire_interval), keybinds, top bar |
| P3 | I-002 designator | `I002_Paint_targets_for_the_network.md` | new `designator.gd` + `target_priority.gd`, `weapon_logic.gd` (_snipe/_lob) |
| P4 | I-004 pressure bounties | `I004_Pressure_bounties.md` | `pressure.gd`, new `bounties.gd`, `level01.gd`, objectives |
| P5 | I-005 hidden ore surveys | `I005_Survey_charges_for_hidden_ore.md` | `level01.gd` ores, new `ore_survey.gd`, placement |
| P6 | I-003 drowning crown nests | `I003_Flood_the_courtyard.md` | crown nest tick, `CastleGuards`; **respect DECISIONS D-001** |

## Prompt (paste into Muse)
```
Clone https://github.com/gbmisa/creeper-ops, check out branch claude/game-design-automation-gy0p8q, and create branch muse/ideas-i001-i006 from it (this prompt authorises creating and pushing exactly that one branch; nothing else).

Read AGENTS.md, CLAUDE.md (Key contracts, Conventions, Testing), docs/tasks/LONG_RUN_RULES.md and muse2.md. Then do phases P0..P6 from the table in muse2.md, in order. For each phase P1..P6 read only that phase's brief in docs/tasks/ plus the files it names; do that brief and nothing else.

P0: create docs/tasks/IDEAS_progress.md (one section per phase). smoke_test.gd is already 251 lines: move its list of smoke-file calls into a new core/smoke_registry.gd (class_name SmokeRegistry, same order, no behaviour change) and register a new smoke_ideas.gd there; start smoke_ideas2.gd when the first nears 250 lines. Record the baseline: parse, smoke pass count, and the `--demo --units --sim=900` and `--autostart` [sim] lines.

Every phase: implement the brief's Scope, meet its Acceptance, run every Verify step, update the progress log (what you did, test output, every decision where the brief was silent, anything unfinished), then commit "IDEAS Pn: I-00N <title>" and push to muse/ideas-i001-i006. Keep each phase playable: parse clean and full smoke all PASS before committing. If a phase is blocked after ~3 real attempts, log exactly why, revert its half-done part and continue with the next phase.

Hard limits: every file under ~250 lines; new tunables only in config.gd or level data; never rename action/structure ids or touch user://keybinds.cfg; creeper must not hurt nest-bred raiders (docs/design/DECISIONS.md D-001). Do not edit HANDOFF.md, CLAUDE.md or anything in docs/design/ (Opus moves ideas on the board). In docs/MASTER_PLAN.md change only Stage 26's status cell and add one Changelog line at the end. With no display, write "screenshots: Opus". Never touch main, never merge, rebase or force-push.

Finish with the AGENTS.md report, per phase: done / partial / skipped, commit hash, smoke counts, sim lines before/after, new files (so Opus can update the CLAUDE.md map), and Suggestions.
```

## Opus 5.5 review (in the main checkout, after Muse reports)
1. `git fetch origin muse/ideas-i001-i006` and read `docs/tasks/IDEAS_progress.md` first; review one phase commit at a time.
2. Per phase: the diff matches its brief's Scope and nothing else; tunables in `config.gd`; files under 250 lines; smoke counts only grew; the two baseline sims within 10% unless the brief expects a change.
3. Check the risky spots: P2 stall guard sits where packets launch (no leaks); P3 `_snipe`/`_lob` fall back cleanly when nothing is designated; P4 `Pressure.offset` resets per level and clamps; P6 asserts nest raiders take no creeper damage.
4. Take the screenshots Muse couldn't (or ask an `auditor` for a verdict in words).
5. For each accepted phase: `python3 tools/gdflow idea move I-00N built`. Gregory plays them; only he runs `... verified --by human`.
6. Merge the gdflow branch and the Muse branch to `main` together (strip `godot/.godot/`), re-run smoke, update the CLAUDE.md map with the new files, HANDOFF.md and MASTER_PLAN Stage 26.
