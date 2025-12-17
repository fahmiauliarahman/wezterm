local wezterm = require("wezterm")
local act = wezterm.action

-- 1. PLUGINS
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")

local config = wezterm.config_builder()

-- =========================================================
-- 2. APPEARANCE & FONT
-- =========================================================
config.front_end = "OpenGL"

config.font = wezterm.font_with_fallback({
	"JetBrainsMono Nerd Font",
	"FiraCode Nerd Font",
})
config.font_size = 13.5
config.line_height = 1.8
config.color_scheme = "Solarized Dark"
config.window_background_opacity = 0.8
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = true
config.window_decorations = "RESIZE"
config.window_padding = { left = 10, right = 10, top = 10, bottom = 0 }

-- =========================================================
-- 3. SYSTEM BEHAVIOR
-- =========================================================
config.audible_bell = "Disabled"
config.adjust_window_size_when_changing_font_size = false
-- MacOS Specific: Use Option as Meta/Alt
config.send_composed_key_when_left_alt_is_pressed = true
config.send_composed_key_when_right_alt_is_pressed = true

-- =========================================================
-- 4. KEYBINDINGS
-- =========================================================
config.keys = {
	-- ---------------------------------------------------------
	-- MACOS SAFETY: Prevent accidental resizing
	-- ---------------------------------------------------------
	-- Disable CTRL +/-/0 so they don't mess up your font size randomly
	{ key = "-", mods = "CTRL", action = act.DisableDefaultAssignment },
	{ key = "=", mods = "CTRL", action = act.DisableDefaultAssignment },
	{ key = "0", mods = "CTRL", action = act.DisableDefaultAssignment },

	-- ---------------------------------------------------------
	-- PANE MODE (Cmd + p)
	-- ---------------------------------------------------------
	{
		key = "p",
		mods = "CMD",
		action = act.ActivateKeyTable({
			name = "pane_mode",
			one_shot = true,
			timeout_milliseconds = 2000,
		}),
	},

	-- ---------------------------------------------------------
	-- SESSION MANAGEMENT (Cmd + Shift + Keys)
	-- ---------------------------------------------------------
	{
		key = "S", -- Cmd + Shift + S (Uppercase implies Shift)
		mods = "CMD",
		action = wezterm.action_callback(function(win, pane)
			resurrect.save_state(resurrect.workspace_state.get_workspace_state())
			win:perform_action(
				act.ToastNotification({
					title = "Session Saved",
					content = "Workspace state saved",
					timeout_milliseconds = 1000,
				}),
				pane
			)
		end),
	},
	{
		key = "L", -- Cmd + Shift + L
		mods = "CMD",
		action = wezterm.action_callback(function(win, pane)
			resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id, label)
				local type = string.match(id, "^.+(%..+)$")
				if type == "json" then
					local state = resurrect.load_state(id, "workspace_state")
					resurrect.workspace_state.restore_workspace(state, {
						window = win,
						relative = true,
						restore_text = true,
						on_pane_restore = resurrect.tab_state.default_on_pane_restore,
					})
				end
			end, {
				title = "Load Session",
				is_fuzzy = true,
			})
		end),
	},
	{
		key = "D", -- Cmd + Shift + D
		mods = "CMD",
		action = wezterm.action_callback(function(win, pane)
			resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id, label)
				id = string.match(id, "([^/]+)$")
				id = string.match(id, "(.+)%..+$")
				win:perform_action(
					act.InputSelector({
						action = wezterm.action_callback(function(_, _, line)
							if line then
								os.remove(wezterm.home_dir .. "/.local/share/wezterm/resurrect/" .. id .. ".json")
							end
						end),
						title = "Delete State",
						choices = { { label = "Confirm Delete: " .. label, id = "delete" } },
					}),
					pane
				)
			end, {
				title = "Delete State",
			})
		end),
	},
	{
		key = "W", -- Cmd + Shift + W
		mods = "CMD",
		action = act.PromptInputLine({
			description = wezterm.format({
				{ Attribute = { Intensity = "Bold" } },
				{ Foreground = { AnsiColor = "Fuchsia" } },
				{ Text = "Enter name for new workspace" },
			}),
			action = wezterm.action_callback(function(window, pane, line)
				if line then
					window:perform_action(act.SwitchToWorkspace({ name = line }), pane)
				end
			end),
		}),
	},

	-- ---------------------------------------------------------
	-- LOCK MODE (Cmd + g)
	-- ---------------------------------------------------------
	{
		key = "g",
		mods = "CMD",
		action = act.ActivateKeyTable({
			name = "locked_mode",
			one_shot = false,
			prevent_fallback = true,
		}),
	},

	-- ---------------------------------------------------------
	-- TAB MODE (Cmd + t)
	-- ---------------------------------------------------------
	{ key = "t", mods = "CMD", action = act.ActivateKeyTable({ name = "tab_mode", one_shot = true }) },

	-- ---------------------------------------------------------
	-- UTILS
	-- ---------------------------------------------------------
	{ key = "LeftArrow", mods = "OPT", action = act.SendString("\x1bb") },
	{ key = "RightArrow", mods = "OPT", action = act.SendString("\x1bf") },

	-- ---------------------------------------------------------
	-- DIRECT TAB JUMP (Cmd + 1..9)
	-- ---------------------------------------------------------
	{ key = "1", mods = "CMD", action = act.ActivateTab(0) },
	{ key = "2", mods = "CMD", action = act.ActivateTab(1) },
	{ key = "3", mods = "CMD", action = act.ActivateTab(2) },
	{ key = "4", mods = "CMD", action = act.ActivateTab(3) },
	{ key = "5", mods = "CMD", action = act.ActivateTab(4) },
	{ key = "6", mods = "CMD", action = act.ActivateTab(5) },
	{ key = "7", mods = "CMD", action = act.ActivateTab(6) },
	{ key = "8", mods = "CMD", action = act.ActivateTab(7) },
	{ key = "9", mods = "CMD", action = act.ActivateTab(8) },
}

