"""Bat-style wings (arm + hand bones, membrane bends at the wrist) and flap poses.
Flyers are authored with the body centre at the origin (they hover), facing +X; `walk` is the flap loop.
"""
import math

import lib

SIDES = (("L", 1), ("R", -1))


def wing_points(s, span, chord, root=(0.05, 0.1, 0.05)):
    """Shoulder, elbow, wrist, three finger tips and the trailing body point, for side s."""
    def p(x, y, z=0.0):
        return (root[0] + x * chord, s * (root[1] + y * span), root[2] + z * span)
    return {"S": p(0, 0), "E": p(-0.05, 0.45, 0.04), "W": p(-0.1, 0.78, 0.03), "F1": p(0.1, 1.08),
            "F2": p(-0.45, 0.98), "F3": p(-0.75, 0.62), "B": p(-0.5, 0.02, -0.03)}


def wing_bones(span, chord, parent="body"):
    out = []
    for sd, s in SIDES:
        w = wing_points(s, span, chord)
        out.append(("wing_" + sd, w["S"], w["E"], parent))
        out.append(("hand_" + sd, w["E"], w["W"], "wing_" + sd))
    return out


def wing_mesh(b, span, chord, skin, bone_mat="bone", parent="body"):
    for sd, s in SIDES:
        w = wing_points(s, span, chord)
        up, lo = "wing_" + sd, "hand_" + sd
        panels = [(("S", parent), ("E", up), ("F3", lo), ("B", parent)),
                  (("E", up), ("W", lo), ("F2", lo), ("F3", lo)),
                  (("W", lo), ("F1", lo), ("F2", lo))]
        for panel in panels:
            pts = [w[k] for k, _ in panel]
            if s < 0:
                pts = list(reversed(pts))
                bones = [bn for _, bn in reversed(panel)]
            else:
                bones = [bn for _, bn in panel]
            b.poly(pts, bones, skin)
        r = 0.035 * span
        b.limb(w["S"], w["E"], r, r * 0.8, bone_mat, up, seg=5)
        b.limb(w["E"], w["W"], r * 0.8, r * 0.6, bone_mat, lo, seg=5)
        for f in ("F1", "F2", "F3"):
            b.limb(w["W"], w[f], r * 0.5, 0.0, bone_mat, lo, seg=4)


def flap(arm, t, amp=0.7, bias=0.1, fold=0.5, sweep=0.0):
    """Wing pose at phase t: downstroke then upstroke, the hand lagging and folding on the way up."""
    a = math.sin(2 * math.pi * t)
    h = math.sin(2 * math.pi * t - 0.9)
    p = {}
    for sd, s in SIDES:
        up = lib.world_rot(arm, "wing_" + sd, (1, 0, 0), s * (bias + amp * a)) @ lib.world_rot(arm, "wing_" + sd, (0, 0, 1), s * sweep)
        p["wing_" + sd] = (up, None)
        p["hand_" + sd] = (lib.world_rot(arm, "hand_" + sd, (1, 0, 0), s * (0.4 * amp * h - fold * max(0.0, -h) * 0.6)), None)
    return p


def folded(arm, k):
    """Wings swept back and folded by k (0..1): dives and deaths."""
    p = {}
    for sd, s in SIDES:
        p["wing_" + sd] = (lib.world_rot(arm, "wing_" + sd, (0, 0, 1), s * 1.0 * k) @ lib.world_rot(arm, "wing_" + sd, (1, 0, 0), s * 0.3 * k), None)
        p["hand_" + sd] = (lib.world_rot(arm, "hand_" + sd, (0, 0, 1), s * 1.2 * k), None)
    return p


def blend(pa, pb, k):
    """Mix two wing poses (quaternions only)."""
    out = {}
    for key in pa:
        qa, qb = pa[key][0], pb.get(key, (None,))[0]
        out[key] = (qa.slerp(qb, k) if qa is not None and qb is not None else qa, None)
    return out
