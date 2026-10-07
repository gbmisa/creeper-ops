// Energy bank. Income comes from the ship, collector land and reactors; spending happens one
// packet at a time in Packets.js, so `spend` here is only for lump costs (penalties, drop pods).

import { ECONOMY } from '../core/config.js';

export class Economy {
  constructor() {
    this.energy = ECONOMY.START_ENERGY;
    this.max = ECONOMY.BASE_MAX;
    this.income = 0;     // per second, for the HUD
    this.fieldCells = 0;
  }

  canAfford(n) { return this.energy >= n; }

  spend(n) {
    if (this.energy < n) return false;
    this.energy -= n;
    return true;
  }

  /** Penalties may push below what you'd voluntarily spend, but never below zero. */
  drain(n) { this.energy = Math.max(0, this.energy - n); }

  add(n) { this.energy = Math.min(this.max, this.energy + n); }

  tick(dt, { shipAlive, fieldIncome, fieldCells, reactorIncome, storage }) {
    this.max = ECONOMY.BASE_MAX + storage;
    this.fieldCells = fieldCells;
    this.income = (shipAlive ? ECONOMY.SHIP_INCOME : 0) + fieldIncome + reactorIncome;
    this.energy = Math.min(this.max, this.energy + this.income * dt);
  }
}
