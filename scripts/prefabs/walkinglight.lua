local SOUND_WALKINGLIGHT_EQUIP = "murrayequip/custom/murray"
local CUSTOM_EQUIP_SOUND_HANDLE = "custom_equip_sound"

local assets = {

    Asset("SOUND", "sound/wilson.fsb"),

    Asset("ANIM", "anim/guywalk.zip"),
    Asset("ATLAS", "images/inventoryimages/walkinglight.xml"),
    Asset("IMAGE", "images/inventoryimages/walkinglight.tex"),
}

local prefabs = {
    "lanternlight",
}

local function DoTurnOffSound(inst, owner)
    inst._soundtask = nil
    (owner ~= nil and owner:IsValid() and owner.SoundEmitter or inst.SoundEmitter):PlaySound("dontstarve/wilson/lantern_off")
end

local function PlayTurnOffSound(inst)
    if inst._soundtask == nil and inst:GetTimeAlive() > 0 then
        inst._soundtask = inst:DoTaskInTime(0, DoTurnOffSound, inst.components.inventoryitem.owner)
    end
end

local function PlayTurnOnSound(inst)
    if inst._soundtask ~= nil then
        inst._soundtask:Cancel()
        inst._soundtask = nil
    elseif not POPULATING and inst._light then
        inst._light.SoundEmitter:PlaySound("dontstarve/wilson/lantern_on")
    end
end

local function fuelupdate(inst)
    if inst._light ~= nil then
        local fuelpercent = inst.components.fueled:GetPercent()
        inst._light.Light:SetIntensity(Lerp(.2, .3, fuelpercent))
        inst._light.Light:SetRadius(Lerp(2.2, 3.2, fuelpercent))
        inst._light.Light:SetFalloff(.9)
    end
end

local function onremovelight(light)
    light._lantern._light = nil
end

local function stoptrackingowner(inst)
    if inst._owner ~= nil then
        inst:RemoveEventCallback("equip", inst._onownerequip, inst._owner)
        inst._owner = nil
    end
end

local function starttrackingowner(inst, owner)
    if owner ~= inst._owner then
        stoptrackingowner(inst)
        if owner ~= nil and owner.components.inventory ~= nil then
            inst._owner = owner
            inst:ListenForEvent("equip", inst._onownerequip, owner)
        end
    end
end

local function turnon(inst)
    if not inst.components.fueled:IsEmpty() then
        inst.components.fueled:StartConsuming()

        local owner = inst.components.inventoryitem.owner

        if inst._light == nil then
            inst._light = SpawnPrefab("lanternlight")
            inst._light._lantern = inst
            inst:ListenForEvent("onremove", onremovelight, inst._light)
            fuelupdate(inst)
            PlayTurnOnSound(inst)
        end
        inst._light.entity:SetParent((owner or inst).entity)
        inst.AnimState:PlayAnimation("idle_on")

        if owner ~= nil and inst.components.equippable:IsEquipped() then
            owner.AnimState:Show("LANTERN_OVERLAY")
        end        

        inst.components.machine.ison = true
        inst.components.inventoryitem:ChangeImageName("walkinglight")
        inst:PushEvent("lantern_on")
    end
end

local function turnoff(inst)
    stoptrackingowner(inst)

    inst.components.fueled:StopConsuming()

    if inst._light ~= nil then
        inst._light:Remove()
        PlayTurnOffSound(inst)
    end

    inst.AnimState:PlayAnimation("idle_off")

    if inst.components.equippable:IsEquipped() then
        inst.components.inventoryitem.owner.AnimState:Hide("LANTERN_OVERLAY")
    end 

    inst.components.machine.ison = false
    inst.components.inventoryitem:ChangeImageName("walkinglight")
    inst:PushEvent("lantern_off")
end

local function OnRemove(inst)
    if inst._light ~= nil then
        inst._light:Remove()
    end
    if inst._soundtask ~= nil then
        inst._soundtask:Cancel()
    end
end

