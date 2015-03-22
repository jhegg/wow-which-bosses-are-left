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
    self:AddLine(format("%s %s", WhichBossesAreLeft.name, WhichBossesAreLeft.version))
end
