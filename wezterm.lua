local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()

-- =========================================================
-- 1. APPEARANCE & FONT
-- =========================================================
config.font = wezterm.font_with_fallback({
	"JetBrainsMono Nerd Font",
	"FiraCode Nerd Font",
})
config.font_size = 14.0
config.line_height = 1.8 -- ~25px height

-- THEME: Matches Solarized Osaka
config.color_scheme = "Solarized Dark"

config.window_background_opacity = 0.80
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = true
config.window_padding = {
	left = 10,
	right = 10,
	top = 10,
	bottom = 0,
}

-- =========================================================
-- 2. SYSTEM BEHAVIOR
-- =========================================================
config.audible_bell = "Disabled"
config.adjust_window_size_when_changing_font_size = false
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false

-- =========================================================
-- 3. KEYBINDINGS
-- =========================================================
config.leader = { key = "p", mods = "CTRL", timeout_milliseconds = 2000 }

config.keys = {
	-- Word Jump Fix
	{ key = "LeftArrow", mods = "OPT", action = act.SendString("\x1bb") },
	{ key = "RightArrow", mods = "OPT", action = act.SendString("\x1bf") },

	-- PANE: Split
	{ key = "n", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "d", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

	-- PANE: Navigation
	{ key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },

	-- PANE: Actions
	{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
	{ key = "f", mods = "LEADER", action = act.TogglePaneZoomState },

	-- MODES
	{ key = "t", mods = "CTRL", action = act.ActivateKeyTable({ name = "tab_mode", one_shot = true }) },
	{ key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_mode", one_shot = false }) },

	-- UTILS
	{ key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "p", mods = "LEADER", action = act.PaneSelect({ mode = "Activate" }) },
}

config.key_tables = {
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
}

-- =========================================================
-- 4. VISUALS: Solarized Colors for Tab Bar
-- =========================================================
config.colors = {
	tab_bar = {
		background = "rgba(0, 0, 0, 0)",
		active_tab = {
			bg_color = "#2aa198", -- Solarized Cyan
			fg_color = "#002b36", -- Solarized Base03 (Dark bg)
			intensity = "Bold",
		},
		inactive_tab = {
			bg_color = "#073642", -- Solarized Base02
			fg_color = "#839496", -- Solarized Base0 (Text)
		},
		new_tab = {
			bg_color = "rgba(0, 0, 0, 0)",
			fg_color = "#839496",
		},
	},
}

-- =========================================================
-- 5. STATUS BAR: Solarized Palette
-- =========================================================
wezterm.on("update-right-status", function(window, pane)
	local name = window:active_key_table()
	local color = "#073642" -- Default (Base02)
	local text = ""
	local status_icon = "  "

	-- 1. TAB MODE
	if name == "tab_mode" then
		name = " TAB "
		color = "#268bd2" -- Solarized Blue
		text = " (n: new | x: close | r: rename | h/l: switch) "
		status_icon = "  "

	-- 2. RESIZE MODE
	elseif name == "resize_mode" then
		name = " RESIZE "
		color = "#cb4b16" -- Solarized Orange
		text = " (h/j/k/l: resize | Esc: exit) "
		status_icon = "  "

	-- 3. LEADER MODE
	elseif window:leader_is_active() then
		name = " LEADER "
		color = "#d33682" -- Solarized Magenta
		text = " (n/d: split | h/j/k/l: move | x: close | f: zoom) "
		status_icon = "  "
	end

	if name then
		window:set_right_status(wezterm.format({
			-- Colored block for Mode Name
			{ Background = { Color = color } },
			{ Foreground = { Color = "#fdf6e3" } }, -- Light text (Base3)
			{ Attribute = { Intensity = "Bold" } },
			{ Text = status_icon .. name },
			-- Dark block for Help Text
			{ Background = { Color = "#002b36" } }, -- Base03
			{ Foreground = { Color = "#839496" } }, -- Base0
			{ Text = text },
		}))
	else
		window:set_right_status(wezterm.format({
			{ Foreground = { Color = "#657b83" } }, -- Base00
			{ Text = " Ctrl+p: Leader | Ctrl+t: Tabs " },
		}))
	end
end)

-- =========================================================
-- 6. STARTUP
-- =========================================================
wezterm.on("gui-startup", function(cmd)
	local tab, pane, window = wezterm.mux.spawn_window(cmd or {})
	window:gui_window():toggle_fullscreen()
end)

return config
