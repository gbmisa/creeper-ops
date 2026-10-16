class_name RangeTestPkmSight
## F76: at full ADS the PKM front post tip is centred in the notch and level with the rear shoulder tops (0.141). Points are the PKM mesh's own (rear block top 0.136, ears 0.141, post tip 0.136, x -0.001).


static func run(t: RangeTest, r: Dictionary) -> void:
	var w: PlayerWeapons = r["w"]
	var vm: TacticalViewmodel = r["vm"]
	var cam: Camera3D = (r["player"] as TacticalPlayer).cam
	RangeTestAttach._equip(r, "pkm")
	RangeTestAds._snap_ads(w, vm)
	var k := 900.0 / cam.get_viewport().get_visible_rect().size.y  # report in 1600x900 pixels
	var px := func(p: Vector3) -> Vector2: return cam.unproject_position(vm.model.global_transform * p) * k
	var tip: Vector2 = px.call(Vector3(-0.001, 0.136, -0.51))
	var block: Vector2 = px.call(Vector3(-0.001, 0.136, -0.059))
	var ear: Vector2 = px.call(Vector3(-0.009, 0.141, -0.059))
	var dx := tip.x - block.x
	var flush := tip.y - ear.y
	print("[range] pkm ads px: post tip ", tip, " shoulder top ", ear, " offset x ", dx, " tip minus shoulder y ", flush)
	t.check("pkm ads: post tip centred in the notch (|dx| %.2f px)" % dx, absf(dx) < 1.0)
	t.check("pkm ads: post tip level with the rear shoulder tops (%.2f px, limit 1)" % flush, absf(flush) <= 1.0)
