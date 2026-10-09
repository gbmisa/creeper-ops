class_name AntiCreeperMesh
extends CreeperMesh
## Anti-creeper surface: the same lattice and shader as the creeper mesh, with a teal color
## ramp. Anti-creeper is simulated on the CPU even when creeper runs on the GPU, so this
## mesh always uploads its textures per tick. It sits a hair above the creeper lattice so
## the two never z-fight where they briefly coexist.

func _init() -> void:
	position.y = 0.02


func _fluid_colors() -> Dictionary:
	return {
		"shallow": Color(0.06, 0.5, 0.48),
		"deep": Color(0.004, 0.035, 0.045),
		"glow": Color(0.12, 0.95, 0.85),
		"sheen": Color(0.5, 0.95, 0.88),
	}


func _fluid_field() -> PackedFloat32Array:
	return sim.anti


func _wants_gpu_tex() -> bool:
	return false
