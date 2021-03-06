local function OnMouseDown(_,_)
    WhichBossesAreLeft.frame:StartMoving()
end

local function OnMouseUp(_,_)
    WhichBossesAreLeft.frame:StopMovingOrSizing()
end

function WhichBossesAreLeft:CreateFrames()
    local frame = WhichBossesAreLeft:CreateMainFrame()

    frame.close = CreateFrame("Button",nil,frame,"UIPanelCloseButton")
    frame.close:SetPoint("TOPRIGHT", -5, -5)
    frame.close:SetScript("OnClick", function() frame:Hide() end)

    frame.outline = WhichBossesAreLeft:CreateFrameOutline(frame)

    frame.header = frame:CreateFontString(nil,"ARTWORK","GameFontHighlight")
    frame.header:SetFont(frame.header:GetFont(),24,"THICKOUTLINE")
    frame.header:SetPoint("TOPLEFT",12,-12)
    frame.header:SetText(
        format("%s %s - By %s", WhichBossesAreLeft.name, WhichBossesAreLeft.version, WhichBossesAreLeft.author))

    frame.root = frame:CreateFontString(nil,"ARTWORK","GameFontHighlight")
    frame.root:SetFont(frame.header:GetFont(),16,"OUTLINE")
    frame.root:SetPoint("RIGHT",frame.close,"LEFT",-8,-1)
    frame.root:SetJustifyH("RIGHT")

    frame.rootFrame = WhichBossesAreLeft:CreateRootFrame(frame)

    frame.entries = WhichBossesAreLeft:CreateEntryFrames(frame)

    frame.scrollFrame = WhichBossesAreLeft:CreateScrollFrame(frame)

    return frame
end

function WhichBossesAreLeft:CreateMainFrame()
    local frame = CreateFrame("Frame", "WhichBossesAreLeftMainFrame", UIParent)
    table.insert(UISpecialFrames, "WhichBossesAreLeftMainFrame") -- Allow the frame to be closed by the ESC key.
    frame:SetWidth(520)
    frame:SetHeight(420)
    frame:EnableMouse(1)
    frame:SetMovable(1)
    frame:SetFrameStrata("HIGH")
    frame:SetPoint("CENTER")
    frame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = 1,
        tileSize = 16,
        edgeSize = 16,
        insets = {
            left = 3,
            right = 3,
            top = 3,
            bottom = 3
        }
    })
    frame:SetBackdropColor(0,0,0,1)
    frame:SetBackdropBorderColor(0.1,0.1,0.1,1)
    frame:SetScript("OnMouseDown",OnMouseDown)
    frame:SetScript("OnMouseUp",OnMouseUp)
    frame:Hide()
    return frame
end

function WhichBossesAreLeft:CreateFrameOutline(frame)
    frame.outline = CreateFrame("Frame",nil,frame)
    frame.outline:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = 1,
        tileSize = 16,
        edgeSize = 16,
        insets = {
            left = 4,
            right = 4,
            top = 4,
            bottom = 4
        }
    })
    frame.outline:SetBackdropColor(0.1,0.1,0.2,1)
    frame.outline:SetBackdropBorderColor(0.8,0.8,0.9,0.4)
    frame.outline:SetPoint("TOPLEFT",12,-38)
    frame.outline:SetPoint("BOTTOMRIGHT",-12,42)
    WhichBossesAreLeft.ITEM_HEIGHT = (frame.outline:GetHeight() - 16) / WhichBossesAreLeft.numberOfRows - 1
    return frame.outline;
end

function WhichBossesAreLeft:CreateRootFrame(frame)
    frame.rootFrame = CreateFrame("Frame",nil,frame)
    frame.rootFrame:SetHeight(20)
    frame.rootFrame:SetPoint("LEFT",frame.root)
    frame.rootFrame:SetPoint("RIGHT",frame.root)
    frame.rootFrame:EnableMouse(1)
    frame.rootFrame:SetScript("OnLeave",function(_) GameTooltip:Hide(); end)
    frame.rootFrame:SetScript("OnEnter",RootFrame_OnEnter)
    frame.rootFrame:SetScript("OnMouseDown",OnMouseDown)
    frame.rootFrame:SetScript("OnMouseUp",OnMouseUp)
    return frame.rootFrame;
end

local function TableLength(T)
    local count = 0
    for _ in pairs(T) do
        count = count + 1
    end
    return count
end

function WhichBossesAreLeft:CreateEntryFrames(frame)
    local entries = {};
    for i=1,WhichBossesAreLeft.numberOfRows do
        entries[i] = WhichBossesAreLeft:CreateEntryFrame(frame,entries,i)
    end
    return entries;
end

function WhichBossesAreLeft:ClearCurrentEntryFrames()
    for i=1,WhichBossesAreLeft.numberOfRows do
        WhichBossesAreLeft.frame.entries[i].name:SetText("")
    end
