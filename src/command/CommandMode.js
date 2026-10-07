// Top-down commander: build tools (ghost + range ring), selection (click / drag-box units,
// click structures), orders (right-click to move units or set a barracks rally point),
// recycle, and unit training hotkeys. Camera lives in CommandCamera.

import * as THREE from 'three';
import { DEFS, BUILD_ORDER } from './structureDefs.js';
import { makeGhost } from './structureMeshes.js';
import { CommandCamera } from './CommandCamera.js';
import { queueUnit } from './structureBehaviors.js';
import { UNIT_DEFS, UNIT_ORDER } from '../units/unitDefs.js';
import { WORLD } from '../core/config.js';
import { bus, log } from '../core/events.js';
import { sfx, setListener } from '../core/audio.js';

const DRAG_PX = 6;

export class CommandMode {
  constructor(world, structures, units, input) {
    this.world = world;
    this.structures = structures;
    this.units = units;
    this.input = input;
    this.cam = new CommandCamera(world.grid);
    this.camera = this.cam.camera;
    this.tool = null;
    this.hover = null;      // { x, z, point }
    this.reason = '';
    this.selected = null;   // selected structure
    this.raycaster = new THREE.Raycaster();
    this.selBox = document.getElementById('selbox');

    this.ghost = makeGhost();
    const ringMat = new THREE.MeshBasicMaterial({ color: 0x5fd4ff, transparent: true, opacity: 0.5, side: THREE.DoubleSide, depthWrite: false });
    this.ring = new THREE.Mesh(new THREE.RingGeometry(0.97, 1, 64), ringMat);
    this.ring.rotation.x = -Math.PI / 2;
    this.selRing = new THREE.Mesh(new THREE.RingGeometry(1.5, 1.8, 32), ringMat.clone());
    this.selRing.material.color.setHex(0x9dff7a);
    this.selRing.rotation.x = -Math.PI / 2;
    this.ghost.visible = this.ring.visible = this.selRing.visible = false;
    world.scene.add(this.ghost, this.ring, this.selRing);
    bus.on('structureRemoved', (s) => { if (s === this.selected) this.selectStructure(null); });
  }

  focus(pos) { this.cam.focus(pos); }

  setTool(type) {
    this.tool = type;
    this.ghost.visible = this.ring.visible = !!type;
    if (type) { this.selectStructure(null); this.units.select([]); }
    bus.emit('toolChanged', type);
  }

  selectStructure(s) {
    this.selected = s;
    if (s?.type === 'beacon') this.structures.selectedBeacon = s;
    bus.emit('selectionChanged');
  }

  update(dt, input) {
    this.handleHotkeys(input);
    this.cam.update(dt, input);
    setListener(this.camera.position);
    this.updateHover(input);
    this.updateSelectionVisuals();
    if (input.mouse.rightClicked) this.rightClick();
    this.handleLeftMouse(input);
  }

  handleHotkeys(input) {
    BUILD_ORDER.forEach((type) => { if (input.wasPressed(DEFS[type].key)) this.setTool(this.tool === type ? null : type); });
    if (input.wasPressed('Escape')) { this.setTool(null); this.selectStructure(null); this.units.select([]); }
    if ((input.wasPressed('Delete') || input.wasPressed('KeyX')) && this.selected) this.recycleSelected();
    if (input.wasPressed('KeyH') && this.structures.ship) this.focus(this.structures.ship.pos);
    for (const type of UNIT_ORDER) if (input.wasPressed(UNIT_DEFS[type].key)) this.train(type);
  }

  train(type) {
    const b = this.selected?.type === 'barracks' ? this.selected : null;
    if (!b) { log('Select a Barracks first (click it), then train units.', 'warn'); sfx('deny'); return; }
    if (b.built < 1) { log('Barracks is still under construction.', 'warn'); return; }
    if (queueUnit(b, type)) { sfx('click'); bus.emit('selectionChanged'); }
  }

  recycleSelected() {
    const s = this.selected;
    if (!s || s.type === 'ship') return;
    log(`${s.def.label} recycled.`, 'info');
    this.structures.recycle(s);
  }

  updateHover(input) {
    const ndc = new THREE.Vector2((input.mouse.x / innerWidth) * 2 - 1, -(input.mouse.y / innerHeight) * 2 + 1);
    this.raycaster.setFromCamera(ndc, this.camera);
    const p = this.world.raycastGround(this.raycaster.ray, 1200);
    if (!p) { this.hover = null; this.reason = ''; this.ghost.visible = this.ring.visible = false; return; }
    const c = this.world.grid.worldToCell(p.x, p.z);
    this.hover = { x: c.x, z: c.z, point: p.clone() };
    if (this.tool) this.updateGhost();
    else this.reason = '';
  }

