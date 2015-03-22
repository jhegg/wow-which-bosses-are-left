local addonName, _ = ...

local highmaulMapId = 994 -- see: http://wow.gamepedia.com/MapID#Draenor_Raids
local blackrockFoundryMapId = 988

local normalDifficultyId = 14 -- see: http://wow.gamepedia.com/API_GetDifficultyInfo#Details
local heroicDifficultyId = 15

WhichBossesAreLeft = {
    name = addonName,
    version = GetAddOnMetadata(addonName, "Version"),
    author = GetAddOnMetadata(addonName, "Author"),
    currentRaids = {
        [GetMapNameByID(highmaulMapId)] = true,
        [GetMapNameByID(blackrockFoundryMapId)] = true,
    },
    difficulties = {
        "Normal",
        "Heroic",
    },
    masterList = {}, -- The data about active instance locks and which bosses are killed.
    flattenedList = {}, -- The flat list of text to be displayed in the window, derived from the masterList.
    frame = {},
    numberOfRows = 20,
}

WhichBossesAreLeft.addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceEvent-3.0")
local addon = WhichBossesAreLeft.addon

SLASH_WHICHBOSSESARELEFT1 = "/whichbossesareleft"

SlashCmdList["WHICHBOSSESARELEFT"] = function()
    WhichBossesAreLeft:DisplayWindow()
end

function WhichBossesAreLeft:UpdateRemainingBosses()
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

function WhichBossesAreLeft:RebuildFlattenedList()
    local flattenedList = {}
    local counter = 0

    for mapName, difficulty in pairs(WhichBossesAreLeft.masterList) do
        for difficultyId, value in pairs (difficulty) do
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
                local difficultyName = GetDifficultyInfo(difficultyId)
                flattenedList[counter].text = difficultyName.." "..mapName.." (No kills)"
                flattenedList[counter].isInstanceName = true
            end
        end
    end

    WhichBossesAreLeft.flattenedList = flattenedList
end

local function UpdateEntries()
    local entries = WhichBossesAreLeft.frame.entries
    WhichBossesAreLeft:UpdateRemainingBosses()
    WhichBossesAreLeft:RebuildFlattenedList()
    WhichBossesAreLeft:ClearCurrentEntryFrames()

    local currentEntry = 0
    for _, listEntry in pairs(WhichBossesAreLeft.flattenedList) do
        currentEntry = currentEntry + 1
        if currentEntry > WhichBossesAreLeft.numberOfRows then
            return
        end
        if listEntry.isInstanceName then
            entries[currentEntry].name:SetText(listEntry.text)
            entries[currentEntry].name:SetTextColor(1.0, 1.0, 1.0)
        else
            entries[currentEntry].name:SetText(listEntry.text)
            if listEntry.isKilled then
                entries[currentEntry].value:SetText("Defeated")
                entries[currentEntry].name:SetTextColor(1.0, 0, 0)
                entries[currentEntry].value:SetTextColor(1.0, 0, 0)
            else
                entries[currentEntry].value:SetText("Available")
                entries[currentEntry].name:SetTextColor(0, 1.0, 0)
                entries[currentEntry].value:SetTextColor(0, 1.0, 0)
            end
        end
    end
end

function WhichBossesAreLeft:DisplayWindow()
    UpdateEntries()
    WhichBossesAreLeft.frame:Show()
end

function addon:OnEnable()
    WhichBossesAreLeft.frame = WhichBossesAreLeft:CreateFrames()

    -- Construct master list placeholders
    for mapName in pairs(WhichBossesAreLeft.currentRaids) do
        WhichBossesAreLeft.masterList[mapName] = {
            [normalDifficultyId] = {
                activeLock = false
            },
            [heroicDifficultyId] = {
                activeLock = false
            },
        }
    end
end
