local BEAR_FORCE_ONE_ADDON_PREFIX = "bfo"

local FONTS_DIR = "Interface\\AddOns\\BearForceOne\\Fonts\\"
local GRAPHICS_DIR = "Interface\\AddOns\\BearForceOne\\Graphics\\"
local SOUNDS_DIR = "Interface\\AddOns\\BearForceOne\\Sound\\"

local BOTTOM_PATH = GRAPHICS_DIR .. "bottom.tga"
local ROBERT_PATH = GRAPHICS_DIR .. "robert.tga"
local YURI_PATH = GRAPHICS_DIR .. "yuri.tga"
local ANIM_DURATION = 14

local BOYS_FONT_PATH = FONTS_DIR .. "BANANASP.TTF"

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

  -- Legion --
  ["Suramar"] = true,
  ["Azsuna"] = true,
  ["Highmountain"] = true,
  ["Val'sharah"] = true,
  ["Stormheim"] = true,
  ["Thunder Totem"] = true,
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

function createAnimationFrame(texture_file, initial_delay_s, side)
  local anim_frame = CreateFrame("Frame", "BearForceOne_Frame", UIParent)
  local h = anim_frame:GetParent():GetHeight()
  local w = h / 2
  local offset_x = h / 2
  local offset_y = 0

  if side == "LEFT" then
    anchor_point = "RIGHT"
  elseif side == "BOTTOM" then
    anchor_point = "TOP"
    w = anim_frame:GetParent():GetWidth()
    h = w / 4
    offset_x = 0
    offset_y = h
  else
    anchor_point = "LEFT"
    offset_x = offset_x * -1
  end

  anim_frame:SetPoint(anchor_point, UIParent, side, 0, 0)
  anim_frame:SetFrameStrata("HIGH")

  anim_frame:SetSize(w, h)
  anim_frame:Hide()

  local texture = anim_frame:CreateTexture()
  texture:SetAllPoints()
  texture:SetTexture(texture_file)

  local group = texture:CreateAnimationGroup()

  local initial_delay = group:CreateAnimation("Animation")
  initial_delay:SetDuration(initial_delay_s)
  initial_delay:SetOrder(0)

  local translate = group:CreateAnimation("Translation")
  translate:SetOffset(offset_x, offset_y)
  translate:SetDuration(0.2)
  translate:SetOrder(1)

  local delay = group:CreateAnimation("Animation")
  delay:SetDuration(ANIM_DURATION - initial_delay_s)
  delay:SetOrder(1)

  local translate_back = group:CreateAnimation("Translation")
  translate_back:SetOffset(offset_x * -1, offset_y * -1)
  translate_back:SetDuration(0.8)
  translate_back:SetOrder(2)

  anim_frame:SetScript("OnShow", function(self)
    group:Play()
  end)

  group:SetScript("OnFinished", function(self)
    anim_frame:Hide()
  end)

  return anim_frame
end

function createTextScroll(font_size, direction, y_offset)
  textFrame =  CreateFrame("Frame", "BearForceOne_Frame", UIParent)
  if direction == "LEFT" then
    anchor_point = "BOTTOMRIGHT"
    translation_offset = textFrame:GetParent():GetWidth() * -5
  else
    anchor_point = "BOTTOMLEFT"
    translation_offset = textFrame:GetParent():GetWidth() * 5
  end

  textFrame:ClearAllPoints()
  textFrame:SetHeight(font_size)
  textFrame:SetWidth(textFrame:GetParent():GetWidth() * 4)
  textFrame:Hide()
  textFrame.text = textFrame:CreateFontString(nil, "HIGH", "PVPInfoTextFont")
  textFrame.text:SetAllPoints()
  textFrame:SetPoint(direction, UIParent, anchor_point, 0, y_offset)
  textFrame.text:SetFont(BOYS_FONT_PATH, font_size, "")
  textFrame.text:SetText(string.rep("BOYS    ", 50))
  textFrame.text:SetTextColor(math.random(), math.random(), math.random())
  textFrame:SetAlpha(1)

  local group = textFrame:CreateAnimationGroup()

  local translate = group:CreateAnimation("Translation")
  translate:SetOffset(translation_offset, 0)
  translate:SetDuration(ANIM_DURATION)
  translate:SetOrder(1)

  textFrame:SetScript("OnShow", function(self)
    group:Play()
  end)

  group:SetScript("OnFinished", function(self)
    textFrame:Hide()
  end)

  return textFrame
end

function events:ACHIEVEMENT_EARNED()
  playBFOSound(ACHIEVEMENT_SOUND)

  anim_frame = createAnimationFrame(ROBERT_PATH, 0, "LEFT")
  anim_frame2 = createAnimationFrame(YURI_PATH, 0.4, "RIGHT")
  anim_frame3 = createAnimationFrame(BOTTOM_PATH, 0.8, "BOTTOM")

  anim_frame:Show()
  anim_frame2:Show()
  anim_frame3:Show()

  for i = 0, UIParent:GetWidth(), 150 do
    if ((i / 75) % 4 == 0) then
      textFrame = createTextScroll(75, "RIGHT", i)
    else
      textFrame = createTextScroll(75, "LEFT", i)
    end
    textFrame:Show()
  end
end

function events:PLAYER_LEVEL_UP()
  events:ACHIEVEMENT_EARNED()
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
SLASH_BOYBOYSBOYS1 = '/bbb';
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
