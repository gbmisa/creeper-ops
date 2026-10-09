"""Big Bertha in three parts (weapon_kit), military: a concrete gun pit ringed with sandbags and
an olive armoured casemate (base); an armoured turntable with a mantlet, ammo crate counterweight
and a red warning lamp (turret); a twin steel boom with hydraulic rams carrying a long howitzer
with a muzzle brake and recoil cylinders (arm).
Pivots match TitanMeshes.bertha: Turret y 2.44, Arm at (-0.7, 0.75), wrist (2.402, 3.735) from
the shoulder, gun tilted 0.7 rad up, Muzzle 1.6 along the gun from the wrist.
Clips: idle = lamp blinks, boom breathes; attack = the barrel slams back, big flash and smoke;
hit = shudder; die = pit sinks, sandbags scatter, the boom droops.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
import weapon_kit as wk  # noqa: E402
from mathutils import Quaternion, Vector  # noqa: E402

T = Vector((0, 0, 2.44))
A = T + Vector((-0.7, 0, 0.75))
E = A + Vector((1.232, 0, 3.169))
W = A + Vector((2.402, 0, 3.735))
D = Vector((math.cos(0.7), 0, math.sin(0.7)))  # gun axis
QD = Quaternion((0, 1, 0), -0.7)
M = W + D * 1.6
CHUNKS = [("chunk%d" % i, (math.cos(a), math.sin(a))) for i, a in enumerate(math.pi / 4 + k * math.pi / 2 for k in range(4))]

BONES = [("base", (0, 0, 0), (0, 0, 0.5), None, "base")]
BONES += [(n, (x * 3.45, y * 3.45, 0.3), (x * 3.45, y * 3.45, 0.6), "base", "base") for n, (x, y) in CHUNKS]
BONES += [("turret", tuple(T), tuple(T + Vector((0, 0, 0.3))), None, "turret"),
          ("lamp", (-1.2, 0.55, 3.75), (-1.2, 0.55, 4.0), "turret", "turret"),
          ("arm", tuple(A), tuple(A + Vector((0, 0, 0.3))), "turret", "arm"),
          ("head", tuple(W), tuple(W + D * 0.3), "arm", "arm"),
          ("barrel", tuple(W), tuple(W + D * 0.3), "head", "arm"),
          ("flash", tuple(M), tuple(M + D * 0.3), "head", "arm"),
          ("smoke", tuple(M), tuple(M + D * 0.3), "head", "arm")]
PIVOTS = {"base": (0, 0, 0), "turret": tuple(T), "arm": tuple(A)}


def g(x):
    """Point x metres along the gun axis from the wrist."""
    return W + D * x


def geometry(k):
    # base: concrete pit slab, sandbag ring, armoured casemate, hazard band, vents
    k.box((0, 0, 0.2), (5.4, 5.4, 0.4), "concrete_dark", "base")
    for s in (1, -1):  # pit lip
        k.box((s * 2.6, 0, 0.6), (0.3, 5.4, 0.45), "concrete", "base")
        k.box((0, s * 2.6, 0.6), (5.4, 0.3, 0.45), "concrete", "base")
        for i in (-1, 0, 1):  # sandbags along each edge
            k.ball((s * 2.6, i * 1.3, 0.98), 0.42, "khaki", "base", scale=(0.6, 1.5, 0.5), seg=8, rings=4)
            k.ball((i * 1.3, s * 2.6, 0.98), 0.42, "khaki", "base", scale=(1.5, 0.6, 0.5), seg=8, rings=4)
    k.box((0, 0, 1.35), (4.4, 4.4, 1.9), "olive", "base")
    k.box((0, 0, 2.33), (4.8, 4.8, 0.16), "olive_dark", "base")
    for s in (1, -1):
        for i in range(5):
            k.box((-1.6 + i * 0.8, s * 2.31, 0.75), (0.7, 0.04, 0.16), "hazard" if i % 2 == 0 else "rubber", "base")
        k.box((s * 2.31, 0, 1.6), (0.05, 1.6, 0.5), "gunmetal", "base")
        for z in (1.45, 1.6, 1.75):
            k.box((s * 2.34, 0, z), (0.03, 1.5, 0.05), "rubber", "base")
    for x, y in ((1, 1), (1, -1), (-1, 1), (-1, -1)):  # corner rivet plates
        k.box((x * 2.18, y * 2.18, 1.35), (0.28, 0.28, 1.95), "olive_dark", "base")
    for n, (x, y) in CHUNKS:  # sandbag stacks at the corners (debris on die)
        a = math.atan2(y, x)
        for j, z in enumerate((0.56, 0.86, 1.14)):
            k.ball((x * 3.45, y * 3.45, z), 0.4, "sandbag", n, scale=(1.5, 0.8, 0.45), seg=8, rings=4,
                   rot=Quaternion((0, 0, 1), a + math.pi / 2 + j * 0.3))
    k.lathe([(1.8, 2.36), (2.0, 2.36), (2.0, 2.46), (1.8, 2.46), (1.8, 2.36)], "gunmetal", "base", seg=24, cap=False)
    # turret: armoured turntable, mantlet cheeks, ammo-crate counterweight, warning lamp
    k.lathe([(1.75, 2.44), (1.8, 2.5), (1.8, 2.7), (0.0, 2.7)], "olive_dark", "turret", seg=16, smooth=False)
    for x, y, _z, _a in [(math.cos(a) * 1.65, math.sin(a) * 1.65, 0, a) for a in (i * math.pi / 6 for i in range(12))]:
        k.ball((x, y, 2.7), 0.06, "steel", "turret", seg=4, rings=2)
    for s in (1, -1):
        k.box((A.x + 0.1, s * 0.75, 3.05), (1.2, 0.18, 0.95), "olive", "turret")
        k.ball((A.x, s * 0.86, A.z), 0.14, "steel", "turret", seg=6, rings=3)
    k.box((-1.55, 0, 3.15), (1.0, 1.3, 0.9), "olive_dark", "turret")
    for z in (2.9, 3.4):
        k.box((-2.06, 0, z), (0.04, 1.3, 0.12), "hazard", "turret")
    k.box((-1.55, 0, 3.62), (0.9, 1.2, 0.06), "gunmetal", "turret")
    k.limb((-1.2, 0.55, 3.62), (-1.2, 0.55, 3.75), 0.06, 0.06, "gunmetal", "turret", seg=6)
    k.ball((-1.2, 0.55, 3.82), 0.1, "lamp_red", "lamp", seg=6, rings=3)
    # arm: shoulder axle, twin steel I-beam boom, elbow, forearm, two hydraulic rams
    k.limb(A + Vector((0, -0.75, 0)), A + Vector((0, 0.75, 0)), 0.15, 0.15, "steel", "arm", seg=10)
    for s in (1, -1):
        k.limb(A + Vector((0, s * 0.42, 0)), E + Vector((0, s * 0.42, 0)), 0.17, 0.15, "gunmetal", "arm", seg=4)
        k.limb(A + Vector((0, s * 0.42, 0)), E + Vector((0, s * 0.42, 0)), 0.05, 0.05, "hazard", "arm", seg=4)
        p0 = A + Vector((-0.5, s * 0.3, -0.45))
        mid = A.lerp(E, 0.5) + Vector((0, s * 0.3, 0))
        k.limb(p0, p0.lerp(mid, 0.55), 0.12, 0.12, "olive_dark", "arm", seg=8)
        k.limb(p0.lerp(mid, 0.5), mid, 0.06, 0.06, "steel", "arm", seg=8)
    k.limb(E + Vector((0, -0.6, 0)), E + Vector((0, 0.6, 0)), 0.2, 0.2, "steel", "arm", seg=10)
    k.limb(E, W, 0.24, 0.22, "olive", "arm", seg=6)
    # head: cradle and breech; the tube recoils on "barrel"
    k.ball(tuple(W), 0.3, "gunmetal", "head", seg=8, rings=4)
    k.box(g(0.0), (1.6, 0.9, 0.7), "olive", "head", rot=QD)
    k.box(g(-1.45), (0.5, 1.05, 1.05), "steel", "barrel", rot=QD)  # breech block
    for s in (1, -1):
        k.limb(g(-0.5) + Vector((0, s * 0.3, 0.25)), g(0.9) + Vector((0, s * 0.3, 0.25)), 0.11, 0.11, "steel", "head", seg=8)
    k.tube([(g(-1.3), 0.66), (g(-0.2), 0.6), (g(-0.15), 0.7), (g(0.0), 0.7), (g(0.05), 0.56), (g(1.25), 0.52)],
           "olive", "barrel", seg=16)
    k.tube([(g(1.25), 0.68), (g(1.6), 0.68)], "brake", "barrel", seg=12)  # muzzle brake  # muzzle brake
    for s in (1, -1):
        k.box(g(1.43) + Vector((0, s * 0.68, 0)), (0.18, 0.06, 0.4), "rubber", "barrel", rot=QD)
    # attack effects
    k.limb(M, M + D * 3.6, 1.4, 0.0, "fire", "flash", seg=8)
    k.ball(M + D * 0.4, 1.0, "flash_white", "flash", seg=6, rings=4)
    for s in (1, -1):
        k.limb(M - D * 0.12, M - D * 0.12 + Vector((0, s * 2.4, 0)), 0.5, 0.0, "fire", "flash", seg=6)
    for i, (x, y, z) in enumerate(((0.3, 0, 0.1), (0.7, 0.3, 0.3), (0.6, -0.35, 0.4))):
        k.ball(M + D * x + Vector((0, y, z)), 0.8 + 0.2 * i, "smoke_dark", "smoke", seg=6, rings=4)


def base_pose(t):
    return {"lamp": {"scale": 1.2 if (t * 2) % 1.0 < 0.5 else 0.6},
            "arm": {"rot": ((0, 1, 0), 0.1 * math.sin(2 * math.pi * t))},
            "flash": {"scale": wk.HIDE}, "smoke": {"scale": wk.HIDE}}


def idle(t):
    return base_pose(t)


def attack(t):
    p = base_pose(0.0)
    f = lib.pulse(t, -0.02, 0.35)
    rc = 1.0 * (1.0 - lib.ease(min(1.0, t / 0.8))) if t > 0.05 else 1.0 * t / 0.05
    p["barrel"] = {"loc": tuple(-D * rc)}
    p["head"] = {"rot": ((0, 1, 0), -0.12 * lib.pulse(t, 0.0, 0.5))}
    p["arm"] = {"rot": ((0, 1, 0), 0.05 * lib.pulse(t, 0.0, 0.6))}
    p["flash"] = {"scale": max(wk.HIDE, 1.4 * f) if t < 0.4 else wk.HIDE}
    u = lib.ease(max(0.0, (t - 0.1) / 0.9))
    p["smoke"] = {"scale": max(wk.HIDE, (0.5 + 1.2 * u) * (1.0 - u * u)) if t > 0.08 else wk.HIDE,
                  "loc": tuple(D * 0.5 * u + Vector((0, 0, 0.6 * u)))}
    p["lamp"] = {"scale": 1.4}
    return p


def hit(t):
    p = base_pose(0.0)
    p.update(wk.hit_common(t))
    j = lib.pulse(t, 0.0, 1.0) * (1.0 - t)
    p["base"] = {"rot": ((1, 0, 0), 0.08 * j * math.sin(16 * t)), "scale": (1 + 0.06 * j, 1 + 0.06 * j, 1 - 0.12 * j)}
    p["turret"]["rot"] = ((0.3, 0, 1), 0.6 * j * math.sin(14 * t))
    return p


def die(t):
    p = base_pose(t)
    p.update(wk.die_common(t, CHUNKS))
    p["lamp"] = {"scale": wk.HIDE if t > 0.3 else 1.4}
    p["arm"] = {"rot": ((0, 1, 0), 0.7 * lib.ease(min(1.0, t / 0.7)))}
    return p


if __name__ == "__main__":
    wk.run("bertha", BONES, PIVOTS, geometry, {
        "idle": (48, idle, True), "attack": (20, attack, False),
        "hit": (10, hit, False), "die": (48, die, False)})
