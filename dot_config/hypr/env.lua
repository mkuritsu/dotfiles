if not IsUWSMActive() then
	hl.env("XCURSOR_SIZE", "24")
	hl.env("XCURSOR_THEME", "Adwaita")
	hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")

	hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
	hl.env("XDG_SESSION_TYPE", "wayland")
	hl.env("XDG_SESSION_DESKTOP", "Hyprland")

	hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
end
