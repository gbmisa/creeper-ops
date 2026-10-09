"""Heavy mortar in three parts (weapon_kit), military: a squat sandbagged concrete bunker with
hazard band, olive armour collar and sandbag stacks on its corners (base); a gunmetal turntable
with armour cheeks, a shell rack and ammo crates (turret); a heavy box-beam arm whose forked
olive cradle holds a fat gunmetal mortar tube on steel trunnions, a heat glow deep in the bore
(arm). Pivots match WeaponMeshes.mortar: Turret y 1.3, Arm at (-0.45, 0.3), wrist
(0.838, 1.345), tube 0.1 ahead and 0.45 above the wrist, tilted 0.25 forward.
Clips: idle = heat glow breathes; attack = arm dips, the tube kicks, a fireball and a smoke puff
leave the mouth; hit = shudder; die = bunker sinks, sandbags fall, the tube tips over.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
import mil_kit as mk  # noqa: E402
import weapon_kit as wk  # noqa: E402
from mathutils import Quaternion, Vector  # noqa: E402

T = Vector((0, 0, 1.3))
A = T + Vector((-0.45, 0, 0.3))
E = A + Vector((0.321, 0, 1.156))
W = A + Vector((0.838, 0, 1.345))
B = W + Vector((0.1, 0, 0.45))
MZ = B + Vector((0, 0, 0.6))  # bowl mouth at rest (untilted); the bowl bone carries the tilt
TILT = 0.25
CHUNKS = [("chunk%d" % i, (math.cos(a), math.sin(a))) for i, a in enumerate(math.pi / 4 + k * math.pi / 2 for k in range(4))]

BONES = [("base", (0, 0, 0), (0, 0, 0.5), None, "base")]
BONES += [(n, (x * 0.84, y * 0.84, 1.3), (x * 0.84, y * 0.84, 1.6), "base", "base") for n, (x, y) in CHUNKS]
BONES += [("turret", tuple(T), tuple(T + Vector((0, 0, 0.3))), None, "turret"),
          ("arm", tuple(A), tuple(A + Vector((0, 0, 0.3))), "turret", "arm"),
          ("head", tuple(W), tuple(W + Vector((0.3, 0, 0))), "arm", "arm"),
          ("bowl", tuple(B), tuple(B + Vector((0, 0, 0.4))), "head", "arm"),
          ("ember", tuple(B + Vector((0, 0, 0.25))), tuple(B + Vector((0, 0, 0.5))), "bowl", "arm"),
          ("flash", tuple(MZ), tuple(MZ + Vector((0, 0, 0.3))), "bowl", "arm"),
          ("smoke", tuple(MZ), tuple(MZ + Vector((0, 0, 0.3))), "head", "arm")]
PIVOTS = {"base": (0, 0, 0), "turret": tuple(T), "arm": tuple(A)}
TUBE = [(0.0, -0.5), (0.3, -0.5), (0.46, -0.36), (0.48, -0.1), (0.42, 0.0), (0.42, 0.62), (0.32, 0.62), (0.3, -0.05)]


def geometry(k):
    # base: slab, sandbags, squat concrete bunker, collar, hazard band, slit, corner sandbag stacks
    mk.slab(k, 1.15, 0.16, "base")
    mk.sandbags(k, 0.82, 0.16, "base", rows=2, per=4)
    mk.square(k, 0.8, 0.16, 1.0, "concrete", "base", top_half=0.72)
    mk.column_trim(k, 0.8, 0.72, 0.16, 1.0, "base", seams=(0.55,))
    mk.square(k, 0.76, 1.0, 1.3, "olive", "base")
    mk.hazard_band(k, 0.76, 1.08, 0.1, "base", n=8)
    for f in ((1, 0), (0, 1)):
        k.box((f[0] * 0.74, f[1] * 0.74, 0.75), (0.04 + 0.6 * f[1], 0.04 + 0.6 * f[0], 0.1), "rubber", "base")
    mk.ladder(k, -0.75, 0, 0.16, 1.3, "base", face=(-1, 0))
    for n, (x, y) in CHUNKS:
        q = Quaternion((0, 0, 1), math.atan2(y, x) + math.pi / 2)
        for z, s in ((1.37, 1.0), (1.52, 0.8)):
            k.ball((x * 0.88, y * 0.88, z), 0.2 * s, "sandbag", n, scale=(1.5, 0.85, 0.5), seg=8, rings=4, rot=q)
    k.lathe([(0.52, 1.28), (0.68, 1.28), (0.68, 1.4), (0.52, 1.4), (0.52, 1.28)], "gunmetal", "base", seg=16, cap=False)
    # turret: turntable, armour cheeks, shell rack, ammo crates
    mk.turntable(k, 0.6, 1.3, 1.46, "turret")
    for s in (1, -1):
        k.box((A.x, s * 0.36, 1.62), (0.7, 0.08, 0.56), "olive", "turret")
        k.box((A.x, s * 0.4, 1.84), (0.7, 0.03, 0.05), "hazard", "turret")
    mk.crate(k, (-0.98, 0.0, 1.62), (0.42, 0.66, 0.32), "turret")
    k.box((-0.98, 0, 1.8), (0.46, 0.7, 0.04), "olive", "turret")
    for i, y in enumerate((0.42, 0.18, -0.18, -0.42)):  # shells standing in a rack
        k.limb((0.3, y, 1.46), (0.3, y, 1.72), 0.08, 0.08, "khaki", "turret", seg=8)
        k.limb((0.3, y, 1.72), (0.3, y, 1.84), 0.08, 0.02, "hazard" if i % 2 else "brass", "turret", seg=8)
    k.box((0.3, 0, 1.52), (0.22, 1.04, 0.1), "gunmetal", "turret")
    # arm: axle, twin box beams, elbow, forearm, hydraulic ram
    k.limb(A + Vector((0, -0.46, 0)), A + Vector((0, 0.46, 0)), 0.1, 0.1, "steel", "arm", seg=8)
    for s in (1, -1):
        k.limb(A + Vector((0, s * 0.16, 0)), E + Vector((0, s * 0.17, 0)), 0.14, 0.12, "olive", "arm", seg=4)
    k.limb(E + Vector((0, -0.3, 0)), E + Vector((0, 0.3, 0)), 0.14, 0.14, "steel", "arm", seg=8)
    k.limb(E, W, 0.17, 0.15, "gunmetal", "arm", seg=4)
    p0, mid = A + Vector((-0.12, 0, -0.2)), A + Vector((0.18, 0, 0.64))
    k.limb(p0, p0.lerp(mid, 0.55), 0.1, 0.1, "gunmetal", "arm", seg=8)
    k.limb(p0.lerp(mid, 0.5), mid, 0.05, 0.05, "brake", "arm", seg=8)
    # head: forked olive cradle, steel trunnion caps
    k.ball(tuple(W), 0.18, "steel", "head", seg=6, rings=3)
    for s in (1, -1):
        fork = W + Vector((0.1, s * 0.8, 0.12))
        k.limb(W, fork, 0.1, 0.1, "olive", "head", seg=4)
        k.limb(fork, B + Vector((0, s * 0.8, 0.0)), 0.1, 0.1, "olive", "head", seg=4)
        k.limb(B + Vector((0, s * 0.7, 0)), B + Vector((0, s * 0.86, 0)), 0.16, 0.16, "gunmetal", "head", seg=8)
    # tube, built upright at B; the bowl bone tilts it forward in every clip
    k.lathe(TUBE, "olive", "bowl", at=tuple(B), seg=14, smooth=False)
    k.lathe([(0.0, -0.5), (0.5, -0.5), (0.5, -0.1), (0.0, -0.1)], "olive_dark", "bowl", at=tuple(B), seg=14, smooth=False)
    k.lathe([(0.42, 0.48), (0.5, 0.48), (0.5, 0.66), (0.32, 0.66), (0.32, 0.6), (0.42, 0.6)], "steel", "bowl", at=tuple(B), seg=14, smooth=False)
    k.lathe([(0.42, 0.22), (0.45, 0.22), (0.45, 0.32), (0.42, 0.32), (0.42, 0.22)], "hazard", "bowl", at=tuple(B), seg=14, cap=False)
    k.limb(B + Vector((0, -0.72, 0)), B + Vector((0, 0.72, 0)), 0.1, 0.1, "steel", "bowl", seg=8)
    k.ball(B + Vector((0, 0, 0.0)), 0.27, "fire", "ember", seg=8, rings=5)
    # fireball and smoke
    for x, y, z, r in ((0.4, 0.25, 0.4, 0.38), (-0.38, 0.3, 0.5, 0.36), (0.1, -0.42, 0.6, 0.36), (0.0, 0.0, 1.3, 0.34)):
        k.ball(MZ + Vector((x, y, z)), r, "fire", "flash", seg=8, rings=5)
    k.ball(MZ + Vector((0, 0, 0.65)), 0.48, "flash_white", "flash", seg=8, rings=5)
    for x, y, z, r in ((0, 0, 0, 0.4), (0.3, 0.15, 0.2, 0.3), (-0.25, -0.2, 0.25, 0.32)):
        k.ball(MZ + Vector((x, y, z)), r, "smoke", "smoke", seg=6, rings=4)


def base_pose(t):
    return {"bowl": {"rot": ((0, 1, 0), TILT)}, "ember": {"scale": 1 + 0.25 * math.sin(2 * math.pi * t)},
            "arm": {"rot": ((0, 1, 0), 0.12 * math.sin(2 * math.pi * t))},
            "flash": {"scale": wk.HIDE}, "smoke": {"scale": wk.HIDE}}


def idle(t):
    return base_pose(t)


def attack(t):
    p = base_pose(0.0)
    pre = lib.ease(min(1.0, t / 0.28))
    back = lib.ease(max(0.0, (t - 0.28) / 0.72))
    kick = lib.pulse(t, 0.27, 0.8)
    p["arm"] = {"rot": ((0, 1, 0), 0.14 * pre * (1 - back) - 0.3 * kick)}
    p["bowl"] = {"rot": ((0, 1, 0), TILT), "loc": (0, 0, -0.35 * kick)}
    p["ember"] = {"scale": 1 + 0.5 * pre if t < 0.3 else max(0.3, 1.5 - 4 * (t - 0.3)) if t < 0.7 else 0.3 + 0.7 * (t - 0.7) / 0.3}
    p["flash"] = {"scale": max(wk.HIDE, 1.2 * lib.pulse(t, 0.25, 0.5))}
    if 0.3 <= t < 0.97:
        u = (t - 0.3) / 0.7
        p["smoke"] = {"loc": (0.2 * u, 0, 1.1 * u), "scale": 0.8 + 1.0 * u}
    return p


def hit(t):
    p = base_pose(0.0)
    p.update(wk.hit_common(t))
    p["bowl"] = {"rot": ((0, 1, 0), TILT + 0.6 * lib.pulse(t, 0.0, 1.0) * (1 - t))}
    return p


def die(t):
    p = base_pose(t)
    p.update(wk.die_common(t, CHUNKS))
    k = lib.ease(min(1.0, t / 0.7))
    p["bowl"] = {"rot": ((0, 1, 0), TILT + 0.9 * k)}
    p["arm"] = {"rot": ((0, 1, 0), 0.45 * k)}
    p["ember"] = {"scale": max(wk.HIDE, 1 + 0.6 * lib.pulse(t, 0, 0.3) - 1.2 * lib.ease(min(1.0, t / 0.45)))}
    return p


if __name__ == "__main__":
    wk.run("mortar", BONES, PIVOTS, geometry, {
        "idle": (48, idle, True), "attack": (24, attack, False),
        "hit": (10, hit, False), "die": (48, die, False)})
