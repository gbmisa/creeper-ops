class_name Keybinds
## Rebindable keys. DEFAULTS is the shipped layout. The player's changes are saved to
## user://keybinds.cfg, which lives outside the game folder, so game updates never overwrite
## them. Only actions the player changed are stored: a new action added in a later update
## gets its default, and every action the player rebound keeps the player's key.
## Esc is fixed (cancel / pause / close menus) and can't be rebound.

const PATH := "user://keybinds.cfg"
const SLOTS := 2  # keys per action: primary, alternate
const GROUPS := ["Global", "Command", "Operative"]

## id -> [group, label, default physical keycodes]
const DEFAULTS := {
	"mute": ["Global", "Mute sound", [KEY_F9]],
	"keybinds": ["Global", "Controls menu", [KEY_F10]],
	"test_recall": ["Global", "Test: recall now (no cooldown)", [KEY_F8]],
	"cam_forward": ["Command", "Camera forward", [KEY_W, KEY_UP]],
	"cam_back": ["Command", "Camera back", [KEY_S, KEY_DOWN]],
	"cam_left": ["Command", "Camera left", [KEY_A, KEY_LEFT]],
	"cam_right": ["Command", "Camera right", [KEY_D, KEY_RIGHT]],
	"cam_rot_left": ["Command", "Rotate camera left", [KEY_Q]],
	"cam_rot_right": ["Command", "Rotate camera right", [KEY_E]],
	"cam_home": ["Command", "Camera to Command Node", [KEY_H]],
	"pause": ["Command", "Pause", [KEY_SPACE]],
	"speed_up": ["Command", "Game speed up", [KEY_EQUAL, KEY_KP_ADD]],
	"speed_down": ["Command", "Game speed down", [KEY_MINUS, KEY_KP_SUBTRACT]],
	"teleport": ["Command", "Deploy Operative", [KEY_T]],
	"tab_1": ["Command", "Build tab: Structures", [KEY_F1]],
	"tab_2": ["Command", "Build tab: Weapons", [KEY_F2]],
	"tab_3": ["Command", "Build tab: Titans", [KEY_F3]],
	"tab_4": ["Command", "Build tab: Orbital", [KEY_F4]],
	"tab_5": ["Command", "Build tab: Castle", [KEY_F5]],
	"tab_next": ["Command", "Next build tab", [KEY_TAB]],
	"build_1": ["Command", "Build slot 1", [KEY_1]],
	"build_2": ["Command", "Build slot 2", [KEY_2]],
	"build_3": ["Command", "Build slot 3", [KEY_3]],
	"build_4": ["Command", "Build slot 4", [KEY_4]],
	"build_5": ["Command", "Build slot 5", [KEY_5]],
	"build_6": ["Command", "Build slot 6", [KEY_6]],
	"build_7": ["Command", "Build slot 7", [KEY_7]],
	"build_8": ["Command", "Build slot 8", [KEY_8]],
	"build_9": ["Command", "Build slot 9", [KEY_9]],
	"recycle": ["Command", "Recycle selected", [KEY_X, KEY_DELETE]],
	"move": ["Command", "Move selected", [KEY_M]],
	"supply": ["Command", "Toggle ammo supply", [KEY_Z]],
	"hold_fire": ["Command", "Toggle hold fire", [KEY_V]],
	"train_soldier": ["Command", "Train Soldier", [KEY_F]],
	"train_crawler": ["Command", "Train Crawler", [KEY_G]],
	"select_units": ["Command", "Select all units", [KEY_U]],
	"op_forward": ["Operative", "Move forward", [KEY_W]],
	"op_back": ["Operative", "Move back", [KEY_S]],
	"op_left": ["Operative", "Strafe left", [KEY_A]],
	"op_right": ["Operative", "Strafe right", [KEY_D]],
	"sprint": ["Operative", "Sprint", [KEY_SHIFT]],
	"jump": ["Operative", "Jump", [KEY_SPACE]],
	"rifle": ["Operative", "Pulse Rifle", [KEY_1]],
	"sprayer": ["Operative", "Null Sprayer", [KEY_2]],
	"rocket": ["Operative", "Rocket Launcher", [KEY_3]],
	"adv_railgun": ["Operative", "Railgun", [KEY_4]],
	"adv_plasma": ["Operative", "Plasma Thrower", [KEY_5]],
	"adv_demo": ["Operative", "Demolition Charge", [KEY_6]],
	"use": ["Operative", "Use / capture", [KEY_E]],
	"recall": ["Operative", "Recall (hold)", [KEY_R]],
	"op_build": ["Operative", "Build mode (first person)", [KEY_B]],
}

static var _map := {}  # id -> Array[int] (current keys)
static var _loaded := false
static var persist := true  # tests turn this off so they never touch the player's file


static func keys(id: String) -> Array:
	if not _loaded:
		load_binds()
	return _map.get(id, [])


static func matches(id: String, keycode: int) -> bool:
	return keys(id).has(keycode)


static func group(id: String) -> String:
	return DEFAULTS[id][0]


static func label(id: String) -> String:
	return DEFAULTS[id][1]


## "W / Up" style text for hints and menus.
static func text(id: String) -> String:
	var names := keys(id).map(func(k): return OS.get_keycode_string(k))
	return " / ".join(PackedStringArray(names)) if not names.is_empty() else "unbound"


## Primary key only (compact hints).
static func short(id: String) -> String:
	var k := keys(id)
	return OS.get_keycode_string(k[0]) if not k.is_empty() else "-"


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
