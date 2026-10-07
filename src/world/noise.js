// Deterministic 2D value noise. Seeded so levels are reproducible.

export function makeNoise(seed = 1) {
  const perm = new Uint8Array(512);
  let s = seed >>> 0;
  const rand = () => ((s = (s * 1664525 + 1013904223) >>> 0) / 4294967296);
  const p = Array.from({ length: 256 }, (_, i) => i);
  for (let i = 255; i > 0; i--) {
    const j = Math.floor(rand() * (i + 1));
    [p[i], p[j]] = [p[j], p[i]];
  }
  for (let i = 0; i < 512; i++) perm[i] = p[i & 255];

  const hash = (x, z) => perm[(perm[x & 255] + z) & 511] / 255;
  const smooth = (t) => t * t * (3 - 2 * t);

  function value(x, z) {
    const x0 = Math.floor(x), z0 = Math.floor(z);
    const tx = smooth(x - x0), tz = smooth(z - z0);
    const a = hash(x0, z0), b = hash(x0 + 1, z0);
    const c = hash(x0, z0 + 1), d = hash(x0 + 1, z0 + 1);
    return (a + (b - a) * tx) + ((c + (d - c) * tx) - (a + (b - a) * tx)) * tz;
  }

  /** Fractal sum, returns roughly 0..1 */
  return function fbm(x, z, octaves = 3) {
    let amp = 1, freq = 1, sum = 0, norm = 0;
    for (let o = 0; o < octaves; o++) {
      sum += value(x * freq, z * freq) * amp;
      norm += amp;
      amp *= 0.5;
      freq *= 2;
    }
    return sum / norm;
  };
}
