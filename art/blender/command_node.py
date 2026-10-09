"""Command Node: stepped stone plinth, tapering tower with four buttresses, crenellated crown and a
turning bronze crown-wheel holding the big rune crystal. Same silhouette as SupportMeshes.node.
Clips: idle = wheel turns, crystal breathes; walk = flying (lift jets under the plinth, banners
flutter, wheel spins fast); attack = packet launch (a rune ring runs up the tower, crystal flares);
hit = shake; die = crystal shatters, crown wheel drops, tower leans and sinks.
Real metres, scale 1, about 11.3 m tall. Game id: command_node.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
import struct_kit as sk  # noqa: E402
from mathutils import Quaternion  # noqa: E402

BUTTRESS = sk.ring(4, 2.55, 0.7, math.pi / 4)
HIDE = (None, None, (0.01, 0.01, 0.01))
SHARDS = {"shard%d" % i: HIDE for i in range(5)}


def build():
    bones = [("root", (0, 0, 0), (0, 0, 0.1), None),
             ("base", (0, 0, 0), (0, 0, 0.9), "root"),
             ("tower", (0, 0, 0.9), (0, 0, 7.6), "base"),
             ("crown", (0, 0, 7.6), (0, 0, 8.1), "tower"),
             ("spin", (0, 0, 7.6), (0, 0, 9.8), "tower"),
             ("gem", (0, 0, 8.9), (0, 0, 11.3), "spin"),
             ("wave", (0, 0, 0.9), (0, 0, 1.2), "base"),
             ("jets", (0, 0, 0.0), (0, 0, -0.6), "base")]
    bones += [("shard%d" % i, (0, 0, 10.1), (x, y, 10.1), "tower") for i, (x, y, _z, _a) in enumerate(sk.ring(5, 0.4, 10.1, 0.3))]
    bones += [("banner%d" % i, (0, s * 1.47, 6.6), (0, s * 1.47, 4.0), "tower") for i, s in enumerate((1, -1))]
    arm = lib.armature("command_node", bones)
    b = lib.Builder("command_node")
    b.lathe([(2.8, 0.0), (2.8, 0.7), (2.3, 0.9), (0.0, 0.9)], "node_stone_dark", "base", seg=8, smooth=False)
    b.lathe([(2.95, 0.0), (2.95, 0.18), (0.0, 0.18)], "bronze_dark", "base", seg=8, smooth=False)  # foot band
    b.lathe([(2.1, 0.9), (1.55, 1.6), (1.35, 6.6), (1.8, 7.1), (1.8, 7.6), (0.0, 7.6)], "node_stone", "tower", seg=8, smooth=False)
    b.lathe([(1.5, 3.5), (1.53, 3.7), (0.0, 3.7)], "bronze", "tower", seg=8, smooth=False)  # band
    b.lathe([(1.84, 7.05), (1.84, 7.15), (0.0, 7.15)], "bronze", "tower", seg=8, smooth=False)  # crown lip
    for x, y, z, a in BUTTRESS:
        c, s = math.cos(a), math.sin(a)
        b.limb((x, y, z), (c * 1.35, s * 1.35, 4.2), 0.34, 0.2, "node_stone", "tower", seg=4)
        b.box((x, y, 0.85), (0.6, 0.6, 0.3), "node_stone_dark", "base", rot=Quaternion((0, 0, 1), a))
        b.box((c * 1.42, s * 1.42, 4.25), (0.3, 0.3, 0.3), "bronze", "tower", rot=Quaternion((0, 0, 1), a))
    for x, y, z, a in sk.ring(8, 1.62, 7.85, math.pi / 8):  # merlons
        b.box((x, y, z), (0.5, 0.5, 0.55), "node_stone", "crown", rot=Quaternion((0, 0, 1), a))
    for k in range(4):  # rune slits on the four faces
        a = k * math.pi / 2
        q = Quaternion((0, 0, 1), a)
        for z, h in ((2.4, 0.6), (5.2, 0.9)):
            r = 1.55 - (z - 1.6) * 0.04 + 0.02
            b.box((math.cos(a) * r, math.sin(a) * r, z), (0.08, 0.42, h), "rune", "tower", rot=q)
    for z in (1.95, 4.75, 6.05):  # mortar courses
        r = 1.55 - (z - 1.6) * 0.04 + 0.015
        b.lathe([(r, z - 0.05), (r, z + 0.05), (0.0, z + 0.05)], "node_stone_dark", "tower", seg=8, smooth=False)
    for i, s in enumerate((1, -1)):
        bn = "banner%d" % i
        b.box((0, s * 1.5, 5.1), (1.25, 0.05, 3.0), "cloth", bn)
        b.box((0, s * 1.51, 3.65), (1.31, 0.07, 0.22), "brass", bn)  # hem
        b.box((0, s * 1.53, 5.5), (0.46, 0.03, 1.1), "rune", bn)  # sigil
        b.limb((-0.72, s * 1.5, 6.6), (0.72, s * 1.5, 6.6), 0.05, 0.05, "bronze", bn, seg=4)  # pole
    for x, y, z, a in sk.ring(3, 0.5, 7.8, 0.0):  # crown-wheel spokes and crystals
        c, s = math.cos(a), math.sin(a)
        tip = (c * 1.2, s * 1.2, 9.5)
        b.limb((x, y, z), tip, 0.1, 0.07, "bronze", "spin", seg=4)
        b.ball((tip[0], tip[1], tip[2] + 0.25), 0.14, "rune", "spin", scale=(1, 1, 2.5), seg=5, rings=2, smooth=False)
    b.lathe([(1.0, 8.72), (1.18, 8.8), (1.0, 8.88), (0.92, 8.8), (1.0, 8.72)], "bronze_dark", "spin", seg=16, cap=False)
    b.lathe([(0.5, 7.6), (0.62, 7.8), (0.4, 8.6), (0.0, 8.6)], "bronze", "spin", seg=8, smooth=False)  # wheel hub
    b.ball((0, 0, 10.1), 0.6, "rune_deep", "gem", scale=(1, 1, 2.0), seg=6, rings=2, smooth=False)
    b.lathe([(1.7, 0.95), (1.9, 1.05), (1.7, 1.15), (1.6, 1.05), (1.7, 0.95)], "rune", "wave", seg=16, cap=False)
    b.limb((0, 0, 0.0), (0, 0, -4.5), 2.2, 0.0, "flame", "jets", seg=10)
    b.limb((0, 0, -0.05), (0, 0, -3.0), 1.4, 0.0, "rune", "jets", seg=8)  # hot core
    for x, y, z, a in BUTTRESS:
        b.limb((x, y, 0.0), (x * 1.08, y * 1.08, -2.6), 0.8, 0.0, "flame", "jets", seg=8)
    b.lathe([(3.2, -0.1), (2.2, -0.05), (0.0, -0.05)], "flame", "jets", seg=16)  # wash on the ground below
    for i, (x, y, z, a) in enumerate(sk.ring(5, 0.4, 10.1, 0.3)):
        b.ball((x, y, z), 0.32, "rune", "shard%d" % i, scale=(1, 1, 2.2), seg=4, rings=2, smooth=False)
    b.finish(arm)
    return arm


def turn(arm, ang, gem=1.0, rise=0.0):
    return {"spin": (Quaternion((0, 1, 0), ang), None),  # bone-local y = up
            "gem": (None, lib.world_loc(arm, "gem", (0, 0, rise)), (gem, gem, gem))}


def banners(arm, amp, t, k=1):
    return {"banner%d" % i: (lib.world_rot(arm, "banner%d" % i, (1, 0, 0),
                                           s * amp * math.sin(2 * math.pi * (k * t + 0.3 * i))), None)
            for i, s in enumerate((1, -1))}


def idle(arm, t):
    p = turn(arm, 2 * math.pi * t, 1 + 0.1 * math.sin(4 * math.pi * t), 0.3 * math.sin(2 * math.pi * t))
    p.update(banners(arm, 0.05, t, 2))
    p["jets"] = p["wave"] = HIDE
    p.update(SHARDS)
    return p


def walk(arm, t):  # flying
    w = 2 * math.pi * t
    p = turn(arm, 2 * math.pi * t, 1.05, 0.2)
    p.update(banners(arm, 0.3, t, 3))
    p["wave"] = HIDE
    p.update(SHARDS)
    f = 1 + 0.18 * math.sin(4 * w) + 0.08 * math.sin(7 * w)
    p["jets"] = (None, None, (1 + 0.06 * math.sin(5 * w), f, 1 + 0.06 * math.sin(5 * w)))
    p["base"] = (lib.world_rot(arm, "base", (1, 0, 0), 0.02 * math.sin(w)), lib.world_loc(arm, "base", (0, 0, 0.6 + 0.15 * math.sin(2 * w))))
    return p


def attack(arm, t):  # packet launch
    u = lib.ease(min(1.0, t / 0.8))
    flare = lib.pulse(t, 0.5, 1.35)
    p = turn(arm, 0.6 * math.pi * t, 1 + 0.4 * flare, 0.35 * flare)
    p.update(banners(arm, 0.05, t))
    p.update(SHARDS)
    p["jets"] = HIDE
    r = 1 - 0.18 * u + 0.25 * flare
    p["wave"] = (None, lib.world_loc(arm, "wave", (0, 0, 6.4 * u)), (r, 1, r) if t < 0.97 else (0.01,) * 3)
    p["crown"] = (None, None, (1 + 0.06 * flare, 1, 1 + 0.06 * flare))
    return p


def hit(arm, t):
    p = sk.hit_pose(arm, idle, t, "tower")
    j = lib.pulse(t, 0.0, 1.0) * (1.0 - t)
    p["spin"] = (Quaternion((0, 1, 0), 0.4 * j * math.sin(12 * t)), None)
    p["gem"] = (None, None, (1 - 0.3 * j,) * 3)
    return p


def die(arm, t):
    p = sk.die_pose(arm, idle, t, {"tower": (1, 0, 0)}, ("gem",), {"spin": 1.6}, 0.3)
    k = lib.ease(min(1.0, t / 0.5))
    for i, (x, y, _z, _a) in enumerate(sk.ring(5, 0.4, 10.1, 0.3)):
        d = 6.0 * k
        p["shard%d" % i] = (None, lib.world_loc(arm, "shard%d" % i, (x * d, y * d, 1.5 * k - 5.0 * k * k)),
                            (max(0.01, 1.4 * (1 - k * 0.6)),) * 3 if t < 0.85 else (0.01,) * 3)
    return p


if __name__ == "__main__":
    out = sys.argv[sys.argv.index("--") + 1]
    lib.reset()
    a = build()
    lib.action(a, "idle", 96, lambda t: idle(a, t), step=2, loop=True)
    lib.action(a, "walk", 24, lambda t: walk(a, t), step=1, loop=True)
    lib.action(a, "attack", 20, lambda t: attack(a, t), step=1)
    lib.action(a, "hit", 10, lambda t: hit(a, t), step=1)
    lib.action(a, "die", 48, lambda t: die(a, t), step=1)
    lib.export(out)
