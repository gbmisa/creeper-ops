"""Shared clips for small leg-walkers: idle, walk, hit and die come from a few numbers;
each creature supplies its own attack pose. Bones: root, body, optional head, legs.
"""
import math
import sys

import lib


def body_pose(arm, pitch=0.0, roll=0.0, yaw=0.0, loc=(0, 0, 0)):
    q = (lib.world_rot(arm, "body", (0, 1, 0), pitch) @ lib.world_rot(arm, "body", (1, 0, 0), roll)
         @ lib.world_rot(arm, "body", (0, 0, 1), yaw))
    return (q, lib.world_loc(arm, "body", loc))


def bone_rot(arm, bone, axis, ang):
    return (lib.world_rot(arm, bone, axis, ang), None)


class Kit:
    def __init__(self, arm, legs, walk_frames=18, swing=0.4, lift=0.5, bend=0.35, duty=0.55, bob=0.02,
                 head=None, roll_die=math.pi * 0.85, sink=0.25):
        self.arm, self.legs = arm, legs
        self.walk_frames, self.swing, self.lift, self.bend, self.duty, self.bob = walk_frames, swing, lift, bend, duty, bob
        self.head, self.roll_die, self.sink = head, roll_die, sink

    def still(self, fn=None):
        return self.legs.all(self.arm, fn or (lambda n, s, i: (0.0, 0.0, 0.0)))

    def idle(self, extra=None):
        def pose(t):
            w = 2 * math.pi * t
            p = self.still()
            p["body"] = body_pose(self.arm, pitch=0.05 * math.sin(w), loc=(0, 0, 0.03 * math.sin(w)))
            if self.head:
                p[self.head] = bone_rot(self.arm, self.head, (0, 0, 1), 0.5 * math.sin(w) * lib.pulse(t, 0.15, 0.75))
            if extra:
                p.update(extra(t))
            return p
        lib.action(self.arm, "idle", 48, pose, step=2, loop=True)

    def walk(self, extra=None):
        def pose(t):
            p = self.legs.walk(self.arm, t, self.swing, self.lift, self.bend, self.duty)
            p["body"] = body_pose(self.arm, roll=0.08 * math.sin(2 * math.pi * t),
                                  loc=(0, 0, 1.8 * self.bob * math.cos(4 * math.pi * t)))
            if extra:
                p.update(extra(t))
            return p
        lib.action(self.arm, "walk", self.walk_frames, pose, step=1, loop=True)

    def hit(self):
        def pose(t):
            j = lib.pulse(t, 0.0, 1.0) * (1.0 - t)
            p = self.still(lambda n, s, i: (0.0, 0.5 * j, 0.4 * j))
            p["body"] = body_pose(self.arm, pitch=-0.45 * j, roll=0.25 * j, loc=(-0.16 * j, 0, 0.05 * j))
            if self.head:
                p[self.head] = bone_rot(self.arm, self.head, (0, 0, 1), 0.6 * j)
            return p
        lib.action(self.arm, "hit", 8, pose, step=1)

    def die(self, extra=None):
        def pose(t):
            flail = math.sin(t * 36.0) * lib.pulse(t, 0.0, 0.35)
            roll = self.roll_die * lib.ease(min(1.0, max(0.0, (t - 0.2) / 0.5)))
            curl = lib.ease(min(1.0, t / 0.6))
            p = self.still(lambda n, s, i: (0.3 * flail * (1 if i % 2 else -1), -0.35 * curl, 0.9 * curl))
            sink = -self.sink * lib.ease(min(1.0, max(0.0, (t - 0.6) / 0.4)))
            p["body"] = body_pose(self.arm, roll=roll, loc=(0, 0, 0.1 * lib.pulse(t, 0.2, 0.7) + sink))
            if extra:
                p.update(extra(t))
            return p
        lib.action(self.arm, "die", 29, pose, step=1)

    def attack(self, frames, pose_fn):
        """pose_fn(t, p) edits a still pose in place."""
        def pose(t):
            p = self.still()
            pose_fn(t, p)
            return p
        lib.action(self.arm, "attack", frames, pose, step=1)


def run(build, clips):
    """build() -> Kit; clips(kit) bakes every clip; then export to argv after '--'."""
    out = sys.argv[sys.argv.index("--") + 1]
    lib.reset()
    kit = build()
    clips(kit)
    lib.export(out)
