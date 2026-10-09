# Art 3 Track M progress (Opus, Blender)
Branch `art/3-models`, worktree `art3-models`. Godot loader is Muse brief A (branch `art/3-creature-anim`).
Tools: `art/blender/review.sh <name> <out.png>` builds one .glb and renders a 5-clip x 4-frame contact sheet; `build_all.sh` rebuilds all.
Shared: `lib.py` (Builder, armature, action baking, export), `legs.py` (insect legs with hip yaw, `pillar=True` legs swing fore-aft).
Contract: u = 1, feet z = 0, faces +X, clips idle/walk/attack/hit/die, material `glow` = tier colour.

| Creature | Status | tris |
|---|---|---|
| skitter | done | 1272 |
| brute | done | 1120 |
| ravager | done | 1200 |
| behemoth | done | 1686 |
| sentinel | done (fixed size: game scale 1) | 595 |
| spitter lancer warden spotter burrower | done (`bug_kit.py` shares idle/walk/hit/die) | 1140/580/728/786/698 |
| spore_bat gasbag wyvern | done (`flyer_kit.py`; origin = body centre; walk = flap) | 502/1756/658 |
| soldier crawler hive_core | done | 804/622/558 |
| trebuchet | built (castle engine, throws +X; not graded yet) | 640 |
| hive_pit hive_spitter hive_launcher hive_mortar hive_roost | done (`struct_kit.py`: static, walk = idle, shared hit/die; game `HiveMeshes.part(kind)` → `hive_<kind>`; real metres, scale 1; spitter/mortar face +X) | |

**Bone scale gotcha:** pose scale is bone-local, and bone **y = along the bone**. For a vertical bone, "taller" is the 2nd component, not the 3rd.
Hidden parts (spit blob, shell, flash, flyer, wave ring) sit at scale 0.01 outside their attack clip.

## Grading (Sonnet grader on contact sheets, 3 iterations, target 8)
Round 1 avg 6.1, round 2 avg 6.8, round 3 avg 7.4. At 8: brute, crawler, sentinel, soldier, spore_bat, warden. At 7: the rest.
Open notes for the in-game pass: wyvern head/neck merge into a round body (lengthen neck and tail, bone-tan ridge); burrower claws +30% and wider; gasbag bigger squash and sag, close the body-tendril gap; lancer two-handed angled spear, thicker torso; skitter bigger rear-up attack; behemoth stomp bob; hive_core opening/jaw on attack; idle breath everywhere; tier accents so bugs don't all read as dark purple blobs (the in-game tier glow helps here).
Hive structures (same grader, 3 rounds): avg 6.7 → 7.3 → 7.75. hive_core 8.5, hive_spitter 8, hive_launcher 8, hive_pit 7.5, hive_mortar 7.5, hive_roost 7, plus a polish pass after round 3 (bigger shell, darker pit lip, thicker cradle, tighter roost collapse). Open: spitter snout/brow, mortar star flash, roost flyer launches up toward the camera.
