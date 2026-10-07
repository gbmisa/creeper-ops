// Mode flow: command <-> operative (surface / cave), teleporting, recalls, briefing,
// alerts and the end screen. Split out of Game.js so that file stays pure wiring.

import { bus, log } from './events.js';
import { OPERATIVE } from './config.js';
import { sfx } from './audio.js';

export class GameFlow {
  constructor(game) {
    this.g = game;
    this.shipAlertCd = 0;
    this.wire();
  }

  wire() {
    const g = this.g;
    // Pointer lock must be requested inside a user-gesture handler, so T is handled here.
    g.input.onKeyDown = (e) => {
      if (e.code === 'KeyT' && g.mode === 'command' && !g.paused && !g.over) this.tryTeleport();
    };
    g.input.onPointerLockChange = (locked) => {
      if (g.over || g.mode === 'command' || g.ignoreLock) return;
      if (locked) g.hud.hideOverlay();
      else g.hud.showOverlay('<h2>Operative paused</h2><p>The battle is frozen.</p>', [
        { label: 'Resume', onClick: () => g.input.lockPointer() },
        { label: 'Recall to ship (−25)', onClick: () => bus.emit('recall', { cost: OPERATIVE.RECALL_COST }) },
      ]);
    };

    bus.on('recall', ({ cost }) => {
      if (cost) g.economy.drain(cost);
      this.toCommand(cost ? `Emergency recall (−${cost} energy).` : 'Operative back aboard.');
    });
    bus.on('operativeDown', () => {
      g.economy.drain(OPERATIVE.KO_PENALTY);
      g.teleportCooldown = OPERATIVE.TELEPORT_COOLDOWN;
      g.hud.alert('SUIT FAILURE: OPERATIVE RECALLED', 'bad');
      this.toCommand(`Suit failure! Auto-recalled (−${OPERATIVE.KO_PENALTY} energy, teleporter offline ${OPERATIVE.TELEPORT_COOLDOWN}s).`, 'bad');
    });
    bus.on('enterCave', () => {
      g.fps.enter(g.cave, { ...g.caveData.pad, yaw: -Math.PI / 2 }, { mites: g.caveHazards.mites });
      this.setMode('cave');
      log('Ops: You\'re in. Three Shield Pylons protect the Core: shoot the glowing crystals. Watch the flood.', 'radio');
    });
    bus.on('exitCave', () => {
      g.fps.enter(g.surface, { x: g.level.rift.x + 2, z: g.level.rift.z, yaw: -Math.PI / 2 });
      this.setMode('surface');
    });
    bus.on('coreDestroyed', () => { g.hazards.onCoreDestroyed(); g.hud.alert('DEEP CORE DESTROYED', 'good'); });
    bus.on('shipHit', () => {
      if (this.shipAlertCd > 0) return;
      this.shipAlertCd = 8;
      sfx('alarm');
      g.hud.alert('COMMAND SHIP UNDER ATTACK', 'bad', 2.5);
    });
    bus.on('shipDestroyed', () => this.endGame(false));
    bus.on('victory', () => this.endGame(true));
  }

  update(dt) { this.shipAlertCd -= dt; }

  tryTeleport() {
    const g = this.g;
    if (g.teleportCooldown > 0) { log(`Teleporter recharging: ${Math.ceil(g.teleportCooldown)}s`, 'warn'); sfx('deny'); return; }
    const beacons = g.structures.beacons;
    const b = beacons.includes(g.structures.selectedBeacon) ? g.structures.selectedBeacon : beacons.at(-1);
    if (!b) { log('No finished Beacon. Build one (8) anywhere outside Blight, then press T.', 'warn'); sfx('deny'); return; }
    g.fps.resetSuit();
    g.fps.enter(g.surface, { x: b.x, z: b.z - 1, yaw: 0 }); // just north of it, facing north
    g.command.setTool(null);
    this.setMode('surface');
    g.input.lockPointer();
    log('Operative deployed. The creeper won\'t wait for you.', 'radio');
  }

  toCommand(message, kind = 'info') {
    const g = this.g;
    g.fps.leave();
    g.input.unlockPointer();
    g.hud.hideOverlay();
    this.setMode('command');
    if (message) log(message, kind);
  }

  setMode(mode) {
    const g = this.g;
    g.mode = mode;
    g.hud.setMode(mode);
    g.buildBar.setVisible(mode === 'command');
    g.structures.field.mesh.visible = mode === 'command';
    if (mode !== 'command') { g.units.select([]); g.command.selectStructure(null); }
  }

  showBriefing() {
    const g = this.g;
    g.hud.showOverlay(`<h2>${g.level.name}</h2>
      <p>Hold the line from orbit, Creeper World style, and drop an <b>Operative</b> to finish what turrets can't.</p>
      <ul>
        <li><b>Packets are everything.</b> Every build, every Blaster shot and every unit is paid for by energy packets that fly along your relay network. Watch them move.</li>
        <li><b>Collectors</b> claim dry land (green field) for income. Creeper on your field means no income.</li>
        <li><b>Creeper destroys anything it touches</b>, including your structures, units and the Operative's suit.</li>
        <li><b>Purple Blight</b> can't be built on. Clear it with units from a <b>Barracks</b>, but only the <b>Operative</b> can plant charges or enter the Rift.</li>
      </ul>
      <p><small>Markers show every objective. Hover the build buttons for exact numbers.</small></p>`,
    [{ label: 'Begin', onClick: () => {
      g.hud.hideOverlay();
      g.paused = false;
      g.level.intro.forEach(([t, k], i) => setTimeout(() => log(t, k), i * 3000));
    } }]);
  }

  endGame(won) {
    const g = this.g;
    if (g.over) return;
    g.over = true;
    g.input.unlockPointer();
    sfx(won ? 'good' : 'lost');
    const t = `${Math.floor(g.time / 60)}m ${Math.floor(g.time % 60)}s`;
    g.hud.showOverlay(won
      ? `<h2>Hollow Ridge secured</h2><p>All threats neutralised in ${t}.</p>`
      : `<h2>Command ship lost</h2><p>The creeper overran the ship after ${t}.</p>`,
    [{ label: 'Play again', onClick: () => location.reload() }]);
  }
}
