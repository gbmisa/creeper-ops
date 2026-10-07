# Development Plan & Model Routing

## Why route by model
Most tasks in this codebase are small and well bounded, because files are under 250 lines and tuning is data-driven. Cheaper models can do most of the work if each task is scoped to a few named files. Save the top models for work that is **cross-cutting, ambiguous, or design-heavy**.

| Model | Use it for | Avoid it for |
|---|---|---|
| **Haiku 4.5** (`haiku`) | Mechanical edits: tuning numbers in `config.js`/level files, new rows in data tables, ASCII cave maps, copying a level template, running the test commands and summarising output, line-count audits, doc touch-ups | Anything touching more than ~3 files, new systems, debugging unclear failures |
| **Sonnet 5.5** (`sonnet`) | The default implementer: a new structure, weapon, or enemy type following an existing pattern, HUD panels, bug fixes with a known repro, level layouts from a written design, writing tests | Re-architecting, designing new core systems, final balance calls |
| **Opus 5.5** (`opus`) | Architecture and new core systems (director/escalation, save system, editor), tricky sim or perf work, multi-file refactors, design reviews, root-causing weird bugs | Routine edits (wasteful) |
| **Fable 5.1** (`fable`) | Optional, for the hardest open-ended design or system problems if Opus stalls. Check your plan's pricing first | Anything routine |

**How to apply in Claude Code**
- Run the main session on Sonnet for day-to-day work (`/model`). Switch to Opus for a planning or architecture session, then back.
- Delegate scoped jobs to the subagents in `.claude/agents/`. Each one pins its model:
  - `level-builder` (Haiku): new levels and caves from a written spec
  - `balance-tester` (Haiku): runs sims and screenshots, reports numbers, edits only `config.js` and level data
  - `feature-dev` (Sonnet): implements one feature that follows an existing pattern
- Give every delegated task (1) the files to touch, (2) the acceptance check (a sim report field, a screenshot, or a `node --check` pass), and (3) "stay under 250 lines per file".

## Roadmap
> **Superseded by [MASTER_PLAN.md](MASTER_PLAN.md)** (2026-10-07). The phases below are the old prototype-era roadmap, kept for history. The model-routing guide above still applies.

### Phase 1: Prototype (done)
Level 01 "Hollow Ridge": fluid sim, structures and network, Spire / emitters / shielded emitter, beacon teleport, surface and cave FPS, Core set piece, objectives, debug hooks.

### Phase 2: Feel & clarity (next)
| Task | Model |
|---|---|
| Playtest pass: list friction points from a real session | **You** (human) + Opus to triage |
| Minimap / overview of the surface while underground (base HP alerts) | Sonnet |
| Audio: weapon, creeper slosh, alarms (WebAudio module) | Sonnet |
| Structure HP bars, damage flashes, under-attack pings | Sonnet |
| Terraforming (raise/lower cells; CW fans love it) | Opus design → Sonnet build |
| Art pass: better meshes and materials per structure | Sonnet (or Blender MCP) |
| Tune level 01 to 15–25 minutes | Haiku (`balance-tester`) |

### Phase 3: Escalation systems (saved direction, build when asked)
The goal is to fix Creeper World's "turtle, then cleanup duty" problem. Levels should be beatable only with strategy, skill and route planning, and not on the first try.
| Task | Model |
|---|---|
| **Director system**: data-driven per-level timeline that ramps emitter rates, adds sources, and changes rules mid-level | **Opus** (design + core), Sonnet (content hooks) |
| **Reinforcements**: enemy drop-ships or spores that arrive on a schedule and target weak points, so passive defense fails | Opus design → Sonnet build |
| **Time-gated objectives** (from level 3): "kill X before T", escorts, closing windows | Sonnet, on top of the director |
| Dynamic difficulty knobs (spawn rate, reinforcement speed) exposed in level data | Sonnet → Haiku tuning |
| Long-level balance (30–45 min, a loss is acceptable) | Haiku sims + human playtests |

### Phase 4: Content
| Task | Model |
|---|---|
| Levels 02–06 from one-paragraph specs (surface + cave) | Opus writes specs → Haiku/Sonnet build (`level-builder`) |
| New operative gear (grenade, grapple, deployable turret) | Sonnet |
| New underground target types (moving heart, timed reactor) | Opus design → Sonnet build |

### Phase 5: Tooling & longevity
| Task | Model |
|---|---|
| In-browser level editor (writes the level data format) | Opus architecture → Sonnet |
| Save/load and level select | Sonnet |
| Performance: worker-thread creeper sim, larger maps | Opus |
