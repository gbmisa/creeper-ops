"""Shared military parts (olive, gunmetal, concrete, sandbags, hazard) for the player structures.
Every helper takes a weapon_kit.Kit or a lib.Builder (`k`); both expose box/ball/lathe/limb.
Glow is only for gameplay cues (status lamps, muzzle flash, energy cells).
"""
import math

from mathutils import Quaternion, Vector


def slab(k, half, h, bone, mat="concrete_dark", chamfer=0.1, z=0.0):
    """Square slab (faces on the axes) with a chamfered top edge."""
    r, c = half * math.sqrt(2), chamfer * math.sqrt(2)
    k.lathe([(r, z), (r, z + h - chamfer), (r - c, z + h), (0.0, z + h)], mat, bone, seg=4, smooth=False,
            phase=math.pi / 4)


def square(k, half, z0, z1, mat, bone, top_half=None):
    """Square column between z0 and z1 (faces on the axes), tapered when top_half is given."""
    th = half if top_half is None else top_half
    k.lathe([(half * math.sqrt(2), z0), (th * math.sqrt(2), z1), (0.0, z1)], mat, bone, seg=4, smooth=False,
            phase=math.pi / 4)


def sandbags(k, half, z, bone, rows=2, per=3, gap=0.0):
    """A ring of sandbags round a square of half-size `half`, `rows` high, `per` bags per edge."""
    bag = 2 * half / per
    for row in range(rows):
        off = 0.5 * bag if row % 2 else 0.0
        zz = z + 0.11 + row * 0.17
        for side in range(4):
            q = Quaternion((0, 0, 1), side * math.pi / 2)
            for i in range(per):
                x = -half + bag * (i + 0.5) + off
                if x > half:
                    continue
                p = q @ Vector((x, half + 0.12 + gap, zz))
                k.ball(tuple(p), bag * 0.5, "sandbag", bone, scale=(1.0, 0.55, 0.36), seg=8, rings=4,
                       rot=q)


def hazard_band(k, half, z, h, bone, n=6, thick=0.03):
    """Yellow/black chevron band on all four faces of a square of half-size `half`."""
    w = 2 * half / n
    for side in range(4):
        q = Quaternion((0, 0, 1), side * math.pi / 2)
        for i in range(n):
            p = q @ Vector((-half + w * (i + 0.5), half + thick / 2, z))
            k.box(tuple(p), tuple(abs(c) for c in q @ Vector((w, thick, h))),
                  "hazard" if i % 2 == 0 else "rubber", bone)


def rivets(k, pts, bone, r=0.035, mat="steel"):
    for p in pts:
        k.ball(tuple(p), r, mat, bone, seg=4, rings=2)


def ladder(k, x, y, z0, z1, bone, face=(1, 0), w=0.32):
    """Steel rung ladder on a face; face = outward normal (x, y)."""
    n = Vector((face[0], face[1], 0))
    t = Vector((-face[1], face[0], 0))
    base = Vector((x, y, 0)) + n * 0.06
    for s in (-1, 1):
        a = base + t * (s * w / 2)
        k.limb(a + Vector((0, 0, z0)), a + Vector((0, 0, z1)), 0.022, 0.022, "steel", bone, seg=4)
    z = z0 + 0.15
    while z < z1 - 0.05:
        k.limb(base - t * (w / 2) + Vector((0, 0, z)), base + t * (w / 2) + Vector((0, 0, z)), 0.016, 0.016,
               "steel", bone, seg=4)
        z += 0.22


def turntable(k, r, z0, z1, bone, mat="gunmetal", bolts=10):
    k.lathe([(r, z0), (r * 1.04, z0 + 0.04), (r * 1.04, z1), (0.0, z1)], mat, bone, seg=16, smooth=False)
    for i in range(bolts):
        a = 2 * math.pi * i / bolts
        k.ball((math.cos(a) * r * 0.9, math.sin(a) * r * 0.9, z1), 0.03, "steel", bone, seg=4, rings=2)


def lamp(k, at, bone, mat="lamp_red", r=0.07):
    """Status lamp with a steel cage collar."""
    k.limb(Vector(at) - Vector((0, 0, r * 1.2)), Vector(at) - Vector((0, 0, r * 0.6)), r * 1.2, r * 1.2,
           "gunmetal", bone, seg=6)
    k.ball(tuple(at), r, mat, bone, seg=6, rings=3)


def antenna(k, at, h, bone, tip_bone=None):
    a = Vector(at)
    k.limb(a, a + Vector((0, 0, 0.12)), 0.05, 0.05, "gunmetal", bone, seg=6)
    k.limb(a + Vector((0, 0, 0.12)), a + Vector((0, 0, h)), 0.018, 0.01, "rubber", tip_bone or bone, seg=4)
    k.ball(tuple(a + Vector((0, 0, h))), 0.035, "lamp_red", tip_bone or bone, seg=4, rings=2)


def muzzle_brake(k, at, r, bone, axis=(1, 0, 0), length=0.3):
    """Steel box brake with side slots along `axis` from `at`."""
    a, d = Vector(at), Vector(axis).normalized()
    k.limb(a, a + d * length, r, r, "steel", bone, seg=8)
    for f in (0.3, 0.7):
        c = a + d * (length * f)
        k.limb(c - d * 0.03, c + d * 0.03, r * 1.12, r * 1.12, "rubber", bone, seg=8)


def flash(k, at, r, bone, axis=(1, 0, 0)):
    """Muzzle flash: orange cone, white core, four petals."""
    a, d = Vector(at), Vector(axis).normalized()
    side = d.orthogonal().normalized()
    up = d.cross(side)
    k.limb(a, a + d * r * 2.6, r, 0.0, "fire", bone, seg=8)
    k.ball(tuple(a + d * r * 0.4), r * 0.9, "flash_white", bone, seg=6, rings=3)
    for v in (side, -side, up, -up):
        k.limb(a + d * r * 0.3, a + d * r * 0.9 + v * r * 1.6, r * 0.25, 0.0, "fire", bone, seg=4)


def crate(k, at, size, bone, mat="olive_dark", stencil=True):
    k.box(at, size, mat, bone)
    if stencil:
        x, y, z = at
        k.box((x, y - size[1] / 2 - 0.005, z), (size[0] * 0.6, 0.01, size[2] * 0.25), "khaki", bone)


def column_trim(k, h0, h1, z0, z1, bone, seams=(0.4, 0.7), mat="concrete_dark", corner="olive_dark"):
    """Formwork seams and angle-iron corners on a (tapered) square column from square()."""
    for f in seams:
        z = z0 + (z1 - z0) * f
        h = h0 + (h1 - h0) * f
        square(k, h + 0.012, z - 0.02, z + 0.02, mat, bone)
    for x, y in ((1, 1), (1, -1), (-1, 1), (-1, -1)):
        k.limb(Vector((x * h0, y * h0, z0)), Vector((x * h1, y * h1, z1)), 0.05, 0.05, corner, bone, seg=4)
