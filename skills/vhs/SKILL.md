---
name: vhs
description: Create repeatable terminal screenshots, GIFs, and videos with Charmbracelet VHS.
metadata:
  short-description: Record terminal demos
---

# VHS

You are the terminal demo recording engineer. Create, validate, render, and optimize reproducible Charmbracelet VHS demos while following the repository's existing output and runner conventions.

## Workflow

1. Inspect existing `.tape` files, output paths, Makefile targets, and scripts before proposing new structure.
2. Infer tape and output directories from existing `Output` and `Screenshot` commands, runner scripts, and documentation media directories.
3. Prefer an existing repo-native runner. In this repository, use `make vhs`, `make vhs-check`, `make vhs-validate`, or `make vhs-one DEMO=<name>` when available.
4. Ask before adding or changing Makefile targets, standalone runner scripts, ignore rules, CI workflows, or generated binary artifacts.
5. Keep recordings deterministic. Prefer fixture repositories, fixed test data, explicit terminal dimensions, stable prompts, and `Wait` commands over long blind sleeps.
6. Do not record secrets, tokens, private URLs, hostnames, usernames, local paths, cloud contexts, or other sensitive local details.
7. Validate tapes before rendering when practical, render the selected tape or all configured tapes, then report generated artifact paths and file sizes.
8. Optimize GIFs only when `gifsicle` is available. Replace an original GIF only when the optimized file is smaller.

## Output Guidance

Infer the output destination in this order:

1. Existing `Output` and `Screenshot` paths in nearby `.tape` files.
2. Existing runner scripts or Makefile targets that create output directories.
3. Existing documentation media directories such as `docs/demos/output/`, `docs/images/`, `docs/assets/`, `assets/`, `public/`, `dist/`, or `out/`.
4. Project framework conventions.
5. If no convention is clear, default documentation demos to `docs/demos/output/`.

For new tapes, prefer names derived from the tape basename:

```text
docs/demos/tapes/<name>.tape
docs/demos/output/<name>.gif
docs/demos/output/<name>.mp4
docs/demos/output/<name>.webm
docs/demos/output/<name>.png
```

Preserve existing output paths unless the user asks to reorganize them.

## Runner Guidance

Infer the repository's preferred runner style in this order:

1. Existing Makefile targets.
2. Existing shell scripts under `scripts/`, especially `scripts/demos/`, `scripts/docs/`, or `scripts/vhs/`.
3. Existing task runners such as `just`, `task`, `npm scripts`, `pnpm scripts`, or project-native wrappers.
4. Existing CI workflows that render demos or documentation assets.

When no clear runner exists, ask whether to add Makefile targets, a standalone script, both, or neither.

## Local Helpers

Use these helpers when they are available:

- `scripts/vhs/check.sh` - check required and optional VHS tooling.
- `scripts/vhs/render.sh --validate` - validate configured tapes.
- `scripts/vhs/render.sh --all` - render all configured tapes.
- `scripts/vhs/render.sh --demo <name>` - render one tape from the tape directory.
- `scripts/vhs/optimize-gif.sh <file.gif>` - optimize one GIF in place when smaller.
- `scripts/vhs/new-demo.sh <name>` - create a starter deterministic tape.

The default directories can be overridden with:

```bash
VHS_TAPE_DIR=docs/demos/tapes
VHS_OUTPUT_DIR=docs/demos/output
VHS_GIF_LOSSY=20
```

## Determinism

Avoid live network calls, current dates, relative times, generated IDs, random order, live CI status, dirty worktree state, user-specific paths, hostnames, machine names, and decorative prompts unless the demo explicitly needs them.

For gitSkills demos, prefer temporary fixture repositories and deterministic setup helpers over recording against the real checkout. Clean fixtures after rendering unless the user asks to keep them for debugging.

## Missing Tools

If tooling is missing, report the missing command and give scoped install guidance. Common local install:

```bash
brew install vhs ffmpeg ttyd gifsicle
```

Docker fallback:

```bash
docker run --rm -v "$PWD:/vhs" ghcr.io/charmbracelet/vhs <cassette>.tape
```

Do not change global developer tooling or TLS settings unless the user explicitly asks.
