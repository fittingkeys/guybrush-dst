--------------------------------------------------------------------------------
-- DrunkennessWidget (Funktioniert mit & ohne Combined Status)
--------------------------------------------------------------------------------

local Badge = require("widgets/badge")
local UIAnim = require("widgets/uianim")
local Text = require("widgets/text")

-- Lade `Widget` **nur**, wenn Combined Status aktiv ist
local Widget

--------------------------------------------------------------------------------
-- Prüft, ob Combined Status aktiv ist
--------------------------------------------------------------------------------
local function IsCombinedStatusActive()
    if not KnownModIndex then
        return false
    end
    for _, modname in pairs(KnownModIndex:GetModsToLoad()) do
        local info = KnownModIndex:GetModInfo(modname)
        if info and info.name and info.name:find("Combined Status") then
            return true
        end
    end
    return false
end

local useCombinedStatus = IsCombinedStatusActive()

-- Falls Combined Status aktiv ist, benötige ich `Widget`
if useCombinedStatus then
    Widget = require("widgets/widget")
end

--------------------------------------------------------------------------------
-- Konstruktor
--------------------------------------------------------------------------------
local DrunkennessWidget = Class(Badge, function(self, owner)
    Badge._ctor(self, "drunkennesswidget", owner)
    self:SetClickable(true)

    -- Ist Combined Status aktiv?
    self.useCombinedStatusPos = useCombinedStatus

    -- Falls Combined Status aktiv, setze `self.underNumber`
    if self.useCombinedStatusPos and Widget then
        self.underNumber = self:AddChild(Widget("underNumber"))
    end

    -- Body & Rahmen setzen
    self.body = self:InitChild("drunkenness_body", "body_0", true, true)
    self.grogEdge = self:InitChild("drunkenness_grog", "grog_edge_anim", true, true)

    -- Falls Combined Status aktiv ist, nutze spezielle Werte
    if self.useCombinedStatusPos then
        self.num = self:AddChild(Text(NUMBERFONT, 28))
        self.num:SetPosition(2, -40.5, 0)
        self.num:SetScale(1, 0.78, 1)
        self.num:Show()

        -- "Max:\n100" beim Hover anzeigen
        self.maxText = self:AddChild(Text(NUMBERFONT, 29))
        self.maxText:SetHAlign(ANCHOR_MIDDLE)
        self.maxText:SetPosition(5, 0, 0)
        self.maxText:SetScale(1, 0.78, 1)
        self.maxText:SetString("Max:\n100")
        self.maxText:Hide()
    else
        -- Kein Combined Status -> Standard Hover-Verhalten
        self.number = self:AddChild(Text(TALKINGFONT, 30))
        self.number:SetHAlign(ANCHOR_MIDDLE)
        self.number:SetPosition(3.5, 0, 0)
        self.number:SetScale(1, 0.78, 1)
        self.number:Hide()
    end

    -- Positionierung
    self:SetWidgetPositions()

    -- (1) Lausche auf das Client-Event "drunkennessdirty"
    if self.owner then
        self.owner:ListenForEvent("drunkennessdirty", function()
            self:OnDrunkennessChanged()
        end, self)
    end

    -- (2) Sofort initial aktualisieren
    self:OnDrunkennessChanged()
    
    -- (3) Zusätzlich: alle 0.5 Sekunden (OnUpdate) abfragen
    self:StartUpdating()
end)

--------------------------------------------------------------------------------
-- Alle 0.5s aktualisieren
--------------------------------------------------------------------------------
function DrunkennessWidget:OnUpdate(dt)
    self.update_timer = (self.update_timer or 0) + dt
    if self.update_timer >= 0.5 then
        self.update_timer = 0
        self:OnDrunkennessChanged()
    end
end

--------------------------------------------------------------------------------
-- Drunkenness-Wert aktualisieren
--------------------------------------------------------------------------------
function DrunkennessWidget:OnDrunkennessChanged()
    local drunkenness = self.owner.replica.drunkenness
    if drunkenness then
        local current = drunkenness:GetCurrent()
        -- Animation
        self:UpdateBodyAnimation(current)
        self:UpdateTransformationFX(current)

        if self.useCombinedStatusPos then
            if self.num then
                self.num:SetString(tostring(current))
            end
        else
            if self.number then
                self.number:SetString(tostring(current))
            end
        end
    end
end

--------------------------------------------------------------------------------
-- 10er-Schritt-Animation
--------------------------------------------------------------------------------
function DrunkennessWidget:UpdateBodyAnimation(current)
    local step = math.floor(current / 10) * 10
    local animName = "body_" .. tostring(step)
    if self.body and self.body:GetAnimState() and not self.body:GetAnimState():IsCurrentAnimation(animName) then
        self.body:GetAnimState():PlayAnimation(animName, true)
    end
end

--------------------------------------------------------------------------------
-- Ab 70 => transform, sonst grog_edge_anim
--------------------------------------------------------------------------------
function DrunkennessWidget:UpdateTransformationFX(current)
    if not (self.grogEdge and self.grogEdge.GetAnimState) then
        return
    end

    if current >= 70 then
        if not self.grogEdge:GetAnimState():IsCurrentAnimation("transform") then
            self.grogEdge:GetAnimState():PlayAnimation("transform", false)
        end
    else
        if not self.grogEdge:GetAnimState():IsCurrentAnimation("grog_edge_anim") then
            self.grogEdge:GetAnimState():PlayAnimation("grog_edge_anim", true)
        end
    end
end

--------------------------------------------------------------------------------
-- Positionierung
--------------------------------------------------------------------------------
function DrunkennessWidget:SetWidgetPositions()
    TheWorld:DoTaskInTime(0, function()
        if self and self.SetPosition then
            if self.useCombinedStatusPos then
                self:SetPosition(-62, -50, 0)
            else
                self:SetPosition(0, -113, 0)
            end
        end
    end)
end

--------------------------------------------------------------------------------
-- UIAnim-Kind
--------------------------------------------------------------------------------
function DrunkennessWidget:InitChild(bankAndBuildName, animation, loop, clickable)
    -- Nur, wenn underNumber existiert (Combined Status)
    if not self.underNumber then
        return
    end

    local child = self.underNumber:AddChild(UIAnim())
    child:GetAnimState():SetBank(bankAndBuildName)
    child:GetAnimState():SetBuild(bankAndBuildName)
    child:GetAnimState():PlayAnimation(animation, loop)
    child:SetClickable(clickable)
    return child
end

--------------------------------------------------------------------------------
-- Hover-Verhalten
--------------------------------------------------------------------------------
function DrunkennessWidget:OnGainFocus()
    if self.useCombinedStatusPos then
        if self.maxText then
            self.maxText:Show()
        end
    else
        if self.number then
            self.number:Show()
        end
    end
end

function DrunkennessWidget:OnLoseFocus()
    if self.useCombinedStatusPos then
        if self.maxText then
            self.maxText:Hide()
        end
    else
        if self.number then
            self.number:Hide()
        end
    end
end

return DrunkennessWidget
