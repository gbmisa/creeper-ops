# TRP spec excerpt: reloading (Apache-2.0, github.com/JuanFNQ/TRP TRP/docs/spec/firing.md, fetched 2026-10-15)
Full repo specs worth reading by section only: hands-on-weapon.md, pistol.md, shotgun.md, bolt-action.md, more-weapons.md.

## Reloading with a magazine

`ReloadExternalMagOperation` sets animator parameters and the animator walks `RELOAD START`, `RELOAD OUT`, `RELOAD IN`, then one of two endings. The marks drive the logic:

- `MagOut`: the old magazine leaves the weapon. `MagHide`: it is put away or dropped.
- `MagShow`: the new magazine appears in the hand. `MagIn`: it is in the weapon and its rounds count.
- At `MagIn`, if a round is already chambered the operation hands over to idle through `RELOAD END`. If the chamber is empty the animator goes on to `RELOAD CHARGE END`, where `AddAmmoInChamber` chambers the first round of the new magazine.

**The reload is over for the logic before its animation is** (read on 2026-10-08, `ReloadExternalMagOperation`). The reload operation hands over to the idling one at `MagIn` when no round has to be chambered (one is in the chamber already, or the magazine going in is empty), and otherwise at `AddAmmoInChamber`. The animator then plays out the rest (`RELOAD IN` and the ending, 0.8 s for the AKM with a round chambered) with the weapon's logic idle. In that tail:

- the aim key works again, as at any other time, and the calls that lower the sights from outside are obeyed ("Aiming, and what takes it away");
- a press of the trigger is still refused. The reload raises a flag on the controller as it starts, and the idling operation drops any press while it is up. What clears it is `IdleStart`, a mark at the very beginning of `IDLE`, which therefore falls on the frame the animator starts blending into `IDLE`. A release is taken at any time;
- the "tactical reload" is switched off (the idling operation does that as it starts).

Two parameters of the **body's** animator follow the reload:

- `ProneReload`, a flag. It is raised when the reload operation begins and lowered when it ends, so it is up from the frame of the key to the mark above. Despite its name it is set in every movement state, standing too; the base class of the movement states does it and none overrides it. (Opening the inventory raises it as well; not built.)
- `ReloadFloat`, set to 1 when the reload begins and back to 0 by `IdleStart`. Other operations set it too (folding the stock, and a fire-mode switch on weapons that have a sprinting variant of it).

What the body does with them is in `body-animator.md`, "Reloading"; what the first does to the prone key, for the online raid's player only, is in `movement.md`, "Prone".

Built: `Firearm::reloading` is the first flag (hosts pass it on as `movement::Input::reloading`), and `set_aim` and `lower_aim` go by it. `Firearm::hands_busy` is the second (`movement::Input::hands_busy`): the body's animator answers it in a sprint.

Compared with the game (sixth recording, which writes both parameters every frame): the simulation's flag is the game's `ProneReload` on every frame of all five reload scenarios, standing and lying. It comes up on the frame of the key and drops on the frame of `MagIn` with a round chambered (frames 358, 539, 419 and 659 of scenarios 23, 29, 30 and 39) and on the frame of `AddAmmoInChamber` from an empty chamber (1182 of 24). The game's `ReloadFloat` drops on the frame its animator starts blending into `IDLE` (451 of 23, 754 of 39).

Seventh recording, whose recorder also writes the name of the operation in hand: both parameters, and the operation (a reload in hand, a look at the weapon, or neither), are the game's on every frame of all 49 scenarios, ten of which reload or look. The tail was pressed in (48: the aim key held from 0.29 s after the magazine went in, the trigger pressed 0.1 s later and again after the weapon was at rest): the sights come up on the frame of the key, with the weapon's animator still in `RELOAD IN`; the first press of the trigger fires nothing; the second fires. The simulation does the same on every frame. With the sights up in the tail the eye follows the sight on the weapon as the reload's clip still has it: fed the recorded place of the weapon's own bone, the replay's eye is within 1.6 mm (root mean square) and 8 mm at worst, where the sight at rest left it 45 mm off for half a second.

