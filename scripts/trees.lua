local utils = require("utils")

local function ImproveTree(inst)
    local oldonfinish = inst.components.workable.onfinish
    inst.components.workable:SetOnFinishCallback(function(inst, chopper)
        -- Drop gummi for any palmconetree, regardless of burnt state
        if inst.prefab == "palmconetree" or inst.prefab == "palmconetree_short" or inst.prefab == "palmconetree_normal" or inst.prefab == "palmconetree_tall" then
            inst.components.lootdropper:SpawnLootPrefab("gummi")
        end
        if oldonfinish then oldonfinish(inst, chopper) end
    end)
end

return ImproveTree
