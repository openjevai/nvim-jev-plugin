# OpenJEV support for jev.nvim

This fork of [balazsorban44/nvim-jev-plugin](https://github.com/balazsorban44/nvim-jev-plugin) adds optional [OpenJEV](https://openjev.sh) support alongside the original TypeSafe integration. TypeSafe stays the default; OpenJEV is a free community gateway to the same Jev model. Jev is built by [TypeSafe](https://typesafe.ai).

## What was added

- **`lua/jev/config.lua`** — new `provider` config field (nil / `'typesafe'` / `'openjev'`, also `$JEV_PROVIDER`) and a `resolve()` function that applies the provider selection rule (see below). Added `M.openjev` table with the OpenJEV endpoint and model id. `api_key()` is unchanged (TypeSafe-only, backward compat).
- **`lua/jev/init.lua`** — `ask()` now calls `config.resolve()` for the key, model and url instead of reading `cfg` directly, so the request is routed to the selected provider. The missing-key error message now mentions `OPENJEV_API_KEY` too.
- **`lua/jev/client.lua`** — added HTTP 503 (OpenJEV overload) to the retryable-status reasons alongside the existing 529. Error messages are now provider-aware (`{P}` placeholder → `TypeSafe` / `OpenJEV`).
- **`lua/jev/health.lua`** — `:checkhealth jev` now detects `$OPENJEV_API_KEY`, reports both key sources in the warning, and prints the resolved provider/model/url.
- **`doc/jev.txt`** — documented the `provider` option and OpenJEV in requirements and configuration.
- **`README.md`** — OpenJEV note after the intro, install instructions for `OPENJEV_API_KEY`, and the `provider` option in the setup block.
- **`tests/test_editor.lua`** — updated the missing-key test to clear `OPENJEV_API_KEY` and match the new error message.

## Provider selection rule

1. Explicit choice wins: `provider` in `setup()` or `$JEV_PROVIDER` (`'openjev'` / `'typesafe'`).
2. Otherwise, if `TYPESAFE_API_KEY` (or `api_key` in setup) is set → TypeSafe, exactly as before (unchanged default).
3. Otherwise, if only `OPENJEV_API_KEY` is set → OpenJEV.

When OpenJEV is selected and `model` and `url` are left at their defaults (`jev-latest` / `https://api.typesafe.ai/v1/systemone`), the request is sent to `https://api.openjev.sh/v1/systemone` with model `openjev`. If the user explicitly set `model` and/or `url`, those values are respected.

Anyone with a TypeSafe key sees zero behaviour change.

## How to configure

```lua
-- Auto: TypeSafe if TYPESAFE_API_KEY is set, else OpenJEV if OPENJEV_API_KEY is set.
require('jev').setup({})

-- Force OpenJEV:
require('jev').setup({ provider = 'openjev' })
-- or: export JEV_PROVIDER=openjev
-- or: export OPENJEV_API_KEY=... (and leave TYPESAFE_API_KEY unset)
```

OpenJEV keys are available at https://openjev.sh/dashboard.

## How it was verified

- A live POST to `https://api.openjev.sh/v1/systemone` with model `openjev`, state `ping`, and one noul question returned HTTP 200.
- Re-grepped the source: no hardcoded `api.typesafe.ai` default was introduced — the TypeSafe defaults remain untouched, and the OpenJEV endpoint/model are only used when OpenJEV is the selected provider.
- The existing test suite was not executed (third-party code is never run during a port). The one test assertion that changed (the missing-key message) was updated to match the new wording and to clear `OPENJEV_API_KEY`.

## Upstream

Original project: https://github.com/balazsorban44/nvim-jev-plugin by @balazsorban44 (MIT license, unchanged).
