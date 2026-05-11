hl.monitor({
	output = "DP-1",
	mode = "1920x1080@120Hz",
	position = "1920x0",
	scale = "1",
})

hl.monitor({
	output = "DP-2",
	mode = "1920x1080@60Hz",
	position = "0x0",
	scale = "1",
})

hl.monitor({
	output = "eDP-1",
	mode = "preferred",
	position = "0x0",
	scale = "1",
})

hl.workspace_rule({ workspace = "10", monitor = "DP-2", default = true })
