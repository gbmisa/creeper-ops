"""Air-defence laser in three parts (weapon_kit), military: a tall round concrete mast with olive
armour bands, a hazard band, a caged ladder and sandbagged foot (base); a gunmetal turntable with
armour cheeks, a power box and a radar dish on a mast (turret); a box-beam arm holding an olive
emitter housing with a steel bezel, a spinning cooling-fin cage and a red focus lens (arm).
Pivots match WeaponMeshes.beam: Turret y 2.4, Arm at (-0.2, 0.3), wrist (0.907, 1.42) from the
shoulder, Muzzle 0.95 ahead of the wrist. Bone names kept: lens = fin cage (spins on +X),
ruby = focus lens, ray = the beam.
Clips: idle = fins turn, the lens breathes; attack = fins spin up and a red beam lances out;
hit = shudder; die = mast sinks, the fin cage drops off the arm.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
import mil_kit as mk  # noqa: E402
import weapon_kit as wk  # noqa: E402
from mathutils import Quaternion, Vector  # noqa: E402

T = Vector((0, 0, 2.4))
A = T + Vector((-0.2, 0, 0.3))
E = A + Vector((0.221, 0, 1.281))
W = A + Vector((0.907, 0, 1.42))
C = W + Vector((0.6, 0, 0))  # ring centre
M = W + Vector((0.95, 0, 0))
CHUNKS = [("chunk%d" % i, (math.cos(a), math.sin(a))) for i, a in enumerate(math.pi / 4 + k * math.pi / 2 for k in range(4))]

BONES = [("base", (0, 0, 0), (0, 0, 0.5), None, "base")]
BONES += [(n, (x * 0.74, y * 0.74, 0.2), (x * 0.74, y * 0.74, 0.5), "base", "base") for n, (x, y) in CHUNKS]
BONES += [("turret", tuple(T), tuple(T + Vector((0, 0, 0.3))), None, "turret"),
          ("arm", tuple(A), tuple(A + Vector((0, 0, 0.3))), "turret", "arm"),
          ("head", tuple(W), tuple(W + Vector((0.3, 0, 0))), "arm", "arm"),
          ("lens", tuple(C), tuple(C + Vector((0.3, 0, 0))), "head", "arm"),  # bone y = +X: spin axis
          ("ruby", tuple(M - Vector((0.08, 0, 0))), tuple(M + Vector((0.22, 0, 0))), "head", "arm"),
          ("ray", tuple(M), tuple(M + Vector((0.3, 0, 0))), "head", "arm")]
PIVOTS = {"base": (0, 0, 0), "turret": tuple(T), "arm": tuple(A)}


def ring_x(k, c, r, thick, mat, bone, n=18):
    """A ring in the YZ plane round centre c (axis +X), built from short tapered segments."""
    pts = [c + Vector((0, math.cos(2 * math.pi * i / n) * r, math.sin(2 * math.pi * i / n) * r)) for i in range(n + 1)]
    for a, b in zip(pts, pts[1:]):
        k.limb(a, b, thick, thick, mat, bone, seg=5)


def geometry(k):
    # base: slab, sandbag ring, round concrete mast, armour bands, hazard band, caged ladder
    mk.slab(k, 0.95, 0.16, "base")
    mk.sandbags(k, 0.62, 0.16, "base", rows=1, per=3)
    k.lathe([(0.62, 0.16), (0.6, 0.5), (0.46, 0.7), (0.42, 2.1), (0.56, 2.22), (0.56, 2.4), (0.0, 2.4)],
            "olive", "base", seg=12, smooth=False)
    for z0, z1, r in ((0.5, 0.62, 0.6), (1.2, 1.32, 0.455), (2.1, 2.3, 0.57)):
        k.lathe([(r, z0), (r, z1), (0.0, z1)], "gunmetal", "base", seg=12, smooth=False)
    for i in range(12):
        a = 2 * math.pi * i / 12
        k.box((math.cos(a) * 0.575, math.sin(a) * 0.575, 2.2), (0.04, 0.3, 0.1), "hazard" if i % 2 else "rubber", "base",
              rot=Quaternion((0, 0, 1), a))
    mk.ladder(k, -0.44, 0, 0.7, 2.1, "base", face=(-1, 0), w=0.26)
    for z in (1.0, 1.4, 1.8):  # ladder cage hoops
        k.lathe([(0.2, z), (0.22, z), (0.22, z + 0.03), (0.2, z + 0.03), (0.2, z)], "steel", "base", at=(-0.7, 0, 0),
                seg=8, cap=False)
    for n, (x, y) in CHUNKS:
        q = Quaternion((0, 0, 1), math.atan2(y, x) + math.pi / 2)
        for z, sc in ((0.3, 1.0), (0.45, 0.8)):
            k.ball((x * 0.8, y * 0.8, z), 0.18 * sc, "sandbag", n, scale=(1.4, 0.8, 0.55), seg=6, rings=3, rot=q)
    k.lathe([(0.44, 2.38), (0.58, 2.38), (0.58, 2.5), (0.44, 2.5), (0.44, 2.38)], "gunmetal", "base", seg=16, cap=False)
    # turret: turntable, cheeks, power box, radar mast
    mk.turntable(k, 0.5, 2.4, 2.54, "turret", bolts=8)
    for s in (1, -1):
        k.box((A.x, s * 0.3, 2.68), (0.52, 0.08, 0.5), "olive", "turret")
        k.box((A.x, s * 0.34, 2.88), (0.52, 0.03, 0.05), "hazard", "turret")
    mk.crate(k, (-0.62, 0, 2.7), (0.3, 0.44, 0.3), "turret", mat="gunmetal", stencil=False)
    k.limb((-0.62, 0, 2.85), (-0.62, 0, 3.35), 0.035, 0.03, "steel", "turret", seg=6)
    dish = Vector((-0.62, 0, 3.45))
    k.lathe([(0.0, -0.02), (0.3, 0.06), (0.34, 0.12), (0.3, 0.1), (0.0, 0.03)], "brake", "turret",
            at=tuple(dish), seg=12, smooth=False)
    k.limb(dish, dish + Vector((0, 0, 0.28)), 0.015, 0.015, "steel", "turret", seg=4)
    k.ball(tuple(dish + Vector((0, 0, 0.3))), 0.035, "lamp_red", "turret", seg=4, rings=2)
    # arm: axle, twin box beams, elbow, forearm, ram
    k.limb(A + Vector((0, -0.38, 0)), A + Vector((0, 0.38, 0)), 0.09, 0.09, "steel", "arm", seg=8)
    for s in (1, -1):
        k.limb(A + Vector((0, s * 0.12, 0)), E + Vector((0, s * 0.12, 0)), 0.095, 0.08, "olive", "arm", seg=4)
    k.limb(E + Vector((0, -0.2, 0)), E + Vector((0, 0.2, 0)), 0.11, 0.11, "steel", "arm", seg=8)
    k.limb(E, W, 0.11, 0.1, "gunmetal", "arm", seg=4)
    p0, mid = A + Vector((-0.1, 0, -0.2)), A + Vector((0.12, 0, 0.7))
    k.limb(p0, p0.lerp(mid, 0.55), 0.07, 0.07, "gunmetal", "arm", seg=8)
    k.limb(p0.lerp(mid, 0.5), mid, 0.04, 0.04, "brake", "arm", seg=8)
    # head: emitter housing along +X, rear power pack, front bezel
    k.ball(tuple(W), 0.14, "steel", "head", seg=6, rings=3)
    k.tube([(W + Vector((x, 0, 0)), r) for x, r in ((-0.55, 0.3), (-0.2, 0.42), (0.6, 0.46), (0.86, 0.5))],
           "olive", "head", seg=12)
    k.box(W + Vector((-0.6, 0, 0.0)), (0.3, 0.5, 0.5), "gunmetal", "head")
    for z in (-0.1, 0.1):
        k.box(W + Vector((-0.6, 0.26, z)), (0.22, 0.02, 0.06), "hazard", "head")
    ring_x(k, M - Vector((0.06, 0, 0)), 0.5, 0.07, "steel", "head", n=16)
    # lens = fin cage: 3 radiator fins on a ring round the housing (3-fold so the turn reads)
    ring_x(k, C - Vector((0.3, 0, 0)), 0.62, 0.05, "gunmetal", "lens", n=16)
    for i in range(3):
        a = i * 2 * math.pi / 3
        d = Vector((0, math.cos(a), math.sin(a)))
        q = Quaternion((1, 0, 0), a)
        k.box(C - Vector((0.3, 0, 0)) + d * 0.62, (0.7, 0.05, 0.2), "steel", "lens", rot=q)
    # ruby = focus lens in the bezel
    k.limb(M - Vector((0.08, 0, 0)), M, 0.36, 0.3, "ruby", "ruby", seg=12)
    k.ball(M - Vector((0.02, 0, 0)), 0.14, "flash_white", "ruby", scale=(0.4, 1, 1), seg=6, rings=3)
    # ray (attack only)
    k.limb(M, M + Vector((6.0, 0, 0)), 0.26, 0.03, "ray_red", "ray", seg=8)
    k.limb(M, M + Vector((6.6, 0, 0)), 0.11, 0.07, "flash_white", "ray", seg=6)
    k.ball(M + Vector((0.1, 0, 0)), 0.38, "flash_white", "ray", seg=6, rings=4)


def base_pose(t):
    return {"lens": {"rot": ((1, 0, 0), 2 * math.pi / 3 * t)}, "ruby": {"scale": 1 + 0.15 * math.sin(2 * math.pi * t)},
            "arm": {"rot": ((0, 1, 0), 0.08 * math.sin(2 * math.pi * t))}, "ray": {"scale": wk.HIDE}}


def idle(t):
    return base_pose(t)


def attack(t):
    p = base_pose(0.0)
    p["lens"] = {"rot": ((1, 0, 0), 4 * math.pi * t * t + 1.0)}
    f = lib.pulse(t, 0.08, 1.0) if t > 0.08 else 0.0
    p["ray"] = {"scale": (0.4 + 0.8 * f, max(wk.HIDE, min(1.0, t / 0.2)), 0.4 + 0.8 * f) if t < 0.95 else wk.HIDE}
    p["ruby"] = {"scale": 2.2 if t < 0.08 else 1 + 0.6 * f}
    p["head"] = {"loc": (-0.12 * f, 0, 0)}
    return p


def hit(t):
    p = base_pose(0.0)
    p.update(wk.hit_common(t))
    return p


def die(t):
    p = base_pose(t)
    p.update(wk.die_common(t, CHUNKS))
    k = lib.ease(min(1.0, t / 0.7))
    p["lens"] = {"rot": ((1, 0, 0), 2 * math.pi * t), "loc": (0.9 * k, 0, -2.6 * k * k)}
    p["ruby"] = {"scale": max(wk.HIDE, 1 + 0.6 * lib.pulse(t, 0, 0.3) - 1.2 * lib.ease(min(1.0, t / 0.4)))}
    return p


if __name__ == "__main__":
    wk.run("beam", BONES, PIVOTS, geometry, {
        "idle": (48, idle, True), "attack": (12, attack, False),
        "hit": (10, hit, False), "die": (48, die, False)})
