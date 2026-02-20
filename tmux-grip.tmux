#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

get_tmux_opt() {
  local key="$1"
  local default="$2"
  local value
  value="$(tmux show-option -gqv "$key")"
  if [ -n "$value" ]; then
    printf '%s\n' "$value"
  else
    printf '%s\n' "$default"
  fi
}

default_slot_key() {
  case "$1" in
    1) printf '%s\n' 'h' ;;
    2) printf '%s\n' 'j' ;;
    3) printf '%s\n' 'k' ;;
    4) printf '%s\n' 'l' ;;
    *) printf '%s\n' '' ;;
  esac
}

bind_prefix_key() {
  local state_key="$1"
  local new_key="$2"
  local command="$3"
  local prev_key

  prev_key="$(tmux show-option -gqv "$state_key")"
  if [ -n "$prev_key" ] && [ "$prev_key" != "$new_key" ]; then
    tmux unbind-key -T prefix "$prev_key" 2>/dev/null
  fi

  if [ -n "$new_key" ]; then
    tmux unbind-key -T prefix "$new_key" 2>/dev/null
    tmux bind-key -T prefix "$new_key" run-shell "$command"
  fi

  tmux set-option -gq "$state_key" "$new_key"
}

open_key="$(get_tmux_opt '@tmux_grip_bind_open' 'g')"
add_key="$(get_tmux_opt '@tmux_grip_bind_add' 'G')"
enable_slot_binds="$(get_tmux_opt '@tmux_grip_enable_slot_binds' 'on')"
script_cmd="/usr/bin/env bash '$CURRENT_DIR/scripts/tmux-grip'"

max_slots_raw="$(get_tmux_opt '@tmux_grip_max_slots' '4')"
case "$max_slots_raw" in
  ''|*[!0-9]*) max_slots=4 ;;
  *) max_slots="$max_slots_raw" ;;
esac
if [ "$max_slots" -lt 1 ]; then
  max_slots=1
fi
if [ "$max_slots" -gt 9 ]; then
  max_slots=9
fi

bind_prefix_key "@tmux_grip_bound_open_key" "$open_key" "$script_cmd menu"
bind_prefix_key "@tmux_grip_bound_add_key" "$add_key" "$script_cmd add '#{session_name}'"

seen_slot_keys="|"
i=1
while [ "$i" -le 9 ]; do
  state_key="@tmux_grip_bound_slot_key_${i}"
  prev_slot_key="$(tmux show-option -gqv "$state_key")"

  if [ "$enable_slot_binds" != "on" ]; then
    if [ -n "$prev_slot_key" ]; then
      tmux unbind-key -T prefix "$prev_slot_key" 2>/dev/null
    fi
    tmux set-option -gq "$state_key" ""
    i=$((i + 1))
    continue
  fi

  slot_key="$(get_tmux_opt "@tmux_grip_bind_slot_${i}" "$(default_slot_key "$i")")"

  if [ -n "$prev_slot_key" ] && [ "$prev_slot_key" != "$slot_key" ]; then
    tmux unbind-key -T prefix "$prev_slot_key" 2>/dev/null
  fi

  if [ -n "$slot_key" ] && [ "$i" -le "$max_slots" ]; then
    case "$seen_slot_keys" in
      *"|$slot_key|"*)
        tmux set-option -gq "$state_key" ""
        tmux display-message "grip: duplicate slot key '$slot_key' for slot $i"
        i=$((i + 1))
        continue
        ;;
    esac
    seen_slot_keys="${seen_slot_keys}${slot_key}|"

    tmux unbind-key -T prefix "$slot_key" 2>/dev/null
    tmux bind-key -T prefix "$slot_key" run-shell "$script_cmd nav $i"
    tmux set-option -gq "$state_key" "$slot_key"
  else
    tmux set-option -gq "$state_key" ""
  fi

  i=$((i + 1))
done
