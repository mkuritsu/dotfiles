hl.on("hyprland.start", function()
	hl.exec_cmd("systemctl start --user dms || dms run")
	hl.exec_cmd("systemctl start --user vicinae || vicinae server")
end)
