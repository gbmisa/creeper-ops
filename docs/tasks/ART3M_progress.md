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
| sentinel | todo (fixed size, robed archer, bow on its left = Blender +Y) | |
| spitter lancer warden spotter burrower | done (`bug_kit.py` shares idle/walk/hit/die) | 1140/580/728/786/698 |
| flyers, soldier/wagon units, hive core | todo | |
