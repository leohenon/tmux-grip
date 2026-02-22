# tmux-grip

<<<<<<< Updated upstream
`tmux-grip` is a tmux plugin inspired by `harpoon.nvim` that pins sessions into numbered slots for deterministic key-based jumps and fast cycling via a lightweight popup.
=======
`tmux-grip` is a tmux plugin inspired by `harpoon.nvim` that pins sessions into numbered slots for key-based jumps and fast cycling via a lightweight simple popup.
>>>>>>> Stashed changes

## Quick Start

- `prefix + G`: add current session to grip
- `prefix + g`: open the grip viewer
- Optional direct slot keys: `prefix + h/j/k/l`

## Install (TPM)

In your `tmux.conf`

```tmux
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'leohenon/tmux-grip'

run '~/.tmux/plugins/tpm/tpm'
```

Reload tmux and press `prefix + I` to install plugins.

## Viewer controls

- `1..9`: jump directly to slot
- `j` / `k`: move selection down/up
- `J` / `K`: reorder selected session
- `x`: remove selected session
- `X`: clear all sessions
- `Enter`: jump to selected session
- `Esc`: close

## Options

```tmux
set -g @tmux_grip_max_slots 4
set -g @tmux_grip_bind_open 'g'
set -g @tmux_grip_bind_add 'G'
set -g @tmux_grip_enable_slot_binds 'on'

# Direct jump keys
set -g @tmux_grip_bind_slot_1 'h'
set -g @tmux_grip_bind_slot_2 'j'
set -g @tmux_grip_bind_slot_3 'k'
set -g @tmux_grip_bind_slot_4 'l'
```

Notes:

- Stale slots are removed when their session no longer exists.
- Direct slot keys are off by default. Enable with `set -g @tmux_grip_enable_slot_binds 'on'`.
- Slot key defaults are `h/j/k/l` for slots `1..4`.
- If you already use `h/j/k/l` for pane focus, remap grip slots to a non-conflicting set like `y/u/i/o`.
- Slots persist across tmux restarts (saved to ~/.tmux/tmux-grip-marks).
- Supports 9 slots max.

## Requirements

- tmux 3.2+

## License

[MIT](LICENSE)
