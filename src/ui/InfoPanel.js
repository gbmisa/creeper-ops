// Selection panel (command mode): what the selected structure is doing (construction packets,
// ammo, network, nullifier charge), barracks training buttons + queue, and unit-group info.

import { UNIT_DEFS, UNIT_ORDER } from '../units/unitDefs.js';
import { THREATS } from '../core/config.js';
import { bus } from '../core/events.js';

export class InfoPanel {
  constructor(command, structures, units) {
    this.command = command;
    this.structures = structures;
    this.units = units;
    this.el = document.getElementById('info');
    this.body = document.getElementById('info-body');
    this.actions = document.getElementById('info-actions');
    this.timer = 0;
    bus.on('selectionChanged', () => this.rebuildActions());
  }

  rebuildActions() {
    this.actions.innerHTML = '';
    const s = this.command.selected;
    const btn = (label, title, fn) => {
      const b = document.createElement('button');
      b.innerHTML = label;
      b.title = title;
      b.addEventListener('click', fn);
      this.actions.appendChild(b);
    };
    if (s?.type === 'barracks') {
      for (const t of UNIT_ORDER) {
        const d = UNIT_DEFS[t];
        btn(`${d.key.slice(3)} · Train ${d.label}<small>${d.cost} packets</small>`, d.desc, () => this.command.train(t));
      }
    }
    if (s && s.type !== 'ship') btn('X · Recycle<small>refund 50%</small>', 'Remove this structure and get half its packets back', () => this.command.recycleSelected());
    this.refresh(true);
  }

  refresh(force = false) {
    const s = this.command.selected, n = this.units.selected.size;
    this.el.classList.toggle('hidden', !s && !n);
    if (!force && (this.timer = (this.timer + 1) % 6)) return; // ~10 Hz is plenty
    if (s) this.body.innerHTML = this.structureHtml(s);
    else if (n) this.body.innerHTML = this.unitsHtml();
  }

  structureHtml(s) {
    const d = s.def, rows = [`<h4>${d.label ?? d.name}</h4>`];
    rows.push(`HP ${Math.ceil(s.hp)} / ${d.hp}`);
    if (s.built < 1) {
      rows.push(d.dropPod ? `Drop pod landing… ${Math.round(s.built * 100)}%` : `Building: <b>${s.delivered} / ${d.cost}</b> packets`);
    }
    if (!s.connected) rows.push('<span class="bad">Not connected to the network</span>');
    if (d.ammo && s.built >= 1) rows.push(`Ammo <b>${Math.floor(s.ammo)} / ${d.ammo.max}</b>${s.ammo < 1 ? ' <span class="bad">EMPTY: waiting for packets</span>' : ''}`);
    if (s.type === 'nullifier' && s.built >= 1) {
      const e = this.structures.hazards?.emitterNear(s.x, s.z, THREATS.NULLIFY_RANGE);
      rows.push(e && this.structures.hazards.isShielded(e) ? `<span class="bad">${e.name} is shielded</span>` : `Charging ${Math.round((s.charge / THREATS.NULLIFY_TIME) * 100)}%`);
    }
    if (s.type === 'barracks') {
      const q = s.queue.map((u, i) => `${UNIT_DEFS[u.type].label} ${i === 0 ? `(${u.delivered}/${u.cost})` : ''}`);
      rows.push(`Queue: ${q.length ? q.join(', ') : 'empty'}`);
      rows.push('<small>Right-click ground to set the rally point.</small>');
    }
    if (s.wet > 0.06) rows.push('<span class="bad">IN CREEPER: taking damage</span>');
    rows.push(`<small>${d.desc}</small>`);
    return rows.join('<br>');
  }

  unitsHtml() {
    const counts = {};
    let hp = 0, max = 0;
    for (const u of this.units.selected) { counts[u.def.label] = (counts[u.def.label] ?? 0) + 1; hp += u.hp; max += u.def.hp; }
    return [`<h4>${Object.entries(counts).map(([k, c]) => `${c}× ${k}`).join(', ')}</h4>`,
      `Health ${Math.round((hp / max) * 100)}%`,
      'Right-click to move. They shoot mites and nests in range and clear creeper when idle.',
      '<small class="warnc">Units can\'t plant charges, hack, or enter the Rift. That takes the Operative.</small>'].join('<br>');
  }
}
