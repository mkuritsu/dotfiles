hl.config({
	input = {
		kb_layout = "us,pt",
		kb_variant = "altgr-intl",
		follow_mouse = 1,
		accel_profile = "flat",
		sensitivity = 0,

		touchpad = {
			natural_scroll = true,
			disable_while_typing = true,
			scroll_factor = 0.3,
		},
	},
})

hl.device({
	name = "elan06fa:00-04f3:327e-touchpad",
	accel_profile = "adaptive",
})
