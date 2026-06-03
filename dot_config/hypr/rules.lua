-- WINDOWRULES
hl.window_rule({
	name = "suppress-maximize-events",
	match = {
		class = ".*",
	},
	suppress_event = "maximize",
})

hl.window_rule({
	name = "bitwarden",
	match = {
		class = "chrome-nngceckbapebfimnlniiiahkandclblb-Default",
	},
	float = true,
	no_screen_share = true,
})

hl.window_rule({
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},
	no_focus = true,
})

hl.window_rule({
	name = "float-nautilus-preview",
	match = {
		class = "org.gnome.NautilusPreviewer",
	},
	float = true,
})

hl.window_rule({
	name = "float-steam-friends-list",
	match = {
		class = "steam",
		title = "Friends List",
	},
	float = true,
})

hl.window_rule({
	match = {
		group = true,
	},
	no_anim = true,
})

-- LAYERRULES
hl.layer_rule({
	name = "vicinae-blur",
	match = {
		namespace = "vicinae",
	},
	blur = true,
})
