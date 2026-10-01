#!/usr/bin/env bash
set -euo pipefail
skill_dir="$(cd "$(dirname "$0")/.." && pwd)"
if [[ "$#" != 1 ]]; then
  printf '%s\n' 'Usage: bash render.sh /path/to/config.json' >&2
  exit 2
fi
bash "$skill_dir/scripts/ensure_environment.sh"
export PAPER_FIGURES_CACHE="${PAPER_FIGURES_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/paper-results-figures}"
exec Rscript "$skill_dir/scripts/render.R" "$1"
