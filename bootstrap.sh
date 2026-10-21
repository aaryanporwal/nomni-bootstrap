#!/usr/bin/env bash
#
# Nomni laptop bootstrap.
#
# Installs the standard CLI toolchain (Brewfile) and the agent instruction
# file (AGENTS.md), then verifies every command resolves on PATH.
#
#   ./bootstrap.sh            install and verify
#   ./bootstrap.sh --check    verify only, change nothing (exit 1 on drift)
#
# Safe to re-run. Every step converges instead of duplicating work.
# Written for macOS stock bash 3.2 — no associative arrays, no ${v,,}.

set -euo pipefail

REPO_URL="${NOMNI_BOOTSTRAP_REPO:-https://github.com/REPLACE-ME/nomni-bootstrap.git}"
REPO_REF="${NOMNI_BOOTSTRAP_REF:-main}"

# Commands that must exist when we are done. Formula names differ from command
# names (ripgrep -> rg), so this list is commands, not formulae.
REQUIRED_COMMANDS="rg fd sd ast-grep sg jq yq xh bun bunx oxlint uv uvx ruff ty pyright"

MARKER="# >>> nomni bootstrap >>>"
MARKER_END="# <<< nomni bootstrap <<<"

MODE="install"
case "${1:-}" in
  --check)      MODE="check" ;;
  -h|--help)    sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  "")           ;;
  *)            echo "unknown argument: $1 (try --help)" >&2; exit 2 ;;
esac

# ---------------------------------------------------------------- output ----
if [ -t 1 ]; then
  C_OFF=$(printf '\033[0m'); C_B=$(printf '\033[1m')
  C_RED=$(printf '\033[31m'); C_GRN=$(printf '\033[32m')
  C_YEL=$(printf '\033[33m'); C_BLU=$(printf '\033[34m')
else
  C_OFF=""; C_B=""; C_RED=""; C_GRN=""; C_YEL=""; C_BLU=""
fi
step() { printf "\n%s==>%s %s%s%s\n" "$C_BLU" "$C_OFF" "$C_B" "$*" "$C_OFF"; }
ok()   { printf "    %sok%s    %s\n"   "$C_GRN" "$C_OFF" "$*"; }
warn() { printf "    %swarn%s  %s\n"   "$C_YEL" "$C_OFF" "$*"; }
info() { printf "          %s\n" "$*"; }
die()  { printf "    %serror%s %s\n"   "$C_RED" "$C_OFF" "$*" >&2; exit 1; }

# ------------------------------------------------------------ locate repo ---
# When piped from curl there is no file on disk, so clone and work from there.
find_repo_dir() {
  local src="${BASH_SOURCE[0]:-}"
  if [ -n "$src" ] && [ -f "$src" ]; then
    local dir
    dir="$(cd "$(dirname "$src")" && pwd)"
    if [ -f "$dir/Brewfile" ]; then
      printf '%s' "$dir"
      return 0
    fi
  fi

  command -v git >/dev/null 2>&1 || die "git is required to fetch the repo"
  local tmp
  tmp="$(mktemp -d)"
  step "Fetching $REPO_URL"
  git clone --quiet --depth 1 --branch "$REPO_REF" "$REPO_URL" "$tmp/repo" \
    || die "could not clone $REPO_URL (is the repo public and the branch correct?)"
  ok "cloned to $tmp/repo"
  printf '%s' "$tmp/repo"
}

# ------------------------------------------------- xcode command line tools -
ensure_clt() {
  step "Xcode Command Line Tools"
  if xcode-select -p >/dev/null 2>&1; then
    ok "already installed ($(xcode-select -p))"
    return 0
  fi
  warn "not installed — opening Apple's installer"
  xcode-select --install >/dev/null 2>&1 || true
  cat <<'MSG'

    A macOS dialog has opened. Finish that install, then run this script
    again. It will pick up where it left off.

MSG
  exit 1
}

# ---------------------------------------------------------------- homebrew --
brew_prefix() {
  if [ -x /opt/homebrew/bin/brew ]; then printf '/opt/homebrew'
  elif [ -x /usr/local/bin/brew ]; then printf '/usr/local'
  else printf ''
  fi
}

ensure_homebrew() {
  step "Homebrew"
  local prefix
  prefix="$(brew_prefix)"
  if [ -n "$prefix" ]; then
    ok "already installed ($prefix)"
  else
    warn "not installed — installing (this asks for your password)"
    NONINTERACTIVE=1 /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
      || die "Homebrew install failed"
    prefix="$(brew_prefix)"
    [ -n "$prefix" ] || die "Homebrew installed but brew not found"
    ok "installed ($prefix)"
  fi
  eval "$("$prefix/bin/brew" shellenv)"
}

