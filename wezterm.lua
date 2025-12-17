local wezterm = require("wezterm")
local act = wezterm.action

-- 1. PLUGINS: Import the Session Manager (Resurrect)
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")

local config = wezterm.config_builder()

-- =========================================================
-- 2. APPEARANCE & FONT
-- =========================================================
config.font = wezterm.font_with_fallback({
	"JetBrainsMono Nerd Font",
	"FiraCode Nerd Font",
})
config.font_size = 14.0
config.line_height = 1.7

config.color_scheme = "Solarized Dark"

config.window_background_opacity = 0.8
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = true

-- NO TITLE BAR
-- "RESIZE" removes the title bar but keeps the resize borders.
config.window_decorations = "RESIZE"

config.window_padding = {
	left = 10,
	right = 10,
	top = 10,
	bottom = 0,
}

-- =========================================================
-- 3. SYSTEM BEHAVIOR
-- =========================================================
config.audible_bell = "Disabled"
config.adjust_window_size_when_changing_font_size = false
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false

-- =========================================================
-- 4. KEYBINDINGS
-- =========================================================
config.leader = { key = "p", mods = "CTRL", timeout_milliseconds = 2000 }

config.keys = {
	-- Word Jump Fix
	{ key = "LeftArrow", mods = "OPT", action = act.SendString("\x1bb") },
	{ key = "RightArrow", mods = "OPT", action = act.SendString("\x1bf") },
	-- DISABLE DEFAULT KEYBINDINGS
	-- Prevent WezTerm from eating these keys so LazyVim can use them
	{ key = "-", mods = "CTRL", action = act.DisableDefaultAssignment },
	{ key = "=", mods = "CTRL", action = act.DisableDefaultAssignment },
	{ key = "0", mods = "CTRL", action = act.DisableDefaultAssignment },

	-- SESSION MANAGEMENT (Resurrect)
	{
		key = "W",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = wezterm.format({
				{ Attribute = { Intensity = "Bold" } },
				{ Foreground = { AnsiColor = "Fuchsia" } },
				{ Text = "Enter name for new workspace" },
			}),
			action = wezterm.action_callback(function(window, pane, line)
				-- line will be `nil` if they hit escape without entering anything
				-- An empty string if they just hit enter
				-- Or the actual line of text they wrote
				if line then
					window:perform_action(
						act.SwitchToWorkspace({
							name = line,
						}),
						pane
					)
				end
			end),
		}),
	},
	{
		key = "S",
		mods = "LEADER",
		action = wezterm.action_callback(function(win, pane)
			resurrect.save_state(resurrect.workspace_state.get_workspace_state())
		end),
	},
	{
		key = "L",
		mods = "LEADER",
		action = wezterm.action_callback(function(win, pane)
			resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id, label)
				-- 1. Load the state from the selected file
				local type = string.match(id, "^.+(%..+)$")
				if type == "json" then
					local state = resurrect.load_state(id, "workspace_state")
					-- 2. Restore the workspace
					resurrect.workspace_state.restore_workspace(state, {
						window = win,
						relative = true,
						restore_text = true,
						on_pane_restore = resurrect.tab_state.default_on_pane_restore,
					})
				end
			end, {
				title = "Load Session",
				description = "Select session to load",
				fuzzy_description = "Search session: ",
				is_fuzzy = true,
			})
		end),
	},
	{
		key = "D",
		mods = "LEADER",
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
				description = "Select session to delete",
				fuzzy_description = "Search session to delete: ",
			})
		end),
	},

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
-- 5. VISUALS: Solarized Colors
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
-- 6. STATUS BAR
-- =========================================================
wezterm.on("update-right-status", function(window, pane)
	local name = window:active_key_table()
	local workspace = window:active_workspace()

	-- Default colors (Solarized Dark)
	local color = "#073642"
	local text = ""
	local status_icon = "  "
	local workspace_icon = "  "
	local workspace_color = "#eee8d5"
	local workspace_text_color = "#002b36"

	if name == "tab_mode" then
		name = " TAB "
		color = "#268bd2"
		text = " (n: new | x: close | r: rename | h/l: switch) "
		status_icon = "  "
	elseif name == "resize_mode" then
		name = " RESIZE "
		color = "#cb4b16"
		text = " (h/j/k/l: resize | Esc: exit) "
		status_icon = "  "
	elseif window:leader_is_active() then
		name = " LEADER "
		color = "#d33682"
		text = " (S: save | L: load | n/d: split | h/j/k/l: move) "
		status_icon = "  "

		-- Optional: Change workspace color when Leader is active to highlight it
		workspace_color = "#d33682"
		workspace_text_color = "#fdf6e3"
		workspace_icon = "  "
	end

	-- If a mode is active (Leader, Tab, Resize), show the specific status
	if name then
		window:set_right_status(wezterm.format({
			-- Workspace / Session Indicator
			{ Background = { Color = workspace_color } },
			{ Foreground = { Color = workspace_text_color } },
			{ Attribute = { Intensity = "Bold" } },
			{ Text = " " .. workspace_icon .. " " .. workspace .. " " },

			-- Mode Indicator (Leader/Tab/Resize)
			{ Background = { Color = color } },
			{ Foreground = { Color = "#fdf6e3" } },
			{ Attribute = { Intensity = "Bold" } },
			{ Text = status_icon .. name },

			-- Helper Text
			{ Background = { Color = "#002b36" } },
			{ Foreground = { Color = "#839496" } },
			{ Text = text },
		}))
	else
		-- Default Status (No specific mode active)
		window:set_right_status(wezterm.format({
			-- Workspace / Session Indicator
			{ Background = { Color = "#eee8d5" } },
			{ Foreground = { Color = "#002b36" } },
			{ Attribute = { Intensity = "Bold" } },
			{ Text = " " .. workspace_icon .. " " .. workspace .. " " },

			-- Default Help Text
			{ Background = { Color = "#002b36" } },
			{ Foreground = { Color = "#657b83" } },
			{ Text = " Ctrl+p: Leader | Ctrl+t: Tabs " },
		}))
	end
end)

return config
