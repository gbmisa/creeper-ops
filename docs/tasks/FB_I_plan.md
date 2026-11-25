# FB-I plan: playtest fixes F55-F63 (start here after /clear)
Feedback: `docs/playtests/feedback_2026-10-15.md` (main checkout). Base: branch `fix/fb-h-ads-rule` (worktree `../fb-h`,
1f799cf, not merged). Make one branch `fix/fb-i` off it (worktree `../fb-i`); every agent below commits there, one at a
time (they touch overlapping files). Gregory plays `godot --path "/home/gregory-milligan/AI projects/creeper fps td-worktrees/fb-i/godot" res://scenes/firing_range.tscn`.
Rules: CLAUDE.md "change only what Gregory asked" (FB-H ADS alignment is **frozen**, F57). Opus reviews every diff and
judges every screenshot; no Haiku on images. Each agent: brief in `docs/tasks/FB_I_<item>.md` with a must-not-change list,
≤2 phases, report <250 words. Verify each: parse, `--range-test` all OK, smoke 0 FAIL.

## Ask Gregory first (one AskUserQuestion)
1. F60 PKM: Opus models a new low-poly PKM, or remove it from roster/racks/crates now?
2. F58 / F59: which other guns clip in ADS / won't fire (besides Mosin / P90)?
3. F63: after the first hip shot lands on the dot, do follow-up shots keep today's spread?

**Answers (2026-10-15):** 1. Model a new PKM. 2. Only Mosin (F58) and P90 (F59); still test every gun.
3. F63: "make it like tarkov, don't even make a classic version, do research on projects that notate the effects and
how it calculates vertical and horizontal recoil with a little bit of randomness with each shot, this is a massively
important aspect of game design to get right." -> F63 folds into item 7: hip fire + recoil become Tarkov-only (the
classic recoil path and the toggle go away, his explicit ask). Research several sources before the brief.
Worktree `../fb-i` (branch fix/fb-i off 1f799cf) created, parse clean.

## Order
1. **F59 guns won't fire** (Sonnet `feature-dev`). Range test: every gun fires N rounds and mag drops by N. Suspect
   first: FB-H `Gun._init` sets `def.fit` (P90 red dot) without `_after_fit()` (mag cap not set). Fix, list each gun found.
2. **F55 skirmish loses the kit** (Sonnet). Review/port WIP `fix/f48-deploy-kit` (../f48, untested; brief in that
   worktree) onto fix/fb-i. Test: range loadout -> deploy -> skirmish keeps every gun + fit. Play that flow before merge.
3. **F62 infinite range ammo** (Sonnet). Range map only: spares/reserve never run out, reload animation still plays.
   Skirmish unchanged (test both).
4. **F63 hip fire** (Sonnet). First hip shot goes exactly to the hip dot; ADS untouched; rest per Gregory's answer.
5. **F58 ADS clipping** (Opus, here). ADS shot of every gun (`--weapon=ID --ads --wait=1.5 --shot=...`, xvfb opengl3
   1600x900); find what crosses the eye. Expected rule addition (CHANGES.md entry first if it changes non-clipping
   guns): relief grows until no gun/arm geometry sits between the eye and the rear sight.
6. **F61 Vector + F60 PKM models** (Opus, Blender; check MCP with get_addon_status, else headless `blender -b`).
   Scratch low-poly (Gregory likes it). Unrigged single mesh, then re-measure sight points with
   `art/guns_src/sight_slab.gd` into `art/gen/mounts.json`; ADS check stays green.
7. **F56 Tarkov recoil** (Opus brief, Sonnet build, own branch after 1-6 merge). Source: TRP
   `TRP/docs/spec/weapon-handling.md` (fetch: `gh api repos/JuanFNQ/TRP/contents/TRP/docs/spec/weapon-handling.md
   --jq .content | base64 -d`), Recoil section only. Port springs/per-shot force/camera share/kick back/bullets along
   barrel into the existing Tarkov toggle (CHANGES P3 approved); live tuning panel; Gregory A/Bs.

## After each item
Update `docs/playtests/feedback_2026-10-15.md` status, HANDOFF.md (short); after all, merge fb-h + fb-i into
`fix/fb-guns` only when Gregory has played it.
