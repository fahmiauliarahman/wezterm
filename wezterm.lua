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
	{ family = "JetBrains Mono", weight = "Bold" }, -- Primary Font, Bold Weight
	{ family = "Fira Code iScript", weight = "Bold" }, -- Secondary Font, Bold Italic Weight
	{ family = "BlexMono Nerd Font", weight = "Bold" }, -- IBM Plex Mono for Programming Ligatures, Bold Weight
	{ family = "CaskaydiaCove Nerd Font", weight = "Bold" }, -- Cascadia Code for Programming Ligatures, Bold Weight
	{ family = "Apple Color Emoji", scale = 0.8 },
})
config.font_size = 13.5
config.line_height = 1.9
config.color_scheme_dirs = { "colors" }
config.color_scheme = "tokyonight_night"
config.window_background_opacity = 0.95
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
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false

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
	{ key = "-", mods = "CTRL", action = act.DisableDefaultAssignment },
	{ key = "h", mods = "OPT", action = act.DisableDefaultAssignment },
	{ key = "i", mods = "OPT", action = act.DisableDefaultAssignment },

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
			resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
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
				local type = string.match(id, "^([^/]+)")
				id = string.match(id, "([^/]+)$")
				id = string.match(id, "(.+)%..+$")
				local opts = {
					relative = true,
					restore_text = true,
					on_pane_restore = resurrect.tab_state.default_on_pane_restore,
				}
				if type == "workspace" then
					local state = resurrect.state_manager.load_state(id, "workspace")
					resurrect.workspace_state.restore_workspace(state, opts)
				elseif type == "window" then
					local state = resurrect.state_manager.load_state(id, "window")
					resurrect.window_state.restore_window(pane:window(), state, opts)
				elseif type == "tab" then
					local state = resurrect.state_manager.load_state(id, "tab")
					resurrect.tab_state.restore_tab(pane:tab(), state, opts)
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
			resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id)
				resurrect.state_manager.delete_state(id)
			end, {
				title = "Delete State",
				description = "Select State to Delete and press Enter = accept, Esc = cancel, / = filter",
				fuzzy_description = "Search State to Delete: ",
				is_fuzzy = true,
			})
		end),
	},
	{
		key = "N", -- Cmd + Shift + N: Create new workspace
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
	{
		key = "R", -- Cmd + Shift + R: Rename current workspace
		mods = "CMD",
		action = act.PromptInputLine({
			description = wezterm.format({
				{ Attribute = { Intensity = "Bold" } },
				{ Foreground = { AnsiColor = "Aqua" } },
				{ Text = "Rename current workspace" },
			}),
			action = wezterm.action_callback(function(window, pane, line)
				if line then
					wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
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
	-- SCROLLING
	-- ---------------------------------------------------------
	{ key = "DownArrow", mods = "CMD", action = act.ScrollToBottom },
	{ key = "UpArrow", mods = "CMD", action = act.ScrollToTop },

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
	-- UNLOCK WITH CMD + g (block all custom shortcuts)
	locked_mode = {
		{ key = "g", mods = "CMD", action = act.PopKeyTable },
		{ key = "p", mods = "CMD", action = act.Nop },
		{ key = "t", mods = "CMD", action = act.Nop },
		{ key = "S", mods = "CMD", action = act.Nop },
		{ key = "L", mods = "CMD", action = act.Nop },
		{ key = "D", mods = "CMD", action = act.Nop },
		{ key = "N", mods = "CMD", action = act.Nop },
		{ key = "R", mods = "CMD", action = act.Nop },
		{ key = "1", mods = "CMD", action = act.Nop },
		{ key = "2", mods = "CMD", action = act.Nop },
		{ key = "3", mods = "CMD", action = act.Nop },
		{ key = "4", mods = "CMD", action = act.Nop },
		{ key = "5", mods = "CMD", action = act.Nop },
		{ key = "6", mods = "CMD", action = act.Nop },
		{ key = "7", mods = "CMD", action = act.Nop },
		{ key = "8", mods = "CMD", action = act.Nop },
		{ key = "9", mods = "CMD", action = act.Nop },
	},
}

-- =========================================================
-- 6. VISUALS
-- =========================================================
config.colors = {
	tab_bar = {
		background = "#1a1b26",
		active_tab = {
			bg_color = "#7aa2f7",
			fg_color = "#16161e",
			intensity = "Bold",
		},
		inactive_tab = {
			bg_color = "#292e42",
			fg_color = "#545c7e",
		},
		new_tab = {
			bg_color = "#1a1b26",
			fg_color = "#7aa2f7",
		},
	},
}

-- =========================================================
-- 7. STATUS BAR
-- =========================================================
wezterm.on("update-right-status", function(window, pane)
	local name = window:active_key_table()
	local workspace = window:active_workspace()

	local color = "#292e42"
	local text = ""
	local status_icon = "  "
	local workspace_icon = "  "
	local workspace_color = "#7aa2f7"
	local workspace_text_color = "#16161e"

	if name == "tab_mode" then
		name = " TABS "
		color = "#7aa2f7"
		text = " (n: new | x: close | r: rename | h/l: switch) "
		status_icon = "  "
	elseif name == "pane_mode" then
		name = " PANES "
		color = "#bb9af7"
		text = " (n/d: split | h/j/k/l: move | x: close | r: resize) "
		status_icon = "  "
		workspace_color = "#bb9af7"
		workspace_text_color = "#16161e"
		workspace_icon = "  "
	elseif name == "resize_mode" then
		name = " RESIZE "
		color = "#e0af68"
		text = " (h/j/k/l: resize | Esc: exit) "
		status_icon = "  "
	elseif name == "locked_mode" then
		name = " LOCKED "
		color = "#f7768e"
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
			{ Foreground = { Color = "#16161e" } },
			{ Attribute = { Intensity = "Bold" } },
			{ Text = status_icon .. name },
			{ Background = { Color = "#1a1b26" } },
			{ Foreground = { Color = "#a9b1d6" } },
			{ Text = text },
		}))
	else
		window:set_right_status(wezterm.format({
			{ Background = { Color = "#7aa2f7" } },
			{ Foreground = { Color = "#16161e" } },
			{ Attribute = { Intensity = "Bold" } },
			{ Text = " " .. workspace_icon .. " " .. workspace .. " " },
			{ Background = { Color = "#1a1b26" } },
			{ Foreground = { Color = "#545c7e" } },
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
end)

-- Optional: Enable periodic auto-save every 5 minutes
resurrect.state_manager.periodic_save({
	interval_seconds = 300,
	save_workspaces = true,
	save_windows = false,
	save_tabs = false,
})

return config
