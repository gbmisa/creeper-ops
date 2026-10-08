# Muse: next task prompts (2026-10-08)

Muse works from the private repo **https://github.com/gbmisa/creeper-ops** (no SSH). Each prompt is one task on its own branch. They share no files, so they can run in parallel, one Muse session each. Briefs: [docs/tasks/ART3_MUSE_briefs.md](docs/tasks/ART3_MUSE_briefs.md). When one finishes, tell Opus the branch name; Opus fetches it, reviews it and merges it.

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

## Rules reminder
- Godot 4.7 is needed for the parse and smoke checks. If Muse's environment doesn't have it, it should say so in the report and Opus runs the checks.
- If Muse pushes to `main`, rewrites AGENTS.md or merges anything: stop it and tell Opus.
