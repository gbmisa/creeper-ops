#[compute]
#version 450
// Creeper fluid automaton on the GPU (creeper_gpu.gd). Same rule as CreeperSim._flow() and
// CreeperMesh._build_surface(); keep them in step. One shader, four passes picked by pc.dims.z:
//   0 deltas   apply queued add/remove/set changes (one invocation per delta, unique cells)
//   1 outflow  per cell: flow toward each lower neighbour, scaled so it never exceeds depth
//   2 apply    depth -= own outflow, += neighbours' outflow toward this cell (in place: each
//              invocation only touches its own depth texel)
//   3 surface  per-cell display level for the creeper mesh
// No atomics, so the result is deterministic on a given GPU.

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0, r32f) uniform restrict readonly image2D height_img;
layout(set = 0, binding = 1, r32f) uniform restrict image2D depth_img;
layout(set = 0, binding = 2, rgba32f) uniform restrict image2D out_img;
layout(set = 0, binding = 3, r32f) uniform restrict writeonly image2D surf_img;

struct Delta { int idx; float amt; int mode; int pad; };  // mode 0 add, 1 set
layout(set = 0, binding = 4, std430) restrict readonly buffer Deltas { Delta d[]; } deltas;

layout(push_constant, std430) uniform Params {
	ivec4 dims;  // w, h, pass, delta count
	vec4 flow;   // FLOW_RATE, MAX_DEPTH, MIN_DEPTH (wet), dry epsilon
	vec4 vis;    // MIN_VIS, SHORE_DIP, HIDDEN, 0
} pc;

float H(ivec2 p) { return imageLoad(height_img, p).r; }
float D(ivec2 p) { return imageLoad(depth_img, p).r; }
vec4 O(ivec2 p) { return imageLoad(out_img, p); }

void pass_deltas() {
	uint i = gl_WorkGroupID.x * 64u + gl_LocalInvocationIndex;
	if (i >= uint(pc.dims.w)) return;
	Delta e = deltas.d[i];
	ivec2 p = ivec2(e.idx % pc.dims.x, e.idx / pc.dims.x);
	float v = e.mode == 1 ? e.amt : D(p) + e.amt;
	imageStore(depth_img, p, vec4(clamp(v, 0.0, pc.flow.y)));
}

void pass_outflow(ivec2 p) {
	int w = pc.dims.x;
	int h = pc.dims.y;
	float d = D(p);
	vec4 o = vec4(0.0);
	if (d >= pc.flow.w) {
		float head = H(p) + d;
		float rate = pc.flow.x;
		if (p.x + 1 < w) { ivec2 q = p + ivec2(1, 0); o.x = max(0.0, head - H(q) - D(q)) * rate; }
		if (p.x > 0)     { ivec2 q = p - ivec2(1, 0); o.y = max(0.0, head - H(q) - D(q)) * rate; }
		if (p.y + 1 < h) { ivec2 q = p + ivec2(0, 1); o.z = max(0.0, head - H(q) - D(q)) * rate; }
		if (p.y > 0)     { ivec2 q = p - ivec2(0, 1); o.w = max(0.0, head - H(q) - D(q)) * rate; }
		float total = o.x + o.y + o.z + o.w;
		if (total > d) o *= d / total;
	}
	imageStore(out_img, p, o);
}

void pass_apply(ivec2 p) {
	int w = pc.dims.x;
	int h = pc.dims.y;
	vec4 o = O(p);
	float d = D(p) - (o.x + o.y + o.z + o.w);
	if (p.x > 0)     d += O(p - ivec2(1, 0)).x;  // west neighbour flowing east
	if (p.x + 1 < w) d += O(p + ivec2(1, 0)).y;  // east neighbour flowing west
	if (p.y > 0)     d += O(p - ivec2(0, 1)).z;
	if (p.y + 1 < h) d += O(p + ivec2(0, 1)).w;
	d = d < pc.flow.w ? 0.0 : min(d, pc.flow.y);
	imageStore(depth_img, p, vec4(d));
}

void pass_surface(ivec2 p) {
	int w = pc.dims.x;
	int h = pc.dims.y;
	float wet = pc.flow.z;
	float hp = H(p);
	float d = D(p);
	float s;
	if (d > wet) {
		s = hp + max(d, pc.vis.x);
	} else {
		float top = -1e30;
		for (int dz = -1; dz <= 1; dz++) {
			for (int dx = -1; dx <= 1; dx++) {
				ivec2 q = p + ivec2(dx, dz);
				if ((dx == 0 && dz == 0) || q.x < 0 || q.y < 0 || q.x >= w || q.y >= h) continue;
				float dq = D(q);
				if (dq > wet) top = max(top, H(q) + max(dq, pc.vis.x));
			}
		}
		if (top < -1e29) s = hp - pc.vis.z;
		else if (top >= hp) s = hp - pc.vis.y;
		else s = top - 0.02;
	}
	imageStore(surf_img, p, vec4(s));
}

void main() {
	int pass_id = pc.dims.z;
	if (pass_id == 0) { pass_deltas(); return; }
	ivec2 p = ivec2(gl_GlobalInvocationID.xy);
	if (p.x >= pc.dims.x || p.y >= pc.dims.y) return;
	if (pass_id == 1) pass_outflow(p);
	else if (pass_id == 2) pass_apply(p);
	else pass_surface(p);
}
