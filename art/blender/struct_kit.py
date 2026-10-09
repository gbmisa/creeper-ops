"""Shared clips for static hive structures (real metres, scale 1, no walking).
Each structure supplies idle(arm, t) and attack(arm, t) pose functions; hit, die and walk
(= idle, so the CreatureAnim contract holds) come from here.
  wilt: {bone: outward axis} bones that fall outward on death
  pop:  bones (glow sacs) that burst and vanish on death
  drop: {bone: metres} hanging parts that fall to the ground on death
"""
import math
import sys

import lib


def merge(*poses):
    out = {}
    for p in poses:
        out.update(p)
    return out


def tangent(x, y):
    """Axis that tips a part at (x, y) outward from the centre when rotated positively."""
    return (-y, x, 0) if (x or y) else (0, 1, 0)


def hit_pose(arm, idle, t, top):
    j = lib.pulse(t, 0.0, 1.0) * (1.0 - t)
    p = idle(arm, 0.0)
    p["base"] = (None, None, (1 + 0.08 * j, 1 - 0.14 * j, 1 + 0.08 * j))  # bone-local y = up
    if top:
        p[top] = (lib.world_rot(arm, top, (0, 1, 0), 0.25 * j), p.get(top, (None, None))[1])
    return p


def die_pose(arm, idle, t, wilt, pop, drop, fall=0.9):
    k = lib.ease(min(1.0, t / 0.6))
    p = idle(arm, (t * 2.5) % 1.0)
    for b, axis in wilt.items():
        p[b] = (lib.world_rot(arm, b, axis, fall * k), None)
    burst = 1 + 0.5 * lib.pulse(t, 0.0, 0.3)
    for b in pop:
        p[b] = (None, None, (max(0.01, burst - k),) * 3)
    for b, h in drop.items():
        f = min(1.0, (t / 0.55) ** 2)
        p[b] = (p.get(b, (None,))[0], lib.world_loc(arm, b, (0, 0, -h * f)))
    sink = lib.ease(max(0.0, (t - 0.35) / 0.65))
    p["base"] = (None, lib.world_loc(arm, "base", (0, 0, -0.35 * sink)),
                 (1 + 0.15 * sink, max(0.2, 1 - 0.6 * sink), 1 + 0.15 * sink))
    return p


def run(build, idle, attack, attack_frames=20, idle_frames=48, top=None, wilt=None, pop=(), drop=None, fall=0.9):
    out = sys.argv[sys.argv.index("--") + 1]
    lib.reset()
    arm = build()
    lib.action(arm, "idle", idle_frames, lambda t: idle(arm, t), step=2, loop=True)
    lib.action(arm, "walk", idle_frames, lambda t: idle(arm, t), step=2, loop=True)
    lib.action(arm, "attack", attack_frames, lambda t: attack(arm, t), step=1)
    lib.action(arm, "hit", 10, lambda t: hit_pose(arm, idle, t, top), step=1)
    lib.action(arm, "die", 40, lambda t: die_pose(arm, idle, t, wilt or {}, pop, drop or {}, fall), step=1)
    lib.export(out)


def ring(n, r, z, phase=0.0):
    """n points on a circle: (x, y, z, angle)."""
    return [(math.cos(phase + i * 2 * math.pi / n) * r, math.sin(phase + i * 2 * math.pi / n) * r, z,
             phase + i * 2 * math.pi / n) for i in range(n)]
