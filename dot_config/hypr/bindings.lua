local mainMod = "SUPER"

local terminal = "ghostty"
local fileManager = "nautilus"
local launcher = "vicinae toggle"
local lockScreen = "loginctl lock-session"

hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(launcher))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())

hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + B", hl.dsp.layout("togglesplit"))

hl.bind(mainMod .. " + SHIFT + E", function()
	if IsUWSMActive() then
		hl.dsp.exec_cmd("uwsm stop")
	else
		hl.dsp.exit()
	end
end)

hl.bind("Print", hl.dsp.exec_cmd("$XDG_CONFIG_HOME/hypr/scripts/screenshot.sh area"))
hl.bind("ALT+Print", hl.dsp.exec_cmd("$XDG_CONFIG_HOME/hypr/scripts/screenshot.sh monitor"))

hl.bind(mainMod .. " + ALT + L", hl.dsp.exec_cmd(lockScreen))
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
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

local focus_binds = {
	left = { "left", "h" },
	down = { "down", "j" },
	up = { "up", "k" },
	right = { "right", "l" },
}

for dir, binds in pairs(focus_binds) do
	for _, bind in ipairs(binds) do
		hl.bind(mainMod .. " + " .. bind, hl.dsp.focus({ direction = dir }))
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

-- GESTURES
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
-- hl.gesture({ fingers = 3, direction = "horizontal", action = "scroll_move" })
