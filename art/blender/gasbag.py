"""Gasbag: slow floating bladder with a glowing gas sac, dangling tendrils and small fins.
Origin at the body centre. Game id: gasbag.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import flyer_kit as fk  # noqa: E402
import lib  # noqa: E402

SPAN, CHORD = 0.55, 0.5
TENDRILS = 6


def tendril(i):
    a = i * 2 * math.pi / TENDRILS
    top = (math.cos(a) * 0.3, math.sin(a) * 0.3, -0.25)
    bot = (math.cos(a) * 0.45, math.sin(a) * 0.45, -1.0 - 0.15 * (i % 3))
    return top, bot


def build():
    bones = [("root", (0, 0, 0), (0, 0, 0.1), None),
             ("body", (-0.2, 0, 0.2), (0.2, 0, 0.2), "root"),
             ("sac", (0, 0, -0.05), (0, 0, -0.45), "body")]
    for i in range(TENDRILS):
        top, bot = tendril(i)
        mid = tuple((a + b) * 0.5 for a, b in zip(top, bot))
        bones += [("ten%d" % i, top, mid, "body"), ("tip%d" % i, mid, bot, "ten%d" % i)]
    arm = lib.armature("gasbag", bones + fk.wing_bones(SPAN, CHORD))
    b = lib.Builder("gasbag")
    b.ball((0, 0, 0.2), 0.55, "gas_skin", "body", scale=(1.25, 1.0, 0.95), seg=14, rings=10)
    for k in range(5):  # rib bands round the bladder
        x = -0.45 + 0.22 * k
        r = 0.55 * math.sqrt(max(0.05, 1 - (x / 0.69) ** 2))
        b.ball((x, 0, 0.2), r * 1.03, "gas_fin", "body", scale=(0.08, 1.0, 0.95), seg=12, rings=8)
    for s in (1, -1):
        b.ball((0.1, s * 0.3, 0.64), 0.14, "sick", "body", seg=6, rings=5)
        b.ball((-0.3, s * 0.2, 0.62), 0.1, "sick", "body", seg=6, rings=5)
    b.ball((0, 0, -0.22), 0.3, "glow", "sac", seg=10, rings=7)
    b.ball((0.7, 0, 0.1), 0.16, "chitin", "body", scale=(1.2, 1, 0.9), seg=7, rings=5)  # blind head
    for s in (1, -1):
        b.limb((0.78, s * 0.06, 0.02), (0.88, s * 0.05, -0.12), 0.03, 0.0, "bone", "body", seg=4)
    for i in range(TENDRILS):
        top, bot = tendril(i)
        mid = tuple((a + b) * 0.5 for a, b in zip(top, bot))
        b.limb(top, mid, 0.05, 0.03, "sick", "ten%d" % i, seg=5, smooth=True)
        b.limb(mid, bot, 0.03, 0.008, "sick", "tip%d" % i, seg=5, smooth=True)
    fk.wing_mesh(b, SPAN, CHORD, "gas_fin")
    b.finish(arm)
    return arm


def R(arm, bone, axis, ang):
    return lib.world_rot(arm, bone, axis, ang)


def drift(arm, t, amp=1.0, sac=1.0):
    w = 2 * math.pi * t
    p = fk.flap(arm, t * 2 % 1.0, amp=0.45, bias=0.0)
    p["body"] = (R(arm, "body", (1, 0, 0), 0.05 * amp * math.sin(w)), lib.world_loc(arm, "body", (0, 0, 0.08 * amp * math.sin(w))))
    p["sac"] = (None, None, (sac,) * 3)
    for i in range(TENDRILS):
        ph = w + i * 1.1
        p["ten%d" % i] = (R(arm, "ten%d" % i, (0, 1, 0), 0.25 * amp * math.sin(ph)), None)
        p["tip%d" % i] = (R(arm, "tip%d" % i, (0, 1, 0), 0.35 * amp * math.sin(ph - 0.8)), None)
    return p


def clips(arm):
    lib.action(arm, "idle", 48, lambda t: drift(arm, t, 0.6, 1 + 0.05 * math.sin(4 * math.pi * t)), step=2, loop=True)
    lib.action(arm, "walk", 36, lambda t: drift(arm, t, 1.0, 1 + 0.05 * math.sin(4 * math.pi * t)), step=2, loop=True)

    def attack(t):  # squeeze the bladder and vent gas from the sac
        sq = lib.pulse(t, 0.1, 0.7)
        p = drift(arm, t, 1.2, 1 + 0.35 * sq)
        p["body"] = (p["body"][0], p["body"][1], (1 - 0.1 * sq, 1 + 0.06 * sq, 1 - 0.12 * sq))
        return p
    lib.action(arm, "attack", 20, attack, step=1)

    def hit(t):
        j = lib.pulse(t, 0.0, 1.0) * (1.0 - t)
        p = drift(arm, 0.0, 1.0)
        p["body"] = (R(arm, "body", (1, 0, 0), 0.25 * j), lib.world_loc(arm, "body", (-0.1 * j, 0, 0.05 * j)), (1 + 0.08 * j,) * 3)
        return p
    lib.action(arm, "hit", 10, hit, step=1)

    def die(t):  # deflates, tendrils go limp, sinks
        d = lib.ease(min(1.0, t / 0.7))
        p = drift(arm, t * 3 % 1.0, 1.0 - d, max(0.01, 1 - d))
        p["body"] = (R(arm, "body", (0, 1, 0), 0.8 * d), lib.world_loc(arm, "body", (0, 0, -1.6 * t * t)),
                     (1 - 0.5 * d, 1 - 0.4 * d, 1 - 0.6 * d))
        return p
    lib.action(arm, "die", 36, die, step=1)


if __name__ == "__main__":
    out = sys.argv[sys.argv.index("--") + 1]
    lib.reset()
    a = build()
    clips(a)
    lib.export(out)
