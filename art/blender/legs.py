"""Two-bone legs (upper hip->knee, lower knee->foot) and a phase-offset gait.
A creature lists its legs once; walk/attack/die poses come from yaw/lift/bend per leg.
"""
import math

import lib
from mathutils import Quaternion, Vector


class Legs:
    def __init__(self):
        self.legs = {}  # name -> (hip, knee, foot, side, phase)
        self.pillars = set()

    def add(self, name, hip, foot, side, phase, knee_up=0.26, knee_out=0.06, pillar=False):
        """pillar: an upright leg that swings fore-aft (elephant), not around the hip (insect)."""
        hip, foot = Vector(hip), Vector(foot)
        knee = (hip + foot) * 0.5 + Vector((0.0, side * knee_out, knee_up))
        self.legs[name] = (hip, knee, foot, side, phase)
        if pillar:
            self.pillars.add(name)

    def bones(self, parent):
        out = []
        for n, (hip, knee, foot, _s, _p) in self.legs.items():
            out.append(("up_" + n, hip, knee, parent))
            out.append(("lo_" + n, knee, foot, "up_" + n))
        return out

    def mesh(self, b, r_hip, r_knee, r_foot, mat="chitin", joint="plate", tip="bone", seg=6):
        for n, (hip, knee, foot, _s, _p) in self.legs.items():
            b.limb(hip, knee, r_hip, r_knee, mat, "up_" + n, seg=seg)
            b.ball(knee, r_knee * 1.1, joint, "up_" + n, seg=5, rings=4, smooth=False)
            if n in self.pillars:  # blunt column down to a pad, no claw
                b.limb(knee, foot + Vector((0, 0, 0.05)), r_knee, r_foot, mat, "lo_" + n, seg=seg)
                continue
            claw = foot + (knee - foot).normalized() * max(0.06, r_foot * 3.0)
            b.limb(knee, claw, r_knee, r_foot, mat, "lo_" + n, seg=seg)
            b.limb(claw, foot, r_foot, 0.0, tip, "lo_" + n, seg=4)

    def pose(self, arm, n, yaw, lift, bend):
        """yaw: + swings the foot forward; lift: + raises it; bend: + folds the shin in."""
        hip, _knee, foot, side, _p = self.legs[n]
        if n in self.pillars:
            q_up = Quaternion((0, 1, 0), -(yaw + 0.5 * lift))
            q_lo = Quaternion((0, 1, 0), bend + lift)
            return {"up_" + n: (lib.local_q(arm, "up_" + n, q_up), None),
                    "lo_" + n: (lib.local_q(arm, "lo_" + n, q_lo), None)}
        out = foot - hip
        out.z = 0.0
        if out.length < 1e-4:
            out = Vector((0.0, side, 0.0))
        k = out.normalized().cross(Vector((0, 0, 1)))
        q_up = Quaternion((0, 0, 1), -side * yaw) @ Quaternion(k, lift)
        return {"up_" + n: (lib.local_q(arm, "up_" + n, q_up), None),
                "lo_" + n: (lib.local_q(arm, "lo_" + n, Quaternion(k, -bend)), None)}

    def all(self, arm, fn):
        """fn(name, side, index) -> (yaw, lift, bend)."""
        pose = {}
        for i, (n, leg) in enumerate(self.legs.items()):
            pose.update(self.pose(arm, n, *fn(n, leg[3], i)))
        return pose

    def walk(self, arm, t, swing, lift=0.55, bend=0.35, duty=0.5):
        """Each leg: stance (foot sweeps back at constant speed) then an eased swing forward."""
        def leg(n, _side, _i):
            ph = (t + self.legs[n][4]) % 1.0
            if ph < duty:
                return (swing * (1.0 - 2.0 * ph / duty), 0.0, 0.0)
            u = (ph - duty) / (1.0 - duty)
            s = math.sin(math.pi * u)
            return (swing * (-1.0 + 2.0 * lib.ease(u)), lift * s, bend * s)
        return self.all(arm, leg)
