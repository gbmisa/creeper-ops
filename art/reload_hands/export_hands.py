# F102: run inside reload_hands.blend (Text Editor > export_hands.py > Run Script). Writes every moved/rotated
# left-hand marker (not "grip") to art/gen/reload_hands.json, which the game reads over ReloadRigs (ReloadAnims.rig).
# Marker frame: origin = palm contact point, Y arrow = fingers, Z arrow = palm faces this way.
import bpy, json, os

out_path = bpy.path.abspath("//../gen/reload_hands.json")


def b2g(v):  # Blender -> Godot axes
    return [round(v.x, 4), round(v.z, 4), round(-v.y, 4)]


bpy.context.view_layer.update()
out = {}
for e in bpy.data.objects:
    if "rh_anchor" not in e or e["rh_anchor"] == "grip":
        continue
    root = e.parent
    m = root.matrix_world.inverted() @ e.matrix_world
    m3 = m.to_3x3().normalized()
    out.setdefault(e["rh_gun"], {})[e["rh_anchor"]] = {
        "p": b2g(m.to_translation()), "f": b2g(m3.col[1]), "n": b2g(m3.col[2])}
os.makedirs(os.path.dirname(out_path), exist_ok=True)
with open(out_path, "w") as f:
    json.dump(out, f, indent=1, sort_keys=True)
print("wrote", out_path, sum(len(v) for v in out.values()), "markers")
