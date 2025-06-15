--====================================================================
--  guysword.lua  –  "Mighty Sword" Prefab
--      · Consumes 1 (cursed_monkey_token) every 10 hits
--      · Deactivates itself when no tokens are left
--      · Continues to show the knock-up FX + recoil animation,
--        but does **not** trigger any form or Wonkey transformation
--====================================================================

local assets =
{
    Asset("ANIM" , "anim/guysword.zip"),
    Asset("ANIM" , "anim/swap_guysword.zip"),
    Asset("ANIM" , "anim/floating_items.zip"),

    Asset("IMAGE", "images/inventoryimages/guysword.tex"),
    Asset("ATLAS", "images/inventoryimages/guysword.xml"),
}

--------------------------------------------------------------------
--  TUNING
--------------------------------------------------------------------
TUNING.guysword_DAMAGE         = 70     -- Base damage
TUNING.guysword_ATKSPEED_BONUS = 1.0    -- attack faster
TUNING.guysword_USAGES         = 0      -- 0 = infinite

local SOUND_GUYSWORD_EQUIP = "guyswordequip/custom/equip"
local CUSTOM_EQUIP_SOUND_HANDLE = "custom_equip_sound"

--------------------------------------------------------------------
--  EQUIP / UNEQUIP
--------------------------------------------------------------------
local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_guysword", "swap_guysword")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

        if owner.SoundEmitter then
        owner.SoundEmitter:KillSound(CUSTOM_EQUIP_SOUND_HANDLE)
        if inst.soundtask then
            inst.soundtask:Cancel()
        end
        inst.soundtask = inst:DoTaskInTime(0.3, function()
            if owner and owner:IsValid() and owner.SoundEmitter then
                owner.SoundEmitter:PlaySound(SOUND_GUYSWORD_EQUIP, CUSTOM_EQUIP_SOUND_HANDLE)
                owner.SoundEmitter:SetVolume(CUSTOM_EQUIP_SOUND_HANDLE, 0.1)
            end
        end)
    end

    if owner.prefab == "guybrush" and owner.components.combat then
        owner:AddTag("guybrush_EQUIP")
        owner.components.combat:SetAttackPeriod(
            TUNING.WILSON_ATTACK_PERIOD / TUNING.guysword_ATKSPEED_BONUS)
    end
end

local function onunequip(inst, owner)
    if inst.soundtask then
        inst.soundtask:Cancel()
        inst.soundtask = nil
    end
    if owner.SoundEmitter then
        owner.SoundEmitter:KillSound(CUSTOM_EQUIP_SOUND_HANDLE)
    end
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

--------------------------------------------------------------------
--  KNOCK-UP (pure FX + animation, **without** transformation)
--------------------------------------------------------------------
local function DoKnockUp(attacker)
    -- small FX cloud
    local fx = SpawnPrefab("monkey_morphin_power_players_fx")
    if fx then
        fx.Transform:SetPosition(attacker.Transform:GetWorldPosition())
    end

    -- Recoil/Knock-back animation (server-side)
    if attacker.sg ~= nil and attacker.sg:HasState("knockback") then
        attacker.sg:GoToState("knockback")
    else
        -- Fallback: Send event (if mod SG)
        attacker:PushEvent("knockback", { knocker = attacker })
    end
end

--------------------------------------------------------------------
--  ON ATTACK
--------------------------------------------------------------------
local function OnAttack(inst, attacker, target)
    local inv   = attacker.components.inventory
    local token = inv and inv:FindItem(function(i) return i.prefab == "cursed_monkey_token" end)

    ----------------------------------------------------------------
    -- 1) NO Token  → Weapon deactivated, show Knock-Up
    ----------------------------------------------------------------
    if not token then
        if inst.components.weapon then
            inst.components.weapon:SetDamage(0)
        end
        inst.disabled = true

        if attacker.components.talker then
            attacker.components.talker:Say(
                "The curse has bound itself to the sword", 2.5)
        end

        DoKnockUp(attacker)
        return
    end

    ----------------------------------------------------------------
    -- 2) At least 1 Token → Weapon active (re-activate if necessary)
    ----------------------------------------------------------------
    if inst.disabled then
        inst.disabled = false
        if inst.components.weapon then
            inst.components.weapon:SetDamage(TUNING.guysword_DAMAGE)
        end
    end

    ----------------------------------------------------------------
    -- 3) Hit counter, every 10 hits Token consumption + FX
    ----------------------------------------------------------------
    inst._hitcount = (inst._hitcount or 0) + 1
    if inst._hitcount % 10 == 0 then
        local token_use = (target and target.prefab == "dummylechuck") and 2 or 1

        -- small FX cloud
        local fx = SpawnPrefab("monkey_morphin_power_players_fx")

        -- Deduct token
        if token.components.stackable then
            local left = token.components.stackable:StackSize() - token_use
            if left > 0 then
                token.components.stackable:SetStackSize(left)
            else
                token:Remove()
            end
        else
            token:Remove()
        end

        if attacker.components.talker then
            attacker.components.talker:Say("Uu‑uu‑aa‑aa!")
        end
    end
end

--------------------------------------------------------------------
--  PREFAB  fn
--------------------------------------------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("guysword")
    inst.AnimState:SetBuild("guysword")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("sharp")
    inst:AddTag("pointy")
    inst:AddTag("weapon")

    MakeInventoryFloatable(inst, "med", .1, { 1.1, .5, 1.1 })

    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst.entity:SetPristine()

    ------------------------------------------------------------
    --  CLIENT-Side
    ------------------------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end

    ------------------------------------------------------------
    --  SERVER-Side
    ------------------------------------------------------------
    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.guysword_DAMAGE)
    inst.components.weapon:SetOnAttack(OnAttack)

    if TUNING.guysword_USAGES > 0 and TUNING.guysword_USAGES < 9999 then
        inst:AddComponent("finiteuses")
        inst.components.finiteuses:SetMaxUses(TUNING.guysword_USAGES)
        inst.components.finiteuses:SetUses   (TUNING.guysword_USAGES)
        inst.components.finiteuses:SetOnFinished(inst.Remove)
    end

    inst:AddComponent("talker")
    inst.components.talker.fontsize = 28
    inst.components.talker.font     = TALKINGFONT or "fonts/talkingfont.fnt"
    inst.components.talker.colour   = Vector3(.9, .4, .4)
    inst.components.talker.symbol   = "swap_guysword"
    inst.components.talker.offset   = Vector3(0, 5, 0)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/guysword.xml"
    inst.components.inventoryitem.imagename = "guysword"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip  (onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("named")
    inst.components.named:SetName("Mighty Sword")

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("guysword", fn, assets)
