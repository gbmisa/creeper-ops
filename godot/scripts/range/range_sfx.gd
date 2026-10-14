class_name RangeSfx
## Maps gun classes to the existing Sfx voices (Sfx is the autoload; voices live in sfx_voices.gd).

const SHOT := {
	"pistol": ["pop", "rifle_crack"],
	"smg": ["blaster", "rifle_crack"],
	"assault rifle": ["rifle", "rifle_crack", "rifle_tail"],
	"shotgun": ["boom", "rifle_crack"],
	"marksman": ["boom", "rifle_crack", "rifle_tail"],
	"bolt-action": ["boom", "rifle_crack", "rifle_tail"],
}


static func shot(gun_class: String) -> void:
	for v in SHOT.get(gun_class, ["rifle"]):
		Sfx.play(v)
