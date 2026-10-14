# gdflow: a lightweight, governed game-design flow

A small CLI (Python 3.9+, standard library only) plus two Claude Code skills that turn
"dream up ideas → decide → build → verify" into a repeatable, governed loop for **any** game
project. It never calls a model itself: Claude Code (or you) does the thinking; gdflow keeps the
context lean, the state honest and the human in charge.

```
 charter ─▶ /dream ─▶ score ─▶ /greenlight ─▶ brief ─▶ agent builds ─▶ review ─▶ human plays ─▶ verified
 (pillars)  (lenses)          (human approves) (task file)  (one branch)   (orchestrator)            + decide
```

## Governance built in
- **Charter first.** `check` fails until the pillars are real (no TODOs). Every idea names a pillar.
- **Humans decide.** Only an approver (`approvers` in `gdflow.json`, default `human`) can move an idea to
  `approved` or `verified`; the skill asks the user explicitly. `check` flags any approval by a non-approver.
- **State machine:** `raw → scored → approved → briefed → built → verified` (+ `parked`, `rejected`,
  both need `--why`). Briefs are only written for approved ideas.
- **Append-only decisions** (`DECISIONS.md`, D-001…) for anything settled.
- **The gate** (`gdflow check`, exit 1 on errors): charter, handoff size and age, idea integrity, brief
  completeness, file size limit, and (with `--run`) the project's own test commands.

## Install
Copy this folder into a project (e.g. `tools/gdflow`) and run `python3 tools/gdflow …`,
or install once for all projects: `pip install ./tools/gdflow` → `gdflow …`.

## Start a new project
```
gdflow init --name "My Game" --design-dir design
```
Creates `design/PILLARS.md` (charter), `design/PLAN.md`, `HANDOFF.md`, `AGENTS.md`,
`design/DECISIONS.md`, the idea board, the `/dream` and `/greenlight` skills, a SessionStart hook that
prints `gdflow status --hook`, and a short section in `CLAUDE.md`. **It never overwrites a file.**

## Adopt an existing project
Point gdflow at the docs you already have instead of creating new ones (Creeper Ops does this):
```
gdflow init --name "Creeper Ops" --design-dir docs/design --pillars-file docs/MASTER_PLAN.md \
  --plan-file docs/MASTER_PLAN.md --tasks-dir docs/tasks --agent-rules AGENTS.md
```
Then edit `gdflow.json`: `systems` (fuel for idea collisions), `playtest_globs`, `line_limit`, `checks`.

## Commands
| Command | What it does |
|---|---|
| `status [--hook]` | Plan stage counts, idea pipeline, what waits on a human, gate summary |
| `check [--run]` | Governance gate; `--run` also runs `checks` commands (fails on exit code or `fail_if` text) |
| `dream [--count N] [--focus X] [--lens id …] [--seed S]` | Prints an ideation packet: pillars, plan, recent changes, playtest notes, board, 3 random lenses, a system collision and a constraint |
| `lenses` | The lens deck (MDA, Schell, Bartle, SCAMPER) and constraints |
| `idea add/list/show/score/move` | The pipeline. Priority = (2·fun + 2·fit + novelty) / (cost + risk) |
| `brief I-007 [--model M] [--read files]` | Writes `<tasks_dir>/I007_<title>.md` with Why, Scope, Acceptance, Verify, Report |
| `decide "rule" --why … --by human` | Appends a numbered decision |

## In Claude Code
- `/dream [focus]`: runs `dream`, diverges then converges, files and scores ideas, never approves.
- `/greenlight`: walks you through scored ideas with AskUserQuestion, records your calls, writes briefs.
- Session start: the hook prints a 3-5 line status, so an orchestrator doesn't need to read the plan.

## Files it owns
`gdflow.json` (config), `<design_dir>/ideas.json` (source of truth), `IDEAS.md` (generated board),
`DECISIONS.md`. Everything else it only reads.

## Tests
`python3 -m unittest discover -s tools/gdflow/tests`
