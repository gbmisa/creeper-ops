// Mesh factories for structures. Primitives with PBR materials and a shared team palette,
// so each type reads clearly from the command camera. Swap per type for real art later.

import * as THREE from 'three';

const M = {};
const mat = (color, { emissive = 0, metal = 0.5, rough = 0.45, ei = 1 } = {}) => {
  const k = `${color}-${emissive}-${metal}-${rough}-${ei}`;
  return (M[k] ??= new THREE.MeshStandardMaterial({ color, emissive, emissiveIntensity: ei, metalness: metal, roughness: rough }));
};
const HULL = 0x9aa8bc, DARK = 0x3b4350, TEAM = 0x3fc6ff, GLOW = { emissive: 0x1a8fd0, ei: 1.4 };

function add(g, geo, material, x = 0, y = 0, z = 0) {
  const m = new THREE.Mesh(geo, material);
  m.position.set(x, y, z);
  m.castShadow = true;
  m.receiveShadow = true;
  g.add(m);
  return m;
}
const box = (w, h, d) => new THREE.BoxGeometry(w, h, d);
const cyl = (rt, rb, h, s = 12) => new THREE.CylinderGeometry(rt, rb, h, s);

const FACTORIES = {
  ship(g) {
    add(g, cyl(3.4, 4.2, 1.4, 10), mat(HULL), 0, 3.2);
    add(g, cyl(4.4, 4.4, 0.25, 10), mat(DARK), 0, 2.5);
    add(g, new THREE.SphereGeometry(1.7, 20, 12, 0, Math.PI * 2, 0, Math.PI / 2), mat(TEAM, { ...GLOW, metal: 0.1, rough: 0.1 }), 0, 3.9);
    add(g, cyl(1.3, 1.3, 0.2, 20), mat(0x4466ff, { emissive: 0x2244dd, ei: 2 }), 0, 0.1);
    for (let i = 0; i < 4; i++) {
      const a = (i / 4) * Math.PI * 2 + Math.PI / 4;
      const leg = add(g, box(0.45, 3.2, 0.45), mat(DARK), Math.cos(a) * 3, 1.5, Math.sin(a) * 3);
      leg.rotation.set(Math.sin(a) * 0.25, 0, -Math.cos(a) * 0.25);
      add(g, box(0.25, 0.25, 0.25), mat(0xffd27a, { emissive: 0xffaa33, ei: 2 }), Math.cos(a) * 4.3, 3.2, Math.sin(a) * 4.3);
    }
  },
  collector(g) {
    add(g, cyl(0.7, 0.9, 0.35, 8), mat(DARK), 0, 0.18);
    add(g, cyl(0.12, 0.12, 0.6), mat(HULL), 0, 0.6);
    g.userData.spin = add(g, cyl(0.85, 0.2, 0.22, 12), mat(0x9fe3ff, { emissive: 0x1a6aa0, metal: 0.8, rough: 0.2 }), 0, 0.95);
  },
  relay(g) {
    add(g, cyl(0.45, 0.6, 0.3, 6), mat(DARK), 0, 0.15);
    add(g, cyl(0.1, 0.16, 2.6, 6), mat(HULL), 0, 1.5);
    g.userData.spin = add(g, new THREE.OctahedronGeometry(0.36), mat(0xffffff, GLOW), 0, 2.95);
  },
  reactor(g) {
    add(g, box(1.6, 0.5, 1.6), mat(DARK), 0, 0.25);
    for (const [x, z] of [[-0.45, -0.45], [0.45, -0.45], [-0.45, 0.45], [0.45, 0.45]]) add(g, cyl(0.25, 0.3, 1.2, 8), mat(HULL), x, 1.0, z);
    g.userData.spin = add(g, new THREE.TorusGeometry(0.42, 0.12, 8, 16), mat(0x7dff9a, { emissive: 0x2fbf55, ei: 2 }), 0, 1.4);
    g.userData.spin.rotation.x = Math.PI / 2;
  },
  storage(g) {
    add(g, box(1.5, 0.4, 1.5), mat(DARK), 0, 0.2);
    add(g, cyl(0.6, 0.6, 1.3, 12), mat(HULL), 0, 1.05);
    g.userData.level = add(g, cyl(0.62, 0.62, 0.2, 12), mat(TEAM, GLOW), 0, 0.7);
  },
  blaster(g) {
    add(g, cyl(0.7, 0.85, 0.45, 8), mat(0x6f6450), 0, 0.22);
    const turret = add(g, box(0.7, 0.45, 0.7), mat(0xe0c46a, { metal: 0.6 }), 0, 0.75);
    const barrel = add(turret, cyl(0.09, 0.11, 1.0, 8), mat(0x2a2a2a), 0.55, 0.05, 0);
    barrel.rotation.z = Math.PI / 2;
    g.userData.turret = turret;
  },
  mortar(g) {
    add(g, box(1.5, 0.55, 1.5), mat(0x55623f), 0, 0.28);
    const tube = add(g, cyl(0.32, 0.4, 1.2, 10), mat(0x2b3324), 0, 1.15);
    tube.rotation.x = -0.45;
  },
  barracks(g) {
    add(g, box(4.6, 1.8, 3.6), mat(0x6c7a66, { metal: 0.3, rough: 0.7 }), 0, 0.9);
    add(g, box(4.8, 0.3, 3.8), mat(0x8c9a84, { metal: 0.3, rough: 0.6 }), 0, 1.95);
    add(g, box(4.82, 0.32, 0.5), mat(0x9dff7a, { emissive: 0x3faa22, ei: 0.8 }), 0, 1.95, 0.9);
    add(g, box(1.6, 1.3, 0.2), mat(0x1b1f24), 0, 0.65, 1.85);           // door
    add(g, box(0.6, 2.6, 0.6), mat(HULL), -1.8, 1.3, -1.3);              // antenna mast
    add(g, new THREE.OctahedronGeometry(0.3), mat(0x9dff7a, { emissive: 0x3faa22, ei: 2 }), -1.8, 2.9, -1.3);
    g.userData.spin = add(g, box(1.2, 0.08, 0.3), mat(HULL), 1.4, 2.25, -0.8);
  },
  beacon(g) {
    add(g, cyl(0.6, 0.75, 0.25, 8), mat(DARK), 0, 0.12);
    g.userData.glow = add(g, cyl(0.12, 0.12, 2.4, 8), mat(0x66ffcc, { emissive: 0x22aa77, ei: 1.5 }), 0, 1.4);
  },
  nullifier(g) {
    add(g, cyl(0.8, 1.0, 0.5, 6), mat(0x4a345e), 0, 0.25);
    for (let i = 0; i < 3; i++) {
      const a = (i / 3) * Math.PI * 2;
      add(g, box(0.18, 1.4, 0.18), mat(HULL), Math.cos(a) * 0.6, 0.9, Math.sin(a) * 0.6);
    }
    g.userData.core = add(g, new THREE.IcosahedronGeometry(0.45), mat(0xd38cff, { emissive: 0x7a2acf, ei: 1.6 }), 0, 1.3);
  },
};

export function makeStructureMesh(type) {
  const g = new THREE.Group();
  FACTORIES[type](g);
  return g;
}

/** Translucent ghost used while placing. */
export function makeGhost() {
  const m = new THREE.Mesh(
    new THREE.CylinderGeometry(1, 1, 0.3, 24),
    new THREE.MeshBasicMaterial({ color: 0x00ff88, transparent: true, opacity: 0.45, depthWrite: false }),
  );
  m.renderOrder = 5;
  return m;
}
