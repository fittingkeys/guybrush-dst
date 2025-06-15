local DrunkennessReplica = Class(function(self, inst)
    self.inst = inst

    -- NetVars
    self.net_current = net_byte(inst.GUID, "drunkenness.net_current", "drunkenness_currentdirty")
    self.net_max     = net_byte(inst.GUID, "drunkenness.net_max",     "drunkenness_maxdirty")

    -- Direkt hier auf die Dirty-Events lauschen
    inst:ListenForEvent("drunkenness_currentdirty", function() self:OnCurrentDirty() end)
    inst:ListenForEvent("drunkenness_maxdirty",     function() self:OnMaxDirty() end)
end)

--------------------------------------------------------------------------------
-- Dirty-Callbacks
--------------------------------------------------------------------------------
function DrunkennessReplica:OnCurrentDirty()
    -- Sobald net_current einen neuen Wert erhält, pushen wir "drunkennessdirty"
    self.inst:PushEvent("drunkennessdirty")
end

function DrunkennessReplica:OnMaxDirty()
    -- Sobald net_max einen neuen Wert erhält, pushen wir "drunkennessdirty"
    self.inst:PushEvent("drunkennessdirty")
end

--------------------------------------------------------------------------------
-- Getter
--------------------------------------------------------------------------------
function DrunkennessReplica:GetCurrent()
    return self.net_current:value()
end

function DrunkennessReplica:GetMax()
    return self.net_max:value()
end

function DrunkennessReplica:GetPercent()
    local max = self:GetMax()
    return (max > 0) and (self:GetCurrent() / max) or 0
end

return DrunkennessReplica
