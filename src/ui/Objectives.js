// Objective tracker: renders the checklist and fires 'victory' when every required one is done.
// Each hint says WHO can do it (turrets, units, or the Operative) and HOW.

import { bus, log } from '../core/events.js';
import { sfx } from '../core/audio.js';

const LIST = [
  { id: 'spire', who: 'Operative', text: 'Destroy the Spore Spire', hint: 'On the Blight plateau (NE). Drop a Beacon near the ramp (south of it), press T, climb, and press E at the Spire. Send units first to kill the nest.' },
  { id: 'e1', who: 'Network', text: 'Nullify Emitter NW', hint: 'Push Relays and Blasters to it, then build a Nullifier (9) within 4 cells.' },
  { id: 'core', who: 'Operative', text: 'Destroy the Deep Core', hint: 'Walk the Operative into the Rift (west, in the Blight) and press E. Shoot the 3 glowing Shield Pylons, then the Core.' },
  { id: 'e2', who: 'Network', text: 'Nullify Emitter East', hint: 'Shielded until the Deep Core dies (follow the purple link). Then build a Nullifier next to it.' },
  { id: 'nests', who: 'Units', text: 'Destroy all Spore Nests', hint: 'Optional. Train Soldiers/Crawlers at a Barracks (7) and right-click them onto the nests.', optional: true },
];

export class Objectives {
  constructor() {
    this.items = LIST.map((o) => ({ ...o, done: false }));
    this.el = document.getElementById('obj-list');
    bus.on('objectiveDone', (id) => this.complete(id));
    this.render();
  }

  complete(id) {
    const o = this.items.find((i) => i.id === id);
    if (!o || o.done) return;
    o.done = true;
    this.render();
    sfx('good');
    const left = this.items.filter((i) => !i.done && !i.optional).length;
    if (left === 0) bus.emit('victory');
    else log(`Objective complete: ${o.text}.${o.optional ? '' : ` ${left} to go.`}`, 'good');
  }

  render() {
    this.el.innerHTML = this.items
      .map((o) => `<li class="${o.done ? 'done' : ''}${o.optional ? ' opt' : ''}"><em class="who ${o.who.toLowerCase()}">${o.who}</em>${o.text}${o.done ? '' : `<small>${o.hint}</small>`}</li>`)
      .join('');
  }
}
