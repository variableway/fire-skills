---
name: scaffold-app
description: Guide for creating a new app from an external template repo (not stored in agentway).
---

# Scaffold App

Use this skill when adding a new application to the agentway monorepo.

## Prerequisites

- External template/starter lives in its own repository (not in agentway).
- Decide app project name (no fixed type folder required).

## Steps

1. **Choose location**: `apps/<project-name>/`
2. **Clone or submodule**:
   - **Local app**: copy from external template into the path above.
   - **Separate repo**: `git submodule add <repo-url> apps/<project-name>`
3. **Register**: add an entry to `apps/registry.yaml` (`source: local` or `source: submodule`), and optionally set:
   - `kind`: app type label (`web` / `cli` / `desktop` / `service` / custom)
   - `tags`: label array for filtering/search (`[internal, mvp, ...]`)
4. **Document**: add `README.md` and `AGENTS.md` inside the app directory.
5. **Node apps**: ensure `package.json` exists (pnpm workspace picks up `apps/<project-name>/`).
6. **Refresh index**: `pnpm manifest` from repo root → `data/manifest.json`.
7. **Install**: `pnpm install` at repo root to link workspace packages.

## Submodule notes

- Record the submodule in `.gitmodules` at repo root.
- Set `source: submodule` and `repo:` in `registry.yaml`.
- After clone, run `git submodule update --init --recursive`, then `pnpm install`.

## Visibility

- Public apps: normal paths under `apps/`.
- Private apps: use a private submodule repo or keep outside this public monorepo.
