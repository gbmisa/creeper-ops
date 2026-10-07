// Dev shortcuts via URL hash, combinable with commas, e.g. index.html#demo,sim600
//   #autostart   skip the briefing
//   #surface     skip briefing, drop the operative just outside the Rift Blight
//   #spire       skip briefing, drop the operative at the foot of the Spire ramp
//   #cave        skip briefing and go straight into the cave
//   #fast        8x simulation speed (balance testing)
//   #nolock      run the operative sim without pointer lock (headless screenshots)
//   #demo        scripted build: relay chain to Emitter NW + nullifier + defences + barracks
//   #units       spawn a squad (4 Soldiers, 2 Crawlers) and send it at the central nest
//   #killcore    destroy the pylons and the Deep Core (tests the shield-drop chain)
//   #look=x.z    point the command camera at a cell (screenshots), e.g. #look=40.23
//   #simN        fast-forward N seconds of game time on load (e.g. #sim600), then log a report
// Never needed for normal play; keeps test hooks out of Game.js.

import { bus } from './events.js';

const DEMO_BUILD = [
  ['relay', 34, 58], ['relay', 28, 48], ['relay', 27, 36], ['relay', 24, 24], ['relay', 19, 14], ['nullifier', 17, 14],
  ['collector', 34, 63], ['collector', 46, 63], ['collector', 40, 59], ['collector', 35, 70], ['collector', 45, 70],
  ['blaster', 33, 56], ['blaster', 47, 57], ['blaster', 40, 55], ['blaster', 29, 50], ['mortar', 37, 59],
  ['reactor', 43, 61], ['storage', 37, 62], ['barracks', 46, 66],
];

export function applyDebugHash(game) {
  const tags = new Set(location.hash.replace('#', '').split(',').filter(Boolean));
  if (!tags.size) return;
  const start = () => { game.hud.hideOverlay(); game.paused = false; };

  if (tags.has('autostart')) start();
  if (tags.has('fast')) game.timeScale = 8;
  if (tags.has('nolock')) game.ignoreLock = true;
  if (tags.has('demo')) {
    start();
    for (const [type, x, z] of DEMO_BUILD) game.structures.place(type, x, z, { instant: true });
  }
  if (tags.has('units')) {
    start();
    const s = game.structures.ship.pos;
    const squad = ['soldier', 'soldier', 'soldier', 'soldier', 'crawler', 'crawler']
      .map((t, i) => game.units.spawn(t, s.x - 6 + i * 2.4, s.z - 12));
    game.units.order(squad, game.level.grid.cellCenter(40, 27));
  }
  const drop = (x, z, yaw) => {
    start();
    const b = game.structures.place('beacon', x, z, { instant: true });
    game.structures.selectedBeacon = b;
    game.flow.tryTeleport();
    game.fps.controller.yaw = yaw;
  };
  if (tags.has('surface')) drop(game.level.rift.x + 9, game.level.rift.z, Math.PI / 2);
  if (tags.has('spire')) drop(61, 37, 0);
  if (tags.has('cave')) { start(); bus.emit('enterCave'); }
  if (tags.has('killcore')) {
    const ch = game.caveHazards;
    for (const c of ch.conduits) c.target.onHit(99);
    ch.core.target.onHit(99, ch.core.pos);
  }
  const look = [...tags].find((t) => t.startsWith('look='));
  if (look) {
    const [x, z] = look.slice(5).split('.').map(Number);
    game.command.focus(game.level.grid.cellCenter(x, z));
    game.command.cam.dist = 55;
  }

  const simTag = [...tags].find((t) => /^sim\d+$/.test(t));
  if (simTag) fastForward(game, Number(simTag.slice(3)));
}

function fastForward(game, seconds) {
  game.hud.hideOverlay();
  game.paused = false;
  const step = 0.05;
  for (let t = 0; t < seconds && !game.over; t += step) game.update(step);
  const s = game.structures;
  const weapons = s.list.filter((x) => x.def.ammo && x.built >= 1);
  console.log('[sim] report', JSON.stringify({
    time: Math.round(game.time),
    energy: Math.round(game.economy.energy),
    income: game.economy.income.toFixed(2),
    field: game.economy.fieldCells,
    structures: s.list.length,
    connected: s.list.filter((x) => x.connected).length,
    unbuilt: s.list.filter((x) => x.built < 1).length,
    weaponsDry: weapons.filter((w) => w.ammo < 1).length + '/' + weapons.length,
    packetsInFlight: s.packets.count,
    shipHp: Math.round(s.ship?.hp ?? 0),
    units: game.units.list.map((u) => `${u.type}:${Math.round(u.hp)}`).join(' '),
    nestsAlive: game.hazards.nests.nests.filter((n) => n.alive).length,
    mites: game.hazards.nests.mites.length,
    coverage: game.surface.creeper.coverage().toFixed(2),
    objectives: game.objectives.items.filter((o) => o.done).map((o) => o.id),
    e2Shielded: game.hazards.isShielded(game.hazards.emitters.find((e) => e.id === 'e2')),
    caveCoverage: game.cave.creeper.coverage().toFixed(2),
    over: game.over,
  }));
}
