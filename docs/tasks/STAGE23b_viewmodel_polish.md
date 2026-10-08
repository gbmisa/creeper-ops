# Stage 23b: Viewmodel polish (arms, Pulse Rifle model, spray brightness)

**Agent:** Muse Code or Claude Sonnet. **Worktree:** `creeper fps td-worktrees/stage23b` · **Branch:** `stage/23b-viewmodel-polish` · **Progress log:** `docs/tasks/STAGE23b_progress.md`
Read [LONG_RUN_RULES.md](LONG_RUN_RULES.md). **Visual only** inside `fps/arm_models.gd`, `fps/rifle_model.gd`, `fps/weapon_models.gd`, `fps/spray_fx.gd`, `fps/crossbow_fx.gd`, `fps/viewmodel_motion.gd` (animation only), `config.gd` (visual tunables). No gameplay numbers.

## Why (Opus review of Stage 23 screenshots)
Stage 23 works (kick, spray, arms, Pulse Rifle vs Crossbow), but stills show: the **arms are straight blue poles** with the gloves hidden behind the gun; the **Pulse Rifle is a stack of boxes**; the **Null Sprayer** at full spray turns into a big white bloom that covers the middle of the screen (blinding); the crossbow reload has no hand motion.

## Do
1. **Arms:** tapered forearm (wrist thinner than elbow), padded/armoured sleeve with a bronze bracer, a glove with visible fingers wrapped on the grip and the off hand on the foregrip; the upper arm angles in from the screen edge (no straight poles); colours match the Operative's suit (not saturated blue: muted dark leather + bronze).
2. **Pulse Rifle:** a readable silhouette at a glance: stock, receiver with rune-lit coil, a shrouded emitter barrel with cooling fins, a top sight with the crystal, a glowing energy cell; bevelled/tapered shapes (ShapeKit/strut/rod helpers), not raw boxes.
3. **Sprayer:** keep the mist obvious but **never white out the view**: cap particle alpha/emission so the centre of the screen stays readable through the spray (you can still see a raider through it), mist tinted pale cyan-green, steam at the impact cells brighter than the mist near the camera.
4. **Crossbow reload:** the off hand draws the string back and places a bolt during the 1.2 s.

## Verify
Parse + full smoke PASS. Xvfb before/after pairs with `--autostart --fire=rifle|crossbow|sprayer` (see `core/debug_fire.gd`): rifle at rest + kick, sprayer over creeper with a raider visible through it, crossbow mid-reload. Look at them; judge with [JUDGE_art_rubric.md](JUDGE_art_rubric.md).
