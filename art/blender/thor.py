"""Thor in three parts (weapon_kit), military: an armoured hover gunship. A hex olive hull with
a hazard deck edge, three ducted lift fans underneath and a sensor pod keel (base); an armoured
cab with a sensor mast and lamp (turret); a twin steel boom holding a rail arc projector with
coil rings and a capacitor pack (arm).
Pivots match TitanMeshes.thor: Hull at y 0, Turret y 0.46, Arm at (0.25, 0.3), wrist
(1.513, 2.077) from the shoulder, Muzzle 1.7 ahead of the wrist.
Clips: idle = fans spin, lamp blinks; attack = coils charge and an arc bolt lances out;
hit = shudder; die = the fans stall and the hull drops and tips.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
import weapon_kit as wk  # noqa: E402
from mathutils import Quaternion, Vector  # noqa: E402

T = Vector((0, 0, 0.46))
A = T + Vector((0.25, 0, 0.3))
E = A + Vector((0.631, 0, 1.898))
W = A + Vector((1.513, 0, 2.077))
M = W + Vector((1.7, 0, 0))
FANS = [("fan%d" % i, Vector((math.cos(a) * 2.85, math.sin(a) * 2.85, -0.2)))
        for i, a in enumerate(i * 2 * math.pi / 3 + math.pi / 3 for i in range(3))]
X = Vector((1, 0, 0))

BONES = [("base", (0, 0, 0), (0, 0, 0.5), None, "base"),
         ("keel", (0, 0, -1.6), (0, 0, -1.3), "base", "base")]
BONES += [(n, tuple(c), tuple(c + Vector((0, 0, 0.3))), "base", "base") for n, c in FANS]
BONES += [("turret", tuple(T), tuple(T + Vector((0, 0, 0.3))), None, "turret"),
          ("lamp", (-0.75, 0, 3.0), (-0.75, 0, 3.2), "turret", "turret"),
          ("arm", tuple(A), tuple(A + Vector((0, 0, 0.3))), "turret", "arm"),
          ("head", tuple(W), tuple(W + X * 0.3), "arm", "arm"),
          ("coil", tuple(W), tuple(W + X * 0.3), "head", "arm"),
          ("arc", tuple(M), tuple(M + X * 0.3), "head", "arm")]
PIVOTS = {"base": (0, 0, 0), "turret": tuple(T), "arm": tuple(A)}


def ring_x(k, c, r, thick, mat, bone, n=12):
    pts = [c + Vector((0, math.cos(2 * math.pi * i / n) * r, math.sin(2 * math.pi * i / n) * r)) for i in range(n + 1)]
    for a, b in zip(pts, pts[1:]):
        k.limb(a, b, thick, thick, mat, bone, seg=4)


def geometry(k):
    # base: hex armoured hull, deck edge, armour plates, lift fans, keel pod
    k.lathe([(0.0, -1.3), (1.1, -1.05), (2.2, -0.45), (2.55, 0.0), (2.5, 0.32), (0.0, 0.32)], "olive", "base", seg=6, smooth=False)
    k.lathe([(2.38, 0.3), (2.52, 0.3), (2.52, 0.4), (2.38, 0.4), (2.38, 0.3)], "hazard", "base", seg=6, cap=False)
    for i in range(6):
        a = i * math.pi / 3 + math.pi / 6
        ap = 2.2 * math.cos(math.pi / 6)
        k.box((math.cos(a) * ap, math.sin(a) * ap, -0.2), (0.12, 1.4, 0.38), "olive_dark", "base", rot=Quaternion((0, 0, 1), a))
    for x, y in ((1.2, 0.9), (-1.3, -0.6)):
        k.box((x, y, 0.5), (0.6, 0.4, 0.36), "olive_dark", "base")  # ammo crates on deck
    for n, c in FANS:
        k.lathe([(0.62, c.z - 0.25), (0.75, c.z - 0.25), (0.75, c.z + 0.25), (0.62, c.z + 0.25), (0.62, c.z - 0.25)],
                "gunmetal", "base", at=(c.x, c.y, 0), seg=14, cap=False)
        k.limb(c * 0.7, c * 0.9, 0.16, 0.16, "olive_dark", "base", seg=6)  # sponson
        k.lathe([(0.55, c.z - 0.3), (0.66, c.z - 0.26), (0.55, c.z - 0.22), (0.5, c.z - 0.26), (0.55, c.z - 0.3)],
                "arc_blue", "base", at=(c.x, c.y, 0), seg=14, cap=False)
        k.ball(tuple(c), 0.14, "steel", n, seg=6, rings=3)
        for j in range(4):
            q = Quaternion((0, 0, 1), j * math.pi / 2)
            k.box(tuple(c + q @ Vector((0.32, 0, 0))), (0.56, 0.13, 0.04), "rubber", n,
                  rot=q @ Quaternion((1, 0, 0), 0.4))
    k.ball((0, 0, -1.3), 0.12, "lamp_red", "keel", seg=6, rings=3)
    # turret: armoured drum, cab, vision slit, sensor mast
    k.lathe([(0.95, 0.46), (0.98, 0.52), (0.98, 0.76), (0.0, 0.76)], "olive_dark", "turret", seg=12, smooth=False)
    k.box((-0.6, 0, 1.15), (1.0, 1.15, 0.8), "olive", "turret")
    k.box((-0.08, 0, 1.3), (0.04, 0.9, 0.12), "rubber", "turret")
    for s in (1, -1):
        k.box((A.x, s * 0.48, 1.0), (0.6, 0.1, 0.55), "gunmetal", "turret")
    k.limb((-0.75, 0, 1.55), (-0.75, 0, 2.95), 0.06, 0.04, "steel", "turret", seg=6)
    k.box((-0.75, 0, 2.5), (0.2, 0.6, 0.25), "olive_dark", "turret")
    k.ball((-0.75, 0, 3.05), 0.12, "arc_blue", "lamp", seg=6, rings=3)
    # arm: axle, twin olive beams, elbow, forearm
    k.limb(A + Vector((0, -0.55, 0)), A + Vector((0, 0.55, 0)), 0.1, 0.1, "steel", "arm", seg=8)
    for s in (1, -1):
        k.limb(A + Vector((0, s * 0.3, 0)), E + Vector((0, s * 0.3, 0)), 0.13, 0.11, "olive", "arm", seg=4)
    k.limb(E + Vector((0, -0.4, 0)), E + Vector((0, 0.4, 0)), 0.14, 0.14, "steel", "arm", seg=8)
    k.limb(E, W, 0.17, 0.15, "gunmetal", "arm", seg=6)
    # head: capacitor pack, twin rails, coil rings, emitter
    k.ball(tuple(W), 0.2, "gunmetal", "head", seg=6, rings=3)
    k.box(W - X * 0.35, (0.9, 0.7, 0.6), "olive", "head")
    for z in (-0.12, 0.12):
        k.box(W - X * 0.35 + Vector((0, 0.36, z)), (0.7, 0.03, 0.08), "hazard", "head")
    for s in (1, -1):
        k.limb(W + Vector((0, s * 0.24, 0)), M + Vector((-0.05, s * 0.24, 0)), 0.11, 0.09, "steel", "head", seg=6)
    for x in (0.35, 0.8, 1.25):
        ring_x(k, W + X * x, 0.44, 0.07, "brake", "head")
        ring_x(k, W + X * x, 0.36, 0.05, "arc_blue", "coil")
    k.ball(tuple(M), 0.2, "arc_blue", "coil", seg=6, rings=3)
    # arc bolt (attack only): a jagged lightning run with a white core
    pts = [M + Vector((i * 0.85, 0.3 * math.sin(i * 2.1), 0.25 * math.cos(i * 1.7) - 0.25)) for i in range(6)]
    pts[0] = M
    for a, b in zip(pts, pts[1:]):
        k.limb(a, b, 0.16, 0.12, "arc_blue", "arc", seg=5)
        k.limb(a, b, 0.06, 0.05, "flash_white", "arc", seg=4)
    k.ball(M + X * 0.15, 0.4, "flash_white", "arc", seg=6, rings=4)


def fans(t):
    return {n: {"rot": ((0, 0, 1), math.pi / 2 * t + i)} for i, (n, _c) in enumerate(FANS)}  # 4 blades loop at 90 degrees


def base_pose(t):
    p = fans(t)
    p["lamp"] = {"scale": 1.3 if (t * 2) % 1.0 < 0.5 else 0.6}
    p["coil"] = {"scale": 1 + 0.1 * math.sin(2 * math.pi * t)}
    p["arm"] = {"rot": ((0, 1, 0), 0.06 * math.sin(2 * math.pi * t))}
    p["arc"] = {"scale": wk.HIDE}
    return p


def idle(t):
    return base_pose(t)


def attack(t):
    p = base_pose(0.0)
    p.update(fans(t))
    ch = min(1.0, t / 0.3)
    p["coil"] = {"scale": 1 + 0.7 * ch if t < 0.35 else 1 + 0.7 * (1 - lib.ease((t - 0.35) / 0.65))}
    f = lib.pulse(t, 0.3, 1.0) if t > 0.3 else 0.0
    p["arc"] = {"scale": (max(wk.HIDE, min(1.0, (t - 0.3) / 0.15)), 0.6 + 0.8 * f, 0.6 + 0.8 * f)
                if 0.3 < t < 0.95 else wk.HIDE}
    p["head"] = {"loc": (-0.2 * f, 0, 0)}
    p["lamp"] = {"scale": 1.6}
    return p


def hit(t):
    p = base_pose(0.0)
    p.update(wk.hit_common(t))
    j = lib.pulse(t, 0.0, 1.0) * (1.0 - t)
    p["base"] = {"rot": ((1, 0.4, 0), 0.12 * j * math.sin(15 * t))}
    return p


def die(t):
    p = base_pose(0.0)
    k = lib.ease(min(1.0, t / 0.8))
    spin = 1.0 - k
    p.update({n: {"rot": ((0, 0, 1), math.pi / 2 * spin * 2 + i)} for i, (n, _c) in enumerate(FANS)})
    drop = 0.6 * k * k
    p["base"] = {"loc": (0, 0, -drop), "rot": ((1, 0.5, 0), 0.3 * k)}
    p["turret"] = {"loc": (0, 0, -drop), "rot": ((1, 0.5, 0), 0.34 * k)}
    p["arm"] = {"rot": ((0, 1, 0), 0.45 * k)}
    p["keel"] = {"scale": max(wk.HIDE, 1 - 1.4 * k)}
    p["lamp"] = {"scale": wk.HIDE if t > 0.3 else 1.4}
    p["coil"] = {"scale": max(wk.HIDE, 1 - k)}
    return p


if __name__ == "__main__":
    wk.run("thor", BONES, PIVOTS, geometry, {
        "idle": (48, idle, True), "attack": (16, attack, False),
        "hit": (10, hit, False), "die": (48, die, False)})