-- =========================================================
-- 5. KEY TABLES
-- =========================================================
config.key_tables = {
	pane_mode = {
		{ key = "n", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
		{ key = "d", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
		{ key = "h", action = act.ActivatePaneDirection("Left") },
		{ key = "j", action = act.ActivatePaneDirection("Down") },
		{ key = "k", action = act.ActivatePaneDirection("Up") },
		{ key = "l", action = act.ActivatePaneDirection("Right") },
		{ key = "x", action = act.CloseCurrentPane({ confirm = true }) },
		{ key = "f", action = act.TogglePaneZoomState },
		{ key = "c", action = act.SpawnTab("CurrentPaneDomain") },
		{ key = "p", action = act.PaneSelect({ mode = "Activate" }) },
		{ key = "r", action = act.ActivateKeyTable({ name = "resize_mode", one_shot = false }) },
		{ key = "Escape", action = "PopKeyTable" },
	},
	tab_mode = {
		{ key = "n", action = act.SpawnTab("CurrentPaneDomain") },
		{ key = "x", action = act.CloseCurrentTab({ confirm = true }) },
		{ key = "h", action = act.ActivateTabRelative(-1) },
		{ key = "l", action = act.ActivateTabRelative(1) },
		{
			key = "r",
			action = act.PromptInputLine({
				description = "Enter new name for tab",
				action = wezterm.action_callback(function(window, _, line)
					if line then
						window:active_tab():set_title(line)
					end
				end),
			}),
		},
		{ key = "Escape", action = "PopKeyTable" },
	},
	resize_mode = {
		{ key = "h", action = act.AdjustPaneSize({ "Left", 5 }) },
		{ key = "l", action = act.AdjustPaneSize({ "Right", 5 }) },
		{ key = "k", action = act.AdjustPaneSize({ "Up", 5 }) },
		{ key = "j", action = act.AdjustPaneSize({ "Down", 5 }) },
		{ key = "Escape", action = "PopKeyTable" },
	},
	-- UNLOCK WITH CMD + g
	locked_mode = {
		{ key = "g", mods = "CMD", action = act.PopKeyTable },
	},
}

-- =========================================================
-- 6. VISUALS
-- =========================================================
config.colors = {
	tab_bar = {
		background = "rgba(0, 0, 0, 0)",
		active_tab = {
			bg_color = "#2aa198",
			fg_color = "#002b36",
			intensity = "Bold",
		},
		inactive_tab = {
			bg_color = "#073642",
			fg_color = "#839496",
		},
		new_tab = {
			bg_color = "rgba(0, 0, 0, 0)",
			fg_color = "#839496",
		},
	},
}

-- =========================================================
-- 7. STATUS BAR
-- =========================================================
wezterm.on("update-right-status", function(window, pane)
	local name = window:active_key_table()
	local workspace = window:active_workspace()

	local color = "#073642"
	local text = ""
	local status_icon = "  "
	local workspace_icon = "  "
	local workspace_color = "#eee8d5"
	local workspace_text_color = "#002b36"

	if name == "tab_mode" then
		name = " TABS "
		color = "#268bd2"
		text = " (n: new | x: close | r: rename | h/l: switch) "
		status_icon = "  "
	elseif name == "pane_mode" then
		name = " PANES "
		color = "#d33682"
		text = " (n/d: split | h/j/k/l: move | x: close | r: resize) "
		status_icon = "  "
		workspace_color = "#d33682"
		workspace_text_color = "#fdf6e3"
		workspace_icon = "  "
	elseif name == "resize_mode" then
		name = " RESIZE "
		color = "#cb4b16"
		text = " (h/j/k/l: resize | Esc: exit) "
		status_icon = "  "
	elseif name == "locked_mode" then
		name = " LOCKED "
		color = "#dc322f"
		text = " (Cmd + g to unlock) "
		status_icon = "  "
	end

	if name then
		window:set_right_status(wezterm.format({
			{ Background = { Color = workspace_color } },
			{ Foreground = { Color = workspace_text_color } },
			{ Attribute = { Intensity = "Bold" } },
			{ Text = " " .. workspace_icon .. " " .. workspace .. " " },
			{ Background = { Color = color } },
			{ Foreground = { Color = "#fdf6e3" } },
			{ Attribute = { Intensity = "Bold" } },
			{ Text = status_icon .. name },
			{ Background = { Color = "#002b36" } },
			{ Foreground = { Color = "#839496" } },
			{ Text = text },
		}))
	else
		window:set_right_status(wezterm.format({
			{ Background = { Color = "#eee8d5" } },
			{ Foreground = { Color = "#002b36" } },
			{ Attribute = { Intensity = "Bold" } },
			{ Text = " " .. workspace_icon .. " " .. workspace .. " " },
			{ Background = { Color = "#002b36" } },
			{ Foreground = { Color = "#657b83" } },
			{ Text = " Cmd+p: Panes | Cmd+t: Tabs " },
		}))
	end
end)

-- =========================================================
-- 8. STARTUP
-- =========================================================
wezterm.on("gui-startup", function(cmd)
	local tab, pane, window = wezterm.mux.spawn_window(cmd or {})
	window:gui_window():maximize()

	local state = resurrect.workspace_state.get_workspace_state()
	if state then
		resurrect.workspace_state.restore_workspace(resurrect.load_state(state.workspace, "workspace_state"), {
			window = window,
			relative = true,
			restore_text = true,
			on_pane_restore = resurrect.tab_state.default_on_pane_restore,
		})
	end
end)

return config
