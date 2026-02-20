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
        printf '%s\n' "${MOCK_MAX_SLOTS:-4}"
        ;;
      *)
        ;;
    esac
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
    case ",${MOCK_SESSIONS:-}," in
      *",$target,"*) exit 0 ;;
      *) exit 1 ;;
    esac
    ;;
  display-message)
    printf '%s\n' "$*" >> "$MOCK_MSG_FILE"
    ;;
  switch-client)
    printf '%s\n' "$*" >> "$MOCK_SWITCH_FILE"
    ;;
  list-commands)
    printf '%s\n' "display-popup"
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
export MOCK_MAX_SLOTS=4
export MOCK_SESSIONS="alpha,gamma"

cat >"$MOCK_DATA_FILE" <<'EOF'
1	alpha
2	beta
3	gamma
EOF

script="$ROOT_DIR/scripts/tmux-grip"

if bash "$script" nav 2; then
	echo "expected nav to stale slot to fail"
	exit 1
fi

expected_after=$'1\talpha\n2\tgamma'
actual_after="$(cat "$MOCK_DATA_FILE")"
if [ "$actual_after" != "$expected_after" ]; then
	echo "stale prune did not compact slots"
	exit 1
fi

if ! grep -q "missing, pruned slot 2" "$MOCK_MSG_FILE"; then
	echo "missing prune notification"
	exit 1
fi
