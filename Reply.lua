local _, ns = ...

local function hasShortTrigger(text)
	local from = 1
	while true do
		local at = text:find("?", from, true)
		if not at then return false end
		if at == 1 or text:sub(at - 1, at - 1):find("%s") then
			local rest = text:sub(at + 1)
			if rest:find("^%s*|c") or rest:find("^%s*[xX]?%s*%d+%s*[xX]?%s*|c") then return true end
		end
		from = at + 1
	end
end

-- Whether the message is a request: "?pc" as a word of its own outside item links (upper and
-- lower case don't matter), or "?" right before an item link.
local function hasTrigger(text)
	return ns.HasWord(ns.Words(text), ns.TRIGGER) or hasShortTrigger(text)
end

local warnedNoAddon = false

local guildDraft
local guildReplyButton
local testDraft

local function showReplyPreview(button)
	if not guildDraft then return end
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	GameTooltip:SetText(guildDraft[1], 1, 1, 1, 1, true)
	GameTooltip:AddLine("Right-drag to move. Shift-right-drag to resize.", 0.8, 0.8, 0.8, true)
	GameTooltip:Show()
end

local function clearDraft()
	guildDraft = nil
	testDraft = nil
	guildReplyButton:Hide()
end

local function replyInGuild()
	if not guildDraft then return end
	if testDraft then
		clearDraft()
		ns.Print("Reply button test clicked.")
		return
	end
	if not ns.CanReply() then
		clearDraft()
		return
	end
	local line = guildDraft[1]
	if IsShiftKeyDown() then
		local openChat = (ChatFrameUtil and ChatFrameUtil.OpenChat) or ChatFrame_OpenChat
		if not openChat then
			ns.Print("your client couldn't open the guild chat box.")
			return
		end
		openChat((SLASH_GUILD1 or "/g") .. " " .. line, DEFAULT_CHAT_FRAME)
	else
		if InCombatLockdown() or UnitAffectingCombat("player")
			or (C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown()) then
			ns.Print("leave combat before trying to send a guild reply.")
			return
		end
		-- Send one line within the hardware click, as in the custom Price Answer button.
		local sendGuild = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage
		sendGuild(line, "GUILD")
	end
	table.remove(guildDraft, 1)
	if #guildDraft == 0 then
		clearDraft()
	elseif GameTooltip:IsOwned(guildReplyButton) then
		showReplyPreview(guildReplyButton)
	end
end

local function showGuildReply(lines, isTest)
	if not guildReplyButton then
		guildReplyButton = CreateFrame("Button", nil, UIParent, "UIPanelButtonTemplate")
		local size = ns.settings.size
		local width = type(size) == "table" and tonumber(size.width) or 64
		local height = type(size) == "table" and tonumber(size.height) or 26
		guildReplyButton:SetSize(math.max(64, width), math.max(26, height))
		guildReplyButton:SetMovable(true)
		guildReplyButton:SetResizable(true)
		if guildReplyButton.SetResizeBounds then
			guildReplyButton:SetResizeBounds(64, 26)
		else
			guildReplyButton:SetMinResize(64, 26)
		end
		guildReplyButton:SetClampedToScreen(true)
		local position = ns.settings.position
		if type(position) == "table" and type(position.x) == "number" and type(position.y) == "number" then
			guildReplyButton:SetPoint("CENTER", UIParent, "BOTTOMLEFT",
				position.x * UIParent:GetWidth(), position.y * UIParent:GetHeight())
		else
			guildReplyButton:SetPoint("LEFT", UIParent, "LEFT", 4, 0)
		end
		guildReplyButton:SetText("Reply")
		local close = CreateFrame("Button", nil, guildReplyButton, "UIPanelCloseButton")
		close:SetSize(10, 10)
		close:SetPoint("BOTTOMLEFT", guildReplyButton, "TOPRIGHT", -3, -3)
		close:SetScript("OnClick", clearDraft)
		guildReplyButton:RegisterForClicks("LeftButtonUp")
		guildReplyButton:RegisterForDrag("RightButton")
		guildReplyButton:SetScript("OnClick", replyInGuild)
		guildReplyButton:SetScript("OnEnter", showReplyPreview)
		guildReplyButton:SetScript("OnLeave", function(button)
			if GameTooltip:IsOwned(button) then GameTooltip:Hide() end
		end)
		guildReplyButton:SetScript("OnHide", guildReplyButton:GetScript("OnLeave"))
		guildReplyButton:SetScript("OnDragStart", function(button)
			if GameTooltip:IsOwned(button) then GameTooltip:Hide() end
			if IsShiftKeyDown() then
				button:StartSizing("BOTTOMRIGHT")
			else
				button:StartMoving()
			end
		end)
		guildReplyButton:SetScript("OnDragStop", function(button)
			button:StopMovingOrSizing()
			button:SetUserPlaced(false)
			local x, y = button:GetCenter()
			local left, bottom = UIParent:GetLeft(), UIParent:GetBottom()
			ns.settings.position = {
				x = (x - left) / UIParent:GetWidth(),
				y = (y - bottom) / UIParent:GetHeight(),
			}
			ns.settings.size = { width = button:GetWidth(), height = button:GetHeight() }
		end)
	end
	guildDraft = lines
	testDraft = isTest
	guildReplyButton:Show()
	if GameTooltip:IsOwned(guildReplyButton) then showReplyPreview(guildReplyButton) end
end

function ns.ShowTestReply()
	showGuildReply({ "Test price reply: Copper Ore, 25 silver." }, true)
end

function ns.HideTestReply()
	if testDraft then clearDraft() end
end


local function onGuildChat(_, _, text, sender, _, _, _, flags, _, _, _, _, _, guid)
	if not ns.CanReply() then return end
	if not (ns.Readable(text) and ns.Readable(sender) and ns.Readable(guid) and ns.Readable(flags)) then return end
	if type(text) ~= "string" or type(sender) ~= "string" or flags == "GM" or flags == "DEV" then return end
	local shortName = Ambiguate and Ambiguate(sender, "none") or sender
	local ownMessage = (guid and guid == UnitGUID("player")) or shortName == UnitName("player")
	if not hasTrigger(text) then return end
	if not ns.CanAnswer(text) then
		if not warnedNoAddon then
			warnedNoAddon = true
			ns.Print(shortName .. " asked for a price, but " .. ns.MissingPriceAddon() .. ".")
		end
		return
	end
	ns.WhenLoaded(text, function()
		if not ns.CanReply() then return end
		local lines = ns.BuildReply(text)
		if not lines then
			if ownMessage then ns.Print("Self-test needs a real item link. Shift-click an item to insert it.") end
			return
		end
		showGuildReply(lines)
	end)
end

function ns.StartListening()
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("CHAT_MSG_GUILD")
	frame:SetScript("OnEvent", onGuildChat)
end

function ns.SelfTest()
	if not IsInGuild() then
		ns.Print("Join a guild before testing guild price requests.")
		return
	end
	if not ns.CanReply() then
		ns.Print("Enable PriceCheck Reply before testing.")
		return
	end
	ns.Print("Your own guild requests count automatically. Send ?pc followed by a shift-clicked item link in guild chat to test.")
end
