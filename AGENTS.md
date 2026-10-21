# Tooling

These are installed. `A > B` means use A, never B.

Shell: `rg` > grep, `fd` > find, `sd` > sed/awk, `jq`/`yq` > inline Python,
`xh` > curl. `ast-grep` (`sg`) for syntax-aware search and codemods.

JS/TS: `bun` > node/npm/yarn/npx (`bun install|run|test`, `bunx`).
`oxlint` > eslint/prettier. Write throwaway scripts in TypeScript
(`bun run x.ts`), not Python.

Python: `uv` > pip/pipx/venv/poetry - never call those directly.
`uv run|add|sync|venv`, `uvx` for CLI tools, `uv run x.py` with PEP 723
metadata for one-offs. `ruff check|format` > flake8/black/isort.
`ty` or `pyright` > mypy.
