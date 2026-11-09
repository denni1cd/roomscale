import hashlib
import json
import shutil
import time
from datetime import datetime, timezone
from pathlib import Path
from urllib.request import urlopen

from gradio_client import Client, handle_file
from huggingface_hub import get_token

INPUT = Path(r"C:\Users\Zero\.codex\checkpoints\roomscale-2026-11-09-pre-reconciliation\image-to-3d\01-bookcase-alpha.png")
OUT = Path(r"C:\Users\Zero\.codex\checkpoints\roomscale-2026-11-09-pre-reconciliation\image-to-3d\trellis2-hf-bench")
OUT.mkdir(parents=True, exist_ok=True)
SPACE = "microsoft/TRELLIS.2"
record = {
    "started_at_utc": datetime.now(timezone.utc).isoformat(),
    "space": SPACE,
    "api_path": ["/preprocess_image", "/image_to_3d", "/extract_glb"],
    "parameters": {
        "seed": 0,
        "resolution": "1024",
        "ss_guidance_strength": 7.5,
        "ss_guidance_rescale": 0.7,
        "ss_sampling_steps": 12,
        "ss_rescale_t": 5.0,
        "shape_slat_guidance_strength": 7.5,
        "shape_slat_guidance_rescale": 0.5,
        "shape_slat_sampling_steps": 12,
        "shape_slat_rescale_t": 3.0,
        "tex_slat_guidance_strength": 1.0,
        "tex_slat_guidance_rescale": 0.0,
        "tex_slat_sampling_steps": 12,
        "tex_slat_rescale_t": 3.0,
        "decimation_target": 100000,
        "texture_size": 2048,
    },
}
with urlopen("https://huggingface.co/api/spaces/microsoft/TRELLIS.2/runtime", timeout=20) as response:
    runtime = json.load(response)
record["space_revision"] = runtime.get("sha")
record["space_runtime_stage"] = runtime.get("stage")
record["space_runtime_hardware"] = (runtime.get("hardware") or {}).get("current")

def local_path(value):
    if isinstance(value, str):
        return Path(value)
    if isinstance(value, dict) and value.get("path"):
        return Path(value["path"])
    path = getattr(value, "path", None)
    if path:
        return Path(path)
    raise TypeError(f"Expected file output, got {type(value)!r}")

def preserve(value, name):
    src = local_path(value)
    dst = OUT / name
    shutil.copy2(src, dst)
    return {
        "path": str(dst),
        "size_bytes": dst.stat().st_size,
        "sha256": hashlib.sha256(dst.read_bytes()).hexdigest(),
    }

client = Client(SPACE, token=get_token(), verbose=False, analytics_enabled=False)
print("connected", SPACE, "revision", record["space_revision"], "hardware", record["space_runtime_hardware"], flush=True)
pipeline_started = time.monotonic()

started = time.monotonic()
preprocessed = client.predict(handle_file(str(INPUT)), api_name="/preprocess_image")
record["preprocess_seconds"] = round(time.monotonic() - started, 3)
record["preprocessed_image"] = preserve(preprocessed, "01-trellis-preprocessed.png")
print("preprocessed", record["preprocessed_image"], flush=True)

started = time.monotonic()
preview = client.predict(
    handle_file(record["preprocessed_image"]["path"]),
    0,
    "1024",
    7.5, 0.7, 12, 5.0,
    7.5, 0.5, 12, 3.0,
    1.0, 0.0, 12, 3.0,
    api_name="/image_to_3d",
)
record["image_to_3d_seconds"] = round(time.monotonic() - started, 3)
preview_text = preview[-1] if isinstance(preview, (tuple, list)) else preview
if isinstance(preview_text, str):
    (OUT / "02-turntable-preview.html").write_text(preview_text, encoding="utf-8")
    record["preview_html_chars"] = len(preview_text)
print("shape_and_material_stage_complete", type(preview).__name__, flush=True)

started = time.monotonic()
extracted = client.predict(100000, 2048, api_name="/extract_glb")
record["glb_export_seconds"] = round(time.monotonic() - started, 3)
glb_value = extracted[0] if isinstance(extracted, (tuple, list)) else extracted
record["generated_glb"] = preserve(glb_value, "03-trellis2-bookcase.glb")
record["total_seconds"] = round(time.monotonic() - pipeline_started, 3)
record["finished_at_utc"] = datetime.now(timezone.utc).isoformat()
record["status"] = "complete"
(OUT / "run-record.json").write_text(json.dumps(record, indent=2), encoding="utf-8")
print("complete", json.dumps(record, indent=2), flush=True)