The animator does not play these states to their ends. Each of its transitions has an exit time (the fraction of the state being left at which it may start), a blend length (seconds, or a fraction of the state being left) and an offset into the next state. The next state's own clock, and so its marks, start when the blend starts. For the AKM:

| From | To | Leaves at | Blends for |
|---|---|---|---|
| `RELOAD START` (0.44 s) | `RELOAD OUT` | 0.30 of it, 0.13 s | 0.75 of it, 0.33 s |
| `RELOAD OUT` (1.43 s) | `RELOAD IN` | 0.78, 1.12 s | 0.22, 0.32 s |
| `RELOAD IN` (1.77 s) | `RELOAD END` | 0.90, 1.59 s | 0.10, 0.18 s |
| `RELOAD IN` | `RELOAD CHARGE END` | 0.95 | 0.05 |
| `RELOAD END` (0.46 s) | `IDLE` | 0.98, 0.45 s | 0.03, 0.01 s |
| `RELOAD CHARGE END` | `IDLE` | 0.92 | 0.25 s |

Firing, the fire-mode switch and the magazine check are entered from `IDLE` with no blend and return to it at their end with none.

**Which clip a state plays.** Two of these states choose between clips by a parameter, and the choice was got wrong until the seventh recording showed the hands' markers elsewhere:

- `IDLE` blends two clips by `LauncherID`, one at -1 and one at 0. The game sets that parameter only on a weapon with an underbarrel launcher (to -1 while the launcher is not the weapon in use). On any other weapon it stays at the 0 the controller starts it with, and the animator rests in the second clip, the one whose name speaks of a launcher (`akm_launcher_0_idle_off`). The two differ in the left hand: its marker sits 2.6 cm and 55 degrees apart, the left elbow's goal 6 mm, the left upper arm a degree. Recorded: both hand markers are that clip's within 0.1 mm and 0.1 degrees on every frame the weapon is at rest. `trp_sim::rest_clip`; before, the clip named `..._idle_armed` was taken.
- `FIREMODE` blends two clips by `FireMode`, which the game sets to its own number for the mode switched to: 0 for automatic, 1 for single shots (3 for bursts). The clip is therefore picked by the mode, not by the mode's place in the weapon's list, where single shots come first. Recorded: with the two the right way round the right hand's marker is within 8 mm through the switch (it was 72 mm off: the hand reaching for the selector the wrong way).

Measured for the AKM with its 30-round magazine: 3.3 s with a round chambered, the magazine out at 0.8 s and the new one in at 2.5 s. Played end to end, as an earlier version did, the same states take 4.1 s.

**When within a frame.** The game runs this logic and the weapon's animator once per drawn frame, after that frame's physics steps. Three things follow, each read off the fourth recording:

- A command acts in the frame it is given: the trigger pulled in a frame fires in that frame, and the round count drops then.
- A state a command starts has run none of its time when that frame ends (`FIRE` stands at its starting point of 0.2, `RELOAD START` at 0). Its clock starts with the next frame.
- A state left at an exit time hands the next state what is left of the frame after that point, as in the body's animator (`body-animator.md`, "Where in the frame a transition starts").

**The recoil's kick, and which physics step takes it** (read and recorded on 2026-10-09, when the recoil was checked over). Making a shot (`InitiateShot`) does not kick the weapon: it raises a flag on the firearm controller, and the controller's own late update, finding the flag, calls the weapon animation's `Shoot(strength)`. That late update is called at the end of the player's (`Player.VisualPass`), after the frame's physics steps have been run through the weapon's springs. So the springs feel a shot on the first physics step of a later frame, never in the frame the shot is made in. For automatic fire the round is taken and the shot made in one call (the fire mark's), so counted from the frame the rounds drop the kick is taken by the first physics step in a frame after it. A single shot takes its round a frame before it makes the shot (above), so its kick is taken by the first physics step in a frame from the second on: one physics step later than an automatic shot's wherever the frame after the press has a physics step, and the same step where it has none.

Recorded (the first shot of each firing scenario in the fourth to the tenth recording, 28 in all, with the springs at rest before it; the frames counted from the one the rounds drop on to the one the position spring first moves on). Automatic: 1 or 2 frames, the simulation's the same in 10 of 12 and a frame either way in the other two. Single: 2 or 3 frames in the game, never 1; with the shot's kick made with the round the simulation had 1 or 2, the game's own in 8 of 16, a frame early in 4 and two early in 4. Built 2026-10-09 (`Firearm`: a single shot's `Shot` event comes with the step after the one that takes the round).

