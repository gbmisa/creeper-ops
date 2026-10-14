# RANGE5 SOUND progress (branch feat/r5-sound)
Done in one commit. Code: `scripts/range/sound_defs.gd` (table), `range_audio.gd` (player: 20 x AudioStreamPlayer3D pool + 6 plain, random pitch +-4 %,
tail delayed by distance/343, indoor zones -> reverb bus "RangeRoom"; KillHouse registers its 30x30 box), test `range_test_sound.gd`.
Routed: player gun shot/dry/mag_out (reload start)/mag_in (reload end)/action (cycle)/mode, bot shots (positional), inventory pick/drop/move by kind, rack pick.
`range_sfx.gd` deleted (replaced). `Gun.id` added. Samples: `godot/assets/audio/range/` (1.1 MB), credits in CREDITS.md, recipe `build_samples.py`.
UTIL must call `RangeAudio.util(item, event, pos)`, GUNS-2 `RangeAudio.attach(id, "fit"|"remove")`; suppressed shots: `RangeAudio.shot(id, pos, true, cal, cls)`. Unmapped: none.

## Mappings for human review (could not listen; sample cut points guessed from silence detection)
Shots: m1911 = 1911 .45; glock18 = Walther PPQ 9mm; revolver = 1911 pitched x0.72 + Savage x0.55 lowpassed (boom); mp5 = Carl Gustav M45 9mm;
vector = Carl Gustav x0.88; p90 = PPSh x1.3 (sharper); ak47/sks/m4a1 = real AK/SKS/AR-15; scarh = Tikka .30-06 x0.9; sr25 = Savage .300 x0.93;
garand = Springfield 1917 + synth ping on clip eject; mosin = real Mosin; sniper .338 = Tikka x0.72 + 1917 x0.55 lowpassed; pkm = Mosin x0.92 + AK x0.7 lowpassed;
m870 = Winchester Model 12; saiga12 = Nova x1.08. Tails = mid-distance recording of same family (revolver/scar/sr25 use Savage, p90 PPSh, pkm Mosin, axmc Tikka).
Suppressed: pistols = OGA silencer; smg/rifle/shotgun/sniper/heavy = same shot low-passed 1.6 kHz, -3 dB, fast fade; played 6 dB lower, tail 14 dB lower.
Mechanics (guessed slices, check by ear): pistol out/in = clipload1 / gunreload1, slide = reload.wav 0.55-1.55 s; smg out/in = clipload2 / StarNinjas 1;
rifle out/in/charge = three slices of assault-rifle reload; saiga/sks charge = shotguncock; pump = Rack.mp3, shell in = Subsequent Shells slice; bolt = lockclick +
Kenney metalLatch layered; revolver/sks/bolt "in" = single bullet; garand out = synth ping; pkm out/in/action = belt clicks (Equipment Clicks), StarNinjas 2, belt close.
Dry = lockclick; mode switch = Kenney metalClick. Attachments: sight = click (x1.15 fit / x0.85 remove), muzzle = latch (x0.8/x0.7), under = latch (x1.2/x1.0), laser = latch, extmag = clipload2.
Inventory: gun metal/plate drop; mag plastic/metal; ammo coins; armor+rig cloth/soft; backpack leather; med plastic/cloth; attachment metal; utility metal/wood.
Utility: grapple fire noise burst, reel = 28 Hz tremolo square, impact = Kenney metal heavy; grenades pin = latch x1.3, throw = whoosh, bounce = metal/plate impact,
frag blast = Kenney low-frequency explosion; smoke hiss = 3.5 s pink noise; flash bang = crunch + metal layered, tinnitus = 4.5 s 7.2 kHz sine fade; stim = cloth belt; binoculars = cloth + click.

MP compliance: all range sound goes through `RangeAudio.event(dict)` (kind, item id, ev, pos, local, suppressed, cal, cls); a client plays a received event
identically. local=true is the player's own non-positional variant, bots/others pass pos (3D). Statics hold only the sample cache, pool and indoor zones (per process).
Emission still happens at the player/bot/inventory call sites (they sit beside the rule code), not yet via signals: MP-1 should route those dicts through the server event stream.
