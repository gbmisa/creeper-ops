---
name: dream
description: Dream up new game-design ideas for this project using randomized design lenses, the project's pillars, plan, playtest notes and idea board, then file the best ones on the gdflow idea board. Use when the user asks for ideas, brainstorming, "what should we add", or to make the game more interesting.
---

# Dream: generate game ideas that serve the pillars

1. Build the packet (args the user gave, e.g. a focus, go into `--focus`):
   `{cli} dream --count 5 [--focus "<area>"] [--lens <id> ...]`
   Use `{cli} lenses` to list lens ids. Do not read design docs in full; the packet is the context.
2. Follow the packet's Task section exactly: diverge (2x ideas), converge (keep the best), write
   title, pitch, hook, pillar and first slice for each keeper.
3. Be a demanding designer: prefer ideas that add a **decision**, create **emergence** between existing
   systems, or fix a weak loop step. Kill ideas that are only more content, fight a pillar, or duplicate the board.
4. File each keeper with `{cli} idea add ... --source dream --lens <ids>`.
5. Score each one honestly with `{cli} idea score I-00N --fun F --fit F --novelty N --cost C --risk R`
   (1-5; cost and risk are bad when high).
6. Reply to the user with a short table (id, title, one-line hook, priority) and your top pick with one
   sentence why. **Never approve ideas**: suggest `/greenlight`.
