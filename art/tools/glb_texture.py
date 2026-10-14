# blender -b --python art/tools/glb_texture.py -- clean.glb out.glb --concept concept.png [--thin x|y|z] [--tex 1024]
# Planar texture projection of a gen3d concept image onto a cleaned flat object (guns, sights...).
# The image is projected along the mesh's thinnest axis (default: auto) onto the other two axes. The concept's
# non-white silhouette bbox is fitted to the mesh bbox. Both sides use the same image (so the far side is mirrored).
# Faces nearly parallel to the projection (|n.thin| < --grazing) sample a small flat patch of the median colour
# in the corner of the texture instead of smeared pixels. Blender axes: Z up, glTF -Z (muzzle) = +Y; the projected
# "right" of the image is the long axis (+Y for guns, muzzle right in the concept) and image up is +Z.
import bpy, sys, argparse, numpy as np
from mathutils import Vector
ap = argparse.ArgumentParser()
ap.add_argument("src"); ap.add_argument("out")
ap.add_argument("--concept", required=True)
ap.add_argument("--tex", type=int, default=1024)
ap.add_argument("--grazing", type=float, default=0.3)
ap.add_argument("--thin", default="x", choices="xyz")
ap.add_argument("--right", default="y", choices="xyz", help="mesh axis that is the image's right (long axis)")
ap.add_argument("--up", default="z", choices="xyz")
a = ap.parse_args(sys.argv[sys.argv.index("--") + 1:])
AX = {"x": 0, "y": 1, "z": 2}
T, R, U = AX[a.thin], AX[a.right], AX[a.up]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=a.src)
ob = next(o for o in bpy.data.objects if o.type == "MESH")
me = ob.data
vs = np.array([v.co[:] for v in me.vertices])
lo, hi = vs.min(0), vs.max(0)

src = bpy.data.images.load(a.concept)
w, h = src.size
px = np.array(src.pixels[:], dtype=np.float32).reshape(h, w, 4)
solid = px[..., :3].min(2) < 0.75  # linear: background is near 1.0
ys, xs = np.where(solid)
x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1  # row 0 = bottom in Blender images
crop = px[y0:y1, x0:x1]
cm = solid[y0:y1, x0:x1]
med = np.median(crop[cm][:, :3], axis=0)
crop = crop.copy()
crop[~cm, :3] = med  # no white fringes where the mesh silhouette is fatter than the concept's
crop[..., 3] = 1.0
N = a.tex
M = N - 24  # picture region; the corner holds the flat patch
tmp = bpy.data.images.new("crop", crop.shape[1], crop.shape[0], alpha=True)
tmp.pixels = crop.ravel().tolist()
tmp.scale(M, M)
pic = np.array(tmp.pixels[:], dtype=np.float32).reshape(M, M, 4)
tex = np.ones((N, N, 4), dtype=np.float32)
tex[..., :3] = med
tex[:M, :M] = pic
timg = bpy.data.images.new(ob.name + "_tex", N, N, alpha=False)
timg.pixels = tex.ravel().tolist()
timg.file_format = "PNG"
timg.pack()

uv = me.uv_layers.new(name="UV")
patch = ((N - 12) / N, (N - 12) / N)
span_r, span_u = hi[R] - lo[R], hi[U] - lo[U]
flat = 0
for poly in me.polygons:
    graze = abs(poly.normal[T]) < a.grazing
    flat += graze
    for li in poly.loop_indices:
        if graze:
            uv.data[li].uv = patch
        else:
            c = vs[me.loops[li].vertex_index]
            uv.data[li].uv = ((c[R] - lo[R]) / span_r * M / N, (c[U] - lo[U]) / span_u * M / N)
mat = bpy.data.materials.new("gen")
mat.use_nodes = True
b = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
b.inputs["Roughness"].default_value = 0.75
t = mat.node_tree.nodes.new("ShaderNodeTexImage")
t.image = timg
mat.node_tree.links.new(t.outputs["Color"], b.inputs["Base Color"])
me.materials.clear()
me.materials.append(mat)
print("TEXTURED polys=%d flat=%d medcolour=%s" % (len(me.polygons), flat, np.round(med, 2)))
bpy.ops.export_scene.gltf(filepath=a.out, export_format="GLB", use_selection=False)
