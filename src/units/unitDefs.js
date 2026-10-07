// Barracks-trained units. They can walk into Blight (where nothing can be built), shoot
// enemies and clear creeper, but they CANNOT do objective actions (charges, hacking, the Rift):
// those always need the Operative.
// climb = max terrain levels between neighbouring cells; drop = max levels they'll step down.

export const UNIT_DEFS = {
  soldier: {
    label: 'Soldier', key: 'KeyF', cost: 6, trainTime: 2, hp: 35, speed: 5.5, climb: 1.1, drop: 3, radius: 0.45,
    gun: { range: 14, damage: 1, rate: 0.35 },
    clear: { range: 3, power: 0.35, splash: 0, rate: 0.45 },
    creeperMult: 1,
    desc: 'Cheap, agile infantry (6 packets). Climbs steep ground, picks off spore mites, and chips at shallow creeper. Fragile in creeper.',
  },
  crawler: {
    label: 'Crawler', key: 'KeyG', cost: 18, trainTime: 4, hp: 130, speed: 4.2, climb: 0.6, drop: 1.2, radius: 0.9,
    gun: { range: 18, damage: 3, rate: 0.9 },
    clear: { range: 3.5, power: 1.1, splash: 1.5, rate: 0.4 },
    creeperMult: 0.35,
    desc: 'Armored vehicle (18 packets). Its nozzle sprays creeper away in a wide splash and it shrugs off shallow creeper, but it needs gentle slopes.',
  },
};

export const UNIT_ORDER = ['soldier', 'crawler'];

export const UNIT_CREEPER = { BASE_DPS: 6, DPS: 12 };
