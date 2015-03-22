local addonName, _ = ...

WhichBossesAreLeft = {
    name = addonName,
    version = GetAddOnMetadata(addonName, "Version"),
    author = GetAddOnMetadata(addonName, "Author"),
    currentRaids = {
        ["Highmaul"] = true,
        ["Blackrock Foundry"] = true,
    },
    difficulties = {
        "Normal",
        "Heroic",
    },
    trackedRaids = {
        highmaul = {
            normal = {},
            heroic = {},
        },
        blackrockFoundry = {
            normal = {},
            heroic = {},
        },
    },
    frame = {},
    numberOfRows = 16,
}

WhichBossesAreLeft.addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceEvent-3.0")
local addon = WhichBossesAreLeft.addon

SLASH_WHICHBOSSESARELEFT1 = "/whichbossesareleft"

SlashCmdList["WHICHBOSSESARELEFT"] = function()
    WhichBossesAreLeft:DisplayWindow()
end

function WhichBossesAreLeft:GetRemainingBosses()
    local bossesLeft = {}
    local numRaids = 0

    for instanceNumber=1,GetNumSavedInstances() do
        local name, _, _, _, locked, _, _, isRaid, _, difficultyName,
        numEncounters, _ = GetSavedInstanceInfo(instanceNumber)
        if (isRaid and locked and WhichBossesAreLeft.currentRaids[name]) then
            numRaids = numRaids + 1
            bossesLeft[numRaids] = {}
            bossesLeft[numRaids].title = "Instance: "..difficultyName.." "..name.." ("..numEncounters.." bosses)"

            local numBossesLeftAlive = 0
            for bossNumber=1,numEncounters do
                local bossName, _, isKilled, _ = GetSavedInstanceEncounterInfo(instanceNumber, bossNumber)
                if (not isKilled) then
                    bossesLeft[numRaids].boss = {}
                    bossesLeft[numRaids].boss[numBossesLeftAlive] = bossName
                end
            end
            bossesLeft[numRaids].numBossesLeftAlive = numBossesLeftAlive
        end
    end

    return bossesLeft, numRaids
end

local function ClearEntries()
    for i=1,WhichBossesAreLeft.numberOfRows do
        WhichBossesAreLeft.frame.entries[i].name:SetText("")
    end
end

local function UpdateEntries()
    local entries = WhichBossesAreLeft.frame.entries
    local bossesLeft, numRaids = WhichBossesAreLeft:GetRemainingBosses()
    WhichBossesAreLeft.remainingBosses = bossesLeft

    ClearEntries()

    if bossesLeft then
        local currentEntry = 0
        -- todo iterate over the number of rows
        --      todo add rows for instance and boss pairs
        --      todo if we hit the max row number, stop updating
        for i=1,numRaids do
            currentEntry = currentEntry + 1
            if currentEntry == WhichBossesAreLeft.numberOfRows then
                return
            end

            entries[currentEntry].name:SetText(bossesLeft[i].title)
            entries[currentEntry].name:SetTextColor(0, 1.0, 0)

            for j=1,bossesLeft[i].numBossesLeftAlive do
                currentEntry = currentEntry + 1
                if currentEntry == WhichBossesAreLeft.numberOfRows then
                    return
                end

                entries[currentEntry].name:SetText(bossesLeft[i].boss[j])
                entries[currentEntry].name:SetTextColor(0, 1.0, 0)
            end
        end
    else
        entries[1].name:SetText("No bosses are left alive for this week!")
    end
end

function WhichBossesAreLeft:DisplayWindow()
    UpdateEntries()
    WhichBossesAreLeft.frame:Show()
end

function addon:OnEnable()
    WhichBossesAreLeft.frame = WhichBossesAreLeft:CreateFrames()
    WhichBossesAreLeft.frame.entries = WhichBossesAreLeft:CreateEntryFrames(WhichBossesAreLeft.frame)
end
