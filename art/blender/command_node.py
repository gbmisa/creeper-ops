"""Command Node, military: a mobile HQ tower. A hazard-banded concrete plinth on four hydraulic
landing legs, an olive armoured octagonal tower with gunmetal bands, dark vision slits and
hydraulic buttress struts, a glazed command deck with a railing, insignia drapes on two faces,
and a turning comms crown (three antenna masts, a radar ring and a dish) round a caged blue
reactor core. Same silhouette as SupportMeshes.node.
Clips: idle = crown turns, core breathes; walk = flying (lift thrusters under the plinth,
drapes flutter, crown spins fast); attack = packet launch (a blue ring runs up the tower, core
flares); hit = shake; die = core shatters, the crown drops, the tower leans and sinks.
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
    P8 = math.pi / 8
    b.lathe([(2.8, 0.0), (2.8, 0.7), (2.3, 0.9), (0.0, 0.9)], "concrete_dark", "base", seg=8, smooth=False, phase=P8)
    for i in range(16):  # hazard foot band
        a = 2 * math.pi * i / 16 + P8 / 2
        b.box((math.cos(a) * 2.6, math.sin(a) * 2.6, 0.45), (0.06, 1.0, 0.3), "hazard" if i % 2 else "rubber",
              "base", rot=Quaternion((0, 0, 1), a))
    b.lathe([(2.1, 0.9), (1.55, 1.6), (1.35, 6.4), (1.35, 6.6), (0.0, 6.6)], "olive", "tower", seg=8, smooth=False, phase=P8)
    for z in (1.95, 3.6, 5.3):  # armour bands
        r = (1.55 - (z - 1.6) * 0.04) / math.cos(P8) + 0.02
        b.lathe([(r, z - 0.12), (r, z + 0.12), (0.0, z + 0.12)], "gunmetal", "tower", seg=8, smooth=False, phase=P8)
    for k in range(8):  # vision slits on every face
        a = k * math.pi / 4
        q = Quaternion((0, 0, 1), a)
        for z in (2.7, 4.45):
            r = 1.55 - (z - 1.6) * 0.04 + 0.02
            b.box((math.cos(a) * r, math.sin(a) * r, z), (0.06, 0.5, 0.14), "solar", "tower", rot=q)
    for x, y, z, a in BUTTRESS:  # hydraulic struts and landing legs
        c, s = math.cos(a), math.sin(a)
        b.limb((x, y, z), (c * 1.4, s * 1.4, 3.6), 0.3, 0.22, "olive_dark", "tower", seg=4)
        b.limb((c * 2.2, s * 2.2, 1.1), (c * 1.5, s * 1.5, 2.8), 0.12, 0.12, "steel", "tower", seg=8)
        b.box((x, y, 0.1), (0.9, 0.9, 0.2), "gunmetal", "base", rot=Quaternion((0, 0, 1), a))
        b.limb((x, y, 0.2), (x * 0.85, y * 0.85, 0.75), 0.18, 0.18, "steel", "base", seg=8)
        b.box((c * 1.45, s * 1.45, 3.65), (0.36, 0.36, 0.3), "hazard", "tower", rot=Quaternion((0, 0, 1), a))
    # command deck: wide glazed octagon
    b.lathe([(1.4, 6.4), (1.95, 6.7), (1.95, 7.5), (1.8, 7.6), (0.0, 7.6)], "olive", "tower", seg=8, smooth=False, phase=P8)
    b.lathe([(1.97, 6.85), (1.97, 7.25), (0.0, 7.25)], "solar", "tower", seg=8, smooth=False, phase=P8)
    for x, y, z, a in sk.ring(8, 1.8, 7.85, P8):  # railing posts (were merlons)
        b.limb((x, y, 7.6), (x, y, 8.1), 0.05, 0.05, "steel", "crown", seg=4)
    b.lathe([(1.78, 8.04), (1.86, 8.04), (1.86, 8.12), (1.78, 8.12), (1.78, 8.04)], "hazard", "crown", seg=8, cap=False, phase=P8)
    for x, y, z, a in sk.ring(6, 1.35, 7.75, 0.3):  # sandbags on the roof
        b.ball((x, y, z), 0.32, "sandbag", "crown", scale=(1.3, 0.7, 0.45), seg=6, rings=3,
               rot=Quaternion((0, 0, 1), a + math.pi / 2))
    for i, s in enumerate((1, -1)):  # insignia drapes
        bn = "banner%d" % i
        b.box((0, s * 1.5, 5.1), (1.25, 0.05, 3.0), "olive_dark", bn)
        b.box((0, s * 1.51, 3.65), (1.31, 0.07, 0.22), "hazard", bn)
        for dz in (0.0, 0.32):  # chevrons
            b.box((-0.2, s * 1.53, 5.4 - dz), (0.5, 0.03, 0.12), "khaki", bn, rot=Quaternion((0, 1, 0), 0.6))
            b.box((0.2, s * 1.53, 5.4 - dz), (0.5, 0.03, 0.12), "khaki", bn, rot=Quaternion((0, 1, 0), -0.6))
        b.limb((-0.72, s * 1.5, 6.6), (0.72, s * 1.5, 6.6), 0.05, 0.05, "steel", bn, seg=4)
    for x, y, z, a in sk.ring(3, 0.5, 7.8, 0.0):  # comms crown: three antenna masts
        c, s = math.cos(a), math.sin(a)
        tip = (c * 1.2, s * 1.2, 9.5)
        b.limb((x, y, z), tip, 0.1, 0.07, "gunmetal", "spin", seg=4)
        b.limb(tip, (tip[0], tip[1], tip[2] + 0.9), 0.04, 0.02, "steel", "spin", seg=4)
        b.ball((tip[0], tip[1], tip[2] + 0.92), 0.09, "lamp_red", "spin", seg=6, rings=3)
    b.lathe([(1.0, 8.72), (1.18, 8.8), (1.0, 8.88), (0.92, 8.8), (1.0, 8.72)], "steel", "spin", seg=16, cap=False)
    b.lathe([(0.5, 7.6), (0.62, 7.8), (0.4, 8.6), (0.0, 8.6)], "gunmetal", "spin", seg=8, smooth=False)
    dish = (1.25, 0.0, 8.5)
    b.limb((0.4, 0, 8.3), dish, 0.06, 0.06, "steel", "spin", seg=4)
    b.lathe([(0.0, -0.05), (0.55, 0.12), (0.62, 0.24), (0.55, 0.2), (0.0, 0.05)], "brake", "spin", at=dish, seg=12, smooth=False)
    b.ball((0, 0, 10.1), 0.55, "arc_blue", "gem", scale=(1, 1, 1.8), seg=10, rings=6)
    for z in (9.0, 11.2):
        b.lathe([(0.0, z - 0.06), (0.62, z - 0.06), (0.62, z + 0.06), (0.0, z + 0.06)], "gunmetal", "gem", seg=8, smooth=False)
    for i in range(4):
        a = i * math.pi / 2 + math.pi / 4
        b.limb((math.cos(a) * 0.6, math.sin(a) * 0.6, 9.0), (math.cos(a) * 0.6, math.sin(a) * 0.6, 11.2), 0.05, 0.05,
               "steel", "gem", seg=4)
    b.lathe([(1.7, 0.95), (1.9, 1.05), (1.7, 1.15), (1.6, 1.05), (1.7, 0.95)], "arc_blue", "wave", seg=16, cap=False)
    b.limb((0, 0, 0.0), (0, 0, -4.5), 2.2, 0.0, "fire", "jets", seg=10)
    b.limb((0, 0, -0.05), (0, 0, -3.0), 1.4, 0.0, "flash_white", "jets", seg=8)  # hot core
    for x, y, z, a in BUTTRESS:
        b.limb((x, y, 0.0), (x * 1.08, y * 1.08, -2.6), 0.8, 0.0, "fire", "jets", seg=8)
    b.lathe([(3.2, -0.1), (2.2, -0.05), (0.0, -0.05)], "smoke_dark", "jets", seg=16)  # wash on the ground below
    for i, (x, y, z, a) in enumerate(sk.ring(5, 0.4, 10.1, 0.3)):
        b.ball((x, y, z), 0.32, "arc_blue", "shard%d" % i, scale=(1, 1, 2.2), seg=4, rings=2, smooth=False)
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
