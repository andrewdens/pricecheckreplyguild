local _, ns = ...

SLASH_PRICECHECKREPLYGUILD1 = "/pcrguild"
SlashCmdList.PRICECHECKREPLYGUILD = function(message)
	local command = strtrim(message):lower()
	if command == "test" then
		ns.ShowTestReply()
	elseif command == "test hide" then
		ns.HideTestReply()
	else
		ns.SelfTest()
	end
end
