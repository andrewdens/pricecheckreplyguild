local ADDON_NAME, ns = ...

ns.ADDON_NAME = ADDON_NAME
ns.PREFIX = "|cff33ff99PriceCheck Reply - Guild:|r "

function ns.Print(text)
	DEFAULT_CHAT_FRAME:AddMessage(ns.PREFIX .. text)
end

-- Whether a value the game handed us can be read. In instances and combat the game can hide chat
-- from addons.
function ns.Readable(value)
	return not (issecretvalue and issecretvalue(value))
end

-- An item or battle pet link in chat. Retail links can carry a quality icon inside the name, so
-- the name runs up to the link's end rather than up to the next "|".
ns.LINK_PATTERN = "|c[^|]*|H(%a+):[^|]*|h.-|h|r"

-- A message's text without its item links, in lower case, so words can be looked for in it
-- without matching item names.
function ns.Words(text)
	return (text:gsub(ns.LINK_PATTERN, " "):lower())
end

-- Whether `word` (lower case) is in `words` (from ns.Words) on its own, not as part of a longer
-- word: "?pc" is in "?pc [x]" but not in "?pcs [x]".
function ns.HasWord(words, word)
	local startsWord, endsWord = word:find("^%w"), word:find("%w$")
	local from = 1
	while true do
		local first, last = words:find(word, from, true)
		if not first then return false end
		local before, after = words:sub(first - 1, first - 1), words:sub(last + 1, last + 1)
		if not (startsWord and before:find("%w")) and not (endsWord and after:find("%w")) then return true end
		from = first + 1
	end
end

---------------------------------------------------------------------------
-- Saved settings
---------------------------------------------------------------------------

-- What a message has to contain, besides an item link, to get an answer. A "?" right before a link
-- works too (see Reply.lua). Both are fixed, so everyone asks the same way.
ns.TRIGGER = "?pc"

-- Chats an addon can't write in when the realm restricts outgoing addon chat. Blizzard sets the
-- restriction per realm; Retail (12.1.5) and WoW Forever (1.60.1) realms have it, both tested in
-- game in November 2026, and there the game blocks addons from guild chat (and officer chat, which
-- goes to the same place) but lets party chat and whispers through.
local RESTRICTED_CHATS = { GUILD = true, OFFICER = true }

-- Whether addons can write in `chatType` chat on this realm. Where they can't, their hidden
-- messages don't get through either, so the players with the addon can't agree on one answerer
-- (see Turns.lua).
function ns.CanAnswerIn(chatType)
	if not RESTRICTED_CHATS[chatType] then return true end
	local restricted = C_ChatInfo and C_ChatInfo.AreOutgoingAddonChatMessagesRestricted
	if not restricted then return true end
	local ok, isRestricted = pcall(restricted)
	return not (ok and isRestricted)
end

local priceDefaults = {
	provider = "auto",       -- "auto" | "tsm" | "auctionator"
	askerPicks = true,       -- "tsm" or "auc" in a request picks the price addon
	tsmSource = "dbmarket",
	tsmSecond = "none",      -- a second TSM price to say next to the main one, or "none"
	showSource = true,       -- say where each price comes from
	showAge = true,          -- say how old an Auctionator price is
	showSaleRate = false,    -- say TSM's region sale rate
	showSoldPerDay = false,  -- say how many TSM says sell per day in the region
	vendorPrice = true,      -- mention the vendor price when there's no auction price
}

-- The main addon's price preferences can change while both addons are loaded.
ns.db = setmetatable({}, {
	__index = function(_, key)
		local value = PriceCheckReplyDB and PriceCheckReplyDB[key]
		if value ~= nil then return value end
		return priceDefaults[key]
	end,
})

function ns.GetMode()
	local main = PriceCheckReplyDB
	if not ns.settings or not main or main.enabled == false then return "off" end
	return ns.settings.mode
end

function ns.SetMode(mode)
	ns.settings.mode = mode
	if mode ~= "off" and PriceCheckReplyDB then
		local current = PriceCheckReplyDB.guildReply
		PriceCheckReplyDB.guildReply = type(current) == "string" and "off" or false
	end
	ns.ClearDraft()
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, _, name)
	if name ~= ADDON_NAME then return end
	self:UnregisterEvent("ADDON_LOADED")
	PriceCheckReplyGuildDB = PriceCheckReplyGuildDB or {}
	ns.settings = PriceCheckReplyGuildDB
	local old = PriceCheckReplyDB
	if not ns.settings.mode or ns.settings.migrationPending then
		local mode = old and old.guildReply
		if mode == "draft" or mode == "channel" or mode == "whisper" then
			ns.settings.position = old.guildReplyPosition
			ns.SetMode(mode)
		else
			ns.SetMode(ns.settings.mode or "off")
		end
		ns.settings.migrationPending = nil
	end
	ns.CreateOptions()
	ns.StartListening()
end)
