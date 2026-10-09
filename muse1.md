# Muse: next task prompts (2026-10-08)

Muse works from the private repo **https://github.com/gbmisa/creeper-ops** (no SSH). Each prompt is one task on its own branch. They share no files, so they can run in parallel, one Muse session each. Briefs: [docs/tasks/ART3_MUSE_briefs.md](docs/tasks/ART3_MUSE_briefs.md). When one finishes, tell Opus the branch name; Opus fetches it, reviews it and merges it.

## Status (Opus, 2026-10-08 evening)
- **Merged:** Playtest 1C hive sites (stripped the `.godot` cache; Opus ran the sims: no balance change).
- **Merged:** `art/3-gun-feel` and `fount/ui-pass` (reviewed; parse/smoke clean). The UI pass wasn't briefed: next time, list ideas as suggestions instead (AGENTS.md rule 1).
- **Queue now (late 2026-10-08):** A3 and C are running. **Start now:** P fix-up, S, T, A4, K (5 workers, separate branches and files).
- Your P3 log for 1C had `<numbers>` placeholders and claimed Xvfb shots you can't take. Write "not run (no display)" instead; Opus takes the screenshots.

## P: L2 raider pressure + trebuchets (playtest 2, top priority: the game is currently unfair)
```
Clone https://github.com/gbmisa/creeper-ops and check out branch fix/playtest2-pressure. Read AGENTS.md, CLAUDE.md, docs/tasks/LONG_RUN_RULES.md and docs/tasks/PLAYTEST2_pressure.md, plus the files it links. Do that brief and nothing else. Commit and push only to fix/playtest2-pressure. Never touch main, never merge. Report in the AGENTS.md format.
```

## A: creature animation runtime (do this first: the Blender models plug into it)
```
Clone https://github.com/gbmisa/creeper-ops and check out branch art/3-creature-anim. Read AGENTS.md, CLAUDE.md, docs/tasks/LONG_RUN_RULES.md and docs/tasks/ART3_MUSE_briefs.md section "A: creature animation runtime", plus the files it links. Do that section and nothing else. Commit and push only to art/3-creature-anim. Never touch main, never merge. Report in the AGENTS.md format.
```

## F: gun feel
```
Clone https://github.com/gbmisa/creeper-ops and check out branch art/3-gun-feel. Read AGENTS.md, CLAUDE.md, docs/tasks/LONG_RUN_RULES.md and docs/tasks/ART3_MUSE_briefs.md section "F: gun feel", plus the files it links. Do that section and nothing else. Commit and push only to art/3-gun-feel. Never touch main, never merge. Report in the AGENTS.md format.
```

## X: effects
```
Clone https://github.com/gbmisa/creeper-ops and check out branch art/3-fx. Read AGENTS.md, CLAUDE.md, docs/tasks/LONG_RUN_RULES.md and docs/tasks/ART3_MUSE_briefs.md section "X: effects", plus the files it links. Do that section and nothing else. Commit and push only to art/3-fx. Never touch main, never merge. Report in the AGENTS.md format.
```

## C: Castles 21b detail pass (after P, A and X are pushed)
```
Clone https://github.com/gbmisa/creeper-ops and check out branch stage/21b-castles-detail. Read AGENTS.md, CLAUDE.md, docs/tasks/LONG_RUN_RULES.md and docs/tasks/STAGE21b_castles_detail_long.md, plus the files it links. Do that brief and nothing else, phase by phase, with one commit per phase. You have no display: skip every "screenshot / look at it" step and write "screenshots: Opus" in the progress log; Opus judges the visuals after you push. Commit and push only to stage/21b-castles-detail. Never touch main, never merge. Report in the AGENTS.md format.
```

## B: small bug fixes (any time; independent of the others)
```
Clone https://github.com/gbmisa/creeper-ops and check out branch fix/muse-b-bugs. Read AGENTS.md, CLAUDE.md and docs/tasks/MUSE_B_bugs.md. Do that brief and nothing else. Commit and push only to fix/muse-b-bugs. Never touch main, never merge. Report in the AGENTS.md format.
```

