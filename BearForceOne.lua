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

-- Dungeon
local QUEUE_SOUND = SOUNDS_DIR .. "pushbutton.ogg"
local KILL_BOSS_SOUND = SOUNDS_DIR .. "pushbutton.ogg"
local WIPE_SOUND = SOUNDS_DIR .. "pushbutton.ogg"

local PVP_KILLS_SOUNDS = {
  SOUNDS_DIR .. "achievement.ogg",
  SOUNDS_DIR .. "death.ogg",
  SOUNDS_DIR .. "enter alliance.ogg",
  SOUNDS_DIR .. "honor kill.ogg",
  SOUNDS_DIR .. "party join.ogg",
}

local NUM_DPS_SOUNDS = 7
local NUM_ENCOUNTER_SOUNDS = 7
local NUM_HEALER_SOUNDS = 6
local NUM_INTERRUPT_SOUNDS = 8
local NUM_TANK_SOUNDS = 8
local NUM_VICTORY_SOUNDS = 7
local NUM_WIPE_SOUNDS = 8

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
  ANIM_ENABLED = true,
  MGS_PERCENT = 0,
  DUNGEON_SOUND_ENABLED = true,
}

-- Overriding DoEmote is probably a bad idea...
local originalDoEmote = DoEmote;
DoEmote = function(emoteName)
  if bfoConfig.EMOTES_ENABLED and IsInGroup() then
    C_ChatInfo.SendAddonMessage(BEAR_FORCE_ONE_ADDON_PREFIX, "emote " .. emoteName, "PARTY")
  else
    originalDoEmote(emoteName)
  end
end

function MaybePlaySound(name)
  if bfoConfig.EMOTES_ENABLED then
    PlaySound(name)
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

function playDungeonSound(soundFile)
  if bfoConfig.DUNGEON_SOUND_ENABLED then
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
  anim_frame:SetFrameStrata("BACKGROUND")

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
  textFrame:SetFrameStrata("BACKGROUND")
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

  if bfoConfig.ANIM_ENABLED then
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
end

function events:PLAYER_LEVEL_UP()
  events:ACHIEVEMENT_EARNED()
end

function events:CHAT_MSG_ADDON(prefix, msg, type, sender)
 if prefix ~= BEAR_FORCE_ONE_ADDON_PREFIX or not bfoConfig.EMOTES_ENABLED then return end

 type, name = string.match(msg, "(%S+) (%S+)")

 if type == "emote" then originalDoEmote(name) end
 if type == "sound" then MaybePlaySound(name) end
end

function events:GROUP_ROSTER_UPDATE()
  if GetNumGroupMembers() > playersInGroup then
    playBFOSound(NEW_PARTY_MEMBER_SOUND)
  end
  playersInGroup = GetNumGroupMembers()
end

function events:ENCOUNTER_START()
  if bfoConfig.MUSIC_ENABLED then
    PlayMusic(BOSS_MUSIC)
  end

  playDungeonSound(SOUNDS_DIR .. "encounter" .. math.random(NUM_ENCOUNTER_SOUNDS) .. ".ogg")
end

function events:ENCOUNTER_END(encounterID, encounterName, difficultyID, groupSize, success)
  if bfoConfig.MUSIC_ENABLED then
    StopMusic()
  end
  if success == 1 then
    playDungeonSound(SOUNDS_DIR .. "victory" .. math.random(NUM_VICTORY_SOUNDS) .. ".ogg")
  else
    playDungeonSound(SOUNDS_DIR .. "wipe" .. math.random(NUM_WIPE_SOUNDS) .. ".ogg")
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

function events:LFG_ROLE_CHECK_SHOW()
  playDungeonSound(QUEUE_SOUND)
end

-- I should confirm that this actually does something
function events:VARIABLES_LOADED(addonName)
  if not bfoConfig then
    bfoConfig = defaultConfig;
  end

  if not bfoConfig.DUNGEON_SOUND_ENABLED then
    bfoConfig.DUNGEON_SOUND_ENABLED = defaultConfig.DUNGEON_SOUND_ENABLED
  end
end

local dps_cooldowns = {
  [275699] = true, -- Apocalypse (Death Knight)
  [42650] = true, -- Army of the Dead (Death Knight)
  [47568] = true, -- Empower Rune Weapon (Death Knight)
  [187827] = true, -- Metamorphosis (Demon Hunter)
  [106951] = true, -- Berserk (Druid)
  [194223] = true, -- Celestial Alignment (Druid)
  [186289] = true, -- Aspect of the Eagle (Hunter)
  [19574] = true, -- Bestial Wrath (Hunter)
  [231548] = true, -- Bestial Wrath r2 (Hunter)
  [266779] = true, -- Coordinated Assault (Hunter)
  [193256] = true, -- Trueshot (Hunter)
  [12042] = true, -- Arcane Power (Mage)
  [190319] = true, -- Combustion (Mage)
  [12472] = true, -- Icy Veins (Mage)
  [190319] = true, -- Combustion (Mage)
  [34433] = true, -- Shadowfiend (Priest)
  [13750] = true, -- Adrenaline Rush (Rogue)
  [121471] = true, -- Shadow Blades (Rogue)
  [79140] = true, -- Vendetta (Rogue)
  [205180] = true, -- Summon Darkglare (Warlock)
  [265187] = true, -- Summon Demonic Tyrant (Warlock)
  [1122] = true, -- Summon Infernal (Warlock)
  [227847] = true, -- Bladestorm (Warrior)
  [1719] = true, -- Recklessness (Warrior)
}

