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

local replyQueue = {}
local guildReplyButton

local function showReplyPreview(button)
	local draft = replyQueue[1]
	if not draft then return end
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	GameTooltip:SetText(draft.lines[1], 1, 1, 1, 1, true)
	if draft.sender then GameTooltip:AddLine("Requested by " .. draft.sender, 1, 1, 1, true) end
	if #replyQueue > 1 then GameTooltip:AddLine((#replyQueue - 1) .. " more waiting", 1, 1, 1) end
	GameTooltip:AddLine("Right-drag to move. Shift-right-drag to resize.", 0.8, 0.8, 0.8, true)
	GameTooltip:Show()
end

local function updateReplyButton()
	if #replyQueue == 0 then
		guildReplyButton:Hide()
		return
	end
	guildReplyButton:SetText(#replyQueue > 1 and string.format("Reply (%d)", #replyQueue) or "Reply")
	guildReplyButton:Show()
	if GameTooltip:IsOwned(guildReplyButton) then showReplyPreview(guildReplyButton) end
end

local function dismissReply()
	table.remove(replyQueue, 1)
	updateReplyButton()
end

local function replyInGuild()
	local draft = replyQueue[1]
	if not draft then return end
	if draft.isTest then
		dismissReply()
		ns.Print(draft.lines[1])
		return
	end
	if not ns.CanReply() then
		dismissReply()
		return
	end
	local line = draft.lines[1]
	if IsShiftKeyDown() then
		local openChat = (ChatFrameUtil and ChatFrameUtil.OpenChat) or ChatFrame_OpenChat
		if not openChat then
			ns.Print("your client couldn't open the guild chat box.")
			return
		end
		openChat((SLASH_GUILD1 or "/g") .. " " .. line, DEFAULT_CHAT_FRAME)
	else
		if C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then
			ns.Print("WoW is blocking addon chat sends. Shift-click Reply to fill the guild chat box.")
			return
		end
		-- Send one line within the hardware click, as in the custom Price Answer button.
		local sendGuild = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage
		sendGuild(line, "GUILD")
	end
	table.remove(draft.lines, 1)
	if #draft.lines == 0 then dismissReply() else updateReplyButton() end
end

local function showGuildReply(lines, isTest, sender)
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
		local close = CreateFrame("Button", nil, guildReplyButton, "UIPanelCloseButton")
		close:SetSize(10, 10)
		close:SetPoint("BOTTOMLEFT", guildReplyButton, "TOPRIGHT", -3, -3)
		close:SetScript("OnClick", dismissReply)
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
	if replyQueue[1] and replyQueue[1].isTest then replyQueue = {} end
	replyQueue[#replyQueue + 1] = { lines = lines, isTest = isTest, sender = sender }
	updateReplyButton()
	ns.PlayReplySound()
end

function ns.ShowTestReply(showQueue)
	if replyQueue[1] and not replyQueue[1].isTest then
		ns.Print("Finish or dismiss the queued guild replies before testing.")
		return
	end
	local age = ns.db.showAge and ns.TSMScanAge()
	local line = "Test price reply: Copper Ore, 25 silver."
	if age then line = line .. " (" .. age .. ")" end
	showGuildReply({ line }, true, showQueue and "Sample requester 1" or nil)
	if showQueue then
		replyQueue[2] = { lines = { "Test price reply: Linen Cloth, 40 silver." }, isTest = true, sender = "Sample requester 2" }
		replyQueue[3] = { lines = { "Test price reply: Peacebloom, 1 gold." }, isTest = true, sender = "Sample requester 3" }
		updateReplyButton()
	end
	if age then ns.Print(age) end
end

function ns.HideTestReply()
	if replyQueue[1] and replyQueue[1].isTest then
		replyQueue = {}
		updateReplyButton()
	end
end


local sayTestArmed = false

function ns.PreviewRequest(text)
	if #ns.ReadItems(text) == 0 then
		ns.Print("Shift-click an item to insert its link into the test request.")
		return
	end
	if not ns.CanAnswer(text) then
		ns.Print(ns.MissingPriceAddon() .. ".")
		return
	end
	ns.WhenLoaded(text, function()
		local lines = ns.BuildReply(text) or {}
		for _, line in ipairs(lines) do ns.Print(line) end
		if ns.db.provider == "auctionator" or not TSM_API then return end
		if not ns.db.showAge then
			ns.Print("TSM age is disabled. Enable 'Say how old prices are' in PriceCheck Reply.")
		elseif not ns.TSMScanAge() then
			local imported = PriceCheckReplyGuild_TSMRealmUpdates
			if type(imported) ~= "table" then
				ns.Print("TSM age is unavailable. Check that PriceCheck Reply Guild - TSM Realm Data is enabled in WoW's AddOns list.")
			else
				ns.Print("TSM age is unavailable for " .. ns.TSMCurrentRealm() .. ". Refresh TSM Desktop App data and rerun the timestamp importer.")
			end
		end
	end)
end

function ns.ArmSayTest()
	sayTestArmed = true
	ns.Print("In Say, send ?pc followed by an item link. The result will appear only in your chat window.")
end

local function onChat(_, event, text, sender, _, _, _, flags, _, _, _, _, _, guid)
	local isSay = event == "CHAT_MSG_SAY"
	if isSay then
		if not sayTestArmed then return end
	elseif not ns.CanReply() then
		return
	end
	if not (ns.Readable(text) and ns.Readable(sender) and ns.Readable(guid) and ns.Readable(flags)) then return end
	if type(text) ~= "string" or type(sender) ~= "string" or flags == "GM" or flags == "DEV" then return end
	local shortName = Ambiguate and Ambiguate(sender, "none") or sender
	local ownMessage = (guid and guid == UnitGUID("player")) or shortName == UnitName("player")
	if not hasTrigger(text) then return end
	if isSay then
		if not ownMessage then return end
		sayTestArmed = false
		ns.PreviewRequest(text)
		return
	end
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
		showGuildReply(lines, false, shortName)
	end)
end

function ns.StartListening()
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("CHAT_MSG_GUILD")
	frame:RegisterEvent("CHAT_MSG_SAY")
	frame:SetScript("OnEvent", onChat)
end

function ns.SelfTest()
	ns.Print("Use /pcrguild test [item link] for a private price preview, or /pcrguild test say to test from Say.")
	ns.Print("Use /pcrguild sound to see and change the reply alert.")
end
