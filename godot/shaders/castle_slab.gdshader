// Roof slabs over castle interiors: the castle ashlar look from
// terrain_look.gdshaderinc (stone kind 0.33): flagstones on tops, ashlar courses on
// edges. World-space, no UVs, so it grades exactly like the terrain walls.
// Undersides (wn.y < -0.5) get flagstones darkened by underside_dark.
shader_type spatial;
render_mode cull_back;

#include "res://shaders/noise.gdshaderinc"
#include "res://shaders/terrain_look.gdshaderinc"

uniform vec3 base_color : source_color = vec3(0.502, 0.541, 0.439); // StrongholdMeshes.DECOR_STONE
uniform float underside_dark = 0.55;
uniform float bump_strength = 0.05;

varying vec3 wpos;
varying vec3 wnrm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize(mat3(MODEL_MATRIX) * NORMAL);
}

void fragment() {
	vec3 wn = normalize(wnrm);
	float bump;
	float cliff;
	if (wn.y < -0.5) {
		cliff = 0.0; // flagstones on the underside
	} else {
		cliff = smoothstep(0.22, 0.5, 1.0 - clamp(wn.y, 0.0, 1.0)); // same slope rule as ground_look
	}
	vec3 c = castle_stone(base_color, wpos, wn, cliff, bump);
	if (wn.y < -0.5) {
		c *= underside_dark;
	}
	ALBEDO = c;
	ROUGHNESS = 0.92;
	SPECULAR = 0.2;
	NORMAL = normalize((VIEW_MATRIX * vec4(bumped(wn, wpos, bump, bump_strength), 0.0)).xyz);
}
