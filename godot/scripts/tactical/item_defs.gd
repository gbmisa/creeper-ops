class_name ItemDefs
## Inventory items: size in grid cells (w x h), kg, kind (gun, mag, ammo, armor, rig, backpack, med).
## Guns, ammo grades and armor reuse their own def tables; mags, bags and meds are rows here.
## Bags (rig, backpack) carry a "grid": [w, h]. Mags/clips: "gun" = weapon id, "cap" = rounds.

const ROUND_KG := {"45acp": 0.02, "57x28": 0.012, "762x39": 0.017, "12ga": 0.04, "3006": 0.03, "338": 0.05,
	"9x19": 0.012, "44mag": 0.03, "556x45": 0.012, "762x51": 0.025, "762x54r": 0.022}
const STACK_MAX := {"45acp": 70, "57x28": 100, "762x39": 90, "12ga": 40, "3006": 60, "338": 30,
	"9x19": 90, "44mag": 40, "556x45": 90, "762x51": 60, "762x54r": 60}
const POCKETS := Vector2i(4, 1)

const ROWS := {
	"mag_m1911": {"name": "M1911 magazine", "kind": "mag", "w": 1, "h": 1, "kg": 0.1, "gun": "m1911"},
	"mag_p90": {"name": "P90 magazine", "kind": "mag", "w": 1, "h": 2, "kg": 0.25, "gun": "p90"},
	"mag_ak47": {"name": "AK-47 magazine", "kind": "mag", "w": 1, "h": 2, "kg": 0.25, "gun": "ak47"},
	"mag_sniper": {"name": "AXMC magazine", "kind": "mag", "w": 1, "h": 2, "kg": 0.2, "gun": "sniper"},
	"mag_glock18": {"name": "Glock 17-rd magazine", "kind": "mag", "w": 1, "h": 1, "kg": 0.12, "gun": "glock18"},
	"mag_revolver": {"name": ".44 speedloader", "kind": "mag", "w": 1, "h": 1, "kg": 0.1, "gun": "revolver"},
	"mag_mp5": {"name": "MP5 magazine", "kind": "mag", "w": 1, "h": 2, "kg": 0.2, "gun": "mp5"},
	"mag_vector": {"name": "Vector magazine", "kind": "mag", "w": 1, "h": 2, "kg": 0.2, "gun": "vector"},
	"mag_m4a1": {"name": "STANAG magazine", "kind": "mag", "w": 1, "h": 2, "kg": 0.2, "gun": "m4a1"},
	"mag_scarh": {"name": "SCAR-H magazine", "kind": "mag", "w": 1, "h": 2, "kg": 0.3, "gun": "scarh"},
	"mag_saiga12": {"name": "Saiga 8-rd magazine", "kind": "mag", "w": 1, "h": 2, "kg": 0.35, "gun": "saiga12"},
	"mag_sks": {"name": "SKS 10-rd magazine", "kind": "mag", "w": 1, "h": 2, "kg": 0.2, "gun": "sks"},
	"mag_sr25": {"name": "SR-25 magazine", "kind": "mag", "w": 1, "h": 2, "kg": 0.3, "gun": "sr25"},
	"mag_mosin": {"name": "Mosin 5-rd clip", "kind": "mag", "w": 1, "h": 1, "kg": 0.1, "gun": "mosin"},
	"mag_pkm": {"name": "PKM 100-rd belt box", "kind": "mag", "w": 2, "h": 2, "kg": 2.5, "gun": "pkm"},
	"clip_garand": {"name": "M1 en-bloc clip", "kind": "mag", "w": 1, "h": 1, "kg": 0.1, "gun": "garand"},
	"rig_chest": {"name": "Chest rig", "kind": "rig", "w": 3, "h": 2, "kg": 0.8, "grid": [4, 2]},
	"pack_small": {"name": "Small backpack", "kind": "backpack", "w": 3, "h": 3, "kg": 0.9, "grid": [4, 4]},
	"pack_big": {"name": "Large backpack", "kind": "backpack", "w": 4, "h": 4, "kg": 1.6, "grid": [5, 6]},
	"med_ifak": {"name": "IFAK medkit", "kind": "med", "w": 1, "h": 2, "kg": 0.4,
		"use": {"time": 3.0, "effect": "hp_pool", "amount": 150.0, "stop": ["light"]}},
	"med_bandage": {"name": "Bandage", "kind": "med", "w": 1, "h": 1, "kg": 0.05,
		"use": {"time": 2.0, "effect": "stop_bleed", "bleed": "light"}},
	"med_esmarch": {"name": "Esmarch tourniquet", "kind": "med", "w": 1, "h": 1, "kg": 0.1,
		"use": {"time": 3.0, "effect": "stop_bleed", "bleed": "heavy", "limb_only": true}},
	"med_splint": {"name": "Aluminium splint", "kind": "med", "w": 2, "h": 1, "kg": 0.2,
		"use": {"time": 5.0, "effect": "fix_fracture"}},
	"med_cms": {"name": "CMS surgical kit", "kind": "med", "w": 2, "h": 2, "kg": 1.0,
		"use": {"time": 15.0, "effect": "surgery", "uses": 3}},
	"med_ai2": {"name": "AI-2 medkit", "kind": "med", "w": 1, "h": 1, "kg": 0.1,
		"use": {"time": 2.0, "effect": "hp_pool", "amount": 100.0}},
	"med_car": {"name": "Car first aid kit", "kind": "med", "w": 2, "h": 1, "kg": 0.3,
		"use": {"time": 4.0, "effect": "hp_pool", "amount": 220.0, "stop": ["light"]}},
	"med_salewa": {"name": "Salewa first aid kit", "kind": "med", "w": 2, "h": 2, "kg": 0.5,
		"use": {"time": 5.0, "effect": "hp_pool", "amount": 400.0, "stop": ["light", "heavy"]}},
	"med_grizzly": {"name": "Grizzly medical kit", "kind": "med", "w": 3, "h": 2, "kg": 1.2,
		"use": {"time": 8.0, "effect": "hp_pool", "amount": 1800.0, "stop": ["light", "heavy"], "all_wounds": true}},
	"med_analgin": {"name": "Analgin painkillers", "kind": "med", "w": 1, "h": 1, "kg": 0.05,
		"use": {"time": 1.0, "effect": "pain_off", "dur": 95.0, "uses": 4}},
	"med_morphine": {"name": "Morphine syrette", "kind": "med", "w": 1, "h": 1, "kg": 0.1,
		"use": {"time": 2.0, "effect": "pain_off", "dur": 300.0, "dehydration": 0.3}},
	"med_propital": {"name": "Propital RG stimulant", "kind": "med", "w": 1, "h": 1, "kg": 0.1,
		"use": {"time": 3.0, "effect": "regen", "rate": 1.0, "dur": 300.0, "id": "med_propital"}},
	"med_sj6": {"name": "SJ6 TGLabs stim", "kind": "med", "w": 1, "h": 1, "kg": 0.1,
		"use": {"time": 2.0, "effect": "sj6"}},
	"med_adrenaline": {"name": "Adrenaline syrette", "kind": "med", "w": 1, "h": 1, "kg": 0.1,
		"use": {"time": 2.0, "effect": "adrenaline", "dehydration": 0.25}},
	"med_etgc": {"name": "eTG-c stim", "kind": "med", "w": 1, "h": 1, "kg": 0.15,
		"use": {"time": 3.0, "effect": "etgc"}},
	"med_iodine": {"name": "Iodine pills", "kind": "med", "w": 1, "h": 1, "kg": 0.05,
		"use": {"time": 1.0, "effect": "iodine"}},
	"med_water": {"name": "Water bottle", "kind": "med", "w": 1, "h": 2, "kg": 0.5,
		"use": {"time": 2.0, "effect": "hydrate", "amount": 0.5}},
	"med_juice": {"name": "Juice carton", "kind": "med", "w": 1, "h": 1, "kg": 0.3,
		"use": {"time": 2.0, "effect": "hydrate", "amount": 0.35, "energy": 0.2}},
	"med_crackers": {"name": "Crackers", "kind": "med", "w": 1, "h": 1, "kg": 0.1,
		"use": {"time": 2.0, "effect": "feed", "amount": 0.3, "dehydration": 0.1}},
	"med_mre": {"name": "MRE ration", "kind": "med", "w": 2, "h": 1, "kg": 0.5,
		"use": {"time": 4.0, "effect": "feed", "amount": 0.6, "dehydration": -0.2}},
	"med_stim": {"name": "Combat stim", "kind": "med", "w": 1, "h": 1, "kg": 0.1,
		"use": {"time": 2.0, "effect": "stim", "dur": 20.0, "mult": 2.0}},
}

