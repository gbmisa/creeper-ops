// Unit meshes. Pivot at the feet, facing +X (rotation.y aims them).

import * as THREE from 'three';

const std = (color, emissive = 0, ei = 1) => new THREE.MeshStandardMaterial({ color, emissive, emissiveIntensity: ei, roughness: 0.55, metalness: 0.4 });
const MATS = {
  armor: std(0x5f7d8f), dark: std(0x2b3238), visor: std(0x7fe0ff, 0x2a9fd0, 1.6),
  tread: std(0x1d2024), hull: std(0x7b8a5a), nozzle: std(0x9dff7a, 0x3faa22, 1.2),
};

function part(g, geo, m, x, y, z) {
  const o = new THREE.Mesh(geo, m);
  o.position.set(x, y, z);
  o.castShadow = true;
  g.add(o);
  return o;
}

export function soldierMesh() {
  const g = new THREE.Group();
  part(g, new THREE.CapsuleGeometry(0.28, 0.7, 4, 8), MATS.armor, 0, 0.65, 0);
  part(g, new THREE.SphereGeometry(0.22, 10, 8), MATS.dark, 0, 1.38, 0);
  part(g, new THREE.BoxGeometry(0.1, 0.08, 0.3), MATS.visor, 0.15, 1.4, 0).rotation.y = Math.PI / 2;
  part(g, new THREE.BoxGeometry(0.7, 0.1, 0.1), MATS.dark, 0.35, 0.95, 0.18);
  part(g, new THREE.BoxGeometry(0.28, 0.4, 0.4), MATS.dark, -0.27, 0.95, 0); // pack
  return g;
}

export function crawlerMesh() {
  const g = new THREE.Group();
  for (const z of [-0.65, 0.65]) part(g, new THREE.BoxGeometry(2.0, 0.55, 0.42), MATS.tread, 0, 0.3, z);
  part(g, new THREE.BoxGeometry(1.8, 0.6, 1.1), MATS.hull, 0, 0.75, 0);
  const turret = part(g, new THREE.CylinderGeometry(0.42, 0.5, 0.4, 10), MATS.armor, -0.1, 1.25, 0);
  part(turret, new THREE.CylinderGeometry(0.1, 0.16, 1.0, 8), MATS.nozzle, 0.6, 0.05, 0).rotation.z = Math.PI / 2;
  g.userData.turret = turret;
  return g;
}

export function selectionRing(radius) {
  const m = new THREE.Mesh(
    new THREE.RingGeometry(radius * 1.15, radius * 1.4, 24),
    new THREE.MeshBasicMaterial({ color: 0x9dff7a, transparent: true, opacity: 0.9, depthWrite: false, side: THREE.DoubleSide }),
  );
  m.rotation.x = -Math.PI / 2;
  m.position.y = 0.08;
  m.visible = false;
  m.renderOrder = 6;
  return m;
}
