local addonName, _ = ...

local tombOfSargerasMapId = 1147

local normalDifficultyId = 14 -- see: http://wow.gamepedia.com/API_GetDifficultyInfo#Details
local heroicDifficultyId = 15
local lookingForRaidDifficultyId = 17

WhichBossesAreLeft = {
    name = addonName,
    version = GetAddOnMetadata(addonName, "Version"),
    author = GetAddOnMetadata(addonName, "Author"),
    currentRaids = {
        [GetMapNameByID(tombOfSargerasMapId)] = true,
    },
    sortedDifficultyIds = {
      lookingForRaidDifficultyId,
      normalDifficultyId,
      heroicDifficultyId,
    },
    raidFinderIds = {
      [GetMapNameByID(tombOfSargerasMapId)] = {
        {raidId = 1494, start = 1, offset = 0}, -- Tomb of Sargeras: The Gates of Hell
        {raidId = 1495, start = 1, offset = 3}, -- Tomb of Sargeras: Wailing Halls
        {raidId = 1496, start = 1, offset = 6}, -- Tomb of Sargeras: Chamber of the Avatar
        {raidId = 1497, start = 1, offset = 9}, -- Tomb of Sargeras: Deceiver's Fall
      },
    },
    masterList = {}, -- The data about active instance locks and which bosses are killed.
    flattenedList = {}, -- The flat list of text to be displayed in the window, derived from the masterList.
    flattenedListSize = 0,
    frame = {},
    numberOfRows = 20,
}

WhichBossesAreLeft.addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceEvent-3.0")
local addon = WhichBossesAreLeft.addon

SLASH_WHICHBOSSESARELEFT1 = "/whichbossesareleft"

SlashCmdList["WHICHBOSSESARELEFT"] = function()
    WhichBossesAreLeft:DisplayWindow()
end

local function UpdateBossesFromSavedInstanceIds()
  for instanceNumber=1,GetNumSavedInstances() do
      local name, _, _, difficulty, locked, _, _, isRaid, _, difficultyName, numEncounters, _ = GetSavedInstanceInfo(instanceNumber)

      if (isRaid and locked and WhichBossesAreLeft.currentRaids[name]) then
          local listEntry = WhichBossesAreLeft.masterList[name][difficulty]
          listEntry.activeLock = true
          listEntry.title = difficultyName.." "..name
          listEntry.bosses = {}

          for bossNumber=1,numEncounters do
              local bossName, _, isKilled, _ = GetSavedInstanceEncounterInfo(instanceNumber, bossNumber)
              listEntry.bosses[bossNumber] = {}
              listEntry.bosses[bossNumber].name = bossName
              listEntry.bosses[bossNumber].isKilled = isKilled
          end
      end
  end
end

local function AreThereAnyKillsInRaidFinder(setOfRaidIds)
  for _, raidPortion in ipairs(setOfRaidIds) do
    local _, numCompleted = GetLFGDungeonNumEncounters(raidPortion.raidId)
    if numCompleted > 0 then return true end
  end
  return false
end

local function UpdateRaidFinderBossesFromLocation(location, setOfRaidIds)
  local anyKills = AreThereAnyKillsInRaidFinder(setOfRaidIds)
  if not anyKills then
    return -- No kills in this entire LFR suite
  else
    local listEntry = WhichBossesAreLeft.masterList[location][lookingForRaidDifficultyId]
    local difficultyName = GetDifficultyInfo(lookingForRaidDifficultyId)
    listEntry.activeLock = true
    listEntry.title = difficultyName.." "..location
    listEntry.bosses = {}

    for _, value in ipairs(setOfRaidIds) do
      local numEncounters, numCompleted = GetLFGDungeonNumEncounters(value.raidId)

      for encounterId = value.start, numEncounters do
        local bossName, texture, isKilled, result4 = GetLFGDungeonEncounterInfo(value.raidId, encounterId)
        local encounterIdPlusOffset = encounterId + value.offset
        if not listEntry.bosses[encounterIdPlusOffset] then
          listEntry.bosses[encounterIdPlusOffset] = {}
          listEntry.bosses[encounterIdPlusOffset].name = bossName
        end

        if not listEntry.bosses[encounterIdPlusOffset].isKilled then
          listEntry.bosses[encounterIdPlusOffset].isKilled = isKilled
        end
      end
    end
  end
end

local function UpdateRaidFinderBosses()
  for location, setOfRaidIds in pairs(WhichBossesAreLeft.raidFinderIds) do
    UpdateRaidFinderBossesFromLocation(location, setOfRaidIds)
  end
end

function WhichBossesAreLeft:UpdateRemainingBosses()
  UpdateRaidFinderBosses()
  UpdateBossesFromSavedInstanceIds()
end

function WhichBossesAreLeft:RebuildFlattenedList()
    local flattenedList = {}
    local counter = 0

    for mapName, mapDifficulties in pairs(WhichBossesAreLeft.masterList) do
        for _, sortedDifficultyId in pairs(WhichBossesAreLeft.sortedDifficultyIds) do
          local value = mapDifficulties[sortedDifficultyId]

          counter = counter + 1
          flattenedList[counter] = {}
          if (value.activeLock) then
              flattenedList[counter].isInstanceName = true
              flattenedList[counter].text = value.title

              for _, bossValue in pairs(value.bosses) do
                  counter = counter + 1
                  flattenedList[counter] = {}
                  flattenedList[counter].isKilled = bossValue.isKilled
                  flattenedList[counter].text = "      > "..tostring(bossValue.name)
              end
          else
              local difficultyName = GetDifficultyInfo(sortedDifficultyId)
              flattenedList[counter].text = difficultyName.." "..mapName.." (No kills)"
              flattenedList[counter].isInstanceName = true
          end
        end
    end

    WhichBossesAreLeft.flattenedList = flattenedList
    WhichBossesAreLeft.flattenedListSize = counter
end

function WhichBossesAreLeft:UpdateEntries()
  WhichBossesAreLeft:UpdateRemainingBosses()
  WhichBossesAreLeft:RebuildFlattenedList()
  WhichBossesAreLeft:ClearCurrentEntryFrames()
  WhichBossesAreLeft:EntryListUpdate()
end

function WhichBossesAreLeft:DisplayWindow()
  WhichBossesAreLeft:UpdateEntries()
  WhichBossesAreLeft.frame:Show()
end

function addon:OnEnable()
  WhichBossesAreLeft.frame = WhichBossesAreLeft:CreateFrames()
  WhichBossesAreLeft:CreateButtonOnRaidFrame()

  -- Construct master list placeholders
  for mapName in pairs(WhichBossesAreLeft.currentRaids) do
    WhichBossesAreLeft.masterList[mapName] = {
      [lookingForRaidDifficultyId] = {
        activeLock = false
      },
      [normalDifficultyId] = {
        activeLock = false
      },
      [heroicDifficultyId] = {
        activeLock = false
      },
    }
  end
end
