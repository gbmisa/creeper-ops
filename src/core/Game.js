// Top-level orchestrator: builds both Worlds and every subsystem, then runs the frame loop.
// Gameplay rules live in the subsystems; mode transitions live in GameFlow. Wiring only.

import * as THREE from 'three';
import { Input } from './input.js';
import { GameFlow } from './GameFlow.js';
import { unlockAudio, toggleMute } from './audio.js';
import { log } from './events.js';
import { World } from '../world/World.js';
import { Bar } from '../world/Bars.js';
import { buildLevel01 } from '../level/level01.js';
import { buildCave01 } from '../level/cave01.js';
import { SurfaceHazards } from '../level/SurfaceHazards.js';
import { CaveHazards } from '../fps/CaveHazards.js';
import { Economy } from '../command/Economy.js';
import { StructureManager } from '../command/StructureManager.js';
import { CommandMode } from '../command/CommandMode.js';
import { UnitManager } from '../units/UnitManager.js';
import { FpsMode } from '../fps/FpsMode.js';
import { Hud } from '../ui/Hud.js';
import { BuildBar } from '../ui/BuildBar.js';
import { InfoPanel } from '../ui/InfoPanel.js';
import { Markers } from '../ui/Markers.js';
import { Objectives } from '../ui/Objectives.js';
import { applyDebugHash } from './debug.js';

const SPEEDS = [1, 2, 3];

export class Game {
  constructor(canvas) {
    this.renderer = new THREE.WebGLRenderer({ canvas, antialias: true });
    this.renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
    this.renderer.setSize(innerWidth, innerHeight);
    this.renderer.shadowMap.enabled = true;
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = 1.05;
    this.input = new Input(canvas);
    this.hud = new Hud();
    this.objectives = new Objectives();
    this.economy = new Economy();

    // Surface
    this.level = buildLevel01();
    this.surface = new World('surface', this.level.grid, { keepClear: this.level.keepClear });
    this.structures = new StructureManager(this.surface, this.economy);
    this.structures.place('ship', this.level.ship.x, this.level.ship.z, { instant: true });
    this.hazards = new SurfaceHazards(this.surface, this.level, this.structures);
    this.structures.hazards = this.hazards;
    this.units = new UnitManager(this.surface);

    // Underground
    this.caveData = buildCave01();
    this.cave = new World('cave', this.caveData.grid, { cave: true });
    this.caveHazards = new CaveHazards(this.cave, this.caveData);

    // Modes + UI
    this.command = new CommandMode(this.surface, this.structures, this.units, this.input);
    this.command.focus(this.structures.ship.pos);
    this.fps = new FpsMode();
    this.fps.beacons = (w) => (w === this.surface ? this.structures.beacons : []);
    this.hazards.nests.prey = () => this.surfacePrey();
    this.buildBar = new BuildBar((t) => this.command.setTool(this.command.tool === t ? null : t));
    this.info = new InfoPanel(this.command, this.structures, this.units);
    this.markers = new Markers();

    this.mode = 'command';
    this.paused = true;      // until the briefing is dismissed
    this.over = false;
    this.time = 0;
    this.teleportCooldown = 0;
    this.speed = 1;
    this.timeScale = 1;      // debug multiplier on top of speed
    this.ignoreLock = false; // debug: let the operative sim run without pointer lock

    this.flow = new GameFlow(this);
    addEventListener('resize', () => this.resize());
    addEventListener('pointerdown', unlockAudio);
    addEventListener('keydown', unlockAudio);
    this.flow.showBriefing();
    applyDebugHash(this);
  }

  /** Everything surface mites may attack. */
  surfacePrey() {
    const prey = this.units.list.map((u) => u.target);
    for (const s of this.structures.list) {
      s.prey ??= { pos: s.pos, radius: s.def.footprint ? 2.5 : 1, get alive() { return !s.dead; }, hit: (d) => this.structures.damage(s, d) };
      prey.push(s.prey);
    }
    if (this.mode === 'surface') prey.push(this.fps.asPrey);
    return prey;
  }

  // ---- loop -----------------------------------------------------------------
  start() {
    let last = performance.now();
    const frame = (now) => {
      const dt = Math.min(0.05, (now - last) / 1000);
      last = now;
      this.tick(dt);
      this.input.endFrame();
      requestAnimationFrame(frame);
    };
    requestAnimationFrame(frame);
  }

  tick(dt) {
    const input = this.input;
    if (input.wasPressed('KeyM')) log(toggleMute() ? 'Sound muted.' : 'Sound on.', 'info');
    if (this.mode === 'command' && !this.over) {
      if (input.wasPressed('Space')) this.paused = !this.paused;
      const i = SPEEDS.indexOf(this.speed);
      if (input.wasPressed('Equal') || input.wasPressed('NumpadAdd')) this.speed = SPEEDS[Math.min(SPEEDS.length - 1, i + 1)];
      if (input.wasPressed('Minus') || input.wasPressed('NumpadSubtract')) this.speed = SPEEDS[Math.max(0, i - 1)];
    }
    const fpsFrozen = this.mode !== 'command' && !input.pointerLocked && !this.ignoreLock;
    // The Operative always plays in real time; fast-forward is for command mode.
    const scale = (this.mode === 'command' ? this.speed : 1) * this.timeScale;
    if (!this.paused && !this.over && !fpsFrozen) this.update(dt * scale);
    else if (this.mode === 'command') this.command.update(0, input); // allow planning while paused
    this.render(dt);
  }

  update(dt) {
    this.time += dt;
    this.teleportCooldown = Math.max(0, this.teleportCooldown - dt);
    this.flow.update(dt);
    if (this.mode === 'command') this.command.update(dt, this.input);
    else this.fps.update(dt, this.input);

    this.surface.update(dt);
    this.cave.update(dt);
    this.structures.update(dt, this.time);
    this.units.update(dt, this.hazards.nests.enemies);
  }

  render(dt) {
    const world = this.mode === 'cave' ? this.cave : this.surface;
    const camera = this.mode === 'command' ? this.command.camera : this.fps.camera;
    world.refreshVisuals();
    Bar.faceCamera(camera);
    this.markers.update(world, camera, { fps: this.mode !== 'command' });

    const ship = this.structures.ship;
    this.hud.updateTop({
      energy: this.economy.energy, max: this.economy.max, income: this.economy.income,
      packets: this.structures.packets.count, field: this.economy.fieldCells, units: this.units.list.length,
      coverage: this.surface.creeper.coverage(), shipHp: ship ? ship.hp / ship.def.hp : 0,
      time: this.time, paused: this.paused, speed: this.speed, dt,
    });
    if (this.mode === 'command') {
      this.hud.updatePlaceReason(this.command.reason);
      this.buildBar.refresh(this.economy.energy);
      this.info.refresh();
    } else {
      this.hud.updateFps(this.fps);
    }
    this.renderer.render(world.scene, camera);
  }

  resize() {
    this.renderer.setSize(innerWidth, innerHeight);
    this.command.resize();
    this.fps.resize();
  }
}
