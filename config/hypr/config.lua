hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 10,
		border_size = 3,
	},

	dwindle = {
		preserve_split = true,
	},

	misc = {
		middle_click_paste = false,
	},

	binds = {
		scroll_event_delay = 150,
	},

	decoration = {
		rounding = 0,
		blur = {
			enabled = true,
			size = 8,
			passes = 2,
			brightness = 0.9,
		},
	},

	group = {
		col = {
			border_active = "rgb(295675)",
		},

		groupbar = {
			enabled = true,
			gradients = true,
			height = 20,
			font_size = 12,
			indicator_gap = 0,
			indicator_height = 0,
			gradient_rounding = 0,
			gaps_out = 0,
			gaps_in = 0,
			font_family = "JetBrainsMono",
			font_weight_active = "semibold",
			font_weight_inactive = "semibold",
			col = {
				active = "rgb(295675)",
				inactive = "rgb(222222)",
			},
		},
	},
})
