class_name HoldBar
extends Control
## Thin hold-to-confirm progress bar for first person: "RECALL [R]" fills while R is
## held, "BUILD WHEEL [B]" fills over the wheel's hold threshold, "SALVAGE [E]"
## fills while E is held on a hold interactable. On completion the bar flashes full
## briefly, then hides; releasing early hides it immediately (the underlying logic
## resets its own progress). Bottom-centre of the FPS HUD, above the status line.

var _label: Label
var _bar: ProgressBar
var _flash_t := 0.0

const FLASH_SECS := 0.3


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 1.0
	anchor_bottom = 1.0
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	offset_left = -140
	offset_right = 140
	offset_top = -238
	offset_bottom = -206
	visible = false
	var box := UiKit.vbox(2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	_label = UiKit.label("", 13, UiKit.WARN)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_label)
	_bar = UiKit.bar(280, 10, UiKit.WARN)
	_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(_bar)


## Show/update the bar. frac in [0, 1]; frac >= 1 starts the completion flash.
func show_hold(label: String, frac: float) -> void:
	if _flash_t > 0.0:
		return
	visible = true
	_label.text = label
	_bar.value = clampf(frac, 0.0, 1.0)
	if frac >= 1.0:
		_flash_t = FLASH_SECS


## Hide immediately (early release). Ignored while the completion flash plays.
func hide_hold() -> void:
	if _flash_t > 0.0:
		return
	visible = false


func _process(dt: float) -> void:
	if _flash_t > 0.0:
		_flash_t -= dt
		_bar.value = 1.0
		modulate.a = 0.6 + 0.4 * absf(sin(_flash_t * 30.0))
		if _flash_t <= 0.0:
			visible = false
			modulate.a = 1.0