  updateGhost() {
    const { x, z } = this.hover;
    const g = this.world.grid, c = g.cellCenter(x, z), y = g.smoothY(c.x, c.z);
    const res = this.structures.canPlace(this.tool, x, z);
    const def = DEFS[this.tool];
    this.reason = res.ok ? '' : res.reason;
    this.ghost.visible = true;
    this.ghost.position.set(c.x, y + 0.3, c.z);
    this.ghost.scale.setScalar(def.footprint ? 2.8 : 1);
    this.ghost.material.color.setHex(res.ok ? 0x00ff88 : 0xff4444);
    const r = (def.range ?? def.link ?? 0) * WORLD.CELL;
    this.ring.visible = r > 0;
    this.ring.scale.setScalar(Math.max(r, 0.01));
    this.ring.position.set(c.x, y + 0.35, c.z);
  }

  updateSelectionVisuals() {
    const s = this.selected;
    this.selRing.visible = !!s;
    if (s) {
      this.selRing.position.set(s.pos.x, s.pos.y + 0.2, s.pos.z);
      this.selRing.scale.setScalar(s.def.footprint ? 2.2 : 1);
    }
  }

  // ---- mouse ----------------------------------------------------------------
  handleLeftMouse(input) {
    const m = input.mouse;
    const dragging = m.left && !this.tool && Math.hypot(m.x - m.downX, m.y - m.downY) > DRAG_PX;
    this.selBox.classList.toggle('hidden', !dragging);
    if (dragging) {
      Object.assign(this.selBox.style, {
        left: `${Math.min(m.x, m.downX)}px`, top: `${Math.min(m.y, m.downY)}px`,
        width: `${Math.abs(m.x - m.downX)}px`, height: `${Math.abs(m.y - m.downY)}px`,
      });
    }
    if (!m.released) return;
    if (!this.tool && Math.hypot(m.x - m.downX, m.y - m.downY) > DRAG_PX) this.boxSelect(m, input.shift);
    else if (this.hover) this.click(this.hover, input.shift);
  }

  boxSelect(m, additive) {
    const x0 = Math.min(m.x, m.downX), x1 = Math.max(m.x, m.downX);
    const y0 = Math.min(m.y, m.downY), y1 = Math.max(m.y, m.downY);
    const v = new THREE.Vector3();
    const picked = this.units.list.filter((u) => {
      v.copy(u.pos).setY(u.pos.y + 1).project(this.camera);
      const sx = (v.x + 1) / 2 * innerWidth, sy = (1 - v.y) / 2 * innerHeight;
      return v.z < 1 && sx >= x0 && sx <= x1 && sy >= y0 && sy <= y1;
    });
    this.units.select(picked, additive);
    if (picked.length) { this.selectStructure(null); sfx('click'); }
    bus.emit('selectionChanged');
  }

  click({ x, z, point }, shift) {
    if (this.tool) {
      const res = this.structures.canPlace(this.tool, x, z);
      if (!res.ok) { log(res.reason, 'warn'); sfx('deny'); return; }
      this.structures.place(this.tool, x, z);
      sfx('click');
      if (!shift) this.setTool(null); // shift-click to keep placing
      return;
    }
    const u = this.units.nearest(point);
    if (u) {
      this.units.select([u], shift);
      this.selectStructure(null);
      sfx('click');
      bus.emit('selectionChanged');
      return;
    }
    this.units.select([]);
    const s = this.structures.structureAt(x, z);
    this.selectStructure(s);
    if (s) sfx('click');
    if (s?.type === 'beacon') log('Beacon selected as drop point. Press T to teleport.', 'info');
  }

  rightClick() {
    if (this.tool) { this.setTool(null); return; }
    if (!this.hover) return;
    const p = this.hover.point;
    if (this.units.selected.size) {
      this.units.order([...this.units.selected], { x: p.x, z: p.z });
      this.world.effects.burst(p.clone().setY(p.y + 0.3), 0x9dff7a, 1.2, 0.3);
    } else if (this.selected?.type === 'barracks') {
      this.selected.rally = { x: p.x, z: p.z };
      this.world.effects.burst(p.clone().setY(p.y + 0.3), 0x9dff7a, 1.2, 0.3);
      log('Barracks rally point set.', 'info');
    }
  }

  resize() { this.cam.resize(); }
}
