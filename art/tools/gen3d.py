#!/usr/bin/env python3
"""Text or image -> 3D mesh on the local ComfyUI (Krea 2 Turbo concept image -> Hunyuan3D v2 -> GLB).

  python3 art/tools/gen3d.py --prompt "rusty military fuel barrel" --out art/gen/barrel
  python3 art/tools/gen3d.py --image concept.png --out art/gen/barrel

Writes <out>.png (concept) and <out>.glb (raw, unrigged, high-poly: clean up in Blender before Godot).
"""
import argparse, json, os, shutil, time, urllib.request, uuid

URL = "http://127.0.0.1:8188"
COMFY_OUT = os.path.expanduser("~/ComfyUI/output")
COMFY_IN = os.path.expanduser("~/ComfyUI/input")
STYLE = (", single object, centered, full object in frame, three-quarter view from slightly above, "
         "plain flat white background, no shadow on the ground, game asset concept, clean readable shapes")


STYLE_SIDE = (", single object, centered, flat orthographic side profile view, entire object in frame, "
              "plain flat white background, no shadow, detailed photorealistic render with soft studio lighting and visible surface detail, "
              "two-tone materials")


def concept_nodes(prompt: str, seed: int, style: str = STYLE) -> dict:
    return {
        "u": {"class_type": "UNETLoader", "inputs": {"unet_name": "krea2_turbo_fp8_scaled.safetensors", "weight_dtype": "default"}},
        "c": {"class_type": "CLIPLoader", "inputs": {"clip_name": "qwen3vl_4b_fp8_scaled.safetensors", "type": "krea2", "device": "default"}},
        "v": {"class_type": "VAELoader", "inputs": {"vae_name": "qwen_image_vae.safetensors"}},
        "p": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["c", 0], "text": prompt + style}},
        "n": {"class_type": "ConditioningZeroOut", "inputs": {"conditioning": ["p", 0]}},
        "l": {"class_type": "EmptyLatentImage", "inputs": {"width": 1024, "height": 1024, "batch_size": 1}},
        "k": {"class_type": "KSampler", "inputs": {"model": ["u", 0], "positive": ["p", 0], "negative": ["n", 0], "latent_image": ["l", 0],
              "seed": seed, "steps": 28, "cfg": 1.0, "sampler_name": "euler", "scheduler": "simple", "denoise": 1.0}},
        "d": {"class_type": "VAEDecode", "inputs": {"samples": ["k", 0], "vae": ["v", 0]}},
        "si": {"class_type": "SaveImage", "inputs": {"images": ["d", 0], "filename_prefix": "gen3d/concept"}},
    }


def mesh_nodes(image_ref: list, seed: int, octree: int) -> dict:
    return {
        "h": {"class_type": "ImageOnlyCheckpointLoader", "inputs": {"ckpt_name": "hunyuan3d-dit-v2.safetensors"}},
        "ms": {"class_type": "ModelSamplingAuraFlow", "inputs": {"model": ["h", 0], "shift": 1.0}},
        "ce": {"class_type": "CLIPVisionEncode", "inputs": {"clip_vision": ["h", 1], "image": image_ref, "crop": "none"}},
        "hc": {"class_type": "Hunyuan3Dv2Conditioning", "inputs": {"clip_vision_output": ["ce", 0]}},
        "hl": {"class_type": "EmptyLatentHunyuan3Dv2", "inputs": {"resolution": 3072, "batch_size": 1}},
        "hk": {"class_type": "KSampler", "inputs": {"model": ["ms", 0], "positive": ["hc", 0], "negative": ["hc", 1], "latent_image": ["hl", 0],
               "seed": seed, "steps": 30, "cfg": 5.0, "sampler_name": "euler", "scheduler": "normal", "denoise": 1.0}},
        "hv": {"class_type": "VAEDecodeHunyuan3D", "inputs": {"samples": ["hk", 0], "vae": ["h", 2], "num_chunks": 8000, "octree_resolution": octree}},
        "hm": {"class_type": "VoxelToMesh", "inputs": {"voxel": ["hv", 0], "algorithm": "surface net", "threshold": 0.6}},
        "sg": {"class_type": "SaveGLB", "inputs": {"mesh": ["hm", 0], "filename_prefix": "gen3d/mesh"}},
    }


def post(path: str, body: dict) -> dict:
    req = urllib.request.Request(URL + path, json.dumps(body).encode(), {"Content-Type": "application/json"})
    return json.load(urllib.request.urlopen(req))


def run(graph: dict, timeout: float) -> dict:
    pid = post("/prompt", {"prompt": graph, "client_id": str(uuid.uuid4())})["prompt_id"]
    t0 = time.time()
    while time.time() - t0 < timeout:
        hist = json.load(urllib.request.urlopen(f"{URL}/history/{pid}"))
        if pid in hist:
            st = hist[pid].get("status", {})
            if st.get("status_str") == "error":
                raise SystemExit("ComfyUI error: " + json.dumps(st.get("messages", []))[-800:])
            if st.get("completed"):
                return hist[pid]["outputs"]
        time.sleep(2)
    raise SystemExit("timed out")


def files(outputs: dict) -> list:
    out = []
    for node in outputs.values():
        for key in ("images", "3d", "result"):
            for f in node.get(key, []) if isinstance(node.get(key), list) else []:
                if isinstance(f, dict) and "filename" in f:
                    out.append(os.path.join(COMFY_OUT, f.get("subfolder", ""), f["filename"]))
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--prompt")
    ap.add_argument("--image")
    ap.add_argument("--out", required=True)
    ap.add_argument("--seed", type=int, default=7)
    ap.add_argument("--side", action="store_true", help="strict side profile (guns, sights, attachments)")
    ap.add_argument("--octree", type=int, default=256, help="mesh detail: 256 normal, 384 fine")
    a = ap.parse_args()
    if not a.prompt and not a.image:
        raise SystemExit("give --prompt or --image")
    g = {}
    if a.image:
        name = f"gen3d_{uuid.uuid4().hex[:8]}{os.path.splitext(a.image)[1]}"
        os.makedirs(COMFY_IN, exist_ok=True)
        shutil.copy(a.image, os.path.join(COMFY_IN, name))
        g["li"] = {"class_type": "LoadImage", "inputs": {"image": name}}
        img = ["li", 0]
    else:
        g.update(concept_nodes(a.prompt, a.seed, STYLE_SIDE if a.side else STYLE))
        img = ["d", 0]
    g.update(mesh_nodes(img, a.seed, a.octree))
    t0 = time.time()
    produced = files(run(g, 900))
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    for f in produced:
        ext = os.path.splitext(f)[1]
        if ext in (".png", ".glb"):
            shutil.copy(f, a.out + ext)
            print("wrote", a.out + ext)
    print(f"done in {time.time() - t0:.0f} s")


if __name__ == "__main__":
    main()
