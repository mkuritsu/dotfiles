local mainMod = "SUPER"

local terminal = "ghostty"
local fileManager = "nautilus"
local launcher = "vicinae toggle"
local lockScreen = "loginctl lock-session"

-- Utility functions
local function get_active_workspace()
	local workspace = hl.get_active_workspace()
	if hl.get_active_special_workspace() then
		workspace = hl.get_active_special_workspace()
	end
	return workspace
end

local function set_workspace_layout(workspace, layout)
	if workspace.special then
		hl.workspace_rule({ workspace = tostring(workspace.name), layout = layout })
	else
		hl.workspace_rule({ workspace = tostring(workspace.id), layout = layout })
	end
end

-- Misc binds
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind("ALT + SPACE", hl.dsp.exec_cmd(launcher))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + P", function()
	-- https://wiki.hypr.land/Configuring/Advanced-and-Cool/Uncommon-tips-and-tricks/#per-workspace-layouts
	local workspace = get_active_workspace()
	if not workspace then
		return
	end

	local layouts = { "dwindle", "scrolling", "master" } -- removed monocle, if I want a better monocle i just use groups
	local next_layout = "dwindle"
	for i = 1, #layouts do
		if layouts[i] == workspace.tiled_layout then
			local next_layout_idx = (i % #layouts) + 1
			next_layout = layouts[next_layout_idx]
			break
		end
	end

	set_workspace_layout(workspace, next_layout)
	hl.exec_cmd('notify-send -a Hyprland "Layout changed to ' .. next_layout .. '"')
end)

hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + B", hl.dsp.layout("togglesplit"))

hl.bind(mainMod .. " + SHIFT + E", function()
	if os.getenv("UWSM_WAIT_VARNAMES") then
		hl.exec_cmd("uwsm stop")
	else
		hl.dispatch(hl.dsp.exit())
	end
end)

hl.bind("Print", hl.dsp.exec_cmd("noctalia msg screenshot-region"))
hl.bind("ALT+Print", hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen"))

hl.bind(mainMod .. " + F10", hl.dsp.exec_cmd(lockScreen))
hl.bind(mainMod .. " + Y", hl.dsp.exec_cmd("hyprpicker --lowercase-hex --autocopy"))

hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + M", hl.dsp.window.fullscreen({ mode = "maximized" }))

-- MEDIA
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "r-1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "r+1" }))
hl.bind(mainMod .. " + CONTROL + mouse_down", hl.dsp.window.move({ workspace = "r-1" }))
hl.bind(mainMod .. " + CONTROL + mouse_up", hl.dsp.window.move({ workspace = "r+1" }))

hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- WORKSPACES
for i = 1, 10 do
	local key = i % 10
	hl.bind(mainMod .. " + " .. key, function()
		local monitor = hl.get_active_monitor().id
		local ws = i + 10 * monitor
		hl.dispatch(hl.dsp.focus({ workspace = ws }))
	end)

	hl.bind(mainMod .. " + SHIFT + " .. key, function()
		local monitor = hl.get_active_monitor().id
		local ws = i + 10 * monitor
		hl.dispatch(hl.dsp.window.move({ workspace = ws }))
	end)
end

local focus_binds = {
	left = { "left", "h" },
	down = { "down", "j" },
	up = { "up", "k" },
	right = { "right", "l" },
}

local function focus_or_switch_group(direction)
	return function()
		local active_window = hl.get_active_window()
		local group = active_window and active_window.group
		if group then
			local current_index = group.current_index
			local group_size = group.size
			local can_switch_tab =
				(direction == "left" and current_index > 1)
				or (direction == "right" and current_index < group_size)

			if can_switch_tab then
				if direction == "left" then
					hl.dispatch(hl.dsp.group.prev())
				else
					hl.dispatch(hl.dsp.group.next())
				end
				return
			end
		end

		hl.dispatch(hl.dsp.focus({ direction = direction }))
	end
end

for dir, binds in pairs(focus_binds) do
	for _, bind in ipairs(binds) do
		local focus = hl.dsp.focus({ direction = dir })
		if dir == "left" or dir == "right" then
			focus = focus_or_switch_group(dir)
		end

		hl.bind(mainMod .. " + " .. bind, focus)
		hl.bind(mainMod .. " + SHIFT + " .. bind, hl.dsp.window.move({ direction = dir }))
	end
end

hl.bind(mainMod .. " + CONTROL + left", hl.dsp.focus({ workspace = "r-1" }))
hl.bind(mainMod .. " + CONTROL + right", hl.dsp.focus({ workspace = "r+1" }))
hl.bind(mainMod .. " + CONTROL + h", hl.dsp.focus({ workspace = "r-1" }))
hl.bind(mainMod .. " + CONTROL + l", hl.dsp.focus({ workspace = "r+1" }))

hl.bind(mainMod .. " + SHIFT + CONTROL + left", hl.dsp.window.move({ workspace = "r-1" }))
hl.bind(mainMod .. " + SHIFT + CONTROL + right", hl.dsp.window.move({ workspace = "r+1" }))
hl.bind(mainMod .. " + SHIFT + CONTROL + h", hl.dsp.window.move({ workspace = "r-1" }))
hl.bind(mainMod .. " + SHIFT + CONTROL + l", hl.dsp.window.move({ workspace = "r+1" }))

-- Groups
hl.bind(mainMod .. " + G", hl.dsp.group.toggle())

hl.bind(mainMod .. " + ALT + H", hl.dsp.group.prev())
hl.bind(mainMod .. " + ALT + L", hl.dsp.group.next())
hl.bind(mainMod .. " + SHIFT + ALT + H", hl.dsp.group.move_window({ forward = false }))
hl.bind(mainMod .. " + SHIFT + ALT + L", hl.dsp.group.move_window({ forward = true }))

hl.bind(mainMod .. " + ALT + left", hl.dsp.group.prev())
hl.bind(mainMod .. " + ALT + right", hl.dsp.group.next())
hl.bind(mainMod .. " + SHIFT + ALT + left", hl.dsp.group.move_window({ forward = false }))
hl.bind(mainMod .. " + SHIFT + ALT + right", hl.dsp.group.move_window({ forward = true }))

hl.bind(mainMod .. " + TAB", hl.dsp.group.next())
hl.bind(mainMod .. " + SHIFT + TAB", hl.dsp.group.prev())

hl.bind("ALT + TAB", hl.dsp.layout("cyclenext"))
hl.bind("ALT + SHIFT + TAB", hl.dsp.layout("cycleprev"))

-- GESTURES
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
