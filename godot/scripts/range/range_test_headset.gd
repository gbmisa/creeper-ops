class_name RangeTestHeadset
## F134: the headset slot takes only headsets, survives to_dict / from_dict, and the volume mods follow the slot.


static func run(t: RangeTest) -> void:
	var inv := Inventory.new()
	var hs := inv.make("headset_comtac")
	t.check("f134: headset fits the headset slot", inv.accepts_slot("headset", hs))
	t.check("f134: helmet / med do not fit the headset slot", not inv.accepts_slot("headset", inv.make("helmet3")) and not inv.accepts_slot("headset", inv.make("med_ifak")))
	t.check("f134: headset does not fit the helmet slot", not inv.accepts_slot("helmet", hs))
	inv.place(inv.make("helmet3"), "helmet")
	inv.place(hs, "headset")
	t.check("f134: worn with a helmet", inv.equipped("helmet") != null and inv.equipped("headset") != null)
	var back := Inventory.from_dict(inv.to_dict())
	t.check("f134: headset survives to_dict / from_dict", back.equipped("headset") != null and back.equipped("headset")["id"] == "headset_comtac")
	var saved := HearingMods.inv
	HearingMods.inv = Inventory.new()
	var off := [HearingMods.step_db(), HearingMods.step_range(), HearingMods.quiet_db(), HearingMods.loud_db()]
	HearingMods.inv = inv
	t.check("f134: mods off without the headset", off == [0.0, 1.0, 0.0, 0.0])
	t.check("f134: mods on with the headset", HearingMods.step_db() == 8.0 and HearingMods.step_range() == 1.5 and HearingMods.quiet_db() == 4.0 and HearingMods.loud_db() == -8.0)
	HearingMods.inv = saved
