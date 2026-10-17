class_name Keybinds
## Rebindable keys. DEFAULTS is the shipped layout. The player's changes are saved to
## user://keybinds.cfg, which lives outside the game folder, so game updates never overwrite
## them. Only actions the player changed are stored: a new action added in a later update
## gets its default, and every action the player rebound keeps the player's key.
## Esc is fixed (cancel / pause / close menus) and can't be rebound.

const PATH := "user://keybinds.cfg"
## Mouse-wheel chords share the keycode lists as pseudo keycodes above any real key (InputState
## presses them when the wheel turns with Ctrl held). They are never read from the keyboard.
const CTRL_WHEEL_UP := 0x7A000001
const CTRL_WHEEL_DOWN := 0x7A000002
const SLOTS := 2  # keys per action: primary, alternate
const GROUPS := ["Tactical"]

## id -> [group, label, default physical keycodes]
const DEFAULTS := {
	"t_forward": ["Tactical", "Move forward", [KEY_W]],
	"t_back": ["Tactical", "Move back", [KEY_S]],
	"t_left": ["Tactical", "Strafe left", [KEY_A]],
	"t_right": ["Tactical", "Strafe right", [KEY_D]],
	"t_sprint": ["Tactical", "Sprint / hold breath in ADS", [KEY_SHIFT]],
	"t_jump": ["Tactical", "Jump", [KEY_SPACE]],
	"t_crouch": ["Tactical", "Crouch", [KEY_C]],
	"t_lean_left": ["Tactical", "Lean left", [KEY_Q]],
	"t_lean_right": ["Tactical", "Lean right", [KEY_E]],
	"t_reload": ["Tactical", "Reload (double-tap: fast, drops mag)", [KEY_R]],
	"t_zoom": ["Tactical", "Variable sight zoom", [KEY_N]],
	"t_fire_mode": ["Tactical", "Fire mode", [KEY_B]],
	"t_mag_check": ["Tactical", "Check magazine", [KEY_T]],
	"t_zero_up": ["Tactical", "Zero distance up", [KEY_PAGEUP]],
	"t_zero_down": ["Tactical", "Zero distance down", [KEY_PAGEDOWN]],
	"t_use": ["Tactical", "Use / take / cycle at bench", [KEY_F]],
	"t_crosshair": ["Tactical", "Toggle hip-fire cone dot", [KEY_X]],
	"t_help": ["Tactical", "Toggle help", [KEY_H]],
	"t_recoil_panel": ["Tactical", "Recoil tuning panel (range)", [KEY_F7]],
	"t_slot_1": ["Tactical", "Weapon slot 1", [KEY_1]],
	"t_slot_2": ["Tactical", "Weapon slot 2", [KEY_2]],
	"t_slot_3": ["Tactical", "Weapon slot 3", [KEY_3]],
	"t_slot_4": ["Tactical", "Quick use 1 (IFAK)", [KEY_4]],
	"t_slot_5": ["Tactical", "Quick use 2 (bandage)", [KEY_5]],
	"t_slot_6": ["Tactical", "Weapon slot 6", [KEY_6]],
	"inventory": ["Tactical", "Open / close inventory", [KEY_TAB]],
	"drop": ["Tactical", "Drop the gun in hand", [KEY_G]],
	"med_quick_1": ["Tactical", "Quick-use 1st med (rig/pockets)", [KEY_F5]],
	"med_quick_2": ["Tactical", "Quick-use 2nd med (rig/pockets)", [KEY_F6]],
	"med_quick_3": ["Tactical", "Quick-use 3rd med (rig/pockets)", [KEY_7]],
	"med_quick_4": ["Tactical", "Quick-use 4th med (rig/pockets)", [KEY_0]],
	"t_util_1": ["Tactical", "Use utility slot 1", [KEY_I]],
	"t_util_2": ["Tactical", "Use utility slot 2", [KEY_O]],
	"t_perf": ["Tactical", "Performance metrics", [KEY_F3]],
	"t_deploy_large": ["Tactical", "Deploy to Skirmish (large) at the truck", [KEY_L]],
}

