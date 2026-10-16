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
const GROUPS := ["Global", "Command", "Operative", "Tactical"]

## id -> [group, label, default physical keycodes]
const DEFAULTS := {
	"mute": ["Global", "Mute sound", [KEY_F9]],
	"keybinds": ["Global", "Controls menu", [KEY_F10]],
	"objectives_toggle": ["Global", "Expand objectives", [KEY_J]],
	"test_recall": ["Global", "Test: recall now (no cooldown)", [KEY_F8]],
	"ammo_next": ["Global", "Next ammo grade", [CTRL_WHEEL_DOWN]],
	"ammo_prev": ["Global", "Previous ammo grade", [CTRL_WHEEL_UP]],
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
	"teleport": ["Command", "Deploy Operative (Totem, else Command Node)", [KEY_T]],
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
	"supply": ["Command", "Deactivate / activate", [KEY_Z]],
	"hold_fire": ["Command", "Toggle hold fire", [KEY_V]],
	"train_soldier": ["Command", "Train Soldier", [KEY_F]],
	"train_crawler": ["Command", "Train Crawler", [KEY_G]],
	"select_units": ["Command", "Select all units", [KEY_U]],
	"patrol": ["Command", "Patrol: click points, press again or right-click to finish", [KEY_P]],
	"terp_up": ["Command", "Terp target up", [KEY_PAGEUP]],
	"terp_down": ["Command", "Terp target down", [KEY_PAGEDOWN]],
	"terp_erase": ["Command", "Erase terp paint (hold)", [KEY_C]],
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
	"crossbow": ["Operative", "Crossbow", [KEY_Y]],
	"adv_demo": ["Operative", "Demolition Charge", [KEY_6]],
	"use": ["Operative", "Use / capture", [KEY_E]],
	"recall": ["Operative", "Recall (hold)", [KEY_R]],
	"op_build": ["Operative", "Build mode (first person)", [KEY_B]],
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
	"t_inspect": ["Tactical", "Inspect / fix malfunction", [KEY_L]],
	"t_zero_up": ["Tactical", "Zero distance up", [KEY_PAGEUP]],
	"t_zero_down": ["Tactical", "Zero distance down", [KEY_PAGEDOWN]],
	"t_use": ["Tactical", "Use / take / cycle at bench", [KEY_F]],
	"t_crosshair": ["Tactical", "Toggle hip-fire cone dot", [KEY_X]],
	"t_help": ["Tactical", "Toggle help", [KEY_H]],
	"t_recoil_panel": ["Tactical", "Recoil tuning panel (range)", [KEY_F7]],
	"t_slot_1": ["Tactical", "Weapon slot 1", [KEY_1]],
	"t_slot_2": ["Tactical", "Weapon slot 2", [KEY_2]],
	"t_slot_3": ["Tactical", "Weapon slot 3", [KEY_3]],
	"t_slot_4": ["Tactical", "Weapon slot 4", [KEY_4]],
	"t_slot_5": ["Tactical", "Weapon slot 5", [KEY_5]],
	"t_slot_6": ["Tactical", "Weapon slot 6", [KEY_6]],
	"inventory": ["Tactical", "Open / close inventory", [KEY_TAB]],
	"drop": ["Tactical", "Drop the gun in hand", [KEY_G]],
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
