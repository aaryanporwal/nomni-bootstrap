# Modern Toolchain & CLI Preferences

Assume the following modern, Rust/Zig-based tools are installed on the system. **Always** prefer them over legacy POSIX, Python, or Node defaults for speed and ergonomics:

## 1. Shell & File Operations
- **Search text:** Use `rg` (ripgrep) instead of `grep`.
- **Find files:** Use `fd` instead of `find`.
- **Find & Replace:** Use `sd` instead of `sed` or `awk` for string/regex replacements.
- **Structural Search/Refactor:** Use `ast-grep` (`sg`) for syntax-aware code searches and codemods.
- **JSON/YAML parsing:** Use `jq` and `yq` instead of writing inline Python one-liners.
- **HTTP requests:** Use `xh` instead of `curl` for readable API testing.

## 2. JavaScript / TypeScript
- **Runtime & Package Manager:** Use `bun` (`bun install`, `bun run`, `bun test`, `bunx`) instead of `node`, `npm`, `yarn`, or `npx`.
- **Quick Scripts:** If you need to write a quick utility or data-processing script, write it in TypeScript and execute it directly with `bun run script.ts` rather than writing a Python script.
- **Linting & Formatting:** Prefer `oxlint` (or `@biomejs/biome`) over `eslint` and `prettier`.

## 3. Python (When Required)
- **Never** use raw `pip`, `pipx`, `venv`, or `poetry`.
- **Package & Env Management:** Always use `uv` (`uv run`, `uv add`, `uv sync`, `uv venv`).
- **One-off Script Execution:** Use `uv run script.py` (with inline PEP 723 dependency metadata if external packages are needed) or `uvx` for CLI tools.
- **Linting & Formatting:** Use `ruff` (`ruff check`, `ruff format`) and `ty` / `pyright` instead of `flake8`, `black`, `isort`, or `mypy`.

---

Installed and kept current by `nomni-bootstrap`. If you add a tool here, add it
to the `Brewfile` and the README table in that repo as well.