**Compared with the running game** (fourth recording, 120 frames a second; frames counted from the scenario's start):

| | Game | Simulation |
|---|---|---|
| Reload, round chambered: `RELOAD START`, the blends into `RELOAD OUT`, `RELOAD IN`, `RELOAD END` and `IDLE` begin | frames 60, 75, 208, 397, 450 | the same five frames |
| That reload, start to the weapon at rest | 3.30 s | 3.30 s |
| Reload, chamber empty: the same with `RELOAD CHARGE END` | frames 714, 730, 864, 1064, 1244 | the same five frames |
| That reload, start to the blend into rest | 4.44 s, and 0.25 s more of blend | the same |
| Fire-mode switch | frames 12 to 152, 1.17 s | the same |
| Single shot: `FIRE`, then `IDLE` | frames 120 and 127; 297 and 306 | the same |
| Rounds left, on every frame of two single-shot and two automatic scenarios | | the same on every frame |
| A full magazine on automatic, first shot to empty chamber | 31 rounds in 3.01 s | the same, each on the game's frame |

What the recording shows differently:

- **The count jumps at the start.** The recorded rounds in the magazine change on the reload's first frame, to what the magazine going in holds, and a round is in the chamber from that frame where there was none. The game settles the exchange as it starts the reload and the animation follows. The simulation counts at the marks (`MagOut`, `MagIn`, `AddAmmoInChamber`), so its count is behind until the new magazine is in.
- **Between automatic shots the animator touches `IDLE`.** `FIRE` is 0.097 s and the cycle 0.1 s, so the game's animator is in `IDLE` for a frame before each further shot. The simulation's fixed sequence restarted `FIRE` without reporting it; since the logic goes by the animator (2026-10-11) it touches `IDLE` on the game's frames.
- **A magazine put away is kept.** The first recorded reload put a magazine of 5 rounds away, and the second reload fitted that same magazine.
- **Running dry on automatic** (a full magazine fired off with the trigger held to 5.5 s; in the fourth, fifth and sixth recordings). The weapon has two states for a pull on an empty chamber, both playing the same 0.133 s clip at half speed: `DRY FIRE`, entered from `IDLE` while the animator's `Armed` flag is up, whose first mark is `Disarm`, and `DRY FIRE DISARMED`, entered while it is down. (The second is the state whose number in a trace, 15805663, stood here unidentified until 2026-10-08; the numbers are the low 24 bits of the CRC-32 of the state's name, and hashing the controller's 99 names finds it.) Each leaves for `IDLE` at the end of a 0.267 s cycle and only if the trigger has been let go, so it lasts whole cycles for as long as the trigger is held. In the fourth and sixth recordings the animator touches `IDLE` for a frame after the last shot, is in `DRY FIRE` for 64 frames (two cycles: the trigger is let go in the second) and back in `IDLE` at 5.65 s. In the fifth it is in `DRY FIRE` for three frames, in `IDLE` for one, and then in `DRY FIRE DISARMED` for the same 64 frames, to the same moment; why the first gave way after three frames there has not been read. The simulation enters `DRY FIRE` when its automatic cycle ends (a frame early in the sixth, two late in the fourth) and reports no return to rest until the next action; that, with the frame of `IDLE` between automatic shots, is the 4.75% of frames by which its weapon state differs in that scenario. Running the weapon's controller on the animator settled all of it ("The weapon's animator as a state machine"); nothing in the logic waits on these states, and the reload that follows starts on the game's frame all the same, with its five stages on the game's frames (711, 727, 861, 1061, 1241 in the fifth).

## The quick reload, and the magazines as things (read 2026-10-14, when the user asked for the quick reload mechanic)

Read from `FirearmHandsInputTranslator` (`QuickReload`, `Reload`, `ReloadExternalMagazine`, `InIdleStateForInvokeOperation`), `Player.FirearmController` (`QuickReloadMag` in `FirearmOperation`, `FireOperationBase` and the idling operation; `ReloadExternalMagOperation`; `ReloadExternalMagResult.Run`; `ShouldForceQuickReload`), `FirearmsAnimator.Reload`, `Weapon.CanReloadFast`, `Inventory.FastAccessSlots`, `InventoryController.GetReachableItemsOfTypeNonAlloc` and `InventoryEquipmentExtension.GetPrioritizedGridsForUnloadedObject`, and from the install's AKM controller.

**The key.** `QuickReloadWeapon`, which the install binds to the reload key's double click (`R`, `DoubleClick`): that binding is why a plain press of `R` waits out the double click's time ("Three more keys" and `settings.md`). The command is heard only while the weapon's animator is at rest (`InIdleStateForInvokeOperation`, which asks the animator whether its hands' layer is in `IDLE` or one of its other resting states); the plain key has no such test. A weapon fired once and thrown away (`IsOneoff`) takes neither.

