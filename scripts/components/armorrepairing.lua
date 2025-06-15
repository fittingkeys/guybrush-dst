local ArmorRepairing = Class(function(self, inst)
    self.inst = inst
    self.repair_value = 35 -- Standardwert, kann beim Prefab überschrieben werden
end)

function ArmorRepairing:DoReparation(target, doer)
    print("[DEBUG] DoReparation aufgerufen für target:", tostring(target), "doer:", tostring(doer), "self.inst:", tostring(self.inst), "repair_value:", tostring(self.repair_value))
    if self.only_tag and not target:HasTag(self.only_tag) then
        print("[DEBUG] DoReparation: Ziel hat nicht das benötigte Tag:", tostring(self.only_tag))
        return false
    end
    if target.components.armor and target.components.armor:GetPercent() < 1 then    
        local delta = target.components.armor.condition + ((target.components.armor.maxcondition * self.repair_value) / 100)
        if delta > target.components.armor.maxcondition then
            delta = target.components.armor.maxcondition
        end
        target.components.armor:SetCondition(delta)
        if self.inst.components.finiteuses then
            self.inst.components.finiteuses:Use(1)
        end
        if self.onarmorrepairs then
            self.onarmorrepairs(self.inst, target, doer)
        end
        return true
    end
end

function ArmorRepairing:CollectUseActions(doer, target, actions, right)
    if self.only_tag and not target:HasTag(self.only_tag) then
        return
    end
    if target:HasTag("armorrepairable") and target.components.armor and target.components.armor:GetPercent() < 1 then
        table.insert(actions, ACTIONS.ARMORREPAIRS)
    end
end

return ArmorRepairing
