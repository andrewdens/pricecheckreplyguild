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

local priceDefaults = {
	provider = "auto",       -- "auto" | "tsm" | "auctionator"
	askerPicks = true,       -- "tsm" or "auc" in a request picks the price addon
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

function ns.CanReply()
	return PriceCheckReplyDB and PriceCheckReplyDB.enabled ~= false and IsInGuild()
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, _, name)
	if name ~= ADDON_NAME then return end
	self:UnregisterEvent("ADDON_LOADED")
	PriceCheckReplyGuildDB = PriceCheckReplyGuildDB or {}
	ns.settings = PriceCheckReplyGuildDB
	local main = PriceCheckReplyDB
	if main then
		if ns.settings.position == nil then ns.settings.position = main.guildReplyPosition end
		main.guildReply = type(main.guildReply) == "string" and "off" or false
	end
	ns.settings.mode = nil
	ns.settings.migrationPending = nil
	ns.StartListening()
end)
