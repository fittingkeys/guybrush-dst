-- monkeycompass.lua

PrefabFiles = {
    "monkeycompass", -- der interne Prefab-Name
}

local assets = {
    Asset("ANIM", "anim/monkeycompass.zip"),
    Asset("ANIM", "anim/swap_monkeycompass.zip"),
    Asset("ATLAS", "images/inventoryimages/monkeycompass.xml"),
    Asset("IMAGE", "images/inventoryimages/monkeycompass.tex"),
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_monkeycompass", "swap_monkeycompass")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    inst.components.fueled:StartConsuming()

    if owner.components.maprevealable ~= nil then
        owner.components.maprevealable:AddRevealSource(inst, "compassbearer")
    end
    owner:AddTag("compassbearer")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")

    inst.components.fueled:StopConsuming()

    if owner.components.maprevealable ~= nil then
        owner.components.maprevealable:RemoveRevealSource(inst)
    end
    owner:RemoveTag("compassbearer")
end

local function onequiptomodel(inst, owner, from_ground)
    inst.components.fueled:StopConsuming()

    if owner.components.maprevealable ~= nil then
        owner.components.maprevealable:RemoveRevealSource(inst)
    end
    owner:RemoveTag("compassbearer")
end

local function ondepleted(inst)
    if inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner ~= nil then
        local data = {
            prefab = inst.prefab,
            equipslot = inst.components.equippable.equipslot,
            announce = "ANNOUNCE_COMPASS_OUT",
        }
        inst.components.inventoryitem.owner:PushEvent("itemranout", data)
    end
    inst:Remove()
end

local function onattack(inst, attacker, target)
    if inst.components.fueled ~= nil then
        local decay_percent = TUNING.COMPASS_ATTACK_DECAY_PERCENT or 0.05
        inst.components.fueled:DoDelta(inst.components.fueled.maxfuel * decay_percent)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("monkeycompass")
    inst.AnimState:SetBuild("monkeycompass")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("compass")
    inst:AddTag("weapon")

    MakeInventoryFloatable(inst, "med", 0.1, 0.6)

    inst.scrapbook_subcat = "tool"

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/monkeycompass.xml"

    inst:AddComponent("inspectable")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable:SetOnEquipToModel(onequiptomodel)

    inst:AddComponent("fueled")
    inst.components.fueled:InitializeFuelLevel(TUNING.COMPASS_FUEL or (5 * TUNING.SEG_TIME))
    inst.components.fueled:SetDepletedFn(ondepleted)
    inst.components.fueled:SetFirstPeriod(
        TUNING.TURNON_FUELED_CONSUMPTION or 1,
        TUNING.TURNON_FULL_FUELED_CONSUMPTION or 1
    )

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.UNARMED_DAMAGE or 10)
    inst.components.weapon:SetOnAttack(onattack)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("monkeycompass", fn, assets)
