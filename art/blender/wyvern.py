"""Wyvern: big winged drake with a long neck and tail; rears back and breathes fire.
Origin at the body centre. Game id: wyvern.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import flyer_kit as fk  # noqa: E402
import lib  # noqa: E402

SPAN, CHORD = 1.5, 1.0


def build():
    arm = lib.armature("wyvern", [("root", (0, 0, 0), (0, 0, 0.1), None),
                                  ("body", (-0.3, 0, 0), (0.3, 0, 0), "root"),
                                  ("neck", (0.35, 0, 0.05), (0.94, 0, 0.42), "body"),
                                  ("head", (0.94, 0, 0.42), (1.24, 0, 0.48), "neck"),
                                  ("jaw", (0.96, 0, 0.39), (1.2, 0, 0.36), "head"),
                                  ("tail", (-0.35, 0, 0), (-1.0, 0, -0.08), "body"),
                                  ("tail2", (-1.0, 0, -0.08), (-1.65, 0, -0.15), "tail")] + fk.wing_bones(SPAN, CHORD))
    b = lib.Builder("wyvern")
    b.ball((0, 0, 0), 0.34, "wyv_skin", "body", scale=(1.7, 1.25, 1.15), seg=12, rings=8)
    b.ball((0.05, 0, -0.18), 0.26, "plate", "body", scale=(1.6, 1.0, 0.45), seg=8, rings=5, smooth=False)  # belly plates
    for x in (0.2, -0.05, -0.3):  # back ridge
        b.limb((x, 0, 0.2), (x - 0.15, 0, 0.45), 0.08, 0.0, "bone", "body", seg=4)
    b.ball((-0.1, 0, -0.2), 0.12, "glow", "body", seg=7, rings=5)  # fire gland
    for s in (1, -1):  # tucked hind claws
        b.limb((-0.15, s * 0.12, -0.2), (-0.35, s * 0.14, -0.38), 0.05, 0.03, "wyv_skin", "body", seg=5)
        b.limb((-0.35, s * 0.14, -0.38), (-0.45, s * 0.14, -0.42), 0.03, 0.0, "bone", "body", seg=4)
    b.limb((0.32, 0, 0.04), (0.96, 0, 0.42), 0.19, 0.1, "wyv_skin", "neck", seg=7, smooth=True)
    for k in range(4):  # neck ridge
        x, z = 0.4 + 0.15 * k, 0.2 + 0.09 * k
        b.limb((x, 0, z), (x - 0.1, 0, z + 0.17), 0.05, 0.0, "bone", "neck", seg=4)
    b.ball((0.86, 0, 0.37), 0.18, "wyv_skin", "head", scale=(1.5, 0.9, 0.8), seg=8, rings=6)
    b.limb((0.78, 0, 0.27), (1.0, 0, 0.24), 0.07, 0.03, "wyv_skin", "jaw", seg=5)
    for s in (1, -1):
        b.ball((0.9, s * 0.08, 0.41), 0.05, "glow", "head", seg=5, rings=4)
        b.limb((0.76, s * 0.06, 0.42), (0.62, s * 0.1, 0.55), 0.05, 0.035, "bone", "head", seg=4)
        b.limb((0.62, s * 0.1, 0.55), (0.45, s * 0.14, 0.78), 0.035, 0.0, "bone", "head", seg=4)
    b.limb((-0.35, 0, 0), (-1.0, 0, -0.08), 0.15, 0.07, "wyv_skin", "tail", seg=6, smooth=True)
    b.limb((-1.0, 0, -0.08), (-1.65, 0, -0.15), 0.07, 0.01, "wyv_skin", "tail2", seg=6, smooth=True)
    for x in (-0.55, -0.8, -1.05):  # tail ridge
        b.limb((x, 0, 0.06), (x - 0.1, 0, 0.18), 0.04, 0.0, "bone", "tail" if x > -1.0 else "tail2", seg=4)
    b.limb((-1.55, 0, -0.14), (-1.85, 0, -0.16), 0.11, 0.0, "bone", "tail2", seg=4)
    for s in (1, -1):  # tail blades
        b.limb((-1.5, 0, -0.13), (-1.65, s * 0.2, -0.12), 0.05, 0.0, "bone", "tail2", seg=4)
    b.move(["head", "jaw"], (0.22, 0, 0.12))
    fk.wing_mesh(b, SPAN, CHORD, "wyv_wing")
    b.finish(arm)
    return arm


def R(arm, bone, axis, ang):
    return lib.world_rot(arm, bone, axis, ang)


def glide(arm, t, flap_amp, phase):
    w = 2 * math.pi * t
    p = fk.flap(arm, phase, amp=flap_amp, bias=0.05)
    p["body"] = (R(arm, "body", (0, 1, 0), 0.04 * math.sin(w)), lib.world_loc(arm, "body", (0, 0, -0.08 * math.sin(2 * math.pi * phase))))
    p["neck"] = (R(arm, "neck", (0, 0, 1), 0.08 * math.sin(w)), None)
    p["tail"] = (R(arm, "tail", (0, 0, 1), 0.12 * math.sin(w + 1.0)), None)
    p["tail2"] = (R(arm, "tail2", (0, 0, 1), 0.2 * math.sin(w + 0.2)), None)
    return p


def clips(arm):
    lib.action(arm, "walk", 24, lambda t: glide(arm, t, 0.6, t), step=1, loop=True)
    lib.action(arm, "idle", 48, lambda t: glide(arm, t, 0.65, t * 2 % 1.0), step=2, loop=True)

    def attack(t):  # rear back, then lunge the head forward with the jaw open
        rear = lib.pulse(t, 0.0, 0.45)
        breathe = lib.pulse(t, 0.35, 1.0)
        p = glide(arm, t, 0.3, t * 2 % 1.0)
        p["neck"] = (R(arm, "neck", (0, 1, 0), -0.8 * rear + 0.7 * breathe), None)
        p["head"] = (R(arm, "head", (0, 1, 0), -0.4 * rear + 0.35 * breathe), None)
        p["jaw"] = (R(arm, "jaw", (0, 1, 0), 0.6 * breathe), None)
        p["body"] = (R(arm, "body", (0, 1, 0), -0.15 * rear + 0.1 * breathe), p["body"][1])
        return p
    lib.action(arm, "attack", 24, attack, step=1)

    def hit(t):
        j = lib.pulse(t, 0.0, 1.0) * (1.0 - t)
        p = glide(arm, 0.0, 0.3, 0.25)
        p["body"] = (R(arm, "body", (1, 0, 0), 0.8 * j), lib.world_loc(arm, "body", (-0.2 * j, 0, 0.2 * j)))
        p["neck"] = (R(arm, "neck", (0, 0, 1), 0.8 * j), None)
        return p
    lib.action(arm, "hit", 10, hit, step=1)

    def die(t):
        fold = lib.ease(min(1.0, t / 0.5))
        p = fk.blend(glide(arm, t, 0.9, t * 3 % 1.0), fk.folded(arm, 1.0), fold)
        p["body"] = (R(arm, "body", (0, 1, 0), 0.9 * t) @ R(arm, "body", (1, 0, 0), 3.0 * t * t), lib.world_loc(arm, "body", (0.3 * t, 0, -2.5 * t * t)))
        p["neck"] = (R(arm, "neck", (0, 1, 0), 0.6 * fold), None)
        p["tail"] = (R(arm, "tail", (0, 1, 0), -0.4 * fold), None)
        return p
    lib.action(arm, "die", 36, die, step=1)


if __name__ == "__main__":
    out = sys.argv[sys.argv.index("--") + 1]
    lib.reset()
    a = build()
    clips(a)
    lib.export(out)
