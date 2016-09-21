local addonName, _ = ...

local emeraldNightmareMapId = 1094
local nightholdMapId = 1088

local normalDifficultyId = 14 -- see: http://wow.gamepedia.com/API_GetDifficultyInfo#Details
local heroicDifficultyId = 15
local lookingForRaidDifficultyId = 17

WhichBossesAreLeft = {
    name = addonName,
    version = GetAddOnMetadata(addonName, "Version"),
    author = GetAddOnMetadata(addonName, "Author"),
    currentRaids = {
        [GetMapNameByID(emeraldNightmareMapId)] = true,
        -- [GetMapNameByID(nightholdMapId)] = true, -- todo: raid opens in 2017
    },
    sortedDifficultyIds = {
      lookingForRaidDifficultyId,
      normalDifficultyId,
      heroicDifficultyId,
    },
    raidFinderIds = {
      [GetMapNameByID(emeraldNightmareMapId)] = {
        {raidId = 1287, start = 1, encounterEnd = 7}, -- The Emerald Nightmare: Darkbough
        {raidId = 1288, start = 1, encounterEnd = 7}, -- The Emerald Nightmare: Tormented Guardians
        {raidId = 1289, start = 1, encounterEnd = 7}, -- The Emerald Nightmare: Rift of Aln
      },
      [GetMapNameByID(nightholdMapId)] = {
        {raidId = 1290, start = 1, encounterEnd = 10}, -- The Nighthold: Arcing Aqueducts
        {raidId = 1291, start = 1, encounterEnd = 10}, -- The Nighthold: Royal Athenaeum
        {raidId = 1292, start = 1, encounterEnd = 10}, -- The Nighthold: Nightspire
        {raidId = 1293, start = 1, encounterEnd = 10}, -- The Nighthold: Betrayer's Rise
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

      -- Since the encounters are out of order, just loop over all of them
      -- for each encounterId, and if any have isKilled=true, then set it to true.
      for encounterId = value.start, value.encounterEnd do
        local bossName, texture, isKilled, result4 = GetLFGDungeonEncounterInfo(value.raidId, encounterId)
        if not listEntry.bosses[encounterId] then
          listEntry.bosses[encounterId] = {}
          listEntry.bosses[encounterId].name = bossName
        end

        if not listEntry.bosses[encounterId].isKilled then
          listEntry.bosses[encounterId].isKilled = isKilled
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
                  flattenedList[counter].text = "      > "..bossValue.name
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
