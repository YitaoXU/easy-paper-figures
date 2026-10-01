#!/usr/bin/env bash
set -euo pipefail
skill_dir="$(cd "$(dirname "$0")/.." && pwd)"
cache_dir="${PAPER_FIGURES_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/paper-results-figures}"
mkdir -p "$cache_dir"
rscript_bin="$(command -v Rscript || true)"
if [[ -z "$rscript_bin" ]]; then
  printf '%s\n' 'Rscript is unavailable. Install R for this operating system, then rerun this command.' >&2
  printf '%s\n' 'Rscript unavailable; no successful environment record created.' > "$cache_dir/environment-failure.txt"
  exit 1
fi
# Cheap file/runtime identity only: no R process or package inventory on a cache hit.
identity="$( { uname -s; uname -m; hostname; printf '%s\n' "$rscript_bin"; ls -lnL "$rscript_bin"; cat "$skill_dir/scripts/dependencies.txt" "$skill_dir/scripts/check_environment.R" "$skill_dir/scripts/font_export.R"; } | cksum)"
if [[ "${1:-}" != "--refresh" && -s "$cache_dir/environment.json" && -f "$cache_dir/environment.ready" && -d "$cache_dir/library" ]]; then
  if [[ "$(cat "$cache_dir/environment.ready")" == "$identity" ]]; then
    printf 'Using cached R environment: %s\n' "$cache_dir/environment.json"
    exit 0
  fi
fi
rm -f "$cache_dir/environment.ready"
"$rscript_bin" "$skill_dir/scripts/check_environment.R" "$skill_dir" "$cache_dir"
printf '%s\n' "$identity" > "$cache_dir/environment.ready"