**What it does, by the weapon's reload mode** (`QuickReload`):

- `ExternalMagazine`: a magazine's reload, the quick way where it can be (below).
- `ExternalMagazineWithInternalReloadSupport`: the same, and with no magazine found, rounds a time into the fitted one (as the plain key's `ReloadWithAmmo`).
- `InternalMagazine`: a revolver's cylinder emptied whole and filled (`ReloadRevolverDrum` with its quick flag: every chamber counted free, the animator's `ReloadFast`); any other weapon of the mode, the plain key's rounds a time.
- `OnlyBarrel` with more barrels than one: the barrels loaded, as the plain key does.

The plain key goes the same way with the quick flag down, unless the head is stunned (`ShouldForceQuickReload`: an active stun on the head makes every reload quick).

**The magazine taken** (`ReloadExternalMagazine`). The magazines within reach are those lying directly in the grids of the pockets and of the vest worn, in that order (`FastAccessSlots`; the search does not go into things inside them, and never into the backpack), each holding at least one round. They are sorted fullest first, and the first that the weapon's magazine slot would take is used. With none, the character only says that it needs ammunition (`ReloadMagNotFound`), and the plain key then tries to put one loose round into an empty chamber by hand (`LoadAmmoToChamber`, the state `LOAD ONE`).

**Quick or plain.** The quick way is taken when the key asked for it, a magazine is fitted, and the weapon's template allows it (`isFastReload`, `Weapon.CanReloadFast`): `QuickReloadMag`. Otherwise the plain one, `ReloadMag`, which is given a place for the old magazine: the first free place in the vest's grids and the pockets', searched grid by grid with the smallest grid first (a tie keeps the vest before the pockets; the backpack is not among them). In the install 134 of the 176 weapons that say allow it. Of those built here the AKM, the Five-seveN, the SV-98 and the SCAR-L (so the StG 44) are reloaded the quick way by the key; the Model 700 allows it too, but its magazine stays in it (`InternalMagazine`), so its key fills it as the plain key does; the SKS, the Rhino, the MP-43e and the M3 do not allow it.

**The operations.** The idling operation takes the command at once: the sights come down below mastering 2, the trigger is let go, and the magazine's reload begins. A shot in hand takes it as it takes the plain one, planned for when the shot is over. Every other operation refuses it.

**The exchange is made as the reload begins** (`ReloadExternalMagResult.Run`). The old magazine is moved to the place found for it, or, with none (always, the quick way), taken out of the weapon with nowhere to go; the new one is moved into the weapon's magazine slot; and with the chamber empty, the new magazine's top round is moved into it. That is why a recording's count jumps on the reload's first frame ("Compared with the running game").