const ARMOR_SIZE := {"vest2": [3, 3, 1.5], "plate4": [3, 3, 6.0], "steel6": [2, 2, 3.5], "helmet3": [2, 2, 1.2]}

static var _uid := 0


## Keeps new uids above any loaded one.
static func note_uid(u: int) -> void:
	_uid = maxi(_uid, u)


static func has(id: String) -> bool:
	return ROWS.has(id) or WeaponDefs.ROWS.has(id) or TacAmmoDefs.ROWS.has(id) or ArmorDefs.ROWS.has(id) or AttachmentDefs.has(id)


static func of(id: String) -> Dictionary:
	if ROWS.has(id):
		var d: Dictionary = ROWS[id].duplicate()
		d["id"] = id
		if d["kind"] == "mag":
			d["cal"] = WeaponDefs.of(d["gun"])["cal"]
			d["cap"] = WeaponDefs.of(d["gun"])["mag"]
		return d
	if WeaponDefs.ROWS.has(id):
		var w := WeaponDefs.of(id)
		return {"id": id, "name": w["name"], "kind": "gun", "w": w["inv_w"], "h": w["inv_h"], "kg": w["kg"],
			"pistol": w["class"] == "pistol", "cal": w["cal"]}
	if TacAmmoDefs.ROWS.has(id):
		var a := TacAmmoDefs.of(id)
		return {"id": id, "name": a["name"], "kind": "ammo", "w": 1, "h": 1, "kg": ROUND_KG[a["cal"]], "cal": a["cal"],
			"stack": STACK_MAX[a["cal"]]}
	if AttachmentDefs.has(id):
		var a: Dictionary = AttachmentDefs.ROWS[id]
		return {"id": id, "name": a["name"], "kind": "attach", "w": a["w"], "h": a["h"], "kg": a["kg"], "slot": a["slot"]}
	var r := ArmorDefs.of(id)
	var s: Array = ARMOR_SIZE[id]
	return {"id": id, "name": r["name"], "kind": "armor", "w": s[0], "h": s[1], "kg": s[2]}