## A2: creature models integration fixes (do next: blocks the Art 3 merge)
```
Clone https://github.com/gbmisa/creeper-ops and check out branch art/3-integration. Read AGENTS.md, CLAUDE.md and docs/tasks/ART3_A2_integration.md. Do that brief and nothing else. Commit and push only to art/3-integration. Never touch main, never merge. Report in the AGENTS.md format.
```

## A3: hive structures, Totem and drop pod use the animated models (after A2; Opus creates the branch)
```
Clone https://github.com/gbmisa/creeper-ops and check out branch art/3-hive-models (if it doesn't exist yet, A2 isn't merged: wait). Read AGENTS.md, CLAUDE.md, docs/tasks/MUSE_NOTES.md and docs/tasks/ART3_A3_hive_models.md. Do that brief and nothing else. Commit and push only to art/3-hive-models. Never touch main, never merge. Report in the AGENTS.md format.
```

## S: screenshot tour hook (start now; independent)
```
Clone https://github.com/gbmisa/creeper-ops and check out branch tools/shot-tour. Read AGENTS.md, CLAUDE.md, docs/tasks/MUSE_NOTES.md and docs/tasks/MUSE_S_shot_tour.md. Do that brief and nothing else. Commit and push only to tools/shot-tour. Never touch main, never merge. Report in the AGENTS.md format.
```

## T: Stage 13 tuning audit (start now)
```
Clone https://github.com/gbmisa/creeper-ops and check out branch stage/13-tuning-audit. Read AGENTS.md, CLAUDE.md, docs/tasks/MUSE_NOTES.md and docs/tasks/STAGE13_tuning_audit.md. Do that brief and nothing else: measure and propose, change no numbers. Commit and push only to stage/13-tuning-audit. Never touch main, never merge. Report in the AGENTS.md format.
```

## A4: player weapons, Collector and Relay models (start now; runs beside A3)
```
Clone https://github.com/gbmisa/creeper-ops and check out branch art/4-structure-models. Read AGENTS.md, CLAUDE.md, docs/tasks/MUSE_NOTES.md and docs/tasks/ART3_A4_structure_models.md. Do that brief and nothing else. Commit and push only to art/4-structure-models. Never touch main, never merge. Report in the AGENTS.md format.
```

## K: file-size cleanup (start now; small)
```
Clone https://github.com/gbmisa/creeper-ops and check out branch chore/k-split-files. Read AGENTS.md, CLAUDE.md, docs/tasks/MUSE_NOTES.md and docs/tasks/MUSE_K_cleanup.md. Do that brief and nothing else. Commit and push only to chore/k-split-files. Never touch main, never merge. Report in the AGENTS.md format.
```

## P fix-up (same P worker, branch fix/playtest2-pressure)
```
Fetch main and read docs/tasks/MUSE_NOTES.md, note "X and B merged; P needs fixes before merge". Fix the 4 items on fix/playtest2-pressure, rerun parse and smoke (0 failures), push, and report.
```

## Rules reminder
- **Opus leaves notes in [docs/tasks/MUSE_NOTES.md](docs/tasks/MUSE_NOTES.md) on `main`. Fetch `main` and read it before you start or resume any brief.** (Latest: hold-to-fire spread and recoil climb added to B.)
- Muse has headless Godot 4.7.2: run the parse and smoke checks and headless sims yourself. Screenshots and GPU checks are Opus's job (Muse has no display).
- All four tasks can run at once, one worker per branch.
- For brief A: real models are on branch `art/3-models` (`godot/assets/models/*.glb`, made by Opus). Copy `skitter.glb` into your branch **only for testing, then remove it before the final commit**; Opus merges the models from its own branch.
- **Never commit `godot/.godot/`** (editor cache) or anything else `.gitignore` excludes; the API push doesn't apply `.gitignore`, so check paths yourself. (Playtest 1C P1 committed it; Opus strips it at merge.)
- If Muse pushes to `main`, rewrites AGENTS.md or merges anything: stop it and tell Opus.
