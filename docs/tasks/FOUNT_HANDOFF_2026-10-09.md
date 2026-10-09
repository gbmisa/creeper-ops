# Fount handoff — Creeper work paused Fri 2026-10-09 ~16:50 MST

Gregory ordered a full pause: no repo refreshes, no workers, until **Wed 2026-10-14**.
The `creeper-ops-notes-watch` cron is disabled until then (a runonce re-enables it
Wed 08:00 MST). This brief is the complete state so you can pick up where I left off.

## Pushed branches ready for your review/merge (from main 863ed38a)

| Branch | SHA | What |
|---|---|---|
| fix/rally-point-marker | 50c89860 | Rally flag+disc+3D line on barracks select; 8/8 |
| fix/drawbridge-solid | 677b6c6d | Lowered decks solid for all factions (was owner-only); 11/11 + 60/60. OPEN: winch now only drives amber tint — repurpose or remove? |
| fix/barracks-cap-spawn | 287d133b | Cap 4→8; free-cell spawn + unstick repath; 6 checks (exact pass count unconfirmed — worker's final report was lost, checks are in-branch) |
| fix/burrower-telegraph | 454936cf | Visible smoke trail, surfacing rumble, unique `burrower_blast` (170 m falloff); mechanic untouched per Gregory; 10/10. Needs in-game ear tuning; Sfx is volume-by-distance only |
| fix/unit-attack-move | ab95737b | Move/return engages in gun range then resumes; burrowed Burrowers untargetable (units, snipers, castle repeaters); 7/7 |
| fix/bailey-capture-broken | efe5b795 | Root cause: castle marker was hardcoded to crown nest, misdirecting players. Marker now follows stage (gate→bailey→crown); L1 briefing line added; 42/42. OVERLAP: unmerged fix/bailey-standard-ux also retargeted the marker — reconcile |
| fix/terp-unlock | 4e4076e7 | Terp was locked behind an unlock no level granted; added to both level dicts; 29/29 |
| feat/pause-menu | 7628fb37 | Full pause menu both modes (Resume/Restart+confirm/Recall/Level select/Controls/Mute/Quit); 24/24. OVERLAP: pt3/pause-button below — reconcile |
| feat/tower-group-formation | b51eba14 | Drag box selects movable towers even with units in box (also fixed a latent crash that broke tower-only box select entirely); group move lands in compact formation; 9/9 |
| fix/unbuilt-creeper-kill | bb130c82 | Zero-progress unbuilt structures in creeper now die on contact (were immortal: `minf(0,0+x)`); partial builds keep CW3 progress-loss; 7/7 + 11/11 CW3 |
| fix/troops-into-castle | (pushed, SHA unconfirmed in my context) | Right-click pathing into held castle courtyards + discoverability hint |
| pt3/pause-button | 39f65c26 | PT3-C: top-bar pause/resume + speed buttons + PAUSED banner; 15/15. OVERLAP with feat/pause-menu — reconcile |

Earlier main-based branches (mortars, raider-circle, deploy-from-node, bailey-standard-ux,
network-planned-relays, fps-build-wheel, spitter-vs-structures, ammo-float-snap,
blight-pylon-aura, spawn-pacing) were reported previously and are unchanged.

## Stopped mid-flight — NO push, resume or redo from the brief

All 8 workers were shut down on Gregory's order. Partial work (if any) sits in my VM
worktrees only — treat the repo briefs as source of truth; I can resume from the
worktrees on Wednesday if you prefer continuity over a fresh start.

| Branch (exists remotely at brief commit) | Brief | Worktree |
|---|---|---|
| fix/keep-instant-convert | Gregory directive: keep converts INSTANTLY on crown death (no 20 s hold); keep counterattack/salvage/retake | ~/workspace/creeper-keepconvert/work |
| pt3/spore-spire | PT3-A: spire range cap, delayed first volley, pressure-scaled volleys | ~/workspace/creeper-pt3a/work |
| pt3/build-on-creeper | PT3-B: find/fix placement paths that allow building on creeper | ~/workspace/creeper-pt3b/work |
| pt3/sprayer-emitter | PT3-D: one sprayer can't permanently dry an emitter | ~/workspace/creeper-pt3d/work |
| pt3/castle-economy | PT3-E: castles pay 1.4 energy/s + 0.4 salvage/s while held; readability | ~/workspace/creeper-pt3e/work |
| pt3/objective-clarity | PT3-F: all objectives visible at once; castle markers styled OPTIONAL | ~/workspace/creeper-pt3f/work |
| pt3/l2-perf | PT3-G: time-sliced RaiderField rebuild; target <2 ms worst frame on L2 | ~/workspace/creeper-pt3g/work |
| pt3/bertha-target | PT3-H: manual Bertha targeting (trebuchets ok, mortars no); cost 600, 30 s interval | ~/workspace/creeper-pt3h/work |

PT3-A..H briefs live at docs/tasks/MUSE_PT3A..H_*.md on their branches (from integ/2026-10-09).

## Open design questions (Gregory's, unresolved)

1. **Gatehouse capture:** Gregory wants taking the gatehouse to be "destroying the gate via an
   objective (or lowering it)" instead of standing in the hall 10 s. Undecided: retake logic
   can't un-destroy a gate. Awaiting his call or your weighing.
2. **Salvage economy:** Gregory: "I get a ton from enemy drops. It should come from hooking
   into the network, not picking orbs up." I asked which source feels worst — no answer yet.
   Note PT3-E *raises* castle salvage to 0.4/s with his sign-off, which cuts the other way.
3. **Winch:** see drawbridge row above.
4. **New UI:** Gregory hasn't seen the ui-viewport-fit redesign — it's pushed but unmerged;
   his build is from main.

## Watch status

`creeper-ops-notes-watch` (every 5 min) disabled 2026-10-09; runonce `creeper-watch-resume-wed`
re-enables it Wed 2026-10-14 08:00 MST and runs one catch-up check. I fixed the watch script
same day: it now matches any-case `MUSE*.md` on main AND alerts on new branches (it had
missed the pt3/* briefs entirely).
