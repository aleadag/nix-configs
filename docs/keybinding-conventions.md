# Keybinding Conventions

Source: [Tips for organizing Sway keybindings](https://mark.stosberg.com/sway-keybindings/).

This repo follows the article's mental model: use modifier combinations as
consistent layers, and treat the QWERTY top row as a workspace number row.

## Core Rules

Use the top row as workspace numbers:

| Key | Workspace |
| --- | --- |
| `q` | 1 |
| `w` | 2 |
| `e` | 3 |
| `r` | 4 |
| `t` | 5 |
| `y` | 6 |
| `u` | 7 |
| `i` | 8 |
| `o` | 9 |
| `p` | 10 |

Keep modifier layers predictable:

| Layer | Linux | macOS | Use |
| --- | --- | --- | --- |
| Main | `Super` / `Mod` | `cmd` | frequent actions and primary workspace switching |
| Danger / move | `Super+Shift` | `cmd+shift` | close, move, send to workspace, reload |
| Utility | `Super+Ctrl` | `cmd+ctrl` | tools, layout toggles, monitor/workspace utilities |
| Secondary workspace | optional | `cmd+alt` | native macOS Desktops when Paneru virtual workspaces are primary |

`Shift` should mean "move/send this thing" when a matching unshifted binding
means "focus/switch there". Avoid assigning shifted workspace chords to
unrelated actions.

## Workspace Policy

Primary workspace switching must stay on the main QWERTY layer.

| Action | Linux / niri | macOS / Paneru |
| --- | --- | --- |
| Switch primary workspace 1-10 | `Mod+q..p` | `cmd+q..p` |
| Move focused item to primary workspace 1-10 | `Mod+Shift+q..p` | `cmd+shift+q..p` |

On macOS, Paneru virtual workspaces are the primary workspace mechanism. Native
macOS Desktops are secondary:

| Action | macOS |
| --- | --- |
| Switch native Desktop 1-10 | `cmd+alt+q..p` |
| Move focused window to native Desktop 1-10 | `cmd+alt+shift+q..p` |

## Relative Workspace Movement

Prefer page keys for relative workspace navigation:

| Action | Linux / niri |
| --- | --- |
| Previous / next workspace | `Mod+Page_Up`, `Mod+Page_Down` |
| Move focused column to previous / next workspace | `Mod+Shift+Page_Up`, `Mod+Shift+Page_Down` |

Avoid adding `Mod+Alt+u/i` or `cmd+alt+u/i` relative-workspace meanings, because
the `Alt` QWERTY layer is reserved for secondary/native workspace numbering.

## Comments and Discoverability

Group bindings by layer, not by implementation file. When adding a binding,
include a short comment if the grouping or purpose is not obvious.

Use structured comments for large binding blocks:

```text
## Domain // Action // Chord ##
```

This makes the config easier to scan and leaves room for future cheat-sheet
generation.

## When To Add A Binding

Only bind actions used often enough to remember. If a shortcut is rarely used,
prefer an app launcher, command palette, or opening the config as a reference.

Before adding or changing a binding:

1. Check whether the chord already exists on macOS and Linux.
2. Check whether the shifted version follows the move/send convention.
3. Keep QWERTY workspace numbering consistent.
4. Keep native macOS Desktop bindings secondary to Paneru virtual workspace
   bindings.
5. Run targeted lint/evaluation checks for the changed configs.
