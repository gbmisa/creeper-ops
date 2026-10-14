"""Texture clean-up for glb_texture.py (numpy only): median denoise, region recolour, roughness/metal maps.
clean_picture(pic RGBA float, linear) -> (pic, roughness, metallic), all M x M."""
import colorsys
import numpy as np

GUNMETAL = np.array([0.10, 0.11, 0.125])  # linear
POLYMER = np.array([0.03, 0.03, 0.033])
WOOD = np.array([0.24, 0.115, 0.045])


def _shifts(a, r):
    p = np.pad(a, ((r, r), (r, r), (0, 0)), mode="edge")
    h, w = a.shape[:2]
    return np.stack([p[y:y + h, x:x + w] for y in range(2 * r + 1) for x in range(2 * r + 1)])


def median(a, r=2):
    return np.median(_shifts(a, r), axis=0)


def bilateral(a, r=2, sig_c=0.12):
    st = _shifts(a, r)
    w = np.exp(-((st - a[None]) ** 2).sum(-1, keepdims=True) / (2 * sig_c ** 2))
    return (st * w).sum(0) / w.sum(0)


def clean_picture(pic):
    rgb = pic[..., :3].copy()
    srgb = np.clip(rgb, 0, 1) ** (1 / 2.2)
    srgb = bilateral(median(srgb, 1), 3, 0.10)  # kill speckle, keep edges
    mx, mn = srgb.max(-1), srgb.min(-1)
    sat = (mx - mn) / np.maximum(mx, 1e-4)
    lum = srgb @ np.array([0.3, 0.59, 0.11])
    r, g, b = srgb[..., 0], srgb[..., 1], srgb[..., 2]
    wood = (sat > 0.35) & (r > b * 1.3) & (lum > 0.12)
    poly = ~wood & (lum < 0.2)
    metal = ~wood & ~poly
    # soft masks so region borders do not show
    masks = [np.clip(median(m[..., None].astype(np.float32), 2)[..., 0], 0, 1) for m in (wood, poly, metal)]
    lin = srgb ** 2.2
    ll = lum[..., None] ** 2.2
    # keep luminance detail, pull chroma to the region palette
    def tint(pal):
        base = pal / max(pal @ np.array([0.3, 0.59, 0.11]), 1e-4)
        return np.clip(ll * base * 0.55 + (lin * 0.45 + pal * 0.2), 0, 1)
    out = masks[0][..., None] * tint(WOOD) + masks[1][..., None] * tint(POLYMER) + masks[2][..., None] * tint(GUNMETAL)
    out = bilateral(out, 2, 0.08)
    rough = masks[0] * 0.7 + masks[1] * 0.7 + masks[2] * (0.38 + 0.25 * (1 - np.clip(lum * 3, 0, 1)))
    metal_v = masks[2] * 0.72
    res = pic.copy()
    res[..., :3] = out
    return res, rough, metal_v
