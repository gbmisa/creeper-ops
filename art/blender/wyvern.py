"""Wyvern: big winged drake with a long neck and tail; rears back and breathes fire.
Origin at the body centre. Game id: wyvern.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import flyer_kit as fk  # noqa: E402
import lib  # noqa: E402

SPAN, CHORD = 2.3, 1.25
HIDE = (None, None, (0.01, 0.01, 0.01))


def build():
    arm = lib.armature("wyvern", [("root", (0, 0, 0), (0, 0, 0.1), None),
                                  ("body", (-0.3, 0, 0), (0.3, 0, 0), "root"),
                                  ("neck", (0.45, 0, 0.08), (1.05, 0, 0.5), "body"),
                                  ("head", (1.05, 0, 0.5), (1.5, 0, 0.5), "neck"),
                                  ("jaw", (1.1, 0, 0.43), (1.48, 0, 0.38), "head"),
                                  ("fire", (1.55, 0, 0.44), (2.6, 0, 0.3), "head"),
                                  ("tail", (-0.4, 0, 0), (-1.15, 0, -0.1), "body"),
                                  ("tail2", (-1.15, 0, -0.1), (-2.0, 0, -0.2), "tail")] + fk.wing_bones(SPAN, CHORD))
    b = lib.Builder("wyvern")
    b.ball((0, 0, 0), 0.36, "wyv_skin", "body", scale=(1.8, 1.2, 1.1), seg=12, rings=8)
    b.ball((0.05, 0, -0.2), 0.28, "plate", "body", scale=(1.6, 1.0, 0.45), seg=8, rings=5, smooth=False)  # belly plates
    for x in (0.25, 0.0, -0.25):  # back ridge
        b.limb((x, 0, 0.22), (x - 0.18, 0, 0.52), 0.09, 0.0, "bone", "body", seg=4)
    b.ball((-0.1, 0, -0.22), 0.13, "glow", "body", seg=7, rings=5)  # fire gland
    for s in (1, -1):  # hind legs tucked under, talons forward
        b.limb((-0.15, s * 0.2, -0.12), (-0.38, s * 0.24, -0.42), 0.12, 0.07, "wyv_skin", "body", seg=6)
        b.limb((-0.38, s * 0.24, -0.42), (-0.2, s * 0.24, -0.62), 0.06, 0.045, "wyv_skin", "body", seg=5)
        for dy in (-0.06, 0.0, 0.06):
            b.limb((-0.2, s * 0.24 + dy, -0.62), (-0.06, s * 0.24 + dy * 1.4, -0.7), 0.025, 0.0, "bone", "body", seg=4)
    b.limb((0.4, 0, 0.06), (1.08, 0, 0.5), 0.21, 0.11, "wyv_skin", "neck", seg=7, smooth=True)
    for k in range(4):  # neck ridge
        x, z = 0.5 + 0.15 * k, 0.26 + 0.1 * k
        b.limb((x, 0, z), (x - 0.1, 0, z + 0.18), 0.05, 0.0, "bone", "neck", seg=4)
    b.ball((1.15, 0, 0.53), 0.19, "wyv_skin", "head", scale=(1.3, 0.95, 0.8), seg=8, rings=6)  # skull
    b.limb((1.25, 0, 0.52), (1.56, 0, 0.47), 0.11, 0.06, "wyv_skin", "head", seg=6)  # snout
    b.limb((1.1, 0, 0.42), (1.5, 0, 0.39), 0.08, 0.04, "wyv_skin", "jaw", seg=5)
    for s in (1, -1):
        b.limb((1.12, s * 0.1, 0.62), (1.42, s * 0.06, 0.55), 0.04, 0.02, "bone", "head", seg=4)  # brow ridge
        b.ball((1.22, s * 0.11, 0.56), 0.045, "glow", "head", seg=5, rings=4)
        b.limb((1.05, s * 0.09, 0.6), (0.85, s * 0.14, 0.72), 0.055, 0.035, "bone", "head", seg=4)  # horns
        b.limb((0.85, s * 0.14, 0.72), (0.62, s * 0.18, 0.94), 0.035, 0.0, "bone", "head", seg=4)
        for x in (1.3, 1.42, 1.52):  # teeth
            b.limb((x, s * 0.05, 0.43), (x + 0.02, s * 0.05, 0.37), 0.018, 0.0, "bone", "head", seg=3)
    b.limb((1.56, 0, 0.44), (2.6, 0, 0.3), 0.06, 0.4, "flame", "fire", seg=10)  # breath cone
    b.limb((1.6, 0, 0.44), (2.3, 0, 0.34), 0.03, 0.18, "glow", "fire", seg=8)
    b.limb((-0.4, 0, 0), (-1.15, 0, -0.1), 0.17, 0.08, "wyv_skin", "tail", seg=6, smooth=True)
    b.limb((-1.15, 0, -0.1), (-2.0, 0, -0.2), 0.08, 0.015, "wyv_skin", "tail2", seg=6, smooth=True)
    for x in (-0.6, -0.9, -1.25, -1.55):  # tail ridge
        b.limb((x, 0, 0.06), (x - 0.1, 0, 0.2), 0.045, 0.0, "bone", "tail" if x > -1.15 else "tail2", seg=4)
    b.limb((-1.9, 0, -0.19), (-2.25, 0, -0.21), 0.13, 0.0, "bone", "tail2", seg=4)
    for s in (1, -1):  # tail spade
        b.limb((-1.85, 0, -0.18), (-2.05, s * 0.26, -0.17), 0.06, 0.0, "bone", "tail2", seg=4)
    fk.wing_mesh(b, SPAN, CHORD, "wyv_wing")
    for sd, s in fk.SIDES:  # wrist claws
        w = fk.wing_points(s, SPAN, CHORD)["W"]
        b.limb(w, (w[0] + 0.22, w[1], w[2] + 0.06), 0.04, 0.0, "bone", "hand_" + sd, seg=4)
    b.finish(arm)
    return arm


def R(arm, bone, axis, ang):
    return lib.world_rot(arm, bone, axis, ang)


def glide(arm, t, flap_amp, phase, bob=0.08):
    w = 2 * math.pi * t
    p = fk.flap(arm, phase, amp=flap_amp, bias=0.05)
    p["body"] = (R(arm, "body", (0, 1, 0), 0.04 * math.sin(w)), lib.world_loc(arm, "body", (0, 0, -bob * math.sin(2 * math.pi * phase))))
    p["neck"] = (R(arm, "neck", (0, 0, 1), 0.08 * math.sin(w)), None)
    p["tail"] = (R(arm, "tail", (0, 0, 1), 0.12 * math.sin(w + 1.0)), None)
    p["tail2"] = (R(arm, "tail2", (0, 0, 1), 0.2 * math.sin(w + 0.2)), None)
    p["fire"] = HIDE
    return p


def clips(arm):
    def lean(p):  # cruising: nose down, neck stretched, tail streaming
        p["body"] = (R(arm, "body", (0, 1, 0), 0.18) @ p["body"][0], p["body"][1])
        p["neck"] = (R(arm, "neck", (0, 1, 0), 0.25) @ p["neck"][0], None)
        p["tail"] = (R(arm, "tail", (0, 1, 0), -0.2) @ p["tail"][0], None)
        return p

    lib.action(arm, "walk", 16, lambda t: lean(glide(arm, t, 0.5, t, bob=0.05)), step=1, loop=True)
    lib.action(arm, "idle", 48, lambda t: glide(arm, t, 0.85, t, bob=0.18), step=2, loop=True)

    def attack(t):  # rear back, then lunge the head forward with the jaw open
        rear = lib.pulse(t, 0.0, 0.5)
        breathe = lib.pulse(t, 0.35, 1.0)
        p = glide(arm, t, 0.3, t * 2 % 1.0)
        p["neck"] = (R(arm, "neck", (0, 1, 0), -1.1 * rear + 0.2 * breathe), None)
        p["head"] = (R(arm, "head", (0, 1, 0), -0.5 * rear + 0.1 * breathe), None)
        p["jaw"] = (R(arm, "jaw", (0, 1, 0), 0.6 * breathe), None)
        p["body"] = (R(arm, "body", (0, 1, 0), -0.15 * rear + 0.05 * breathe), lib.world_loc(arm, "body", (-0.15 * breathe, 0, 0)))
        f = lib.ease(min(1.0, max(0.0, (t - 0.42) / 0.2))) * (1.0 - lib.ease(max(0.0, (t - 0.94) / 0.06)))
        k = 1 + 0.12 * math.sin(40 * t)
        p["fire"] = (None, None, (max(0.01, f * k), max(0.01, f), max(0.01, f * k)))
        return p
    lib.action(arm, "attack", 24, attack, step=1)

    def hit(t):
        j = lib.pulse(t, 0.0, 1.0) * (1.0 - t)
        p = glide(arm, 0.0, 0.3, 0.25)
        p.update(fk.blend(p, fk.folded(arm, 1.0), 0.6 * j))
        p["body"] = (R(arm, "body", (0, 1, 0), -0.6 * j) @ R(arm, "body", (1, 0, 0), 0.5 * j), lib.world_loc(arm, "body", (-0.45 * j, 0, 0.3 * j)))
        p["neck"] = (R(arm, "neck", (0, 0, 1), 0.9 * j), None)
        p["tail"] = (R(arm, "tail", (0, 1, 0), 0.5 * j), None)
        p["head"] = (R(arm, "head", (0, 1, 0), -0.6 * j), None)
        p["fire"] = HIDE
        return p
    lib.action(arm, "hit", 10, hit, step=1)

    def die(t):
        fold = lib.ease(min(1.0, t / 0.5))
        p = fk.blend(glide(arm, t, 0.9, t * 3 % 1.0), fk.folded(arm, 1.0), fold)
        p["body"] = (R(arm, "body", (0, 1, 0), 0.9 * t) @ R(arm, "body", (1, 0, 0), 1.6 * t * t), lib.world_loc(arm, "body", (0.3 * t, 0, -1.1 * t * t)))
        p["fire"] = HIDE
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
