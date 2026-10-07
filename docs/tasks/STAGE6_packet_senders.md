# Stage 6: several packet senders (Outposts)

Spec: docs/STRONGHOLDS_DESIGN.md §1.5. Read it first.

## Steps
1. **Split first.** `command/packets.gd` is 179 lines and will grow. Move `need()`, `transit_headroom()`, `rate()` and `speed()` into a new static class `command/packet_requests.gd` (`PacketRequests`). `Packets` calls it. No behaviour change in this step; run the smoke tests before going on.
2. **Senders in data.** Add `"sender": true` to the `node` def in `structure_defs.gd`. Add a new `outpost` def: tab Structures, cost 40 (packets, built like any structure for now; Stage 9a adds its Ore cost), hp 200, link 6, `relays: true`, `sender: true`, `movable: false`, footprint 1. Add a mesh case in `structure_meshes.gd` (a squat, wide relay-like tower with a ring; visibly different from the Node) and a short `desc` tooltip.
3. **Network.** In `network.gd` `rebuild()`, run Dijkstra from **every** sender that is built and not flying, all at distance 0, with `_prev[sender] = null`. Then `route(s)` starts at the nearest sender automatically. Update the file's header comment.
4. **Packets.** "Node ready" becomes "at least one sender is built, connected and not flying". A flying Node no longer stops packets if an Outpost is up. Find where `node_ready` is computed (probably `structure_manager.gd`) and change it there.
5. **Economy.** One shared bank. Each built Outpost adds `Config.OUTPOST_STORAGE` (50) to `max_energy`. Outposts produce nothing.
6. **CLAUDE.md:** update the "CW3 economy" key contract (packets now launch from the nearest sender) and the `command/` architecture row.

## Smoke checks (new file `core/smoke_senders.gd`)
- A structure far from the Node but next to an Outpost: its `network.route()` starts at the Outpost.
- Destroy the Outpost: the route falls back to the Node, or is empty if out of range.
- Node flying with a built Outpost: packets still launch.
- Two Outposts raise `max_energy` by 2 × `OUTPOST_STORAGE`.

## Verify
Parse check; all smoke tests PASS; `--demo --units --sim=1200` report (should match `main` closely, since the demo builds no Outpost).

**Opus reviews this stage before merging**, so keep the diff focused.
