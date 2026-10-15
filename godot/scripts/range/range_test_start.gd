class_name RangeTestStart
## F46: the gun selected by PlayerWeapons.setup (before the viewmodel connects) must already be drawn once the viewmodel is set up.


static func run(t: RangeTest) -> void:
	var r := RangeTestAttach._rig(t)
	var w: PlayerWeapons = r["w"]
	var vm: TacticalViewmodel = r["vm"]
	t.check("start gun: weapons hold a gun after setup", w.gun != null)
	t.check("start gun: viewmodel built a model for it", w.gun != null and vm.model != null)
