# Ollama CUDA Overlay Workaround Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use beads-superpowers:subagent-driven-development (recommended) or beads-superpowers:executing-plans to implement this plan task-by-task. Each Task becomes a bead (`bd create -t task --parent <epic-id>`). Steps within tasks use checkbox (`- [ ]`) syntax for human readability.

**Goal:** Make CUDA-enabled Ollama builds find `nvcc` while leaving non-CUDA Ollama packages unchanged.

**Architecture:** Override `pkgs.ollama` in the repository's existing package overlay only when `prev.config.cudaSupport` is true. Prepend the actual `cuda_nvcc` output to Ollama's build environment as `CUDAToolkit_ROOT`, then run the upstream `preBuild` unchanged.

**Tech Stack:** Nix flakes, nixpkgs overlays, Home Manager, CUDA 12.9, CMake

## Global Constraints

- Modify only `overlays/default.nix`; keep the Home Manager Ollama service module unchanged.
- Gate the workaround strictly on `prev.config.cudaSupport`.
- Preserve the upstream Ollama `preBuild` after exporting `CUDAToolkit_ROOT`.
- Do not alter explicit per-service CUDA acceleration when global `cudaSupport` is false.
- Do not commit or push without explicit user authorization.

---

### Task 1: Gate the Ollama CUDA toolkit-root override

**Files:**
- Modify: `overlays/default.nix`
- Reference: `.internal/specs/2026-07-27-ollama-cuda-overlay-workaround-design.md`

**Interfaces:**
- Consumes: `prev.config.cudaSupport`, `prev.ollama`, and `prev.cudaPackages.cuda_nvcc` from the nixpkgs overlay argument.
- Produces: `final.ollama`, identical to `prev.ollama` when CUDA support is disabled and carrying the toolkit-root export when CUDA support is enabled.

**Acceptance Criteria:**
- `pvg1`'s Ollama `preBuild` exports `CUDAToolkit_ROOT` to the `cuda_nvcc` package before the upstream build commands.
- The default non-CUDA `legacyPackages.x86_64-linux.ollama` `preBuild` does not contain the workaround.
- The CUDA-enabled Ollama derivation builds successfully and contains `lib/ollama/cuda_v12/libggml-cuda.so`.
- `overlays/default.nix` passes the repository's targeted formatting and lint checks.
- No files outside `overlays/default.nix` and the approved design/plan artifacts are changed.

- [ ] **Step 1: Demonstrate that the CUDA host lacks the override**

Run:

```bash
nix eval --raw path:.#homeConfigurations.pvg1.config.services.ollama.package.preBuild \
  | rg -F 'export CUDAToolkit_ROOT='
```

Expected before implementation: exit status 1 with no matching output.

- [ ] **Step 2: Add the minimal gated overlay**

Add this attribute beside the other package attributes in `overlays/default.nix`:

```nix
ollama =
  if prev.config.cudaSupport then
    prev.ollama.overrideAttrs (oldAttrs: {
      preBuild = ''
        export CUDAToolkit_ROOT="${prev.cudaPackages.cuda_nvcc}"
        ${oldAttrs.preBuild}
      '';
    })
  else
    prev.ollama;
```

- [ ] **Step 3: Verify the CUDA host receives the override**

Run:

```bash
nix eval --raw path:.#homeConfigurations.pvg1.config.services.ollama.package.preBuild \
  | rg -F 'export CUDAToolkit_ROOT='
```

Expected: one line exporting a `/nix/store/...-cuda12.9-cuda_nvcc-...` path.

- [ ] **Step 4: Verify non-CUDA Ollama remains unchanged**

Run:

```bash
nix eval --raw path:.#legacyPackages.x86_64-linux.ollama.preBuild \
  | rg -F 'export CUDAToolkit_ROOT='
```

Expected: exit status 1 with no matching output.

- [ ] **Step 5: Build and inspect the CUDA-enabled package**

Run:

```bash
nix build --no-link -L path:.#homeConfigurations.pvg1.config.services.ollama.package
```

Expected: exit status 0, including successful CUDA toolkit detection and version check.

Then run:

```bash
ollama_out="$(
  nix eval --raw path:.#homeConfigurations.pvg1.config.services.ollama.package.outPath
)"
test -f "$ollama_out/lib/ollama/cuda_v12/libggml-cuda.so"
```

Expected: exit status 0.

- [ ] **Step 6: Run targeted repository checks**

Run:

```bash
just lint overlays/default.nix
```

Expected: exit status 0.

Run:

```bash
git diff --check -- overlays/default.nix
```

Expected: exit status 0 with no output.

- [ ] **Step 7: Review scope without committing**

Run:

```bash
git status --short
git diff -- overlays/default.nix
```

Expected: the implementation diff changes only the gated `ollama` attribute in `overlays/default.nix`; existing user changes such as `flake.lock` remain untouched. Report the result and wait for explicit commit or push authorization.
