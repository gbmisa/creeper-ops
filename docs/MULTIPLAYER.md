# Multiplayer readiness (Gregory, 2026-10-14: "Make sure this will be able to be multiplayer")
Scope: the tactical layer (`scripts/tactical/`, `scripts/range/`: Firing Range hub, Skirmish, future raids). Target:
co-op PvE first (2–4 players vs bots), PvPvE possible later. Godot high-level multiplayer (ENet), **listen server**
(host is authoritative), dedicated server later from the same code (`--server`, headless).

## Authority
| Thing | Owner | Clients |
|---|---|---|
| Player movement | owning client simulates (input -> CharacterBody), server accepts within speed/teleport limits | others interpolate |
| Firing | owning client plays effects at once and sends `fire(seq, origin, dir, gun_uid)`; **server** runs ballistics, hits, damage | hit markers/damage arrive from server |
| Health, armor, death, bleeds | server | replicated |
| Inventory, loot, world items, crates, attachments | server (clients send requests: move/fit/drop/pick) | replicated per owner; others see equipped gear only |
| Bots (perception, brain, shooting) | server only | positions/anim state replicated |
| Grenades, grapple, doors, extract timer | server | replicated |
| Recoil, sway, viewmodel, HUD, audio | local only (never networked) | — |

## Rules for all code from now on
1. **No per-player state in statics or autoload singletons.** Per player: a `PlayerState`/player node owns inventory,
   loadout, recoil mode, health, stats. Statics only for immutable data tables and per-process settings. Today's
   offenders get fixed in MP-1 (`RangeLoadout.saved`, recoil toggle, `RangeMaps.selected`, anything `static var`).
2. **"The player" is never a singleton.** Systems take a player/peer id or a list of players (bots pick targets from
   `players`, not `player`). HUD/viewmodel/camera bind to the *local* player only.
3. **Input is data.** Gameplay reads an input frame (`InputState` snapshot: move, look, buttons, seq), never `Input.*`
   directly, so the server can run a remote player from received frames.
4. **State changes go through one function per action** (`inventory.request_move(...)`, `gun.request_fire(...)`), so
   each becomes an RPC with server validation without rewriting callers.
5. **Randomness on the server is seeded per entity** (`RandomNumberGenerator` owned by the gun/bot/item), never the
   global `randf()`, so replays/desync checks are possible. Cosmetic randomness may stay local.
6. **Everything spawnable has a stable id** (uid for items exists; add for players, bots, world items, projectiles)
   and a `to_dict()/from_dict()` so it can be sent and joined mid-session.
7. **Effects are events.** Gameplay emits events (shot, hit, explode, pickup); visuals/audio subscribe. The server
   sends events to clients; nothing visual is required for the rules to work (headless tests already prove this).
8. Physics props that matter to gameplay are server-simulated; purely cosmetic ones are local.

## Stages
- **MP-0 (now):** this doc; running tracks follow the rules; an audit lists every blocker with file:line.
- **MP-1:** refactor blockers (players list, PlayerState, input frames, seeded RNG, request functions). Behaviour
  identical in single player; tests prove it.
- **MP-2:** ENet listen server: host/join from the main menu (IP or LAN), 2–4 players in the range hub and Skirmish,
  MultiplayerSpawner/Synchronizer, server hits, interpolation, 100–150 ms latency simulation test.
- **MP-3:** co-op polish: shared extract, revive/down state, party deploy truck, loot ownership, voice-less pings.
