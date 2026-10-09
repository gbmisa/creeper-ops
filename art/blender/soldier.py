"""Soldier: 1.8 m footman (mail, blue tabard, bronze helm, round shield on the left arm, crossbow).
Real metres: the game uses it at scale 1. Game id: soldier.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
from legs import Legs  # noqa: E402
from mathutils import Quaternion  # noqa: E402

LEGS = Legs()
for n, s, ph in (("L", 1, 0.0), ("R", -1, 0.5)):
    LEGS.add(n, (0, s * 0.11, 0.88), (0, s * 0.11, 0.0), s, ph, knee_up=0.0, knee_out=0.0, pillar=True)


def build():
    arm = lib.armature("soldier", [("root", (0, 0, 0), (0, 0, 0.1), None),
                                   ("hips", (0, 0, 0.88), (0, 0, 1.1), "root"),
                                   ("chest", (0, 0, 1.1), (0, 0, 1.5), "hips"),
                                   ("head", (0, 0, 1.5), (0, 0, 1.8), "chest"),
                                   ("arm_L", (0, 0.25, 1.4), (0.3, 0.12, 1.08), "chest"),
                                   ("arm_R", (0, -0.25, 1.4), (0.3, -0.12, 1.08), "chest"),
                                   ("xbow", (0.3, 0, 1.08), (0.7, 0, 1.08), "chest")] + LEGS.bones("hips"))
    b = lib.Builder("soldier")
    LEGS.mesh(b, 0.1, 0.085, 0.075, mat="dark", joint="mail", tip="dark", seg=7)
    for n, (_h, _k, foot, _s, _p) in LEGS.legs.items():
        b.box((foot.x + 0.06, foot.y, 0.05), (0.26, 0.12, 0.1), "oak", "lo_" + n)  # boots
    b.lathe([(0.2, 0.82), (0.24, 1.0), (0.2, 1.1)], "mail", "hips", seg=8)
    b.lathe([(0.2, 1.1), (0.26, 1.2), (0.24, 1.45), (0.1, 1.5), (0.0, 1.5)], "mail", "chest", seg=8)
    b.box((0.21, 0, 1.08), (0.1, 0.3, 0.62), "cloth", "chest")
    b.box((0.27, 0, 1.3), (0.05, 0.08, 0.08), "unit_glow", "chest")
    b.box((-0.2, 0, 0.95), (0.05, 0.5, 1.0), "cloth", "chest", rot=Quaternion((0, 1, 0), 0.12))  # cloak
    b.ball((0, 0, 1.6), 0.12, "skin", "head", seg=10, rings=7)
    b.lathe([(0.15, 1.56), (0.14, 1.7), (0.08, 1.78), (0.0, 1.8)], "bronze", "head", seg=8)
    b.box((-0.02, 0, 1.82), (0.24, 0.03, 0.1), "cloth", "head")
    for sd, s in (("L", 1), ("R", -1)):
        b.ball((0, s * 0.25, 1.43), 0.13, "bronze", "chest", seg=8, rings=6)
        b.limb((0, s * 0.25, 1.38), (0.3, s * 0.12, 1.08), 0.07, 0.06, "mail", "arm_" + sd, seg=6, smooth=True)
    b.limb((0.12, 0.27, 1.05), (0.12, 0.33, 1.05), 0.26, 0.26, "bronze", "arm_L", seg=12)  # round shield
    b.ball((0.12, 0.35, 1.05), 0.06, "rune", "arm_L", seg=6, rings=4)
    b.box((0.42, 0, 1.08), (0.62, 0.08, 0.08), "oak", "xbow")
    b.box((0.68, 0, 1.1), (0.06, 0.56, 0.05), "bronze_dark", "xbow")
    b.limb((0.68, 0.28, 1.1), (0.5, 0, 1.1), 0.01, 0.01, "dark", "xbow", seg=3)  # string
    b.limb((0.68, -0.28, 1.1), (0.5, 0, 1.1), 0.01, 0.01, "dark", "xbow", seg=3)
    b.finish(arm)
    return arm


def R(arm, bone, axis, ang):
    return lib.world_rot(arm, bone, axis, ang)


def stand(arm):
    return LEGS.all(arm, lambda n, s, i: (0.0, 0.0, 0.0))


def clips(arm):
    def walk(t):
        p = LEGS.walk(arm, t, 0.5, lift=0.3, bend=0.9, duty=0.6)
        w = 2 * math.pi * t
        p["hips"] = (R(arm, "hips", (0, 0, 1), 0.08 * math.sin(w)), lib.world_loc(arm, "hips", (0, 0, 0.03 * math.cos(2 * w))))
        p["chest"] = (R(arm, "chest", (0, 0, 1), -0.1 * math.sin(w)) @ R(arm, "chest", (0, 1, 0), 0.06), None)
        return p
    lib.action(arm, "walk", 30, walk, step=1, loop=True)

    def idle(t):
        w = 2 * math.pi * t
        p = stand(arm)
        p["chest"] = (R(arm, "chest", (0, 1, 0), 0.02 * math.sin(w)), None)
        p["head"] = (R(arm, "head", (0, 0, 1), 0.35 * math.sin(w) * lib.pulse(t, 0.2, 0.8)), None)
        return p
    lib.action(arm, "idle", 72, idle, step=3, loop=True)

    def attack(t):
        aim = lib.ease(min(1.0, t / 0.25)) * (1.0 - lib.ease(max(0.0, (t - 0.75) / 0.25)))
        kick = lib.pulse(t, 0.3, 0.55)
        p = stand(arm)
        p["chest"] = (R(arm, "chest", (0, 1, 0), -0.05 * kick), None)
        p["xbow"] = (R(arm, "xbow", (0, 1, 0), -0.1 * aim - 0.2 * kick), lib.world_loc(arm, "xbow", (-0.08 * kick, 0, 0.1 * aim)))
        p["arm_R"] = (None, lib.world_loc(arm, "arm_R", (-0.08 * kick, 0, 0.1 * aim)))
        return p
    lib.action(arm, "attack", 20, attack, step=1)

    def hit(t):
        j = lib.pulse(t, 0.0, 1.0) * (1.0 - t)
        p = stand(arm)
        p["chest"] = (R(arm, "chest", (0, 1, 0), -0.25 * j), None)
        p["head"] = (R(arm, "head", (0, 1, 0), -0.3 * j), None)
        return p
    lib.action(arm, "hit", 10, hit, step=1)

    def die(t):
        buckle = lib.ease(min(1.0, t / 0.35))
        fall = lib.ease(min(1.0, max(0.0, (t - 0.2) / 0.55)))
        p = LEGS.all(arm, lambda n, s, i: (0.4 * buckle, 0.0, 1.0 * buckle * (1.0 - fall)))
        p["root"] = (R(arm, "root", (0, 1, 0), -1.45 * fall), lib.world_loc(arm, "root", (-0.25 * fall, 0, -0.08 * fall)))
        p["hips"] = (None, lib.world_loc(arm, "hips", (0, 0, -0.25 * buckle * (1.0 - fall))))
        p["arm_L"] = (R(arm, "arm_L", (1, 0, 0), -0.6 * fall), None)
        p["xbow"] = (R(arm, "xbow", (0, 1, 0), 0.8 * fall), None)
        return p
    lib.action(arm, "die", 32, die, step=1)


if __name__ == "__main__":
    out = sys.argv[sys.argv.index("--") + 1]
    lib.reset()
    a = build()
    clips(a)
    lib.export(out)
