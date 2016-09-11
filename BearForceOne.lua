local BEAR_FORCE_ONE_ADDON_PREFIX = "bfo"

local SOUNDS_DIR = "Interface\\AddOns\\BearForceOne\\Sound\\"

local BEAR_FORCE_ONE_MUSIC = SOUNDS_DIR .. "bfo.ogg"
local BOSS_MUSIC = SOUNDS_DIR .. "mgs.ogg"
local MGS_FULL_MUSIC = SOUNDS_DIR .. "mgs_full.ogg"

local ACHIEVEMENT_SOUND = SOUNDS_DIR .. "achievement.ogg"
local NEW_PARTY_MEMBER_SOUND = SOUNDS_DIR .. "party join.ogg"
local PLAYER_DEATH_SOUND = SOUNDS_DIR .. "death.ogg"

local PVP_KILLS_SOUNDS = {
  SOUNDS_DIR .. "achievement.ogg",
  SOUNDS_DIR .. "death.ogg",
  SOUNDS_DIR .. "enter alliance.ogg",
  SOUNDS_DIR .. "honor kill.ogg",
  SOUNDS_DIR .. "party join.ogg",
}

local playingBFOMusic = false
local lastPvpSoundTime = 0

local playersInGroup = 1 -- see GROUP_ROSTER_UPDATE

local ALLIANCE_ZONES = {
  ["Ashenvale"] = true,
  ["Azuremyst Isle"] = true,
  ["Bloodmyst Isle"] = true,
  ["Darkshore"] = true,
  ["Dun Morogh"] = true,
  ["Duskwood"] = true,
  ["Elwynn Forest"] = true,
  ["Loch Modan"] = true,
  ["Redridge Mountains"] = true,
  ["Teldrassil"] = true,
  ["Westfall"] = true,
  ["Wetlands"] = true,
}

local defaultConfig = {
  EMOTES_ENABLED = true,
  MUSIC_ENABLED = true,
  SOUND_ENABLED = true,
  MGS_PERCENT = 0,
}

-- Overriding DoEmote is probably a bad idea...
local originalDoEmote = DoEmote;
DoEmote = function(emoteName)
  if bfoConfig.EMOTES_ENABLED and IsInGuild() then
    SendAddonMessage(BEAR_FORCE_ONE_ADDON_PREFIX, emoteName, "GUILD")
  else
    originalDoEmote(emoteName)
  end
end

function playBFOMusic()
  if bfoConfig.MUSIC_ENABLED and not playingBFOMusic then
    PlayMusic(BEAR_FORCE_ONE_MUSIC)
    playingBFOMusic = true
  end
end

function stopBFOMusic()
  if bfoConfig.MUSIC_ENABLED then
    StopMusic();
    playingBFOMusic = false
  end
end

function playBFOSound(soundFile)
  if bfoConfig.SOUND_ENABLED then
    PlaySoundFile(soundFile)
  end
end

local frame, events = CreateFrame("Frame"), {};

function events:ACHIEVEMENT_EARNED()
  playBFOSound(ACHIEVEMENT_SOUND)
end

function events:CHAT_MSG_ADDON(prefix, msg, type, sender)
  if prefix == BEAR_FORCE_ONE_ADDON_PREFIX and bfoConfig.EMOTES_ENABLED then originalDoEmote(msg) end
end

function events:GROUP_ROSTER_UPDATE()
  if GetNumGroupMembers() > playersInGroup then
    playBFOSound(NEW_PARTY_MEMBER_SOUND)
  end
  playersInGroup = GetNumGroupMembers()
end

function events:INSTANCE_ENCOUNTER_ENGAGE_UNIT()
  if bfoConfig.MUSIC_ENABLED then
    PlayMusic(BOSS_MUSIC)
  end
end

function events:PLAYER_DEAD()
  playBFOSound(PLAYER_DEATH_SOUND)
end

function events:PLAYER_PVP_KILLS_CHANGED()
  if GetTime() > lastPvpSoundTime + 0.5 and bfoConfig.SOUND_ENABLED then
    PlaySoundFile(PVP_KILLS_SOUNDS[random(#PVP_KILLS_SOUNDS)])
    lastPvpSoundTime = GetTime()
  end

end

function events:ZONE_CHANGED_NEW_AREA()
  if math.random(0,100) < bfoConfig.MGS_PERCENT then
    PlayMusic(MGS_FULL_MUSIC)
  elseif ALLIANCE_ZONES[GetZoneText()] then
    playBFOMusic()
  else
    stopBFOMusic()
  end
end

-- I should confirm that this actually does something
function events:VARIABLES_LOADED(addonName)
  if not bfoConfig then
    bfoConfig = defaultConfig;
  end
end

SLASH_BOYBOYSBOYS1 = '/boysboysboys';
local function handler()
 events:ACHIEVEMENT_EARNED()
end
SlashCmdList["BOYBOYSBOYS"] = handler;

-- This may or may not be ripped straight out of the beginner's tutorial
frame:SetScript("OnEvent", function(self, event, ...)
 events[event](self, ...); -- call one of the functions above
end);
for k, v in pairs(events) do
 frame:RegisterEvent(k); -- Register all events for which handlers have been defined
end

RegisterAddonMessagePrefix(BEAR_FORCE_ONE_ADDON_PREFIX)
