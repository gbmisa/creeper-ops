class_name Levels
## Level selection. `selected` survives scene reloads (the briefing buttons set it and reload);
## `--level=N` on the command line sets it once at start. Level 1 stays the default.

const NAMES := ["Hollow Ridge", "The Crown Marches"]

static var selected := 0  # 0 = not chosen yet


static func current() -> int:
	if selected == 0:
		selected = 1
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--level="):
				selected = clampi(int(a.trim_prefix("--level=")), 1, NAMES.size())
	return selected


static func build(n: int) -> Dictionary:
	return Level02.build() if n == 2 else Level01.build()


static func cave(_n: int) -> Dictionary:
	return Cave01.build()  # both levels descend into the same Rift for now