**The animator.** `FirearmsAnimator.Reload(old, new, quick)` sets the two magazine indices as for any reload (`RelTypeOld`, `RelTypeNew`) and then raises `ReloadFast` in place of `Reload`. In the AKM's controller `IDLE` leaves for `RELOAD OUT ALL` on `ReloadFast` with `MagInWeapon` and `CanReload` (blend 0.098 of the state): a clip of 1.0 s that throws the magazine out (`MagOut` 0.486, `MagHide` 0.602) and leaves for `RELOAD IN` at 0.9 of it, after which the quick reload is the plain one, the same states and the same endings. `RELOAD OUT ALL` stands in for the plain reload's `RELOAD START` (0.44 s, left at 0.3) and `RELOAD OUT` (1.43 s, left at 0.78).

**Where the old magazine goes** (`OnMagPuttedToRig`, at `MagHide`). A magazine that was taken out with nowhere to go is thrown into the world from where the weapon's magazine is at that moment, falling with a hundredth of a metre a second downwards and a random spin (`DropMod`, `GameWorld.ThrowItem`): loot on the ground, which keeps its rounds. A magazine that had a place is already there.

**What the plain reload's key does in the game, magazine by magazine**, follows from the same code: the fullest magazine within reach goes in, and the old one, with what is left in it, goes to the vest or the pockets. "A magazine put away is kept" (above) is that.

### Built (2026-10-14)

- `trp_sim::firearm`: `Firearm::quick_reload_with(rounds)` is the command: refused with the animator not at rest; quick where a magazine is fitted and `FirearmSettings::fast_reload` (the template's `isFastReload`) allows, else the plain reload. The animator is told `ReloadFast`, and then everything is the plain reload's. Two events tell the host: `MagazineSwap { left, quick }` as the reload begins (the rounds the old magazine leaves with, none if there was none fitted) and `MagazineHidden` at `MagHide`.
- `trp_sim::inventory`: `next_magazine` (the fullest magazine within reach that the weapon's slot takes), `swap_magazine` (the exchange at the start: the old magazine with its rounds to the vest or the pockets, or kept out to fall; the new one into the weapon), `magazine_rounds`, `set_magazine_rounds`, `fill_magazine`.
- The app: the plain reload and the quick one both take the magazine from the pockets and the vest, by those rules; the quick one's old magazine, and a plain one's that has no room, lie on the ground at `MagHide`, where they can be taken up again. A weapon in the crate has its magazine full in the inventory as in the hands, and every weapon fed from magazines has spare ones beside it.

### Not built, and open

- A revolver's quick reload (the cylinder emptied whole), the plain key's round put into the chamber by hand with no magazine found (`LoadAmmoToChamber`, `LOAD ONE`), the stun that makes every reload quick, the voice line for a magazine not found, and the left hand's layer that `ReloadFast` resets.
- `PROVISIONAL`: magazines of the same count are taken in the order they lie (the game's sort is not a stable one, so its order between two magazines that hold the same is not known).
- `PROVISIONAL`: the magazine in the weapon is brought up to date in the inventory when it leaves the weapon (its rounds then are the simulation's), where the game takes each round out of it as it is fired; the carried weight is the heavier by the rounds fired since the last reload.
- `ESTIMATE`: where a magazine let fall lies. The game drops it from the weapon's own magazine and lets it fall; the app has no physics, and lays it on the ground under where the weapon is held (`MAGAZINE_DROP` in `trp-app/src/inventory_view.rs`).
- **Measured on the install's AKM** (`the_quick_reload_throws_the_akm_s_magazine_out`, the controller run by the simulation at 120 frames a second): the plain reload has the old magazine out at 0.80 s, out of the hand at 1.26 s, the new one in at 2.50 s and the weapon at rest at 3.32 s (4.69 s from an empty chamber); **the quick one has it out at 0.49 s and out of the hand at 0.61 s, the new one in at 2.15 s and the weapon at rest at 2.97 s** (4.34 s): 0.35 s sooner, from RELOAD IN on the same states.
- **In the app** (2026-10-14, scripted captures): R twice reloads the AKM by RELOAD OUT ALL and the old magazine lies on the ground before the character, a box that F takes up again; R once takes the vest's first magazine and puts the old one, with 29 rounds, into the vest's next free grid of its size. Not played by hand.
- **Compared with nothing**: no recording has a quick reload, and which magazine the app's plain reload takes from the gear is not set beside the recorded ones (the replay is told each recorded reload's count).

