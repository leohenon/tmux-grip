#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"

cleanup() {
	rm -rf "$TMP_DIR"
}
trap cleanup EXIT

mkdir -p "$TMP_DIR/bin" "$TMP_DIR/state"

cat >"$TMP_DIR/bin/tmux" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

cmd="${1:-}"
shift || true

case "$cmd" in
  show-option)
    key="${@: -1}"
    case "$key" in
      @tmux_grip_data_file)
        printf '%s\n' "$MOCK_DATA_FILE"
        ;;
      @tmux_grip_max_slots)
        printf '%s\n' "${MOCK_MAX_SLOTS:-2}"
        ;;
      @tmux_grip_enable_slot_binds)
        printf '%s\n' "${MOCK_ENABLE_SLOT_BINDS:-on}"
        ;;
      @tmux_grip_bound_slot_key_1)
        printf '%s\n' "${MOCK_SLOT_KEY_1:-y}"
        ;;
      *)
        ;;
    esac
    ;;
  display-message)
    if [ "${1:-}" = "-p" ] && [ "${2:-}" = "#{session_name}" ]; then
      printf '%s\n' "${MOCK_CURRENT_SESSION:-alpha}"
    else
      printf '%s\n' "$*" >> "$MOCK_MSG_FILE"
    fi
    ;;
  has-session)
    target=""
    while [ "$#" -gt 0 ]; do
      if [ "$1" = "-t" ]; then
        shift
        target="${1:-}"
      fi
      shift || true
    done
    case "$target" in
      alpha|beta) exit 0 ;;
      *) exit 1 ;;
    esac
    ;;
  list-windows)
    target=""
    while [ "$#" -gt 0 ]; do
      if [ "$1" = "-t" ]; then
        shift
        target="${1:-}"
      fi
      shift || true
    done
    if [ "$target" = "alpha" ]; then
      printf '%s\n' "1"
      printf '%s\n' "2"
    fi
    ;;
  list-panes)
    target=""
    while [ "$#" -gt 0 ]; do
      if [ "$1" = "-t" ]; then
        shift
        target="${1:-}"
      fi
      shift || true
    done
    case "$target" in
      alpha:1)
        printf '%s\n' "nvim|fish|alpha:1.0"
        ;;
      alpha:2)
        printf '%s\n' "agt|opencode|alpha:2.0"
        ;;
    esac
    ;;
  switch-client)
    printf '%s\n' "$*" >> "$MOCK_SWITCH_FILE"
    ;;
  select-pane)
    ;;
  *)
    exit 0
    ;;
esac
EOF

chmod +x "$TMP_DIR/bin/tmux"

export PATH="$TMP_DIR/bin:$PATH"
export MOCK_DATA_FILE="$TMP_DIR/state/marks"
export MOCK_MSG_FILE="$TMP_DIR/state/messages"
export MOCK_SWITCH_FILE="$TMP_DIR/state/switches"
export MOCK_MAX_SLOTS=2
export MOCK_ENABLE_SLOT_BINDS=on
export MOCK_SLOT_KEY_1=y
export MOCK_CURRENT_SESSION=alpha

cat >"$MOCK_DATA_FILE" <<'EOF'
1	alpha
2	beta
EOF

script="$ROOT_DIR/scripts/tmux-grip"

# Tab into pane view, then jump first pane by number.
printf '\t1' | bash "$script" popup >/dev/null 2>&1 || true
if ! grep -q -- "-t alpha:1.0" "$MOCK_SWITCH_FILE"; then
	echo "pane jump did not target expected pane"
	exit 1
fi

: >"$MOCK_SWITCH_FILE"

# Even in pane view, direct slot key should still jump to session.
printf '\ty' | bash "$script" popup >/dev/null 2>&1 || true
if ! grep -q -- "-t alpha" "$MOCK_SWITCH_FILE"; then
	echo "direct slot key did not jump to session from pane view"
	exit 1
fi