local healer_cooldowns = {
  [29166] = true, -- Innervate (Druid)
  [740] = true, -- Tranquility (Druid)
  [116849] = true, -- Life Cocoon (Monk)
  [115310] = true, -- Revival (Monk)
  [31821] = true, -- Aura Mastery (Paladin)
  [1022] = true, -- Blessing of Protection (Paladin)
  [184662] = true, -- Shield of Vengeance (Paladin)
  [64843] = true, -- Divine Hymn (Priest)
  [47788] = true, -- Guardian Spirit (Priest)
  [33206] = true, -- Pain Suppression (Priest)
  [62618] = true, -- Power Word: Barrier (Priest)
  [47536] = true, -- Rapture (Priest)
  [64901] = true, -- Symbol of Hope (Priest)
  [108280] = true, -- Healing Tide Totem (Shaman)
  [98008] = true, -- Spirit Link Totem (Shaman)
}

local tank_cooldowns = {
  [61336] = true, -- Survival Instincts (Druid)
  [115203] = true, -- Fortifying Brew (Monk)
  [115176] = true, -- Zen Meditation (Monk)
  [31850] = true, -- Ardent Defender (Paladin)
  [86659] = true, -- Guardian of Ancient Kings (Paladin)
  [198103] = true, -- Earth Elemental (Shaman)
  [118038] = true, -- Die by the Sword (Warrior)
  [12975] = true, -- Last Stand (Warrior)
  [97462] = true, -- Rallying Cry (Warrior)
}

local interrupts = {
  [47528] = true, -- Mind Freeze (Death Knight)
  [183752] = true, -- Disrupt (Demon Hunter)
  [78675] = true, -- Solar Beam (Druid)
  [106839] = true, -- Skull Bash (Druid)
  [147362] = true, -- Counter Shot (Hunter)
  [2139] = true, -- Counterspell (Mage)
  [116705] = true, -- Spear Hand Strike (Monk)
  [96231] = true, -- Rebuke (Paladin)
  [15487] = true, -- Silence (Priest)
  [1766] = true, -- Kick (Rogue)
  [57994] = true, -- Wind Shear (Shaman)
  [19647] = true, -- Spell Lock (Warlock)
  [6552] = true, -- Pummel (Warrior)
}

function events:COMBAT_LOG_EVENT_UNFILTERED()
  spellId = select(12, CombatLogGetCurrentEventInfo())
  spellName = select(13, CombatLogGetCurrentEventInfo())
  event = select(2, CombatLogGetCurrentEventInfo())

  if dps_cooldowns[spellId] then
    if event ~= "SPELL_AURA_APPLIED" then return end
    playDungeonSound(SOUNDS_DIR .. "dps" .. math.random(NUM_DPS_SOUNDS) .. ".ogg")
  elseif healer_cooldowns[spellId] then
    if event ~= "SPELL_AURA_APPLIED" then return end
    playDungeonSound(SOUNDS_DIR .. "healer" .. math.random(NUM_HEALER_SOUNDS) .. ".ogg")
  elseif tank_cooldowns[spellId] then
    if event ~= "SPELL_AURA_APPLIED" then return end
    playDungeonSound(SOUNDS_DIR .. "tank" .. math.random(NUM_TANK_SOUNDS) .. ".ogg")
  elseif interrupts[spellId] then
    playDungeonSound(SOUNDS_DIR .. "interrupt" .. math.random(NUM_INTERRUPT_SOUNDS) .. ".ogg")
  end
end

SLASH_BOYBOYSBOYS1 = '/boysboysboys';
SLASH_BOYBOYSBOYS1 = '/bbb';
SLASH_BEARFORCESOUND1 = '/bfo';
local function handler()
 events:ACHIEVEMENT_EARNED()
end
SlashCmdList["BOYBOYSBOYS"] = handler;

local function handler2(name)
  if IsInGroup() then
    C_ChatInfo.SendAddonMessage(BEAR_FORCE_ONE_ADDON_PREFIX, "sound " .. name, "PARTY")
  else
    MaybePlaySound(name)
  end
end

SlashCmdList["BEARFORCESOUND"] = handler2;

-- This may or may not be ripped straight out of the beginner's tutorial
frame:SetScript("OnEvent", function(self, event, ...)
 events[event](self, ...); -- call one of the functions above
end);
for k, v in pairs(events) do
 frame:RegisterEvent(k); -- Register all events for which handlers have been defined
end

C_ChatInfo.RegisterAddonMessagePrefix(BEAR_FORCE_ONE_ADDON_PREFIX)
