"""Nullifier in two parts (weapon_kit parts base/core), military: a hex concrete plinth with a
hazard band and a thin void slit, three olive hydraulic clamp arms with steel rams and claw pads
(base); a void crystal in a steel cage (core). The game spins and grows the "Core" node while
it charges (StructureBehaviors._charge_null), so the core is its own glb at Core (y 2.75).
Clips: idle = clamps breathe, the cage turns; attack = discharge (clamps squeeze, the core
flares, a void ring runs out along the ground); hit = shudder; die = the core bursts, clamps
fall open, the plinth sinks.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
import weapon_kit as wk  # noqa: E402
from mathutils import Vector  # noqa: E402

C = Vector((0, 0, 2.75))
DIRS = [Vector((math.cos(a), math.sin(a), 0)) for a in (i * 2 * math.pi / 3 + math.pi / 6 for i in range(3))]
CLAMPS = [("clamp%d" % i, d) for i, d in enumerate(DIRS)]

BONES = [("base", (0, 0, 0), (0, 0, 0.5), None, "base"),
         ("pulse", (0, 0, 0.05), (0, 0, 0.3), "base", "base")]
BONES += [(n, tuple(d * 0.75 + Vector((0, 0, 1.35))), tuple(d * 0.75 + Vector((0, 0, 1.65))), "base", "base") for n, d in CLAMPS]
BONES += [("core", tuple(C), tuple(C + Vector((0, 0, 0.3))), None, "core"),
          ("gem", tuple(C), tuple(C + Vector((0, 0, 0.3))), "core", "core")]
PIVOTS = {"base": (0, 0, 0), "core": tuple(C)}


def tan(d):
    return (-d.y, d.x, 0)  # rotating + tips a clamp outward


def geometry(k):
    # base: plinth, hazard band, void slit, rivets
    k.lathe([(1.25, 0.0), (1.25, 0.3), (1.08, 0.45), (1.0, 1.35), (0.0, 1.35)], "concrete_dark", "base", seg=6, smooth=False)
    for i, z in enumerate((0.46, 0.7, 0.94)):
        k.lathe([(1.08 - 0.009 * i * 2, z), (1.08 - 0.009 * (i * 2 + 1), z + 0.22), (0.0, z + 0.22)],
                "hazard" if i != 1 else "rubber", "base", seg=6, smooth=False)
    k.lathe([(1.01, 1.18), (1.02, 1.3), (0.0, 1.3)], "void", "base", seg=6, smooth=False)
    k.lathe([(0.82, 1.35), (0.85, 1.45), (0.0, 1.45)], "gunmetal", "base", seg=6, smooth=False)
    for n, d in CLAMPS:
        s = d * 0.75 + Vector((0, 0, 1.35))
        e = d * 1.3 + Vector((0, 0, 2.5))
        tip = d * 0.62 + Vector((0, 0, 3.75))
        k.box(tuple(s), (0.5, 0.5, 0.36), "gunmetal", "base")
        k.limb(s, e, 0.3, 0.24, "olive", n, seg=6)
        k.ball(tuple(e), 0.27, "steel", n, seg=8, rings=4)
        k.limb(e, tip, 0.22, 0.16, "olive", n, seg=6)
        k.box(tuple(tip - d * 0.1), (0.36, 0.5, 0.42), "hazard", n)
        r0 = d * 0.35 + Vector((0, 0, 1.4))
        k.limb(r0, r0.lerp(e, 0.5), 0.1, 0.1, "steel", n, seg=6)  # hydraulic ram
        k.limb(r0.lerp(e, 0.45), e, 0.06, 0.06, "brake", n, seg=6)
    k.lathe([(1.2, 0.03), (1.45, 0.08), (1.2, 0.13), (1.1, 0.08), (1.2, 0.03)], "void", "pulse", seg=18, cap=False)
    # core: steel cage round the void crystal
    for z in (C.z - 0.75, C.z + 0.75):
        k.lathe([(0.6, z - 0.05), (0.7, z - 0.05), (0.7, z + 0.05), (0.6, z + 0.05), (0.6, z - 0.05)], "steel", "core", seg=12, cap=False)
    for d in DIRS:
        b = Vector((-d.x, -d.y, 0)) * 0.65  # bars sit between the clamps
        k.limb(b + Vector((0, 0, C.z - 0.75)), b + Vector((0, 0, C.z + 0.75)), 0.05, 0.05, "steel", "core", seg=4)
    k.ball(tuple(C), 0.64, "void", "gem", scale=(1, 1, 1.7), seg=6, rings=2, smooth=False)
    k.ball(tuple(C), 0.22, "flash_white", "gem", seg=6, rings=3)


def base_pose(t):
    p = {n: {"rot": (tan(d), 0.04 * math.sin(2 * math.pi * t))} for n, d in CLAMPS}
    p["core"] = {"rot": ((0, 0, 1), 2 * math.pi / 3 * t)}  # 3 bars: a third of a turn loops
    p["gem"] = {"scale": 1 + 0.12 * math.sin(2 * math.pi * t)}
    p["pulse"] = {"scale": wk.HIDE}
    return p


def idle(t):
    return base_pose(t)


def attack(t):
    p = base_pose(0.0)
    sq = lib.pulse(t, 0.0, 0.5)
    for n, d in CLAMPS:
        p[n] = {"rot": (tan(d), -0.22 * sq)}
    p["core"] = {"rot": ((0, 0, 1), 3 * math.pi * t * t)}
    p["gem"] = {"scale": 1 + 0.9 * lib.pulse(t, 0.1, 0.7)}
    u = lib.ease(max(0.0, (t - 0.25) / 0.75))
    r = 1.0 + 2.4 * u
    p["pulse"] = {"scale": (r, r, 1) if 0.25 < t < 0.97 else wk.HIDE}
    return p


def hit(t):
    p = base_pose(0.0)
    j = lib.pulse(t, 0.0, 1.0) * (1.0 - t)
    for i, (n, d) in enumerate(CLAMPS):
        p[n] = {"rot": (tan(d), 0.15 * j * math.sin(18 * t + i))}
    p["base"] = {"scale": (1 + 0.06 * j, 1 + 0.06 * j, 1 - 0.1 * j)}
    p["gem"] = {"scale": 1 + 0.8 * j}
    p["core"] = {"loc": (0.12 * j * math.sin(20 * t), 0, -0.1 * j)}
    return p


def die(t):
    p = base_pose(0.0)
    k = lib.ease(min(1.0, t / 0.6))
    s = wk.sink(t)
    p["base"] = {"loc": (0, 0, -s), "scale": (1 + 0.1 * s, 1 + 0.1 * s, max(0.3, 1 - 0.5 * s))}
    for n, d in CLAMPS:
        p[n] = {"rot": (tan(d), 0.55 * k)}
    p["core"] = {"loc": (0, 0, -s - 1.9 * k * k), "scale": max(wk.HIDE, 1 - 0.6 * k)}
    p["gem"] = {"scale": max(wk.HIDE, 1 + 0.9 * lib.pulse(t, 0, 0.3) - 1.6 * lib.ease(min(1.0, t / 0.4)))}
    return p


if __name__ == "__main__":
    wk.run("nullifier", BONES, PIVOTS, geometry, {
        "idle": (48, idle, True), "attack": (24, attack, False),
        "hit": (10, hit, False), "die": (48, die, False)}, parts=("base", "core"))
