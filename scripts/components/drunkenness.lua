local Drunkenness = Class(function(self, inst)
    self.inst = inst
    self.max = 100
    self.current = 0            -- Startwert
    self.transformed = false    -- false = Guybrush, true = Gulet

    -- Neuer Schalter, um Abbau zu blockieren
    self.decrease_blocked = false

    -- Verringert den Trunkenheitswert alle 30 Sekunden um 1
    print("[DEBUG] Drunkenness-Komponente init: Starte Decrease-Task alle 30 Sek.")
    self.inst:DoPeriodicTask(60, function() self:DecreaseDrunkenness() end)
end)

function Drunkenness:BlockDecrease(enable)
    self.decrease_blocked = enable
    print("[DEBUG] Drunkenness:BlockDecrease() - decrease_blocked =", enable)
end

function Drunkenness:DecreaseDrunkenness()
    if not self.decrease_blocked then
        local old = self.current
        self:SetCurrent(math.max(self.current - 1, 0))
        print("[DEBUG] DecreaseDrunkenness() - Alt:", old, "Neu:", self.current)
    else
        print("[DEBUG] DecreaseDrunkenness() - Blockiert, kein Abbau.")
    end
end

function Drunkenness:SetCurrent(val)
    print("[DEBUG] Drunkenness:SetCurrent() - Neuer Wert:", val)
    self.current = math.min(val, self.max)
    
    -- Netvar-Update (nur auf Server) -> Client empfängt "drunkenness_currentdirty"
    if self.inst.replica and self.inst.replica.drunkenness then
        self.inst.replica.drunkenness.net_current:set(self.current)
        self.inst.replica.drunkenness.net_max:set(self.max)
    end

    -- Client-Event
    self.inst:PushEvent("drunkennesschanged")

    self:CheckTransformation()
end

function Drunkenness:GetCurrent()
    return self.current
end

function Drunkenness:GetMax()
    return self.max
end

function Drunkenness:GetPercent()
    return (self.max > 0) and (self.current / self.max) or 0
end

-- Transformation bei >= 70 (Gulet) und < 70 (zurück zu Guybrush)
function Drunkenness:CheckTransformation()
    print("[DEBUG] Drunkenness:CheckTransformation() - current =", self.current, "transformed =", self.transformed)
    if self.current >= 70 and not self.transformed then
        self.transformed = true
        local fx = SpawnPrefab("explode_small")
        fx.Transform:SetPosition(self.inst.Transform:GetWorldPosition())

        print("[DEBUG] Drunkenness:CheckTransformation() - -> transform_gulet Event!")
        self.inst:PushEvent("transform_gulet")

    elseif self.current < 70 and self.transformed then
        self.transformed = false
        print("[DEBUG] Drunkenness:CheckTransformation() - -> transform_guybrush Event!")
        self.inst:PushEvent("transform_guybrush")
    end
end

function Drunkenness:DoDelta(delta)
    local old = self.current
    local new_val = self.current + delta
    self:SetCurrent(new_val)
    print("[DEBUG] Drunkenness:DoDelta() - Alt:", old, "Delta:", delta, "Neu:", self.current)
end

--------------------------------------------------------------------------------
-- OnSave / OnLoad für das Speichern und Laden
--------------------------------------------------------------------------------
function Drunkenness:OnSave()
    print("[DEBUG] Drunkenness:OnSave() - current:", self.current, 
          "transformed:", self.transformed,
          "decrease_blocked:", self.decrease_blocked)
    local data = {}
    data.current          = self.current
    data.transformed      = self.transformed
    data.decrease_blocked = self.decrease_blocked
    return data
end

function Drunkenness:OnLoad(data)
    print("[DEBUG] Drunkenness:OnLoad() - Lade Daten.", data and data.current or "nil")
    if data ~= nil then
        -- Hier kommt der Fix!
        if data.current ~= nil then
            -- statt self.current = data.current
            self:SetCurrent(data.current)
        end
        if data.transformed ~= nil then
            self.transformed = data.transformed
        end
        if data.decrease_blocked ~= nil then
            self.decrease_blocked = data.decrease_blocked
        end
        
        -- Nach dem Laden: Bei mismatch erzwinge das Event
        if self.transformed then
            print("[DEBUG] OnLoad() -> transform_gulet Event for consistency.")
            self.inst:PushEvent("transform_gulet")
        else
            print("[DEBUG] OnLoad() -> transform_guybrush Event for consistency.")
            self.inst:PushEvent("transform_guybrush")
        end
    end

    -- Prüfe nochmal, ob wir transformieren müssen
    self:CheckTransformation()
end

return Drunkenness
