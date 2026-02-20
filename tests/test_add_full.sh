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
  display-message)
    printf '%s\n' "$*" >> "$MOCK_MSG_FILE"
    ;;
  has-session)
    exit 0
    ;;
  switch-client)
    exit 0
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
export MOCK_MAX_SLOTS=4

script="$ROOT_DIR/scripts/tmux-grip"

bash "$script" add alpha
bash "$script" add beta
bash "$script" add gamma
bash "$script" add delta

expected_before=$'1\talpha\n2\tbeta\n3\tgamma\n4\tdelta'
actual_before="$(cat "$MOCK_DATA_FILE")"
if [ "$actual_before" != "$expected_before" ]; then
	echo "unexpected state after filling slots"
	exit 1
fi

if bash "$script" add epsilon; then
	echo "expected add to fail when list is full"
	exit 1
fi

actual_after="$(cat "$MOCK_DATA_FILE")"
if [ "$actual_after" != "$expected_before" ]; then
	echo "state changed after rejected add"
	exit 1
fi

if ! grep -q "grip list is full" "$MOCK_MSG_FILE"; then
	echo "missing full-list message"
	exit 1
fi
