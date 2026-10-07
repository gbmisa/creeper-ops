// DOM HUD: top bar, event log, operative readouts, alerts and modal overlays.

import { bus } from '../core/events.js';
import { OPERATIVE } from '../core/config.js';

const $ = (id) => document.getElementById(id);
const MAX_LOG = 10;

export class Hud {
  constructor() {
    this.logEl = $('log');
    this.alertT = 0;
    bus.on('log', ({ text, kind }) => this.addLog(text, kind));
  }

  addLog(text, kind) {
    const top = this.logEl.firstChild;
    if (top && top.dataset.text === text) { // collapse repeats into "×N"
      top.dataset.count = Number(top.dataset.count) + 1;
      top.textContent = `${text}  ×${top.dataset.count}`;
      return;
    }
    const div = document.createElement('div');
    div.dataset.text = text;
    div.dataset.count = 1;
    div.className = kind;
    div.textContent = text;
    this.logEl.prepend(div);
    while (this.logEl.children.length > MAX_LOG) this.logEl.lastChild.remove();
  }

  /** Big centre-screen banner for things you must not miss. */
  alert(text, kind = 'bad', secs = 3) {
    const el = $('alert');
    el.textContent = text;
    el.className = kind;
    this.alertT = secs;
  }

  setMode(mode) {
    const labels = { command: 'COMMAND', surface: 'OPERATIVE · SURFACE', cave: 'OPERATIVE · UNDERGROUND' };
    $('hud-mode').textContent = labels[mode];
    const fps = mode !== 'command';
    $('fps-hud').classList.toggle('hidden', !fps);
    $('place-reason').classList.toggle('hidden', fps);
    $('help-command').classList.toggle('hidden', fps);
    $('help-fps').classList.toggle('hidden', !fps);
    document.body.classList.toggle('fps', fps);
  }

  updateTop({ energy, max, income, packets, field, coverage, shipHp, time, paused, speed, units, dt }) {
    $('hud-energy').textContent = `${Math.floor(energy)} / ${max}`;
    $('hud-energy-fill').style.width = `${(energy / max) * 100}%`;
    $('hud-income').textContent = `+${income.toFixed(1)}/s`;
    $('hud-packets').textContent = packets;
    $('hud-field').textContent = field;
    $('hud-units').textContent = units;
    $('hud-coverage').textContent = `${(coverage * 100).toFixed(0)}%`;
    $('hud-ship').textContent = `${Math.max(0, Math.round(shipHp * 100))}%`;
    $('hud-ship').className = shipHp < 0.35 ? 'bad' : shipHp < 0.7 ? 'warnc' : '';
    const m = Math.floor(time / 60), s = Math.floor(time % 60);
    $('hud-time').textContent = `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
    $('hud-speed').textContent = paused ? 'PAUSED' : `${speed}×`;
    $('hud-speed').className = paused ? 'bad' : '';
    this.alertT -= dt;
    $('alert').style.opacity = this.alertT > 0 ? 1 : 0;
  }

  updatePlaceReason(text) { $('place-reason').textContent = text; }

  updateFps(fps) {
    const suit = Math.max(0, fps.suit) / OPERATIVE.SUIT_MAX;
    $('suit-fill').style.width = `${suit * 100}%`;
    $('suit-fill').style.background = suit < 0.35 ? 'var(--bad)' : 'var(--good)';
    $('tank-fill').style.width = `${(fps.weapons.tank / OPERATIVE.TANK_MAX) * 100}%`;
    $('weapon-name').textContent = fps.weapons.name;
    $('creeper-warn').classList.toggle('hidden', !fps.inCreeper);
    $('creeper-warn').textContent = `IN CREEPER · SUIT BURNING${fps.creeperDepth > 1 ? ' FAST' : ''}`;
    $('prompt').textContent = fps.prompt;
    $('crosshair').classList.toggle('hit', fps.weapons.hitMarker > 0);
    const r = fps.recallHold / OPERATIVE.RECALL_HOLD;
    $('recall').style.display = r > 0 ? 'block' : 'none';
    $('recall-fill').style.width = `${r * 100}%`;
    $('damage-flash').style.opacity = fps.hurtFlash > 0 ? 1 : fps.inCreeper ? 0.7 : 0;
    $('creeper-tint').style.opacity = fps.inCreeper ? Math.min(0.55, 0.2 + fps.creeperDepth * 0.2) : 0;
  }

  /** Modal overlay. buttons: [{ label, onClick }] */
  showOverlay(html, buttons = []) {
    const box = $('overlay-box');
    box.innerHTML = html;
    for (const b of buttons) {
      const el = document.createElement('button');
      el.textContent = b.label;
      el.addEventListener('click', b.onClick);
      box.appendChild(el);
    }
    $('overlay').classList.remove('hidden');
  }

  hideOverlay() { $('overlay').classList.add('hidden'); }
}
