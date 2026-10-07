// Mesh factories for enemy / level objects (emitters, nests, spire, rift, core, pylons...).

import * as THREE from 'three';

const std = (color, emissive = 0, ei = 1, rough = 0.6) => new THREE.MeshStandardMaterial({ color, emissive, emissiveIntensity: ei, roughness: rough, metalness: 0.2 });

function add(g, geo, mat, y = 0) {
  const m = new THREE.Mesh(geo, mat);
  m.position.y = y;
  m.castShadow = true;
  m.receiveShadow = true;
  g.add(m);
  return m;
}

export function emitterMesh() {
  const g = new THREE.Group();
  add(g, new THREE.CylinderGeometry(1.5, 2.1, 1.0, 9), std(0x1a1530), 0.5);
  for (let i = 0; i < 5; i++) {
    const a = (i / 5) * Math.PI * 2;
    const fang = add(g, new THREE.ConeGeometry(0.3, 2.4, 5), std(0x2a2040), 1.4);
    fang.position.set(Math.cos(a) * 1.3, 1.4, Math.sin(a) * 1.3);
    fang.rotation.set(Math.sin(a) * -0.35, 0, Math.cos(a) * 0.35);
  }
  g.userData.orb = add(g, new THREE.SphereGeometry(0.85, 18, 12), std(0x2a5cff, 0x1a44ff, 2.2, 0.2), 1.7);
  return g;
}

export function shieldMesh(radius = 3) {
  return new THREE.Mesh(
    new THREE.IcosahedronGeometry(radius, 2),
    new THREE.MeshBasicMaterial({ color: 0xc070ff, transparent: true, opacity: 0.28, depthWrite: false, wireframe: false }),
  );
}

/** Pulsing tube that shows where a shield draws its power from. */
export function shieldLink(from, to) {
  const mid = from.clone().lerp(to, 0.5);
  mid.y = Math.max(from.y, to.y) + from.distanceTo(to) * 0.25;
  const curve = new THREE.QuadraticBezierCurve3(from, mid, to);
  return new THREE.Mesh(
    new THREE.TubeGeometry(curve, 48, 0.18, 6, false),
    new THREE.MeshBasicMaterial({ color: 0xc070ff, transparent: true, opacity: 0.55, depthWrite: false, blending: THREE.AdditiveBlending, fog: false }),
  );
}

export function ventMesh() {
  const g = new THREE.Group();
  const ring = add(g, new THREE.TorusGeometry(0.85, 0.3, 8, 14), std(0x332244, 0x2a0a55, 1.5), 0.2);
  ring.rotation.x = Math.PI / 2;
  g.userData.ring = ring;
  return g;
}

export function nestMesh() {
  const g = new THREE.Group();
  add(g, new THREE.SphereGeometry(1.6, 12, 8, 0, Math.PI * 2, 0, Math.PI / 2), std(0x2d3a1a, 0x0a1404), 0);
  for (let i = 0; i < 6; i++) {
    const a = (i / 6) * Math.PI * 2;
    const tendril = add(g, new THREE.ConeGeometry(0.22, 2.2, 5), std(0x3d5020), 0.9);
    tendril.position.set(Math.cos(a) * 1.2, 0.9, Math.sin(a) * 1.2);
    tendril.rotation.set(Math.sin(a) * -0.6, 0, Math.cos(a) * 0.6);
  }
  g.userData.sac = add(g, new THREE.SphereGeometry(0.75, 14, 10), std(0xa8ff5a, 0x4a9a10, 1.6, 0.3), 1.6);
  return g;
}

export function spireMesh() {
  const g = new THREE.Group();
  add(g, new THREE.CylinderGeometry(1.9, 2.4, 1.6, 6), std(0x5a5a66, 0, 1, 0.4), 0.8);
  add(g, new THREE.ConeGeometry(1.4, 9, 6), std(0x3a2a40, 0x1a0a20), 5.2);
  for (let i = 0; i < 3; i++) {
    const rib = add(g, new THREE.BoxGeometry(0.3, 6, 0.3), std(0x5a5a66, 0, 1, 0.4), 4);
    const a = (i / 3) * Math.PI * 2;
    rib.position.set(Math.cos(a) * 1.1, 4, Math.sin(a) * 1.1);
  }
  g.userData.sac = add(g, new THREE.SphereGeometry(0.9, 14, 10), std(0x88ff55, 0x337711, 1.8, 0.3), 7.5);
  return g;
}

export function riftMesh() {
  const g = new THREE.Group();
  const hole = add(g, new THREE.CircleGeometry(1.7, 28), new THREE.MeshBasicMaterial({ color: 0x000000 }), 0.06);
  hole.rotation.x = -Math.PI / 2;
  const ring = add(g, new THREE.TorusGeometry(1.8, 0.22, 8, 28), std(0x8844ff, 0x6a2aff, 2), 0.12);
  ring.rotation.x = Math.PI / 2;
  g.userData.marker = add(g, new THREE.OctahedronGeometry(0.5), std(0xffffff, 0x8844ff, 2), 3);
  return g;
}

export function coreMesh() {
  const g = new THREE.Group();
  g.userData.heart = add(g, new THREE.IcosahedronGeometry(1.6, 1), std(0xff3355, 0x880022, 1.5, 0.3), 2.6);
  add(g, new THREE.CylinderGeometry(0.4, 1.2, 2, 8), std(0x442233), 1);
  return g;
}

/** Shield pylon in the cave (was "conduit"): a tall crystal on a stalk, clearly a target. */
export function pylonMesh() {
  const g = new THREE.Group();
  add(g, new THREE.CylinderGeometry(0.35, 0.6, 3, 6), std(0x553366), 1.5);
  g.userData.crystal = add(g, new THREE.OctahedronGeometry(0.75), std(0xd38cff, 0x8833cc, 2, 0.2), 3.6);
  return g;
}

export function padMesh() {
  const m = new THREE.Mesh(new THREE.CylinderGeometry(1.2, 1.2, 0.2, 20), std(0x4466ff, 0x2233aa, 1.5));
  m.position.y = 0.1;
  return m;
}
