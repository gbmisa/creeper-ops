class_name RangeTestPkmSight
## F76: at full ADS the PKM front post tip is centred on the rear sight's middle block and shows above its top edge,
## below the rear ears' tops. Points are the PKM mesh's own (rear block top 0.136, ears 0.141, post tip 0.136, x -0.001).


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
	var above := block.y - tip.y
	var room := block.y - ear.y
	print("[range] pkm ads px: post tip ", tip, " block top ", block, " ear top ", ear, " offset x ", dx, " above block ", above)
	t.check("pkm ads: post tip centred on the middle block (|dx| %.2f px)" % dx, absf(dx) < 1.0)
	t.check("pkm ads: post tip shows above the block top (%.1f px) and under the ear tops (%.1f px)" % [above, room],
		above >= 3.0 and above < room)