# ------------------------------------------------------------- shell PATH ---
# Put brew (and therefore every tool) on PATH for future shells. Guarded by a
# marker so re-running never appends twice.
configure_shell() {
  step "Shell PATH"
  local prefix; prefix="$(brew_prefix)"

  _write_block() {
    local file="$1" body="$2"
    mkdir -p "$(dirname "$file")"
    [ -f "$file" ] || touch "$file"
    if grep -qF "$MARKER" "$file" 2>/dev/null; then
      ok "$file already configured"
      return 0
    fi
    { printf '\n%s\n' "$MARKER"
      printf '%s\n' "$body"
      printf '%s\n' "$MARKER_END"
    } >> "$file"
    ok "updated $file"
  }

  _write_block "$HOME/.zprofile"  "eval \"\$($prefix/bin/brew shellenv)\""
  _write_block "$HOME/.bash_profile" "eval \"\$($prefix/bin/brew shellenv)\""
  _write_block "$HOME/.config/fish/conf.d/nomni.fish" \
    "$prefix/bin/brew shellenv fish | source"
}

# ------------------------------------------------------------------ brew ----
run_bundle() {
  step "Toolchain (brew bundle)"
  brew bundle install --file="$REPO_DIR/Brewfile" --no-upgrade \
    || die "brew bundle failed"
  ok "Brewfile applied"
}

# ------------------------------------------------------- agent instructions -
# Never clobber a file the user already has. If ours differs, park it next to
# theirs and say so.
install_file() {
  local src="$1" dest="$2"
  if [ ! -e "$dest" ]; then
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    ok "installed $dest"
  elif cmp -s "$src" "$dest"; then
    ok "$dest already current"
  else
    cp "$src" "$dest.new"
    warn "$dest exists and differs"
    info "wrote $dest.new — merge it by hand, then delete the .new file"
  fi
}

install_agent_files() {
  step "Agent instructions"
  install_file "$REPO_DIR/AGENTS.md" "$HOME/AGENTS.md"

  # Claude Code reads ~/.claude/CLAUDE.md. Point it at AGENTS.md so there is
  # one source of truth rather than two copies that drift.
  local claude_md="$HOME/.claude/CLAUDE.md"
  mkdir -p "$HOME/.claude"
  if [ -f "$claude_md" ] && grep -qF '@~/AGENTS.md' "$claude_md"; then
    ok "$claude_md already references AGENTS.md"
  else
    [ -f "$claude_md" ] || touch "$claude_md"
    printf '@~/AGENTS.md\n' >> "$claude_md"
    ok "pointed $claude_md at ~/AGENTS.md"
  fi
}

# ---------------------------------------------------------------- verify ----
verify() {
  step "Verification"
  local prefix missing found cmd path
  prefix="$(brew_prefix)"
  [ -n "$prefix" ] && PATH="$prefix/bin:$prefix/sbin:$PATH"
  missing=""
  found=0

  for cmd in $REQUIRED_COMMANDS; do
    # `command -v` reports shell functions too, which is how a bundled `rg`
    # can look installed when no binary exists. Insist on a real file.
    path="$(command -v "$cmd" 2>/dev/null || true)"
    if [ -n "$path" ] && [ -x "$path" ] && [ -f "$path" ]; then
      printf "    %sok%s    %-10s %s\n" "$C_GRN" "$C_OFF" "$cmd" "$path"
      found=$((found + 1))
    else
      printf "    %smiss%s  %-10s not on PATH\n" "$C_RED" "$C_OFF" "$cmd"
      missing="$missing $cmd"
    fi
  done

  printf "\n"
  if [ -n "$missing" ]; then
    printf "  %s%d of %d present. Missing:%s%s\n" "$C_RED" "$found" \
      "$(echo $REQUIRED_COMMANDS | wc -w | tr -d ' ')" "$missing" "$C_OFF"
    return 1
  fi
  printf "  %sAll %d tools present.%s\n" "$C_GRN" "$found" "$C_OFF"
  return 0
}

# Allow sourcing for tests: `NOMNI_BOOTSTRAP_LIB=1 . ./bootstrap.sh` defines the
# functions above without running any of them.
if [ "${NOMNI_BOOTSTRAP_LIB:-0}" = "1" ]; then
  return 0 2>/dev/null || true
fi

# ------------------------------------------------------------------ main ----
REPO_DIR="$(find_repo_dir)"

if [ "$MODE" = "check" ]; then
  verify
  exit $?
fi

ensure_clt
ensure_homebrew
configure_shell
run_bundle
install_agent_files

if verify; then
  cat <<'DONE'

  Done. Open a new terminal tab so the PATH change takes effect.

  Read the brief:  https://github.com/REPLACE-ME/nomni-bootstrap
  Re-check later:  ./bootstrap.sh --check

DONE
else
  die "some tools are missing — see above"
fi
