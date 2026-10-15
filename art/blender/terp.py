"""Terp in two parts (weapon_kit parts base/spin), military: a terraforming rig. A concrete pad
with four hydraulic outrigger legs, an armoured olive hex tower with hazard bands, amber work
lamps and exhaust stacks (base); a turning crane deck with a cab, counterweight and a jointed
boom swinging a pile-driver hammer (spin). The game turns the "Spin" node (y 5.3) while the
Terp works, so the crane is its own glb there.
Clips: idle = lamps blink, the hammer sways; attack = the boom winds up and slams the hammer
down, a shock ring runs out from the pad; hit = shudder; die = boom collapses, tower sinks.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
import weapon_kit as wk  # noqa: E402
from mathutils import Quaternion, Vector  # noqa: E402

P = Vector((0, 0, 5.3))
S = P + Vector((-0.4, 0, 0.4))
E = S + Vector((1.115, 0, 1.148))
W = S + Vector((2.234, 0, -0.262))
LEGS = [("leg%d" % i, Vector((math.cos(a), math.sin(a), 0))) for i, a in enumerate(math.pi / 4 + k * math.pi / 2 for k in range(4))]

BONES = [("base", (0, 0, 0), (0, 0, 0.5), None, "base"),
         ("lamps", (0, 0, 4.3), (0, 0, 4.6), "base", "base"),
         ("shock", (0, 0, 0.05), (0, 0, 0.3), "base", "base")]
BONES += [(n, tuple(d * 1.5 + Vector((0, 0, 0.9))), tuple(d * 1.5 + Vector((0, 0, 1.2))), "base", "base") for n, d in LEGS]
BONES += [("spin", tuple(P), tuple(P + Vector((0, 0, 0.3))), None, "spin"),
          ("boom", tuple(S), tuple(S + Vector((0, 0, 0.3))), "spin", "spin"),
          ("fore", tuple(E), tuple(E + Vector((0, 0, 0.3))), "boom", "spin"),
          ("hammer", tuple(W), tuple(W + Vector((0, 0, -0.3))), "fore", "spin")]
PIVOTS = {"base": (0, 0, 0), "spin": tuple(P)}


def geometry(k):
    # base: pad, outriggers, armoured hex tower, bands, lamps, stacks
    k.box((0, 0, 0.15), (4.6, 4.6, 0.3), "concrete", "base")
    for n, d in LEGS:
        a = math.atan2(d.y, d.x)
        h = d * 1.5 + Vector((0, 0, 0.9))
        foot = d * 2.35 + Vector((0, 0, 0.35))
        k.limb(h, foot, 0.2, 0.17, "olive", n, seg=6)
        k.limb(h.lerp(foot, 0.4), h.lerp(foot, 0.6), 0.21, 0.2, "hazard", n, seg=6)
        k.box(tuple(d * 2.4 + Vector((0, 0, 0.36))), (0.7, 0.7, 0.12), "gunmetal", n, rot=Quaternion((0, 0, 1), a))
        k.limb(d * 1.2 + Vector((0, 0, 1.6)), h.lerp(foot, 0.5), 0.08, 0.08, "steel", n, seg=6)
    k.lathe([(1.75, 0.3), (1.75, 0.7), (1.45, 0.9), (1.15, 4.6), (1.45, 4.85), (1.45, 5.3), (0.0, 5.3)],
            "olive", "base", seg=6, smooth=False)
    for z in (1.5, 3.2):
        r = 1.45 - (z - 0.9) * 0.3 / 3.7 + 0.01
        k.lathe([(r, z), (r - 0.01, z + 0.22), (0.0, z + 0.22)], "hazard", "base", seg=6, smooth=False)
    k.lathe([(1.47, 4.9), (1.48, 5.02), (0.0, 5.02)], "gunmetal", "base", seg=6, smooth=False)
    for i in range(6):
        a = i * math.pi / 3 + math.pi / 6
        ap = 1.33 * math.cos(math.pi / 6)
        k.box((math.cos(a) * ap, math.sin(a) * ap, 2.4), (0.08, 0.7, 0.9), "olive_dark", "base", rot=Quaternion((0, 0, 1), a))
        if i % 2 == 0:
            k.box((math.cos(a) * 1.4, math.sin(a) * 1.4, 4.4), (0.16, 0.34, 0.2), "lamp_amber", "lamps", rot=Quaternion((0, 0, 1), a))
    for x, y in ((-0.8, 0.9), (-0.8, -0.9)):  # exhaust stacks
        k.limb((x, y, 4.6), (x * 1.05, y * 1.05, 6.0), 0.13, 0.11, "gunmetal", "base", seg=8)
        k.limb((x * 1.05, y * 1.05, 6.0), (x * 1.05, y * 1.05, 6.08), 0.15, 0.15, "rubber", "base", seg=8)
    k.lathe([(1.5, 0.05), (2.3, 0.14), (1.5, 0.23), (1.35, 0.14), (1.5, 0.05)], "fire", "shock", seg=20, cap=False)
    # spin: turntable, cab, counterweight
    k.lathe([(1.15, 5.3), (1.2, 5.36), (1.2, 5.5), (0.0, 5.5)], "gunmetal", "spin", seg=12, smooth=False)
    k.box((0.25, 0.65, 5.95), (0.9, 0.6, 0.9), "olive", "spin")
    k.box((0.72, 0.65, 6.05), (0.04, 0.5, 0.35), "rubber", "spin")
    k.box((-1.05, 0, 5.85), (0.8, 1.0, 0.7), "concrete_dark", "spin")
    for z in (5.7, 6.0):
        k.box((-1.47, 0, z), (0.04, 1.0, 0.1), "hazard", "spin")
    for s in (1, -1):
        k.box((S.x, s * 0.32, 5.65), (0.5, 0.08, 0.5), "gunmetal", "spin")
    # boom: lattice-style twin beam with a ram
    k.limb(S + Vector((0, -0.5, 0)), S + Vector((0, 0.5, 0)), 0.13, 0.13, "steel", "boom", seg=8)
    for s in (1, -1):
        k.limb(S + Vector((0, s * 0.26, 0)), E + Vector((0, s * 0.26, 0)), 0.16, 0.13, "hazard", "boom", seg=4)
    k.limb(S + Vector((-0.2, 0, -0.25)), S.lerp(E, 0.55), 0.07, 0.07, "steel", "boom", seg=6)
    k.ball(tuple(E), 0.21, "steel", "fore", seg=6, rings=3)
    k.limb(E, W, 0.18, 0.15, "olive", "fore", seg=6)
    k.limb(E.lerp(W, 0.3), E.lerp(W, 0.5), 0.185, 0.17, "hazard", "fore", seg=6)
    # hammer: pile-driver ram on a guide
    k.ball(tuple(W), 0.12, "steel", "hammer", seg=6, rings=3)
    k.limb(W + Vector((0, 0, 0.25)), W + Vector((0, 0, -0.9)), 0.1, 0.1, "steel", "hammer", seg=6)
    k.box(W + Vector((0, 0, -1.3)), (1.05, 1.05, 0.9), "olive", "hammer")
    for z in (-0.92, -1.68):
        k.box(W + Vector((0, 0, z)), (1.1, 1.1, 0.14), "hazard", "hammer")
    k.box(W + Vector((0, 0, -1.8)), (0.75, 0.75, 0.16), "steel", "hammer")


def base_pose(t):
    return {"lamps": {"scale": 1.25 if (t * 2) % 1.0 < 0.5 else 0.7},
            "hammer": {"rot": ((0, 1, 0), 0.12 * math.sin(2 * math.pi * t))},
            "shock": {"scale": wk.HIDE}}


def idle(t):
    return base_pose(t)


def attack(t):
    p = base_pose(0.0)
    up = lib.ease(min(1.0, t / 0.4))
    slam = lib.ease(min(1.0, max(0.0, (t - 0.4) / 0.15)))
    back = lib.ease(max(0.0, (t - 0.7) / 0.3))
    a = -0.45 * up + 0.95 * slam - 0.5 * back
    p["boom"] = {"rot": ((0, 1, 0), a)}
    p["fore"] = {"rot": ((0, 1, 0), 0.3 * slam * (1 - back))}
    p["hammer"] = {"rot": ((0, 1, 0), -a - 0.3 * slam * (1 - back))}  # stays plumb
    u = lib.ease(max(0.0, (t - 0.5) / 0.5))
    r = 1.0 + 1.6 * u
    p["shock"] = {"scale": (r, r, 1) if 0.5 < t < 0.97 else wk.HIDE}
    p["lamps"] = {"scale": 1.6 if 0.5 < t < 0.75 else 1.0}
    p["base"] = {"scale": (1, 1, 1 - 0.04 * lib.pulse(t, 0.5, 0.75))}
    return p


def hit(t):
    p = base_pose(0.0)
    j = lib.pulse(t, 0.0, 1.0) * (1.0 - t)
    p["base"] = {"scale": (1 + 0.05 * j, 1 + 0.05 * j, 1 - 0.08 * j)}
    p["spin"] = {"rot": ((0.3, 0, 1), 0.3 * j * math.sin(14 * t)), "loc": (0, 0, -0.22 * j)}
    p["boom"] = {"rot": ((0, 1, 0), 0.25 * j * math.sin(18 * t))}
    return p


def die(t):
    p = base_pose(0.0)
    s = wk.sink(t) * 1.6
    k = lib.ease(min(1.0, t / 0.6))
    p["base"] = {"loc": (0, 0, -s), "scale": (1 + 0.1 * k, 1 + 0.1 * k, max(0.35, 1 - 0.35 * s))}
    p["spin"] = {"loc": (0, 0, -s * 2.2)}
    p["boom"] = {"rot": ((0, 1, 0), 1.0 * k)}
    p["fore"] = {"rot": ((0, 1, 0), 0.8 * k)}
    p["lamps"] = {"scale": wk.HIDE if t > 0.25 else 1.5}
    for n, d in LEGS:
        p[n] = {"rot": ((-d.y, d.x, 0), 0.25 * k)}
    return p


if __name__ == "__main__":
    wk.run("terp", BONES, PIVOTS, geometry, {
        "idle": (48, idle, True), "attack": (24, attack, False),
        "hit": (10, hit, False), "die": (48, die, False)}, parts=("base", "spin"))
