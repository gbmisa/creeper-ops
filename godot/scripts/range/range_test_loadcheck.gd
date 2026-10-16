class_name RangeTestLoadCheck
extends RefCounted
## A script that fails to compile must FAIL the run (it used to be skipped silently, or hang the harness).
## Static and independent of RangeTest, so it still works when RangeTest itself cannot compile.


## Paths of every .gd under `dir` that fails to load or compile.
static func broken(dir := "res://scripts") -> Array:
	var bad: Array = []
	for path in _scripts(dir):
		var s := load(path) as GDScript
		if s == null or not s.can_instantiate():
			bad.append(path)
	return bad


static func _scripts(dir: String) -> Array:
	var out: Array = []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		out.append_array(_scripts(dir.path_join(d)))
	return out
