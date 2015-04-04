local libDataBroker = LibStub:GetLibrary("LibDataBroker-1.1", true)
if not libDataBroker then return end

local ldb = libDataBroker:NewDataObject("WhichBossesAreLeft", {
    type = "launcher",
    icon = "Interface\\Icons\\ACHIEVEMENT_BOSS_KILJAEDAN",
    label = "WhichBossesAreLeft",
})

function ldb:OnClick(clickedFrame, button)
    if (WhichBossesAreLeft.frame:IsVisible()) then
        WhichBossesAreLeft.frame:Hide()
    else
        WhichBossesAreLeft:DisplayWindow()
    end
end

function ldb:OnTooltipShow()
  WhichBossesAreLeft:UpdateEntries()
  self:AddLine(format("%s %s", WhichBossesAreLeft.name, WhichBossesAreLeft.version))
  self:AddLine("------------------------------")
  for line = 1, WhichBossesAreLeft.flattenedListSize do
    local listEntry = WhichBossesAreLeft.flattenedList[line]
    if listEntry.isInstanceName then
      self:AddLine(format("|cFFFFFFFF%s|r", listEntry.text))
    else
      if not listEntry.isKilled then
        self:AddLine(format("|cFF00FF00%s|r", listEntry.text))
      end
    end
  end
end
