local _, ns = ...

SLASH_PRICECHECKREPLYGUILD1 = "/pcrguild"
SlashCmdList.PRICECHECKREPLYGUILD = function(message)
	local text = strtrim(message)
	local command = text:lower()
	if command == "sound" or command:match("^sound%s+") then
		ns.SoundCommand(command:match("^sound%s+(.+)$") or "")
	elseif command == "test" then
		ns.ShowTestReply()
	elseif command == "test queue" then
		ns.ShowTestReply(true)
	elseif command == "test hide" then
		ns.HideTestReply()
	elseif command == "test say" then
		ns.ArmSayTest()
	elseif command:match("^test%s+") then
		ns.PreviewRequest(text:match("^%S+%s+(.+)$"))
	else
		ns.SelfTest()
	end
end
