local _, ns = ...

local choices = {
	{ key = "whisper", label = "Whisper", kit = "TELL_MESSAGE", id = 3081 },
	{ key = "ping", label = "Map ping", kit = "MAP_PING", id = 3175 },
	{ key = "ready", label = "Ready check", kit = "READY_CHECK", id = 8960 },
	{ key = "raid", label = "Raid warning", kit = "RAID_WARNING", id = 8959 },
	{ key = "off", label = "Off" },
}

local function findSound(key)
	for _, choice in ipairs(choices) do
		if choice.key == key then return choice end
	end
end

local function selectedSound()
	return findSound(ns.settings.replySound) or choices[1]
end

local function playSound(choice, preview)
	if not choice.id then
		if preview then ns.Print("Reply sound is off.") end
		return
	end

	local id = (SOUNDKIT and SOUNDKIT[choice.kit]) or choice.id
	local play = (C_Sound and C_Sound.PlaySound) or PlaySound
	local played = play and play(id, "Master")
	if preview then
		local sound = string.format("%s (%s, ID %d)", choice.label, choice.kit, id)
		if played then
			ns.Print("Playing " .. sound .. " on the Master channel.")
		else
			ns.Print("WoW did not start " .. sound .. ". Check that Sound is enabled in WoW's Audio settings.")
		end
	end
end

function ns.PlayReplySound()
	playSound(selectedSound())
end

function ns.SoundCommand(command)
	local previewKey = command:match("^preview%s+(.+)$")
	if command == "preview" then
		playSound(selectedSound(), true)
		return
	end

	local choice = findSound(previewKey or command)
	if choice then
		if not previewKey then
			ns.settings.replySound = choice.key
			ns.Print("Reply sound set to " .. choice.label .. ".")
		end
		playSound(choice, true)
		return
	end

	if command ~= "" then ns.Print("Unknown reply sound.") end
	ns.Print("Current reply sound — " .. selectedSound().label)
	for _, option in ipairs(choices) do
		ns.Print("/pcrguild sound " .. option.key .. " — " .. option.label)
	end
	ns.Print("Use /pcrguild sound preview to hear the current sound, or add a sound name to try it without changing your selection.")
end
