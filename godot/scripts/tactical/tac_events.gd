class_name TacEvents
extends RefCounted
## Per-session gameplay event bus (MULTIPLAYER.md rule 7). Gameplay emits; visuals and audio
## subscribe. Offline the session forwards to RangeAudio; in MP-2 the server broadcasts these.

signal shot_fired(res: Dictionary, gun: Gun)
signal hit_confirmed(res: Dictionary)
signal reloaded(gun: Gun)
signal picked_up(item: Dictionary)
signal dropped(item: Dictionary)
signal died(who: Object)
signal noise_emitted(pos: Vector3, radius: float, kind: String, src: Object)
