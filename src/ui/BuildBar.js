// Command-mode build buttons with hover tooltips (cost, stats, what it's for).

import { DEFS, BUILD_ORDER } from '../command/structureDefs.js';
import { bus } from '../core/events.js';

export class BuildBar {
  constructor(onSelect) {
    this.el = document.getElementById('buildbar');
    this.tip = document.getElementById('tooltip');
    this.buttons = {};

    BUILD_ORDER.forEach((type) => {
      const d = DEFS[type];
      const b = document.createElement('button');
      const cost = d.dropPod ? `${d.cost} energy` : `${d.cost} packets`;
      b.innerHTML = `<kbd>${d.key.slice(5)}</kbd>${d.label}<small>${cost}</small>`;
      b.addEventListener('click', () => onSelect(type));
      b.addEventListener('mouseenter', () => this.showTip(type));
      b.addEventListener('mouseleave', () => this.tip.classList.add('hidden'));
      this.el.appendChild(b);
      this.buttons[type] = b;
    });

    bus.on('toolChanged', (type) => {
      for (const [t, b] of Object.entries(this.buttons)) b.classList.toggle('active', t === type);
    });
  }

  showTip(type) {
    const d = DEFS[type];
    const cost = d.dropPod ? `${d.cost} energy up front` : `${d.cost} packets`;
    this.tip.innerHTML = `<b>${d.label}</b> · ${cost} · ${d.hp} HP<br>${d.desc}`;
    this.tip.classList.remove('hidden');
  }

  /** Drop pods need energy up front; packet builds can always be queued. */
  refresh(energy) {
    for (const [t, b] of Object.entries(this.buttons)) b.classList.toggle('cant', !!DEFS[t].dropPod && energy < DEFS[t].cost);
  }

  setVisible(v) { this.el.classList.toggle('hidden', !v); if (!v) this.tip.classList.add('hidden'); }
}
