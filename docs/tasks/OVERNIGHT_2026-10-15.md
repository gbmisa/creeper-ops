# Overnight queue 2026-10-15 (Gregory: "create multiple phases to work overnight", use ~40% of the week's budget)
Orchestrator: Opus (main session). Each step is a fresh background agent; the next starts when the last reports.
Tracks touch different worktrees and files, so A, B and C run side by side. Nothing merges into fix/fb-guns,
integ or main: Gregory plays the results in the morning. Every agent: brief + progress log, ≤2 phases, report
<250 words, parse / range / smoke green, list every behaviour change. Opus is used where the work is judged by
pictures or is the recoil port Gregory called "massively important"; Sonnet for plain implementation.

## Track A: reload animations (worktree ../fb-reload, branch feat/fb-reload, brief FB_R_reload_anims.md)
- A1 (running, Opus): phase 1 = system + AK47, M1911, resumed from the 1e07209 handover.
- A2 (Opus): detachable mags: glock18, mp5, p90, scarh, sr25, sks, saiga12 (mag split in Blender where no
  Magazine bone). M4A1 posed arms: propose only, don't touch (needs Gregory).
- A3 (Opus): tube (shotgun), en-bloc (garand), bolt (mosin, sniper), revolver.
- A4 (Opus): merge fix/fb-i into feat/fb-reload (new vector/pkm), then vector, pkm (mag split in their scratch
  scripts: add a separate mag part), m4a1 (Gregory: "animate all guns": his posed arms stay untouched at rest; during
  the reload the viewmodel blends to the IK FpArms the timeline drives, then back).
- **Judge loop (Gregory 2026-10-15: "have a judge agent look at them and go up to 3 iterations shooting for a 8/10"):**
  after each A phase a separate Opus judge agent (never the builder, never Haiku) grades every gun's empty and
  tactical reload sheets 0-10 with `docs/tasks/FB_R_judge_rubric.md`. Any gun under 8 goes back to a fix agent with
  the judge's notes; re-judge; at most 3 judge rounds per gun. Scores + notes in `docs/art/reload/SCORES.md`.

## Track B: Tarkov recoil + hip fire (worktree ../fb-i-recoil, branch fix/fb-i-recoil, cut from fix/fb-i after F62)
Brief FB_I_tarkov_recoil.md + FB_I_trp_recoil_spec.md.
- B1 (Opus): phase 1, the model + the AKM acceptance checks.
- B2 (Opus): phase 2, wiring (bullets along the barrel, camera kick, kick back, hip on the dot, classic removed)
  + live tuning panel.
- B3 (orchestrator): judge mid-burst hip/ADS strips; Opus fix-up agent if needed.

## Track C: Muse branches FB-A/B/C (worktree ../review-muse, branch review/muse-fb-abc off fix/fb-i after F62)
- C1 (Opus): merge fix/fb-a-ragdoll, fix/fb-b-skirmish, fix/fb-c-range one at a time; resolve conflicts (FB-C
  "restart loadout" vs F55 kit carry likely); review each diff against its brief and the change-only-what-was-asked
  rule; parse / range / smoke after each; findings list. No push.
- C2 (Sonnet): fix the findings C1 marks as bugs (not design), one commit each.

## Track D: morning build (after A, B, C)
- D1 (orchestrator): branch night/2026-10-15 = fix/fb-i + fix/fb-i-recoil + feat/fb-reload + review/muse-fb-abc,
  parse / range / smoke, headless range -> deploy -> skirmish flow, screenshot pass. HANDOFF.md + play command.

## Status
- F59 no repro (Gregory to say how the P90 failed). F55, F58, F60, F61, F62 done on fix/fb-i.
- B DONE: B1 60d7f07 (AKM numbers match TRP), B2 1fb2902 (barrel bullets, camera kick, auto stable mode, hip-settle
  rule, classic toggle removed, F7 panel). Range 661 / smoke 1264 OK. Opus look: burst poses plausible; the muzzle
  flash blob is big in Xvfb shots (pre-existing flash, not changed). Gregory A/Bs with F7. Pivot 0.25 m is a guess.
- C DONE: merged A/B/C + fixes (0dee4dc..1b23bed); range 690, smoke 1264 OK; CHANGES M1-M6 for Gregory. Watch a
  rare Mosin bolt check flake (2 checks once in 3 runs).
- A: A1 8b35a57; judge r1 71777b1 (ak 6/5/5, m1911 8/7/7); A2a (round-1 fixes) running.
