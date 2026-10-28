# Step1X-3D Citizen Strategy Preflight — 2026-10-28

## Candidate fit

Step1X-3D was assessed as a character-specific alternative for the Citizen pilot. Its official workflow has separate geometry-generation and texture-synthesis stages and exports a textured mesh. It does not assume that a furniture-oriented generator is also the best character generator.

## Official runtime requirements

The [official Step1X-3D README](https://github.com/stepfun-ai/Step1X-3D/blob/main/README.md) documents a Python 3.10 environment checked with CUDA 12.4, PyTorch 2.5.1, PyTorch3D, Kaolin, and builds for its custom rasterizer and differentiable renderer. Its published full geometry-plus-texture inference uses 27 GB of GPU memory for 50 steps. The [official model card](https://huggingface.co/stepfun-ai/Step1X-3D) lists the model as Apache 2.0 licensed.

## Local preflight evidence

- GPU: NVIDIA GeForce RTX 5090, 32,607 MiB total and 31,447 MiB free at inspection. This satisfies the README's stated GPU-memory figure at idle.
- Host: Windows PowerShell.
- `nvcc.exe` and the Visual C++ `cl.exe` compiler are not available on PATH; no installed Visual Studio toolchain or CUDA Toolkit directory was found.
- WSL has no installed Linux distribution, and `wsl --status` reports that WSL2 cannot start because virtualization is disabled in the machine configuration.
- The documented Step1X-3D build path therefore cannot be reproduced in this checkout's current host environment without changing system-level virtualization/toolchain prerequisites.
- The official inference examples export an unrigged mesh and textured mesh. The RoomScale Citizen also needs the existing five pivots and animation-compatible skinning, so rigging and weight transfer would still require a separate validated path after model inference.

## Outcome

**Not run — blocked at local runtime prerequisites; not a visual failure, pilot pass, or plateau strategy.** No Step1X-3D weights or candidate outputs were downloaded or generated. Keep `citizen-v007` and all existing candidates unchanged. Revisit this strategy only with a supported CUDA build environment and a concrete plan to preserve the Citizen skeleton/pivot contract.
