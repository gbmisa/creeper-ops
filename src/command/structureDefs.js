// Data table for every buildable structure. Tooltips live next to the numbers they describe
// so in-game explanations never drift from the real values.
// cost = energy packets that must physically arrive over the network before it works.
// link = connection radius (cells). relays = passes packets on to other structures.

export const DEFS = {
  ship: {
    name: 'Command Ship', label: 'Command Ship', hp: 500, link: 10, relays: true, footprint: 1, linkY: 3.2, buildable: false, creeperResist: 0.6,
    desc: 'Your mothership and the network root. Launches energy packets and hosts the teleporter. If it falls, you lose.',
  },
  collector: {
    key: 'Digit1', label: 'Collector', cost: 5, hp: 30, link: 6, relays: true, linkY: 0.9,
    desc: 'Claims dry land within 3 cells and turns it into energy. Overlapping fields share land, so space them out. Also relays packets (link 6).',
  },
  relay: {
    key: 'Digit2', label: 'Relay', cost: 6, hp: 25, link: 13, relays: true, linkY: 2.9,
    desc: 'Long-range network node (link 13). Packets hop relay to relay to reach the front.',
  },
  reactor: {
    key: 'Digit3', label: 'Reactor', cost: 30, hp: 60, link: 4, linkY: 1.2, income: 0.6,
    desc: 'Generates a flat +0.6 energy/s anywhere. Expensive but needs no land.',
  },
  storage: {
    key: 'Digit4', label: 'Storage', cost: 12, hp: 50, link: 4, linkY: 1, storage: 50,
    desc: 'Raises your energy cap by 50 so you can bank for big builds and nullifiers.',
  },
  blaster: {
    key: 'Digit5', label: 'Blaster', cost: 12, hp: 40, link: 4, linkY: 0.9,
    range: 8, fireRate: 0.3, power: 1.3, ammo: { max: 12, perPacket: 4 },
    desc: 'Fast beam that strips creeper from the nearest wet cell in range 8. Holds 12 shots; each orange ammo packet refills 4. No packets, no shots.',
  },
  mortar: {
    key: 'Digit6', label: 'Mortar', cost: 25, hp: 55, link: 4, linkY: 1.4,
    range: 16, fireRate: 2.4, power: 4.5, splash: 2.5, ammo: { max: 3, perPacket: 1 },
    desc: 'Lobs a shell at the deepest pool within range 16, clearing a 2.5-cell splash. One packet per shell, holds 3.',
  },
  barracks: {
    key: 'Digit7', label: 'Barracks', cost: 35, hp: 140, link: 5, linkY: 2, footprint: 1,
    desc: 'Trains Soldiers and Crawlers that can walk into Blight where nothing can be built. Select it to queue units. Units can fight and clear creeper, but only the Operative can plant charges, hack, or enter the Rift.',
  },
  beacon: {
    key: 'Digit8', label: 'Beacon', cost: 10, hp: 40, link: 0, needsNetwork: false, linkY: 1, dropPod: true,
    desc: 'Teleporter drop point. Dropped from orbit: needs no network, but not inside Blight. Click it, then press T to send the Operative down.',
  },
  nullifier: {
    key: 'Digit9', label: 'Nullifier', cost: 40, hp: 70, link: 4, linkY: 1.2, buildOnCreeper: true, creeperResist: 0.35,
    desc: 'Build within 4 cells of an UNSHIELDED emitter. Once its 40 packets arrive it charges for 8 s and destroys the emitter. Armored, but deep creeper still kills it.',
  },
};

export const BUILD_ORDER = ['collector', 'relay', 'reactor', 'storage', 'blaster', 'mortar', 'barracks', 'beacon', 'nullifier'];

// Defaults so every row has the fields the systems read.
for (const d of Object.values(DEFS)) {
  d.footprint ??= 0;
  d.relays ??= false;
  d.cost ??= 0;
}
