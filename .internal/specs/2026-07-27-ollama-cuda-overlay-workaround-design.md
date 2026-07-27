# Ollama CUDA Overlay Workaround

## Context

With `nixpkgs.config.cudaSupport = true`, nixpkgs builds Ollama with CUDA.
Its CUDA setup hook currently constructs `CUDAToolkit_ROOT` from library
outputs that do not contain `bin/nvcc`, so Ollama's llama.cpp CMake build
fails to find the CUDA toolkit.

An isolated build verified that setting `CUDAToolkit_ROOT` to
`cudaPackages.cuda_nvcc` immediately before Ollama invokes CMake allows the
complete CUDA build and install checks to succeed.

## Design

Define `ollama` in `overlays/default.nix` as follows:

- When `prev.config.cudaSupport` is false, preserve `prev.ollama` unchanged.
- When `prev.config.cudaSupport` is true, use `overrideAttrs` to prepend an
  export of `CUDAToolkit_ROOT` pointing to
  `prev.cudaPackages.cuda_nvcc` before the existing `preBuild`.
- Preserve the upstream `preBuild` verbatim after the export.

The Home Manager Ollama module remains responsible only for service
configuration. The workaround does not alter the global CUDA setup hook or
explicit per-service CUDA acceleration when global `cudaSupport` is false.

## Verification

- Evaluate `pvg1` and confirm its Ollama package uses the overridden
  derivation.
- Build the overridden Ollama CUDA package.
- Confirm a non-CUDA package evaluation remains the original Ollama
  derivation.
- Run targeted formatting and lint checks for `overlays/default.nix`.
