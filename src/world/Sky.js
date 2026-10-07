// Gradient sky dome (surface) and rocky ceiling (cave). Purely visual.

import * as THREE from 'three';
import { makeNoise } from './noise.js';

export function skyDome({ top = 0x1b2a4a, horizon = 0x8a7a8f, ground = 0x1a1a22, sunDir = new THREE.Vector3(-0.4, 0.5, 0.3) } = {}) {
  const mat = new THREE.ShaderMaterial({
    side: THREE.BackSide, depthWrite: false, fog: false,
    uniforms: {
      top: { value: new THREE.Color(top) }, horizon: { value: new THREE.Color(horizon) },
      ground: { value: new THREE.Color(ground) }, sunDir: { value: sunDir.clone().normalize() },
    },
    vertexShader: `varying vec3 vDir; void main() { vDir = normalize(position);
      gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0); }`,
    fragmentShader: `uniform vec3 top; uniform vec3 horizon; uniform vec3 ground; uniform vec3 sunDir; varying vec3 vDir;
      void main() {
        float h = vDir.y;
        vec3 c = h > 0.0 ? mix(horizon, top, pow(h, 0.55)) : mix(horizon, ground, pow(-h, 0.4));
        float sun = max(0.0, dot(vDir, sunDir));
        c += vec3(1.0, 0.8, 0.55) * (pow(sun, 400.0) * 1.5 + pow(sun, 8.0) * 0.25);
        gl_FragColor = vec4(c, 1.0);
      }`,
  });
  const dome = new THREE.Mesh(new THREE.SphereGeometry(900, 32, 16), mat);
  dome.renderOrder = -1;
  dome.name = 'sky';
  return dome;
}

/** Low, lumpy ceiling with stalactites, spanning the cave grid. */
export function caveCeiling(grid, baseY = 8) {
  const noise = makeNoise(5);
  const W = grid.worldWidth, D = grid.worldDepth;
  const geo = new THREE.PlaneGeometry(W + 40, D + 40, 80, 60);
  geo.rotateX(Math.PI / 2); // faces down
  geo.translate(W / 2, 0, D / 2);
  const p = geo.attributes.position;
  for (let i = 0; i < p.count; i++) {
    const x = p.getX(i), z = p.getZ(i);
    p.setY(i, baseY + noise(x / 9, z / 9, 3) * 3 - 0.5);
  }
  geo.computeVertexNormals();
  const ceiling = new THREE.Mesh(geo, new THREE.MeshStandardMaterial({ color: 0x241f2b, roughness: 1, flatShading: true }));
  const group = new THREE.Group();
  group.add(ceiling);

  const cone = new THREE.ConeGeometry(0.5, 1, 6);
  cone.rotateX(Math.PI);
  cone.translate(0, -0.5, 0);
  const count = 220;
  const stal = new THREE.InstancedMesh(cone, new THREE.MeshStandardMaterial({ color: 0x3a3244, roughness: 0.9, flatShading: true }), count);
  const m = new THREE.Matrix4(), q = new THREE.Quaternion(), s = new THREE.Vector3(), v = new THREE.Vector3();
  for (let i = 0; i < count; i++) {
    const x = Math.random() * W, z = Math.random() * D;
    const len = 0.8 + Math.random() * 2.5;
    s.set(0.5 + Math.random(), len, 0.5 + Math.random());
    v.set(x, baseY + noise(x / 9, z / 9, 3) * 3 - 0.6, z);
    stal.setMatrixAt(i, m.compose(v, q, s));
  }
  group.add(stal);
  return group;
}
