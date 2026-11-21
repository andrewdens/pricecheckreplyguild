local _, ns = ...
local category

function ns.CreateOptions()
	local layout
	category, layout = Settings.RegisterVerticalLayoutCategory("PriceCheck Reply - Guild")
	local setting = Settings.RegisterAddOnSetting(category, "PRICECHECKREPLYGUILD_MODE", "mode",
		ns.settings, (Settings.VarType and Settings.VarType.String) or "string", "Guild chat", "off")
	setting:SetValueChangedCallback(function(_, value) ns.SetMode(value) end)
	local function choices()
		local options = Settings.CreateControlTextContainer()
		options:Add("off", "Don't answer")
		options:Add("draft", "Show a reply button")
		options:Add("channel", "Reply in guild chat automatically")
		options:Add("whisper", "Whisper the asker and show a reply button")
		return options:GetData()
	end
	layout:AddInitializer(Settings.CreateControlInitializer("PriceCheckReplyGuildSettingsDropdownTemplate",
		setting, choices, "Selecting an active mode here turns off the main addon's guild whispers."
		.. " Click Reply to send to guild chat. Right-drag the button to move it."))
	Settings.RegisterAddOnCategory(category)
end

SLASH_PRICECHECKREPLYGUILD1 = "/pcrguild"
SlashCmdList.PRICECHECKREPLYGUILD = function(message)
	if strtrim(message):lower() == "selftest" then
		ns.SelfTest()
	elseif not InCombatLockdown() then
		Settings.OpenToCategory(category:GetID())
	end
end
