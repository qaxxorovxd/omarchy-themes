#!/usr/bin/env bash
#
# Remove the Kagerou theme pack from Omarchy.
#
#   ./uninstall.sh                 remove every theme this pack installed
#   ./uninstall.sh sakura-drift    remove just those named
#   ./uninstall.sh --list          show what is currently installed
#
# Only directories carrying the pack's marker file are touched, so a theme you
# wrote yourself that happens to share a name is left alone.
#
set -euo pipefail

DEST="${OMARCHY_THEMES_DEST:-$HOME/.config/omarchy/themes}"
MARK="影"
MARKER_FILE=".kagerou"
STATE="$HOME/.local/state/omarchy/current"

SLUGS=(
  sakura-drift yugure-ember kitsune-amber komorebi-gold matcha-yuki
  mizu-lagoon yozora-indigo fuji-lavender akihabara-neon nanairo
)

bold=$'\e[1m'; dim=$'\e[2m'; red=$'\e[31m'; grn=$'\e[32m'; ylw=$'\e[33m'; off=$'\e[0m'
[[ -t 1 ]] || { bold=""; dim=""; red=""; grn=""; ylw=""; off=""; }

info() { printf '%s==>%s %s\n' "$grn" "$off" "$*"; }
warn() { printf '%s==>%s %s\n' "$ylw" "$off" "$*" >&2; }
die()  { printf '%serror:%s %s\n' "$red" "$off" "$*" >&2; exit 1; }

usage() {
  cat <<'USAGE'
Remove the Kagerou theme pack

Usage:
  ./uninstall.sh [options] [theme ...]

Themes may be named bare (sakura-drift) or with the mark (影-sakura-drift).

Options:
  -l, --list         list the pack's themes that are currently installed
  -n, --dry-run      print what would be removed, delete nothing
  -d, --dest DIR     look in DIR instead of ~/.config/omarchy/themes
  -k, --keep-theme   do not switch away even if the active theme is removed
  -h, --help         this text

With no theme names, every theme this pack installed is removed.
USAGE
}

to_slug() {
  local raw="$1"
  raw="${raw#"$MARK"-}"
  raw="${raw#"$MARK" }"
  printf '%s' "${raw,,}" | tr ' ' '-'
}

known_slug() {
  local want="$1" slug
  for slug in "${SLUGS[@]}"; do
    [[ $slug == "$want" ]] && return 0
  done
  return 1
}

theme_name() { printf '%s-%s' "$MARK" "$1"; }
is_ours()    { [[ -f $DEST/$(theme_name "$1")/$MARKER_FILE ]]; }

# ── Argument parsing ──────────────────────────────────────────────────────
selected=(); do_list=0; dry=0; keep_theme=0

while (( $# )); do
  case "$1" in
    -l|--list)       do_list=1 ;;
    -n|--dry-run)    dry=1 ;;
    -k|--keep-theme) keep_theme=1 ;;
    -h|--help)       usage; exit 0 ;;
    -d|--dest)       [[ $# -ge 2 ]] || die "--dest needs a directory"; DEST="$2"; shift ;;
    -*)              die "unknown option: $1 (try --help)" ;;
    *)               slug=$(to_slug "$1")
                     known_slug "$slug" || die "no theme named '$1' in this pack"
                     selected+=("$slug") ;;
  esac
  shift
done

if (( do_list )); then
  found=0
  for slug in "${SLUGS[@]}"; do
    if is_ours "$slug"; then
      printf '  %s%s%s\n' "$bold" "$(theme_name "$slug")" "$off"
      found=$((found + 1))
    fi
  done
  (( found )) || printf '  %snone of this pack is installed in %s%s\n' "$dim" "$DEST" "$off"
  exit 0
fi

(( ${#selected[@]} )) || selected=("${SLUGS[@]}")

run() { (( dry )) && { printf '%s  would run:%s %s\n' "$dim" "$off" "$*"; return 0; }; "$@"; }

# ── Remove ────────────────────────────────────────────────────────────────
active=$(cat "$STATE/theme.name" 2>/dev/null || true)
active_removed=0
removed=0

for slug in "${selected[@]}"; do
  name=$(theme_name "$slug")
  target="$DEST/$name"

  if [[ ! -e $target ]]; then
    continue
  elif ! is_ours "$slug"; then
    warn "skipping $name: $target was not installed by this pack"
    continue
  fi

  info "removing $name"
  run rm -rf -- "$target"
  removed=$((removed + 1))
  [[ $active == "$name" ]] && active_removed=1
done

info "removed $removed theme(s) from $DEST"
(( dry )) && exit 0

# Omarchy keeps the active theme as a copy under ~/.local/state, so the desktop
# survives the delete — but the recorded name now points at nothing, and the
# next background cycle would find no wallpapers. Move to a theme that exists.
if (( active_removed && ! keep_theme )); then
  if command -v omarchy-theme-set >/dev/null 2>&1; then
    fallback=""
    for candidate in tokyo-night catppuccin nord gruvbox everforest; do
      if [[ -d ${OMARCHY_PATH:-/usr/share/omarchy}/themes/$candidate ]]; then
        fallback="$candidate"
        break
      fi
    done
    if [[ -n $fallback ]]; then
      warn "the active theme was removed — switching to $fallback"
      omarchy-theme-set "$fallback"
    else
      warn "the active theme was removed; pick another from the theme menu"
    fi
  else
    warn "the active theme was removed; pick another from the theme menu"
  fi
fi