local function ondropped(inst)
    turnoff(inst)
    turnon(inst)
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "guywalk", "swap_walking_stick")
    owner.AnimState:OverrideSymbol("lantern_overlay", "guywalk", "lantern_overlay")

    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

        if owner.SoundEmitter then
        owner.SoundEmitter:KillSound(CUSTOM_EQUIP_SOUND_HANDLE)
        if inst.soundtask then
            inst.soundtask:Cancel()
        end
        inst.soundtask = inst:DoTaskInTime(0.3, function()
            if owner and owner:IsValid() and owner.SoundEmitter then
                owner.SoundEmitter:PlaySound(SOUND_WALKINGLIGHT_EQUIP, CUSTOM_EQUIP_SOUND_HANDLE)
                owner.SoundEmitter:SetVolume(CUSTOM_EQUIP_SOUND_HANDLE, 0.1)
            end
        end)
    end

    if inst.components.fueled:IsEmpty() then
        owner.AnimState:Hide("LANTERN_OVERLAY")
    else
        owner.AnimState:Show("LANTERN_OVERLAY")
        turnon(inst)
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
    owner.AnimState:ClearOverrideSymbol("lantern_overlay")
    owner.AnimState:Hide("LANTERN_OVERLAY")
    turnoff(inst)

    if inst.components.machine.ison then
        starttrackingowner(inst, owner)
    end
end

local function onequiptomodel(inst, owner, from_ground)
    if inst.components.machine.ison then
        starttrackingowner(inst, owner)
    end

    turnoff(inst)
end

local function nofuel(inst)
    if inst.components.equippable:IsEquipped() and inst.components.inventoryitem.owner ~= nil then
        local data = {
            prefab = inst.prefab,
            equipslot = inst.components.equippable.equipslot,
        }
        turnoff(inst)
        inst.components.inventoryitem.owner:PushEvent("torchranout", data)
    else
        turnoff(inst)
    end
end

local function ontakefuel(inst)
    if inst.components.equippable:IsEquipped() then
        turnon(inst)
    end
end

local floatable_swap_data = {sym_build = "guywalk", sym_name = "swap_walking_stick"}


local function OnLightWake(inst)
    if not inst.SoundEmitter:PlayingSound("loop") then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/lantern_LP", "loop")
    end
end

local function OnLightSleep(inst)
    inst.SoundEmitter:KillSound("loop")
end


local function lanternlightfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddLight()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    -- Weißliches Licht
    inst.Light:SetColour(0.95, 0.95, 1)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst.OnEntityWake = OnLightWake
    inst.OnEntitySleep = OnLightSleep

    return inst
end

local function fn()
    local inst = CreateEntity()
    
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("guywalk")
    inst.AnimState:SetBuild("guywalk")
    inst.AnimState:PlayAnimation("idle_off")

    inst:AddTag("light")

    MakeInventoryFloatable(inst, "med", 0.05, {0.95, 0.40, 0.95}, true, 1, floatable_swap_data)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    local inventoryitem = inst:AddComponent("inventoryitem")
    inventoryitem.atlasname = "images/inventoryimages/walkinglight.xml"
    inventoryitem:SetOnDroppedFn(ondropped)
    inventoryitem:SetOnPutInInventoryFn(turnoff)
    
    inst:AddComponent("equippable")

    local fueled = inst:AddComponent("fueled")

    local machine = inst:AddComponent("machine")
    machine.turnonfn = turnon
    machine.turnofffn = turnoff
    machine.cooldowntime = 0

    fueled.fueltype = FUELTYPE.CAVE
    fueled.secondaryfueltype = FUELTYPE.NIGHTMARE -- Allows nightmarefuel in addition to CAVE items
    fueled:InitializeFuelLevel(TUNING.LANTERN_LIGHTTIME)
    fueled:SetDepletedFn(nofuel)
    fueled:SetUpdateFn(fuelupdate)
    fueled:SetTakeFuelFn(ontakefuel)
    fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)
    fueled.accepting = true

    inst._light = nil

    MakeHauntableLaunch(inst)

    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable:SetOnEquipToModel(onequiptomodel)

    inst.components.equippable.walkspeedmult = TUNING.WALKING_STICK_SPEED_MULT * 1.2 -- Achtung darf keine ungeraden Werte haben wegen Precision!

    inst.OnRemoveEntity = OnRemove

    inst._onownerequip = function(owner, data)
        if data.item ~= inst and (data.eslot == EQUIPSLOTS.HANDS or (data.eslot == EQUIPSLOTS.BODY and data.item:HasTag("heavy"))) then
            turnoff(inst)
        end
    end
    return inst
end

return Prefab("walkinglight", fn, assets, prefabs),
    Prefab("lanternlight", lanternlightfn)