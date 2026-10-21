# Nomni standard laptop toolchain.
#
# Every entry here is a tool our AGENTS.md tells coding agents to prefer.
# If you add a line, add it to AGENTS.md and the README table too, or agents
# will not know the tool exists.
#
# Apply with:  brew bundle --file=Brewfile
# Check with:  brew bundle check --file=Brewfile --verbose

# --- Shell & file operations ------------------------------------------------
brew "ripgrep"    # rg      — search text (replaces grep)
brew "fd"         # fd      — find files (replaces find)
brew "sd"         # sd      — find & replace (replaces sed/awk)
brew "ast-grep"   # ast-grep, sg — syntax-aware search and codemods
brew "jq"         # jq      — JSON parsing
brew "yq"         # yq      — YAML parsing
brew "xh"         # xh      — HTTP requests (replaces curl for API testing)

# --- JavaScript / TypeScript ------------------------------------------------
brew "bun"        # bun, bunx — runtime, package manager, test runner
brew "oxlint"     # oxlint  — linting (replaces eslint/prettier)
# brew "biome"    # optional alternative to oxlint; uncomment if a repo uses it

# --- Python -----------------------------------------------------------------
brew "uv"         # uv, uvx — packages, envs, script running
brew "ruff"       # ruff    — lint and format (replaces flake8/black/isort)
brew "ty"         # ty      — type checking (Astral)
brew "pyright"    # pyright — type checking (Microsoft)
#                   NB: pulls Homebrew node as a dependency. If you use nvm,
#                   see the nvm note in the README.