## Hidden chords (physical keycode | modifier mask): never listed, never rebindable, never in the cfg file.
const HIDDEN := {
	"secret_tempest": [KEY_P | KEY_MASK_CTRL | KEY_MASK_ALT],
	"cheat_menu": [KEY_KP_5 | KEY_MASK_CTRL],
}

static var _map := {}  # id -> Array[int] (current keys)
static var _loaded := false
static var persist := true  # tests turn this off so they never touch the player's file


static func keys(id: String) -> Array:
	if not _loaded:
		load_binds()
	return _map.get(id, [])


## All rebindable action ids (for InputState.snap()).
static func action_ids() -> Array:
	return DEFAULTS.keys()


static func matches(id: String, keycode: int) -> bool:
	return keys(id).has(keycode)


static func group(id: String) -> String:
	return DEFAULTS[id][0]


static func label(id: String) -> String:
	return DEFAULTS[id][1]


## "W / Up" style text for hints and menus.
static func text(id: String) -> String:
	var names := keys(id).map(func(k): return key_name(k))
	return " / ".join(PackedStringArray(names)) if not names.is_empty() else "unbound"


## Primary key only (compact hints).
## Swap "{action}" tokens in player text for the keys bound right now (const hints can't call short()).
static func fill(text: String) -> String:
	if not text.contains("{"):
		return text
	for id in DEFAULTS:
		text = text.replace("{%s}" % id, short(id))
	return text


static func short(id: String) -> String:
	var k := keys(id)
	return key_name(k[0]) if not k.is_empty() else "-"


## Display name of a bound key code, including the Ctrl + wheel chords.
static func key_name(k: int) -> String:
	if k == CTRL_WHEEL_UP:
		return "Ctrl+Wheel Up"
	if k == CTRL_WHEEL_DOWN:
		return "Ctrl+Wheel Down"
	return OS.get_keycode_string(k)


## Bind `keycode` to slot 0/1 of `id` (0 keycode clears the slot). Any other action in a
## clashing group loses that key. Returns the labels of the actions that lost it.
static func bind(id: String, slot: int, keycode: int) -> Array:
	var lost := []
	if keycode != 0:
		for other in DEFAULTS:
			if other != id and _clash(group(id), group(other)) and keys(other).has(keycode):
				_map[other].erase(keycode)
				lost.append(label(other))
	var k: Array = keys(id).duplicate()
	k.erase(keycode)
	if slot < k.size():
		k.remove_at(slot)
	if keycode != 0:
		k.insert(mini(slot, k.size()), keycode)
	_map[id] = k.slice(0, SLOTS)
	save()
	return lost


static func _clash(a: String, b: String) -> bool:
	return a == b or a == "Global" or b == "Global"


static func reset_all() -> void:
	_map = {}
	for id in DEFAULTS:
		_map[id] = (DEFAULTS[id][2] as Array).duplicate()
	_loaded = true
	save()


static func load_binds() -> void:
	_loaded = true
	_map = {}
	for id in DEFAULTS:
		_map[id] = (DEFAULTS[id][2] as Array).duplicate()
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	for id in (cfg.get_section_keys("binds") if cfg.has_section("binds") else PackedStringArray()):
		if DEFAULTS.has(id):  # actions removed in an update are ignored
			_map[id] = Array(cfg.get_value("binds", id, [])).filter(func(k): return k is int and k != 0)


## Writes only the actions that differ from the shipped defaults.
static func save() -> void:
	if not persist:
		return
	var cfg := ConfigFile.new()
	for id in DEFAULTS:
		if keys(id) != DEFAULTS[id][2]:
			cfg.set_value("binds", id, keys(id))
	cfg.save(PATH)
