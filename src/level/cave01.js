// Level 01 underground — "The Hollow". Edit the ASCII map directly.
//   #  rock wall         0-3  floor height        .  floor height 1
//   P  recall pad / spawn (floor 3)   C  Deep Core (floor 0)   K  Shield Pylon (floor 1)

import { Grid } from '../world/Grid.js';

const MAP = `
########################################
#3333333####.........###################
#33P3333####..........##################
#3333333###.....K......#################
#33333332211...........#######.....#####
###33332211.............#####.......####
####22221111..................K.....####
#####111111.......000.........11....####
######1111......0000000.......111...####
######111......000000000.......11...####
#####1111.....00000C00000........#######
#####111......000000000..........#######
####1111.......0000000...........#######
####111.........00000...........########
###111...........................#######
###11.....##....................########
###1.....####..........######.....######
###1....######........########....######
###11....####.........########.....#####
####11.......K.........######......#####
#####111...........................#####
#######1111.......................######
##########1111.................#########
########################################`;

const WALL = 7;

export function buildCave01() {
  const rows = MAP.trim().split('\n');
  const w = Math.max(...rows.map((r) => r.length));
  const grid = new Grid(w, rows.length);
  const cave = { grid, pad: null, core: null, pylons: [], ceiling: 8 };

  rows.forEach((row, z) => {
    for (let x = 0; x < w; x++) {
      const ch = row[x] ?? '#';
      let h = 1;
      if (ch === '#') h = WALL;
      else if (ch >= '0' && ch <= '9') h = Number(ch);
      else if (ch === 'P') { h = 3; cave.pad = { x, z }; }
      else if (ch === 'C') { h = 0; cave.core = { x, z }; }
      else if (ch === 'K') { h = 1; cave.pylons.push({ x, z }); }
      grid.setHeight(x, z, h);
    }
  });

  // The Core floods its pit; the cap rises over time so waiting makes the dive harder.
  cave.coreSource = { amount: 1.0, interval: 1.5, baseCap: 1.4, capGrowth: 1 / 900 };
  return cave;
}
