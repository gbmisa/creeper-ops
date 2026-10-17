class_name BugReport
extends PanelContainer
## Esc menu > Report a bug: record a voice note from the microphone, type a note, Save. Each report is a folder
## user://reports/<time>/ with voice.wav, note.txt, screenshot.png (the frame before the menu opened), godot.log and
## info.txt (build, map, gun, position, GPU). "Open reports folder" shows them so the tester can zip and send them.
## Needs audio/driver/enable_input (project.godot). Works while the tree is paused (the Esc menu pauses it).

signal closed

const DIR := "user://reports"
const BUS := "BugReportMic"

var shot: Image   # set by RangeMenu.open() before the menu draws
var context := {}  # map / gun / pos, set by RangeMenu
var _rec: AudioEffectRecord
var _mic: AudioStreamPlayer
var _voice: AudioStreamWAV
var _rec_btn: Button
var _status: Label
var _note: TextEdit


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	add_theme_stylebox_override("panel", UiKit.style(Color(0.05, 0.06, 0.08, 0.97)))
	custom_minimum_size = Vector2(420, 0)
	var col := VBoxContainer.new()
	add_child(col)
	col.add_child(UiKit.label("REPORT A BUG", 20))
	col.add_child(UiKit.label("Say what happened and what you were doing.", 13, UiKit.DIM))
	_rec_btn = UiKit.button("Start recording", _toggle_rec)
	col.add_child(_rec_btn)
	_note = TextEdit.new()
	_note.placeholder_text = "Or type it here (optional)"
	_note.custom_minimum_size = Vector2(400, 90)
	_note.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	col.add_child(_note)
	_status = UiKit.label("", 13, UiKit.ACCENT_HI)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(400, 0)
	col.add_child(_status)
	col.add_child(UiKit.button("Save report", _save))
	col.add_child(UiKit.button("Open reports folder", func(): OS.shell_open(ProjectSettings.globalize_path(DIR))))
	col.add_child(UiKit.button("Close", close))


func open() -> void:
	visible = true
	_voice = null
	_note.text = ""
	_status.text = ""


func close() -> void:
	if _rec != null and _rec.is_recording_active():
		_toggle_rec()
	visible = false
	closed.emit()


func _toggle_rec() -> void:
	_ensure_mic()
	if _rec.is_recording_active():
		_rec.set_recording_active(false)
		_mic.stop()
		_voice = _rec.get_recording()
		_rec_btn.text = "Record again"
		_status.text = "Recorded %.0f s. Press Save report." % (_voice.get_length() if _voice != null else 0.0)
	else:
		_mic.play()
		_rec.set_recording_active(true)
		_rec_btn.text = "Stop recording"
		_status.text = "Recording... speak now."


## A muted bus carrying the microphone into an AudioEffectRecord (muted: you don't hear yourself).
func _ensure_mic() -> void:
	if _rec != null:
		return
	var idx := AudioServer.get_bus_index(BUS)
	if idx < 0:
		idx = AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, BUS)
		AudioServer.set_bus_mute(idx, true)
		AudioServer.add_bus_effect(idx, AudioEffectRecord.new())
	_rec = AudioServer.get_bus_effect(idx, 0) as AudioEffectRecord
	_mic = AudioStreamPlayer.new()
	_mic.stream = AudioStreamMicrophone.new()
	_mic.bus = BUS
	_mic.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_mic)


func _save() -> void:
	if _rec != null and _rec.is_recording_active():
		_toggle_rec()
	var dir := "%s/%s" % [DIR, Time.get_datetime_string_from_system().replace(":", "-")]
	DirAccess.make_dir_recursive_absolute(dir)
	if _voice != null:
		_voice.save_to_wav(dir + "/voice.wav")
	if _note.text.strip_edges() != "":
		_write(dir + "/note.txt", _note.text)
	if shot != null:
		shot.save_png(dir + "/screenshot.png")
	_write(dir + "/info.txt", info_text(context))
	var log_path := "user://logs/godot.log"
	if FileAccess.file_exists(log_path):
		_write(dir + "/godot.log", FileAccess.get_file_as_string(log_path))
	_status.text = "Saved. Press Open reports folder, zip the newest folder and send it.\n%s" % ProjectSettings.globalize_path(dir)
	print("[bug report] saved ", ProjectSettings.globalize_path(dir))


static func info_text(ctx: Dictionary) -> String:
	var lines := ["build: " + build_id(), "time: " + Time.get_datetime_string_from_system(),
		"os: %s %s" % [OS.get_name(), OS.get_version()], "gpu: " + RenderingServer.get_video_adapter_name(),
		"driver: " + RenderingServer.get_current_rendering_driver_name(),
		"window: %s" % str(DisplayServer.window_get_size())]
	for k in ctx:
		lines.append("%s: %s" % [k, str(ctx[k])])
	return "\n".join(lines) + "\n"


## Git commit + date written by tools/export_windows.sh into res://export_data/build.txt; "dev" when run from source.
static func build_id() -> String:
	var p := "res://export_data/build.txt"
	return FileAccess.get_file_as_string(p).strip_edges() if FileAccess.file_exists(p) else "dev"


static func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(text)
