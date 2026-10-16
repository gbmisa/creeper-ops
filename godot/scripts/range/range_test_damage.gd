class_name RangeTestDamage
## P10 / P12 / P13: worn armor protects the player like a bot's, player head damage x0.5, blacked legs slow.


static func run(t: RangeTest) -> void:
	var weak := {"dmg": 40.0, "pen": 5.0, "armor_dmg": 20.0, "glance": 90.0}
	var bot := BodyHealth.new()
	bot.equip("helmet3")
	var rb := bot.shoot("head", weak)
	var inv := Inventory.new(IdSource.new())
	inv.place(inv.make("helmet3"), "helmet")
	var me := BodyHealth.new()
	WornArmor.sync(inv, me)
	var rp := me.shoot("head", weak)
	t.check("P12: player helmet stops a round a bot helmet stops",
		rb["result"] == "BLOCKED" and rp["result"] == "BLOCKED" and absf(rb["armor_dur"] - rp["armor_dur"]) < 0.01 and inv.slots["helmet"]["uid"] > 0)
	WornArmor.sync(inv, me)
	t.check("P12: durability goes back onto the item", absf(inv.slots["helmet"]["dur"] - me.armor["head"]["dur"]) < 0.01 and inv.slots["helmet"]["dur"] < 30.0)
	inv.remove(inv.slots["helmet"])
	WornArmor.sync(inv, me)
	t.check("P12: removing the helmet removes the protection", not me.armor.has("head"))
	var strong := {"dmg": 40.0, "pen": 90.0, "armor_dmg": 0.0, "glance": 90.0, "lbleed": 0.0, "hbleed": 0.0}
	var a := BodyHealth.new()
	var b := BodyHealth.new()
	b.head_mult = TacticalConfig.PLAYER_HEAD_MULT
	var da: float = a.shoot("head", strong)["dmg"]
	var db: float = b.shoot("head", strong)["dmg"]
	t.check("P13: player head takes x0.5, other zones and bots unchanged", absf(db - da * 0.5) < 0.01 and b.shoot("thorax", strong)["dmg"] == a.shoot("thorax", strong)["dmg"])
	var legs := BodyHealth.new()
	var one := 1.0 == legs.move_mult()
	legs.hit("lleg", 999.0)
	var l1 := legs.move_mult()
	legs.hit("rleg", 999.0)
	t.check("P10: a blacked leg = x0.6, two legs do not stack", one and l1 == TacticalConfig.LEG_BLACKED_SPEED and legs.move_mult() == l1)
