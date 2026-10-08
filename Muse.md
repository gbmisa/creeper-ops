# Using Muse on Creeper Ops

Written 2026-10-08 so it doesn't get lost in chat. Short version: **Muse Code** (Meta's terminal coding agent) can take over the role Grok Build had. It runs on your machine in a worktree, reads our `AGENTS.md` by itself, edits files, runs Godot's tests, and commits to its own branch. Claude Opus stays the orchestrator: it writes briefs, reviews, and is the only one that merges into `main`.

## 1. What Muse Code is (checked 2026-10-08)
- A CLI coding agent from Meta, backed by the Muse Spark models (default `muse-spark-1.2`; Spark 1.3 is the newest).
- Runs on Linux, macOS and Windows. Installs a native `muse` binary.
- Interactive mode: `muse` (a terminal UI with slash commands and approval prompts).
- Headless mode: `muse exec "<prompt>"` runs a task to completion without you there.
- Reads project instructions from **`AGENTS.md`** (falls back to `CLAUDE.md`). We already have an `AGENTS.md` written for delegated agents, so Muse gets our rules automatically.
- Sign-in: browser login with your Meta account, or an API key in `META_API_KEY` for headless use.
- I could not find official numbers for plan limits. Your 100M tokens/week is what your plan says; check your usage on dev.meta.ai.

## 2. One-time setup (about 5 minutes)
```bash
curl -fsSL https://dev.meta.ai/install.sh | sh     # official installer (you can open the URL first to read it)
muse --version                                      # check it installed
cd "/home/gregory-milligan/AI projects/creeper fps td-worktrees/stage20"
muse                                                # first run: trust the folder, sign in in the browser
```
**Do NOT run `muse init`.** It seeds a new `AGENTS.md`; ours is already written and must not be replaced. If Muse ever offers to create or rewrite `AGENTS.md`, say no.

## 3. How to give Muse a task
Same pattern as Grok. Every task has a brief in `docs/tasks/` and its own worktree (table: `docs/tasks/README.md`).

1. `cd` into the task's worktree (never the main folder `creeper fps td/`).
2. Start `muse` and paste this one line:
   > Read AGENTS.md, CLAUDE.md, HANDOFF.md, docs/MASTER_PLAN.md, docs/tasks/LONG_RUN_RULES.md and docs/tasks/<BRIEF>.md, then do that task and nothing else. Commit only on this worktree's branch. Never merge.
3. For long unattended runs (overnight), use headless mode instead, from the worktree:
   ```bash
   muse exec "Read AGENTS.md, CLAUDE.md, HANDOFF.md, docs/MASTER_PLAN.md, docs/tasks/LONG_RUN_RULES.md and docs/tasks/<BRIEF>.md, then do that task and nothing else. Commit only on this worktree's branch. Never merge." 2>&1 | tee muse_run.log
   ```
   Headless can't ask you to approve commands. If it stops on approvals, run it interactively and approve "always" for `godot`, `git add/commit`, `xvfb-run`, `grep`, `ls`, `cat`.
4. Progress shows up in `docs/tasks/<STAGE>_progress.md` in the worktree (the long-run rules make every agent keep one). If a run dies, the next agent resumes from that file.
5. When it's done, tell Claude Opus: "Muse finished <stage>, review and merge." Opus checks it and merges.

**Run at most 3-4 agents at once** (Claude + Muse combined). Each one runs Godot tests and screenshots, and too many at once slow the machine and make timing-sensitive smoke checks flaky.

## 4. Who does what
| Work | Who | Why |
|---|---|---|
| Orchestration, design of new mechanics, reviews, merges into `main` | **Claude Opus** | Cross-system judgment; one owner for `main` |
| Implementation from a written brief | **Muse Code** first (big budget), **Claude Sonnet** when Muse is busy or a task needs care | Follows briefs and patterns |
| Audits, running sims, small tuning, docs | **Claude Haiku** or Muse | Mechanical |

## 5. Task queue (as of 2026-10-08)
**Running now (Claude, background):** Stage 21 Castles 2.0 (Opus, worktree `stage21`), Stage 9b Salvage Engines + ammo + placement + tuning (Sonnet, `stage9b`), Stage 19 flyers (Sonnet, `stage19`). Don't start Muse in those three worktrees. (Stage 23 first-person feel is done and merged: recoil, spray, arms, Pulse Rifle + a reloading Crossbow on **Y**.)

**Ready for Muse now:**
| Worktree | Brief | Notes |
|---|---|---|
| `stage20` | `STAGE20_art2_long.md` | Art pass 2. **Skip its first-person recoil part** (Stage 23 does that); keep weapon effects on *network* weapons, hits, deaths, walk cycles, the cave |
| `stage23b` | `STAGE23b_viewmodel_polish.md` | Short. Arms that look like arms, a real Pulse Rifle silhouette, the sprayer not blinding you, a reload hand. Good first Muse task to see how it does |
| `bench512` | `BENCH512_long.md` | Measures a 512×512 map. Needs your real display for the GPU numbers, so run it when you're at the PC |

**Coming next (Opus writes the brief first):**
- `STAGE21b_castles_detail_long.md`: castle decor, interiors, turret variety. The castle agent writes it when it finishes.
- Stage 22 auto-advance: weapons creep forward as ground is cleared. Opus designs it, then Muse or Sonnet builds it.
- Bug fixes from your playtest notes. Opus turns them into a brief.

## 6. Spending the Claude budget before it resets (~16 h from 2026-10-08 afternoon)
1. Let the four Claude agents above finish. Opus reviews and merges each one as it reports.
2. Start Muse on `stage20` now, and on `bench512` when you're home.
3. Playtest whatever has merged and write notes. Opus turns them into briefs, and Muse burns through them on its own weekly budget.
4. After the reset, Opus does the next round of design and reviews: castle detail, auto-advance, playtest fixes.

## 7. Things to know
- **Privacy:** Muse sends the prompts and the files it reads to Meta's servers. Same trade as Grok and Claude.
- **Muse Spark API** (pay-as-you-go: $1.25 / $4.25 per million input/output tokens) is a separate route. You only need it for scripted `muse exec` with an API key or other tools such as OpenRouter. Your plan's browser login is enough for normal use.
- **If Muse misbehaves** (edits `main`, rewrites `AGENTS.md`, merges): stop it, tell Opus, and Opus will clean up. `git worktree list` shows which folder belongs to which task.

Sources: [Meta Muse Code docs](https://dev.meta.ai/docs/muse-code), [Meta announcement of Muse Spark / Model API](https://ai.meta.com/blog/introducing-muse-spark-meta-model-api/), [Muse Code getting started (SitePoint)](https://www.sitepoint.com/meta-muse-code-getting-started/), [CNBC on the Muse Code launch](https://www.cnbc.com/2026/08/05/meta-debuts-muse-code-to-take-on-anthropic-and-openai-.html), [musecodes.io (unofficial; AGENTS.md handling)](https://musecodes.io/docs/).
