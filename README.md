# Nomni laptop bootstrap

Sets up a new Nomni laptop with our standard command-line toolchain, and tells
your coding agents to use it.

Two things get installed:

1. **The tools** — 14 command-line programs, listed in [`Brewfile`](Brewfile).
2. **The agent instructions** — [`AGENTS.md`](AGENTS.md), copied to `~/AGENTS.md`
   and referenced from `~/.claude/CLAUDE.md`.

Both matter. Without step 2 your Claude Code will keep reaching for `grep` and
`npm`, because it has no way to know the better tools are there.

## Run it

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/REPLACE-ME/nomni-bootstrap/main/bootstrap.sh)"
```

Takes about five minutes on a fresh machine, most of it Homebrew. You will be
asked for your password once, by Homebrew's own installer.

When it finishes, **open a new terminal tab**. The PATH change does not apply to
the tab you ran it in.

### If you would rather read it first

Fair. Nothing here is secret.

```bash
git clone https://github.com/REPLACE-ME/nomni-bootstrap.git
cd nomni-bootstrap
less bootstrap.sh
./bootstrap.sh
```

### Checking a machine later

```bash
./bootstrap.sh --check
```

Changes nothing, prints every tool and where it resolves, exits non-zero if any
are missing. Use this when a tool starts behaving oddly, or to confirm a laptop
has not drifted.

## What you just installed, and what it replaces

| Tool | Use instead of | Why |
|---|---|---|
| `rg` (ripgrep) | `grep` | Much faster, respects `.gitignore`, sane recursive default |
| `fd` | `find` | Readable syntax, fast, respects `.gitignore` |
| `sd` | `sed`, `awk` | Normal regex syntax; no quoting puzzles for a simple replace |
| `ast-grep` / `sg` | `grep` for code | Matches syntax, not text, so it understands structure |
| `jq` | inline Python | Purpose-built JSON querying |
| `yq` | inline Python | Same, for YAML |
| `xh` | `curl` | Readable output and arguments for API testing |
| `bun` / `bunx` | `node`, `npm`, `yarn`, `npx` | One fast tool for runtime, installs, scripts and tests |
| `oxlint` | `eslint`, `prettier` | Orders of magnitude faster |
| `uv` / `uvx` | `pip`, `pipx`, `venv`, `poetry` | One fast tool for packages and environments |
| `ruff` | `flake8`, `black`, `isort` | One fast tool for lint and format |
| `ty` | `mypy` | Fast Python type checking, from the `uv` and `ruff` authors |
| `pyright` | `mypy` | Mature type checking; what most editors use |

Two habits worth forming on day one, because they are the ones people forget:

- Write throwaway scripts in TypeScript and run them with `bun run script.ts`.
  Reach for Python only when the task genuinely calls for it.
- Never run `pip install` directly. Use `uv add` inside a project, or `uvx` to
  run a CLI tool without installing anything.

## Adding a tool

Three files, all in this repo, kept deliberately in step:

1. `Brewfile` — add the formula.
2. `AGENTS.md` — add the rule, or agents will not use it.
3. `README.md` — add a row to the table above.

Then add the command name to `REQUIRED_COMMANDS` in `bootstrap.sh` so
`--check` covers it. Formula names and command names differ sometimes, which is
why that list exists separately (`ripgrep` installs `rg`; `ast-grep` installs
both `ast-grep` and `sg`).

Everyone picks the change up by re-running the script. It is safe to re-run.

## Notes

- **macOS only.** It assumes Homebrew and handles both Apple Silicon
  (`/opt/homebrew`) and Intel (`/usr/local`).
- **It sets PATH for zsh, bash and fish.** zsh is the macOS default; some of us
  use fish.
- **It will not overwrite your files.** If you already have an `~/AGENTS.md`
  that differs, it writes `~/AGENTS.md.new` beside it and tells you to merge.
- **Homebrew does not pin versions.** You get whatever is current. That is a
  deliberate trade: pinned, byte-identical toolchains would mean Nix, and Nix
  needs an owner. Revisit if version skew ever actually bites us.
- **`rg` can lie.** Claude Code injects an `rg` shell function pointing at its
  own bundled copy, so `command -v rg` can succeed on a machine with no ripgrep
  installed. `--check` insists on a real executable file for this reason.
