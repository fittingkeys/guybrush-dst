local PIRATE_BLOCK_VALUE = 0.8
local PIRATE_DURABILITY_MULTIPLICATOR = 5

local assets =
{
    Asset("ANIM", "anim/armor_pirate.zip"),
    Asset("ATLAS", "images/inventoryimages/armor_pirate.xml"),
    Asset("IMAGE", "images/inventoryimages/armor_pirate.tex"),
}

local function OnBlocked(owner)
    owner.SoundEmitter:PlaySound("dontstarve/wilson/hit_armour")
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "armor_pirate", "swap_body")
    inst:ListenForEvent("blocked", OnBlocked, owner)
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    inst:RemoveEventCallback("blocked", OnBlocked, owner)
end

local function fn()
    local inst = CreateEntity()
    inst:AddTag("leather")

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("armor_pirate")
    inst.AnimState:SetBuild("armor_pirate")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("wood")
    inst:AddTag("armorrepairable") -- Enables repair by Repair or Custom components

    inst.foleysound = "dontstarve/movement/foley/logarmour"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.foleysound = "dontstarve/movement/foley/logarmour"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/armor_pirate.xml"

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(TUNING.ARMORWOOD * PIRATE_DURABILITY_MULTIPLICATOR, PIRATE_BLOCK_VALUE)

    -- Repairable by Papyrus (via tag)
    -- armorrepairing component is NO longer added here, but to Papyrus.

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)

    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("armor_pirate", fn, assets)
