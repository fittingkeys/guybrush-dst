local assets = {
    Asset("ANIM", "anim/leather_repairkit.zip"),
    Asset("ATLAS", "images/inventoryimages/leather_repairkit.xml"),
    Asset("IMAGE", "images/inventoryimages/leather_repairkit.tex"),
}

local function onarmorrepairs(inst, target, doer)
    if doer then
        doer:PushEvent("repair")
        if doer.SoundEmitter then
            doer.SoundEmitter:PlaySound("dontstarve/HUD/repair_clothing")
        end
    end
end

local function fn(Sim)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    
    MakeInventoryPhysics(inst)
    
    inst.AnimState:SetBank("leather_repairkit")
    inst.AnimState:SetBuild("leather_repairkit")
    inst.AnimState:PlayAnimation("idle")
    
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
    
    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.ARMOR_REPAIR_KIT_USES or 5)
    inst.components.finiteuses:SetUses(TUNING.ARMOR_REPAIR_KIT_USES or 5)
    inst.components.finiteuses:SetOnFinished(inst.Remove)
    
    inst:AddComponent("armorrepairing")
    inst.components.armorrepairing.repair_value = TUNING.ARMOR_REPAIR_KIT_REPAIR_VALUE or 20
    inst.components.armorrepairing.only_tag = "leather"
    inst.components.armorrepairing.onarmorrepairs = onarmorrepairs
    
    inst:AddComponent("inspectable")
    
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "leather_repairkit"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/leather_repairkit.xml"
    
    if MakeHauntableLaunch then
        MakeHauntableLaunch(inst)
    end
    
    return inst
end

return Prefab("leather_repairkit", fn, assets)
