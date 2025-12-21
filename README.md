# WezTerm Config Summary

If you are having familiarities with [zellij](https://zellij.dev), this wezterm config is very easy to use. Here is the list shortcuts that i modified. DWYOR and backup your config first.

## Appearance
- Frontend: OpenGL, Solarized Dark, 75% opacity, tab bar at bottom
- Fonts: bold JetBrains Mono → Fira Code iScript → BlexMono Nerd Font → CaskaydiaCove Nerd Font → Apple Color Emoji (0.8 scale)
- Font size: 13.5, line height: 1.8

## Session Management (resurrect plugin)
| Keybinding | Action |
|------------|--------|
| `Cmd+Shift+S` | Save workspace state |
| `Cmd+Shift+L` | Load session via fuzzy picker (workspace/window/tab) |
| `Cmd+Shift+D` | Delete saved state via fuzzy picker |
| `Cmd+Shift+N` | Create new named workspace |
| `Cmd+Shift+R` | Rename current workspace |

Auto-save: Workspace state saves automatically every 5 minutes.

## Pane Mode (`Cmd+p`)
| Key | Action |
|-----|--------|
| `n` | Split horizontal |
| `d` | Split vertical |
| `h/j/k/l` | Navigate panes |
| `x` | Close pane |
| `f` | Toggle zoom |
| `p` | Pane selector |
| `r` | Enter resize mode |
| `Esc` | Exit mode |

## Tab Mode (`Cmd+t`)
| Key | Action |
|-----|--------|
| `n` | New tab |
| `x` | Close tab |
| `h/l` | Prev/next tab |
| `r` | Rename tab |
| `Esc` | Exit mode |

## Other Keybindings
- `Cmd+1-9`: Jump to tab by number
- `Opt+Left/Right`: Word jump

## Lock Mode (`Cmd+g`)

Blocks all custom shortcuts while allowing normal typing. Useful when running apps that need those keybindings (e.g., vim, tmux).

Blocked shortcuts: `Cmd+p`, `Cmd+t`, `Cmd+1-9`, `Cmd+Shift+S/L/D/N/R`

Press `Cmd+g` again to unlock.

## Safety
- Disables `Ctrl +/=/0` and `Opt+h/i` to prevent accidental font changes (because i am using lazyvim and this keybind is on my lazyvim keymaps.)
- Audible bell disabled

## Startup
- Window maximizes on launch
- Use `Cmd+Shift+L` to restore a previous session