end

function WhichBossesAreLeft:CreateEntryFrame(frame,entries,i)
    local entry = CreateFrame("Button", nil, frame.outline);
    entry:SetWidth(WhichBossesAreLeft.ITEM_HEIGHT);
    entry:SetHeight(WhichBossesAreLeft.ITEM_HEIGHT);
    entry:RegisterForClicks("AnyUp");
    entry:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight");

    if (i == 1) then
        entry:SetPoint("TOPLEFT", 8, -8);
        entry:SetPoint("TOPRIGHT", -8, -8);
    else
        entry:SetPoint("TOPLEFT", entries[i - 1], "BOTTOMLEFT", 0, -1);
        entry:SetPoint("TOPRIGHT", entries[i - 1], "BOTTOMRIGHT", 0, -1);
    end

    entry.name = entry:CreateFontString(nil, "ARTWORK", "GameFontNormal");
    entry.name:SetPoint("TOPLEFT");
    entry.name:SetPoint("BOTTOMLEFT");
    entry.name:SetJustifyH("LEFT");

    entry.value = entry:CreateFontString(nil, "ARTWORK", "GameFontNormal");
    entry.value:SetPoint("RIGHT", -4, 0);
    entry.value:SetPoint("LEFT", entry.name, "RIGHT", 12, 0);
    entry.value:SetJustifyH("RIGHT");

    return entry
end

function WhichBossesAreLeft:UpdateEntry(entry, text, isInstanceName, isKilled)
    if isInstanceName then
        entry.name:SetText(text)
        entry.name:SetTextColor(1.0, 1.0, 1.0)
        entry.value:SetText("")
    else
        entry.name:SetText(text)
        if isKilled then
            entry.value:SetText("Defeated")
            entry.name:SetTextColor(1.0, 0, 0)
            entry.value:SetTextColor(1.0, 0, 0)
        else
            entry.value:SetText("Available")
            entry.name:SetTextColor(0, 1.0, 0)
            entry.value:SetTextColor(0, 1.0, 0)
        end
    end
end

local function entryListUpdate()
    WhichBossesAreLeft:EntryListUpdate()
end

function WhichBossesAreLeft:EntryListUpdate()
    local frame = WhichBossesAreLeft.frame
    local entries = WhichBossesAreLeft.frame.entries

    FauxScrollFrame_Update(frame.scrollFrame,
        WhichBossesAreLeft.flattenedListSize,
        WhichBossesAreLeft.numberOfRows,
        WhichBossesAreLeft.ITEM_HEIGHT);
    local offset = FauxScrollFrame_GetOffset(frame.scrollFrame)

    for line = 1, WhichBossesAreLeft.numberOfRows do
        local listNumber = offset + line
        if listNumber > WhichBossesAreLeft.flattenedListSize then
            entries[line]:Hide()
        else
            local listEntry = WhichBossesAreLeft.flattenedList[listNumber]
            WhichBossesAreLeft:UpdateEntry(entries[line], listEntry.text, listEntry.isInstanceName, listEntry.isKilled)
            entries[line]:Show()
        end
    end
end

function WhichBossesAreLeft:CreateScrollFrame(frame)
    local scrollFrame = CreateFrame("ScrollFrame", "WhichBossesAreLeftScrollFrame", frame, "FauxScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame.entries[1])
    scrollFrame:SetPoint("BOTTOMRIGHT", frame.entries[#frame.entries], -6, -1)
    scrollFrame:SetScript("OnShow", entryListUpdate)
    scrollFrame:SetScript("OnVerticalScroll",
        function(self,offset)
            FauxScrollFrame_OnVerticalScroll(self, offset, WhichBossesAreLeft.ITEM_HEIGHT, entryListUpdate)
        end)
    scrollFrame.ScrollBar.scrollStep = 1 * WhichBossesAreLeft.ITEM_HEIGHT
    return scrollFrame
end

local function clickRaidFrameButton()
    if (WhichBossesAreLeft.frame:IsShown()) then
      WhichBossesAreLeft.frame:Hide()
    else
      WhichBossesAreLeft:DisplayWindow()
    end
end

function WhichBossesAreLeft:CreateButtonOnRaidFrame()
    local button = CreateFrame("Button", "WBALButton", RaidFrame, "UIPanelButtonTemplate")
    button:SetSize(16, 16)
    button:SetNormalTexture("Interface\\Icons\\ACHIEVEMENT_BOSS_KILJAEDAN")
    button:SetPoint("TOPRIGHT", -110, -27)
    button:SetScript("OnClick", clickRaidFrameButton)
    button:SetScript("OnEnter", function (self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Which Bosses Are Left?")
    end)
    button:SetScript("OnLeave", function () GameTooltip:Hide() end)
    WhichBossesAreLeft.raidFrameButton = button
end
