local assets =
{
    Asset("ANIM", "anim/gummihuhn.zip"),
    Asset("ANIM", "anim/swap_gummihuhn.zip"),
    Asset("ANIM", "anim/floating_items.zip"),

    Asset("IMAGE", "images/inventoryimages/gummihuhn.tex"),
    Asset("ATLAS", "images/inventoryimages/gummihuhn.xml"),

}

TUNING.gummihuhn_DAMAGE = 34  -- Damage
TUNING.gummihuhn_ATKSPEED_BONUS = 1.0  -- Attack speed bonus / I don't think this works correctly
TUNING.gummihuhn_USAGES = 500  -- Maximum uses

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_gummihuhn", "swap_gummihuhn")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    if owner.prefab == "guybrush" and owner.components.combat then
        owner:AddTag("guybrush_EQUIP")
        owner.components.combat:SetAttackPeriod(TUNING.WILSON_ATTACK_PERIOD / TUNING.gummihuhn_ATKSPEED_BONUS)
    end
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("gummihuhn")
    inst.AnimState:SetBuild("gummihuhn")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("sharp")
    inst:AddTag("pointy")
    inst:AddTag("weapon")

    MakeInventoryFloatable(inst, "med", 0.1, {1.1, 0.5, 1.1})

    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.gummihuhn_DAMAGE)
    
    -- Disable default hit sound and play custom sound
    inst.components.weapon:SetOnAttack(function(inst, attacker, target)
        if attacker and attacker.SoundEmitter then
            -- Disable default hit sound
            attacker.SoundEmitter:KillSound("dontstarve/common/weapon_hit")
            
            -- Play custom sound
            local sound_id = "gummihuhn_sound_" .. tostring(math.random())
            attacker.SoundEmitter:PlaySound("chickenkweek/custom/ckweek", sound_id)
            attacker.SoundEmitter:SetVolume(sound_id, 0.5)
        end
    end)

    if TUNING.gummihuhn_USAGES > 0 and TUNING.gummihuhn_USAGES < 9999 then
        inst:AddComponent("finiteuses")
        inst.components.finiteuses:SetMaxUses(TUNING.gummihuhn_USAGES)
        inst.components.finiteuses:SetUses(TUNING.gummihuhn_USAGES)
        inst.components.finiteuses:SetOnFinished(inst.Remove)
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "gummihuhn"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/gummihuhn.xml"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("named")
    inst.components.named:SetName("Rubber Chicken")

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("gummihuhn", fn, assets)
