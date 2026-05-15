local value = os.getenv("UWSM_WAIT_VARNAMES")

if value == nil or value == "" then
	hl.env("XCURSOR_SIZE", "24")
	hl.env("XCURSOR_THEME", "Adwaita")
	hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
end
