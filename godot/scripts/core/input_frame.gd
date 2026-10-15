class_name InputFrame
extends RefCounted
## Plain-data input snapshot for one frame (MULTIPLAYER.md rule 3). Produced by InputState.snap()
## at the start of each frame; gameplay reads only this, never Input.* directly, so the server
## can run a remote player from received frames. `seq` orders frames for the network.

var seq := 0
var _pressed := {}  # action id -> true (pressed this frame)
var _held := {}  # action id -> true (held now)
var mouse := Vector2.ZERO
var mouse_delta := Vector2.ZERO
var left := false
var left_pressed := false
var left_released := false
var right := false
var right_clicked := false
var wheel := 0.0
var shift := false
var captured := false  # mouse captured: look input applies


## Rebindable action pressed this frame (see Keybinds).
func act(id: String) -> bool:
	return _pressed.has(id)


## Rebindable action held down.
func held(id: String) -> bool:
	return _held.has(id)