## A fresh item instance. opts: count (ammo), rounds + ammo (mags), rot, gun (a Gun).
static func make(id: String, opts: Dictionary = {}) -> Dictionary:
	_uid += 1
	var d := of(id)
	var it := {"id": id, "uid": _uid, "rot": int(opts.get("rot", 0)), "loc": "", "x": 0, "y": 0}
	match d["kind"]:
		"ammo":
			it["count"] = int(opts.get("count", d["stack"]))
		"mag":
			var cal_grade: String = TacAmmoDefs.grades(d["cal"])[0]
			it["ammo"] = str(opts.get("ammo", cal_grade))
			it["rounds"] = int(opts.get("rounds", d["cap"]))
		"gun":
			it["gun"] = opts.get("gun", Gun.new(id))
		"rig", "backpack":
			it["items"] = []
		"med":
			if d.get("use", {}).has("uses"):
				it["uses"] = int(d["use"]["uses"])
	return it


static func def_of(item: Dictionary) -> Dictionary:
	return of(item["id"])


## Item weight including mag rounds, stack count and bag contents.
static func item_kg(item: Dictionary) -> float:
	var d := of(item["id"])
	var kg: float = d["kg"]
	match d["kind"]:
		"ammo":
			kg *= int(item["count"])
		"mag":
			kg += int(item["rounds"]) * ROUND_KG[d["cal"]]
		"rig", "backpack":
			for sub in item["items"]:
				kg += item_kg(sub)
		"gun":
			for id in (item["gun"] as Gun).fit.values():
				kg += float(AttachmentDefs.ROWS[id]["kg"])
	return kg


static func label(item: Dictionary) -> String:
	var d := of(item["id"])
	match d["kind"]:
		"ammo":
			return "%s x%d" % [d["name"], int(item["count"])]
		"mag":
			return "%s (%d/%d %s)" % [d["name"], int(item["rounds"]), maxi(int(d["cap"]), int(item["rounds"])), TacAmmoDefs.of(item["ammo"])["name"]]
	return d["name"]
