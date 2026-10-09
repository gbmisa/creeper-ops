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
| trebuchet | done (castle engine, throws +X; fire pot payload, anticipation, frame rock) | |
| totem drop_pod | done (`totem` = structure `beacon`: attack = Operative deploys; `drop_pod`: walk = falling, attack = touchdown + doors open, idle = landed, die = recall sink) | |
| hive_pit hive_spitter hive_launcher hive_mortar hive_roost | done (`struct_kit.py`: static, walk = idle, shared hit/die; game `HiveMeshes.part(kind)` → `hive_<kind>`; real metres, scale 1; spitter/mortar face +X) | |

**Bone scale gotcha:** pose scale is bone-local, and bone **y = along the bone**. For a vertical bone, "taller" is the 2nd component, not the 3rd.
Hidden parts (spit blob, shell, flash, flyer, wave ring) sit at scale 0.01 outside their attack clip.

## Grading (Sonnet grader on contact sheets, 3 iterations, target 8)
Round 1 avg 6.1, round 2 avg 6.8, round 3 avg 7.4. At 8: brute, crawler, sentinel, soldier, spore_bat, warden. At 7: the rest.
Open notes for the in-game pass: wyvern head/neck merge into a round body (lengthen neck and tail, bone-tan ridge); burrower claws +30% and wider; gasbag bigger squash and sag, close the body-tendril gap; lancer two-handed angled spear, thicker torso; skitter bigger rear-up attack; behemoth stomp bob; hive_core opening/jaw on attack; idle breath everywhere; tier accents so bugs don't all read as dark purple blobs (the in-game tier glow helps here).

## 2026-10-08 (night): player structures (for A4)
- `weapon_kit.py`: weapons as 3 glbs (base / turret / arm), pivots from WeaponMeshes; `wreview.sh` previews the assembled weapon.
- Grades (Sonnet, 3 rounds max): cannon 5→6→7, mortar 5.5→6.5→7, sniper 5→6→6.5, beam 5→6.5→7.5, collector 6→7, relay 6→7.
- Lessons: a 3-fold spinning part must turn a third of a turn per loop (or 2-fold, half a turn), or the 4 sampled frames alias. Rune slits go on the face apothem, not the corner radius. Emissive flame reads as salmon in the preview, so use the saturated `fire` / `ray_red`.

## 2026-10-08: military models (Gregory: "more military, less futuristic brass")
Bertha 7, Thor 7, Terp 8, Nullifier 7, Outpost 8 (Sonnet grader, up to 3 rounds each). Branch `art/3-models`.
- Lessons: concrete or olive on the grey preview floor blends, so use dark concrete with bold hazard bands. Emissive colours need to be saturated (void 9a2bff, arc 00b4ff). Thin parts disappear at RTS distance; titans need about 1.5x part thickness.
- 2-part models: `weapon_kit.run(..., parts=("base", "core"))`. The Terp `Spin` and the Nullifier `Core` stay code-driven.
Hive structures (same grader, 3 rounds): avg 6.7 → 7.3 → 7.75. hive_core 8.5, hive_spitter 8, hive_launcher 8, hive_pit 7.5, hive_mortar 7.5, hive_roost 7, plus a polish pass after round 3 (bigger shell, darker pit lip, thicker cradle, tighter roost collapse). Open: spitter snout/brow, mortar star flash, roost flyer launches up toward the camera.
Player side + trebuchet (same grader, 3 rounds): totem 6 → 7 → 7.5, drop_pod 4 → 7 → 7.5, trebuchet 7 → 7 → 7.5 (+ flame polish). Open: totem value contrast (teal plinth rim), stronger hit flashes (needs emission animation in game, not bone scale), visible projectile arcs (the game's own projectile covers that).
Wyvern: neck and tail lengthened, bone ridges (open note). `lathe(cap=False)` for rings: capped lathes made solid discs.
