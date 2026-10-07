// Entry point. Keep this tiny: everything else hangs off Game.

import { Game } from './core/Game.js';

const game = new Game(document.getElementById('view'));
game.start();
window.game = game; // handy for console debugging / balancing
