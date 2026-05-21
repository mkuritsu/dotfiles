hl.on("hyprland.start", function()
	if not IsUWSMActive() then
		hl.exec_cmd("dms run")
		hl.exec_cmd("vicinae server")
	else
		hl.exec_cmd("systemctl start --user dms")
		hl.exec_cmd("systemctl start --user vicinae")
	end
	hl.exec_cmd("systemctl start --user opentabletdriver")
	hl.exec_cmd("systemctl start --user hyprpolkitagent")
	hl.exec_cmd("flatpak run com.github.wwmm.easyeffects")
end)
