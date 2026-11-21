local _, ns = ...

-- The same answer isn't sent to the same place twice within this many seconds. That also stops two
-- players running the addon from answering each other in a loop.
local REPEAT_WINDOW = 10
-- At most this many lines sent in any RATE_WINDOW seconds, so a flood of requests can't get the
-- player muted for spam.
local RATE_LINES, RATE_WINDOW = 8, 15
-- Seconds between the lines of one answer. Lines sent in the same moment can reach the asker out
-- of order (seen on WoW Forever), and the total has to come first.
local LINE_GAP = 0.3

local SendChat = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage
local selfTestUntil = 0

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

local lastSent = {}  -- place .. answer -> time sent
local sendTimes = {} -- times of recent lines, oldest first
local warnedRate, warnedNoAddon = false, false

local function roomToSend(count)
	local now = GetTime()
	while sendTimes[1] and now - sendTimes[1] > RATE_WINDOW do table.remove(sendTimes, 1) end
	return #sendTimes + count <= RATE_LINES
end

local function send(lines, chatType, target)
	-- Retail stops addons sending chat during boss fights, Mythic+ and PvP matches.
	if C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then return end

	local place = chatType .. ":" .. tostring(target or "")
	local answer = table.concat(lines, "\n")
	local now = GetTime()
	for key, sentAt in pairs(lastSent) do
		if now - sentAt >= REPEAT_WINDOW then lastSent[key] = nil end
	end
	if lastSent[place .. answer] and now - lastSent[place .. answer] < REPEAT_WINDOW then return end
	if not roomToSend(#lines) then
		if not warnedRate then
			warnedRate = true
			ns.Print("too many price requests at once; some went unanswered.")
		end
		return
	end
	lastSent[place .. answer] = now

	local function sendLine(line)
		SendChat(line, chatType, nil, target)
	end
	for i, line in ipairs(lines) do
		sendTimes[#sendTimes + 1] = now
		if i == 1 then
			sendLine(line)
		else
			C_Timer.After((i - 1) * LINE_GAP, function() sendLine(line) end)
		end
	end
end

local guildDraft
local guildReplyButton

local function hasGuildReplyButton(mode)
	return mode == "draft" or mode == "whisper"
end

function ns.ClearDraft()
	guildDraft = nil
	if guildReplyButton then guildReplyButton:Hide() end
end

local function replyInGuild()
	if not guildDraft or not hasGuildReplyButton(ns.GetMode()) or not IsInGuild() then
		ns.ClearDraft()
		return
	end
	if ns.CanAnswerIn("GUILD") then
		local lines = guildDraft
		ns.ClearDraft()
		send(lines, "GUILD")
		return
	end
	local openChat = (ChatFrameUtil and ChatFrameUtil.OpenChat) or ChatFrame_OpenChat
	if not openChat then
		ns.Print("your client couldn't open the guild chat box.")
		return
	end
	local line = table.remove(guildDraft, 1)
	if #guildDraft == 0 then ns.ClearDraft() end
	openChat((SLASH_GUILD1 or "/g") .. " " .. line, DEFAULT_CHAT_FRAME)
end

local function showGuildReply(lines)
	if not guildReplyButton then
		guildReplyButton = CreateFrame("Button", nil, UIParent, "UIPanelButtonTemplate")
		guildReplyButton:SetSize(64, 26)
		guildReplyButton:SetMovable(true)
		guildReplyButton:SetClampedToScreen(true)
		local position = ns.settings.position
		if type(position) == "table" and type(position.x) == "number" and type(position.y) == "number" then
			guildReplyButton:SetPoint("CENTER", UIParent, "BOTTOMLEFT",
				position.x * UIParent:GetWidth(), position.y * UIParent:GetHeight())
		else
			guildReplyButton:SetPoint("LEFT", UIParent, "LEFT", 4, 0)
		end
		guildReplyButton:SetText("Reply")
		guildReplyButton:RegisterForClicks("LeftButtonUp")
		guildReplyButton:RegisterForDrag("RightButton")
		guildReplyButton:SetScript("OnClick", replyInGuild)
		guildReplyButton:SetScript("OnDragStart", guildReplyButton.StartMoving)
		guildReplyButton:SetScript("OnDragStop", function(button)
			button:StopMovingOrSizing()
			button:SetUserPlaced(false)
			local x, y = button:GetCenter()
			local left, bottom = UIParent:GetLeft(), UIParent:GetBottom()
			ns.settings.position = {
				x = (x - left) / UIParent:GetWidth(),
				y = (y - bottom) / UIParent:GetHeight(),
			}
		end)
	end
	guildDraft = lines
	guildReplyButton:Show()
end


local function onGuildChat(_, _, text, sender, _, _, _, flags, _, _, _, _, _, guid)
	local mode = ns.GetMode()
	if mode == "off" or not IsInGuild() then return end
	if not (ns.Readable(text) and ns.Readable(sender) and ns.Readable(guid) and ns.Readable(flags)) then return end
	if type(text) ~= "string" or type(sender) ~= "string" or flags == "GM" or flags == "DEV" then return end
	local shortName = Ambiguate and Ambiguate(sender, "none") or sender
	local ownMessage = (guid and guid == UnitGUID("player")) or shortName == UnitName("player")
	if ownMessage and GetTime() >= selfTestUntil then return end
	if not hasTrigger(text) then return end
	if not ns.CanAnswer(text) then
		if not warnedNoAddon then
			warnedNoAddon = true
			ns.Print(shortName .. " asked for a price, but " .. ns.MissingPriceAddon() .. ".")
		end
		return
	end
	ns.WhenLoaded(text, function()
		if ns.GetMode() ~= mode or not IsInGuild() then return end
		local lines = ns.BuildReply(text)
		if not lines then return end
		if hasGuildReplyButton(mode) then showGuildReply(lines) end
		if mode == "draft" then return end
		ns.TakeTurns("GUILD", text, function()
			if ns.GetMode() ~= mode or not IsInGuild() then return end
			if mode == "whisper" or not ns.CanAnswerIn("GUILD") then
				local mainWhisper = PriceCheckReplyDB.guildReply
				if mainWhisper and mainWhisper ~= "off" then return end
				send(lines, "WHISPER", sender)
			else
				send(lines, "GUILD")
			end
		end)
	end)
end

function ns.StartListening()
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("CHAT_MSG_GUILD")
	frame:SetScript("OnEvent", onGuildChat)
end

function ns.SelfTest()
	selfTestUntil = GetTime() + 300
	ns.Print("For five minutes, your own guild price requests count for testing.")
end
