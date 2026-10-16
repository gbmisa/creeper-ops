class_name InputState
extends Node
## Per-frame input snapshot. Rebindable actions: act()/held() (Keybinds); raw keys:
## was_pressed()/down() (only Esc uses these). Mouse buttons come through
## _unhandled_input, so clicks on HUD controls never reach the world. Call end_frame() after
## the game has consumed the frame.

var _pressed := {}
var mouse := Vector2.ZERO
var mouse_delta := Vector2.ZERO
var left := false
var left_pressed := false
var left_released := false
var right_clicked := false
var down_pos := Vector2.ZERO
var wheel := 0.0
var shift := false
## Set by the HUD when a key it handles (e.g. menu hotkeys) should not reach the game.
var on_key: Callable = Callable()
## Latest input snapshot for gameplay (MULTIPLAYER.md rule 3). Snapped in _process before
## gameplay runs; gameplay reads frame, never Input.* directly.
var frame := InputFrame.new()
var right := false  # right mouse held
var _seq := 0


func _ready() -> void:
	process_priority = -100  # snap before gameplay
	process_mode = Node.PROCESS_MODE_ALWAYS  # FB-B: mouse releases must land while the pause menu is open


func _process(_delta: float) -> void:
	frame = snap()


## Plain-data snapshot of this frame's input for gameplay (or the network, in MP-2).
func snap() -> InputFrame:
	var f := InputFrame.new()
	f.seq = _seq
	_seq += 1
	for id in Keybinds.action_ids():
		if act(id):
			f._pressed[id] = true
		if held(id):
			f._held[id] = true
	f.mouse = mouse
	f.mouse_delta = mouse_delta
	f.left = left
	f.left_pressed = left_pressed
	f.left_released = left_released
	f.right = right
	f.right_clicked = right_clicked
	f.wheel = wheel
	f.shift = shift
	f.captured = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	return f


func _input(e: InputEvent) -> void:
	if get_tree().paused:  # paused: only button releases, so held fire/aim end; nothing else queues up
		if e is InputEventMouseButton and not e.pressed:
			if e.button_index == MOUSE_BUTTON_LEFT and left:
				left = false
				left_released = true
			elif e.button_index == MOUSE_BUTTON_RIGHT:
				right = false
		return
	if e is InputEventKey and e.pressed and not e.echo:
		_pressed[e.physical_keycode] = true
		if on_key.is_valid():
			on_key.call(e.physical_keycode)
	elif e is InputEventMouseMotion:
		mouse = e.position
		mouse_delta += e.relative
	elif e is InputEventMouseButton and not e.pressed and e.button_index == MOUSE_BUTTON_LEFT and left:
		left = false
		left_released = true  # release counts even over UI so drags always end


func _unhandled_input(e: InputEvent) -> void:
	if get_tree().paused:
		return
	if e is InputEventMouseButton:
		mouse = e.position
		match e.button_index:
			MOUSE_BUTTON_LEFT:
				if e.pressed:
					left = true
					left_pressed = true
					down_pos = e.position
			MOUSE_BUTTON_RIGHT:
				if e.pressed:
					right = true
					right_clicked = true
				else:
					right = false
			MOUSE_BUTTON_WHEEL_UP:
				if e.ctrl_pressed:  # Ctrl + wheel switches ammo; it does not also zoom or scroll
					_pressed[Keybinds.CTRL_WHEEL_UP] = true
				else:
					wheel -= 1.0
			MOUSE_BUTTON_WHEEL_DOWN:
				if e.ctrl_pressed:
					_pressed[Keybinds.CTRL_WHEEL_DOWN] = true
				else:
					wheel += 1.0


func was_pressed(key: Key) -> bool:
	return _pressed.has(key)


func down(key: Key) -> bool:
	return Input.is_physical_key_pressed(key)


## Rebindable action pressed this frame (see Keybinds).
func act(id: String) -> bool:
	return Keybinds.keys(id).any(func(k): return _pressed.has(k))


## Rebindable action held down.
func held(id: String) -> bool:
	return Keybinds.keys(id).any(func(k): return Input.is_physical_key_pressed(k))


func end_frame() -> void:
	_pressed.clear()
	mouse_delta = Vector2.ZERO
	left_pressed = false
	left_released = false
	right_clicked = false
	wheel = 0.0
	shift = Input.is_physical_key_pressed(KEY_SHIFT)
