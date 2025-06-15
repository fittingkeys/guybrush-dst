local assets = {
    Asset("ANIM", "anim/gummi.zip"),
    Asset("ATLAS", "images/inventoryimages/gummi.xml"),
    Asset("IMAGE", "images/inventoryimages/gummi.tex"),
}

local function OnBurnt(inst)
    inst.AnimState:PlayAnimation("burnt")
    inst:AddTag("burnt")
    inst:RemoveComponent("burnable")
    inst:RemoveComponent("propagator")
    inst.components.floater:OnNoLongerLanded()
    inst.components.lootdropper:SpawnLootPrefab("gummi")
    -- Default charcoal smoke effect
    if inst.components.burnable and inst.components.burnable.onburnt then
        inst.components.burnable.onburnt(inst)
    else
        SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "small", 0.1, 0.8)

    inst.AnimState:SetBank("gummi")
    inst.AnimState:SetBuild("gummi")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("gummi")
    inst:AddTag("aquatic")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()
    
    -- Important for repair detection
    inst:AddTag("health_gummi")
    
    -- Repairer component for Guybrush bumper
    inst:AddComponent("repairer")
    inst.components.repairer.repairmaterial = "gummi"
    inst.components.repairer.healthrepairvalue = 66  -- 33% of 200
    inst.components.repairer.workrepairvalue = 0
    inst.components.repairer.perishrepairpercent = 0
    inst.components.repairer.finiteusesrepairvalue = 0

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "gummi"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/gummi.xml"

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("burnable")
    inst.components.burnable:SetOnBurntFn(OnBurnt)
    inst.components.burnable:SetFXLevel(2)
    inst:AddComponent("propagator")

    inst:AddComponent("lootdropper")

    MakeHauntableLaunchAndIgnite(inst)

    return inst
end

return Prefab("gummi", fn, assets)