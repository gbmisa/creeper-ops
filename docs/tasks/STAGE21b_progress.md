# Stage 21b progress log (Castles detail pass)

Branch `stage/21b-castles-detail`. Brief: [STAGE21b_castles_detail_long.md](STAGE21b_castles_detail_long.md).
Rules: [LONG_RUN_RULES.md](LONG_RUN_RULES.md), repo [AGENTS.md](../../AGENTS.md).
**No display on this machine: every "screenshot / look at it" step is recorded as
"not run (no display); Opus judges visuals". No placeholders, no claimed screenshots.**

## P0 audit (no code)

Baseline (tree at 0aa2823b, Godot 4.7.2-stable headless, 2026-10-09 ~03:13 UTC):
- Parse: `--headless --path . --import` — 0 script errors.
- Smoke: 734 PASS, 0 FAIL (`[smoke] OK: 0 failure(s)`).
- Sims:
  - `--demo --units --sim=900`: node_hp 500, over=false, time 900 — node survives.
  - `--autostart --sim=900`: node_hp 0, over=true, time 341 — node dies t=341.
  - `--level=2 --demo --sim=900`: node_hp 0, over=true, time 391 — node dies t=391.
  - `--level=2 --autostart --sim=900`: node_hp 0, over=true, time 229 — node dies t=229.
- Screenshots: not run (no display); Opus judges visuals.

### Rubric scores (code-based; no screenshots possible on this machine)
Judged against [JUDGE_art_rubric.md](JUDGE_art_rubric.md) criteria relevant to castles.
1. Fantasy coherence: 4/5 (stone/bronze/wood read; slabs are the flat note).
2. Weapon arms: n/a (no change this stage).
3. Weapon readability: n/a.
4. Scale: 4/5 (towers +6/+7 over yard dwarf the Operative; headroom respected).
5. Enemies: n/a.
6. Castles: 3/5 (reads as a castle, but bare: flat slabs, empty halls, no parapets on roofs).
7. Gameplay readability: 3/5 (roofs hide creeper in command view; no reach ring on trebuchets).
8. Polish: 3/5 (no floating parts found in code; plain surfaces everywhere).

### 10 weakest things, ranked
1. Roof slabs are flat untextured stone — the most visible castle surface in command view (P1).
2. Command view cannot see creeper under roofs (P4).
3. Halls lit by a single bare OmniLight; no braziers or torches (P2).
4. No parapets/merlons on keep roof or gatehouse roof edges (P1).
5. No stone arches over interior doors (P1).
6. Keep hall is empty: no dais, tables, weapon racks, rug (P3).
7. Gate hall is empty: no winch wheel/chains for the portcullis (P3).
8. No bailey standard or gate-stage banner showing capture progress (P2/P4).
9. Turret variety: Repeater/Lobber/Flak share one model (P5).
10. Hostile castles feel ungarrisoned: no wall patrols, no hall guard (P6).
Also queued: portcullis raise/lower tween, enemy builder skipping taken baileys,
`--castle2=0,gate`/`tower` spot aim (all P8).

### Phase order decision
Kept as briefed (P1→P8). The weakest list maps 1:1 onto the phase order and the
phases have a natural build dependency (stone → light → props → readability).
No reorder justified.

## P0 done
- Commit: FILL (pushed via push_work.py; branch `stage/21b-castles-detail` created).
- No code changed. Log written; phase order kept as briefed.

## P1 stone that reads as a castle — FILL
## P2 light and life — FILL
## P3 interior props — FILL
## P4 command-view readability — FILL
## P5 turret variety — FILL
## P6 castle guards — FILL
## P7 castle-only production — FILL
## P8 Stage 21 leftovers — FILL

## Suggestions (unbriefed, not implemented)
- (append as phases run)
