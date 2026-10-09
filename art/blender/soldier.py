"""Soldier: 1.8 m rifleman (olive fatigues, khaki plate carrier with pouches, olive helmet with
goggles, radio pack, green IR strobe on the shoulder, assault rifle held in both hands).
The rifle bone keeps its old name (xbow) so the clips and the game contract hold.
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
                                   ("xbow", (0.3, 0, 1.08), (0.7, 0, 1.08), "chest"),
                                   ("flash", (0.9, 0, 1.11), (1.1, 0, 1.11), "xbow")] + LEGS.bones("hips"))
    b = lib.Builder("soldier")
    LEGS.mesh(b, 0.08, 0.07, 0.06, mat="olive", joint="olive_dark", tip="rubber", seg=7)
    for n, (_h, _k, foot, _s, _p) in LEGS.legs.items():
        b.box((foot.x + 0.06, foot.y, 0.06), (0.28, 0.13, 0.12), "rubber", "lo_" + n)  # boots
    b.lathe([(0.2, 0.82), (0.24, 1.0), (0.2, 1.1)], "olive", "hips", seg=8)
    b.lathe([(0.25, 0.94), (0.255, 1.0), (0.0, 1.0)], "khaki", "hips", seg=8)  # belt
    b.lathe([(0.2, 1.1), (0.23, 1.2), (0.22, 1.45), (0.1, 1.5), (0.0, 1.5)], "olive", "chest", seg=8)
    b.box((0.04, 0, 1.28), (0.38, 0.44, 0.38), "khaki", "chest")  # plate carrier
    for y in (-0.12, 0.0, 0.12):  # mag pouches
        b.box((0.25, y, 1.18), (0.08, 0.1, 0.14), "olive_dark", "chest")
    b.box((-0.22, 0, 1.25), (0.16, 0.3, 0.4), "olive_dark", "chest")  # radio pack
    b.limb((-0.24, 0.1, 1.42), (-0.24, 0.1, 1.95), 0.01, 0.006, "rubber", "chest", seg=3)
    b.box((0.02, 0.27, 1.47), (0.06, 0.06, 0.05), "unit_glow", "chest")  # IR strobe
    b.ball((0, 0, 1.6), 0.13, "skin", "head", seg=10, rings=7)
    b.lathe([(0.17, 1.6), (0.17, 1.63), (0.155, 1.72), (0.09, 1.79), (0.0, 1.8)], "olive", "head", seg=10)
    b.box((0.13, 0, 1.66), (0.05, 0.2, 0.05), "rubber", "head")  # goggles on the brim
    b.box((0.12, 0, 1.6), (0.04, 0.16, 0.03), "solar", "head")
    for sd, s in (("L", 1), ("R", -1)):
        b.ball((0, s * 0.25, 1.43), 0.11, "olive_dark", "chest", seg=8, rings=6)
        b.limb((0, s * 0.25, 1.38), (0.3, s * 0.12, 1.08), 0.07, 0.06, "olive", "arm_" + sd, seg=6, smooth=True)
    b.limb((0.3, 0.12, 1.08), (0.5, 0.03, 1.1), 0.05, 0.045, "olive", "arm_L", seg=6, smooth=True)  # support hand
    b.ball((0.5, 0.03, 1.1), 0.045, "rubber", "arm_L", seg=6, rings=4)
    b.box((0.36, 0, 1.1), (0.36, 0.08, 0.13), "gunmetal", "xbow")  # receiver
    b.box((0.13, 0, 1.08), (0.16, 0.05, 0.1), "rubber", "xbow")  # stock
    b.box((0.56, 0, 1.1), (0.24, 0.09, 0.1), "olive_dark", "xbow")  # handguard
    b.limb((0.66, 0, 1.11), (0.9, 0, 1.11), 0.025, 0.025, "gunmetal", "xbow", seg=6)  # barrel
    b.limb((0.9, 0, 1.11), (1.15, 0, 1.11), 0.07, 0.0, "fire", "flash", seg=6)
    b.ball((0.93, 0, 1.11), 0.06, "flash_white", "flash", seg=6, rings=3)
    b.box((0.4, 0, 1.0), (0.06, 0.04, 0.14), "gunmetal", "xbow", rot=Quaternion((0, 1, 0), 0.25))  # magazine
    b.box((0.36, 0, 1.18), (0.1, 0.04, 0.05), "rubber", "xbow")  # optic
    b.finish(arm)
    return arm


def R(arm, bone, axis, ang):
    return lib.world_rot(arm, bone, axis, ang)


def stand(arm):
    p = LEGS.all(arm, lambda n, s, i: (0.0, 0.0, 0.0))
    p["flash"] = (None, None, (0.01, 0.01, 0.01))
    return p


def clips(arm):
    def walk(t):
        p = LEGS.walk(arm, t, 0.5, lift=0.3, bend=0.9, duty=0.6)
        p["flash"] = (None, None, (0.01, 0.01, 0.01))
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
        p["chest"] = (R(arm, "chest", (0, 1, 0), -0.15 * kick) @ R(arm, "chest", (0, 0, 1), 0.1 * kick), None)
        p["xbow"] = (R(arm, "xbow", (0, 1, 0), -0.1 * aim - 0.35 * kick), lib.world_loc(arm, "xbow", (-0.18 * kick, 0, 0.12 * aim)))
        p["arm_R"] = (None, lib.world_loc(arm, "arm_R", (-0.18 * kick, 0, 0.12 * aim)))
        fl = lib.pulse(t, 0.28, 0.45)
        p["flash"] = (None, None, (max(0.01, 1.6 * fl),) * 3)
        return p
    lib.action(arm, "attack", 20, attack, step=1)

    def hit(t):
        j = lib.pulse(t, 0.0, 1.0) * (1.0 - t)
        p = stand(arm)
        p["chest"] = (R(arm, "chest", (0, 1, 0), -0.8 * j) @ R(arm, "chest", (0, 0, 1), 0.3 * j), None)
        p["head"] = (R(arm, "head", (0, 1, 0), -0.6 * j), None)
        p["hips"] = (None, lib.world_loc(arm, "hips", (-0.25 * j, 0, -0.08 * j)))
        p["xbow"] = (R(arm, "xbow", (0, 1, 0), 0.5 * j), None)
        return p
    lib.action(arm, "hit", 10, hit, step=1)

    def die(t):
        buckle = lib.ease(min(1.0, t / 0.35))
        fall = lib.ease(min(1.0, max(0.0, (t - 0.2) / 0.55)))
        p = LEGS.all(arm, lambda n, s, i: (0.4 * buckle, 0.0, 1.0 * buckle * (1.0 - fall)))
        p["flash"] = (None, None, (0.01, 0.01, 0.01))
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
