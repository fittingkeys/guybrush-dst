--------------------------------------------------------------------------------
-- Grog Assets
--------------------------------------------------------------------------------
local assets = {
    Asset("ANIM", "anim/grog.zip"),
    Asset("ATLAS", "images/inventoryimages/grog.xml"),
    Asset("IMAGE", "images/inventoryimages/grog.tex"),
}

--------------------------------------------------------------------------------
-- Define Fueltype CHEMICAL
--------------------------------------------------------------------------------
local GLOBAL = _G or GLOBAL 
local FUELTYPE = GLOBAL.FUELTYPE

if not FUELTYPE.CHEMICAL then
    FUELTYPE.CHEMICAL = "CHEMICAL"
end

-- Buff Constants
local GROG_BUFF_DURATION = 30
local FASTWORK_MULTIPLIER = 0.5
local MOVESPEED_MULTIPLIER = 1.4

local function stop_all_tasks(eater)
    if eater._grog_task then
        eater._grog_task:Cancel()
        eater._grog_task = nil
    end
end

local function reset_grog_effect(eater)
    if eater.SoundEmitter then
        eater.SoundEmitter:KillSound("grog_drink")
    end

    -- Only reset Fastwork buff if not in Gulet form
    if eater.AnimState:GetBuild() ~= "gulet" then
        if eater.prefab == "guybrush" and eater.components.fastwork then
            eater.components.fastwork:SetActionSpeed("chop", 1)
            eater.components.fastwork:SetActionSpeed("mine", 1)
            eater.components.fastwork:Reload()
            eater._fastwork_mult = nil
        end
    end

    -- Reset Movement Speed Boost
    if eater.components.locomotor then
        eater.components.locomotor:RemoveExternalSpeedMultiplier(eater, "grog_speed_buff")
    end

    eater._grog_buff_active = false
end

local function oneat(inst, eater)
    stop_all_tasks(eater)

    if not eater._grog_buff_active then
        eater._grog_buff_active = true
    end

    if eater.SoundEmitter then
        eater.SoundEmitter:KillSound("grog_drink")
        eater.SoundEmitter:PlaySound("grog_drink/custom/burb", "grog_drink")

        eater:DoTaskInTime(0.1, function()
            if eater.SoundEmitter then
                eater.SoundEmitter:SetVolume("grog_drink", 0.1)
            end
        end)
    end

    if eater.components.talker then
        eater.components.talker:Say("Arrr! That burns!")
    end

    if eater.prefab == "guybrush" and eater.components.fastwork then
        eater._fastwork_mult = FASTWORK_MULTIPLIER
        eater.components.fastwork:SetActionSpeed("chop", FASTWORK_MULTIPLIER)
        eater.components.fastwork:SetActionSpeed("mine", FASTWORK_MULTIPLIER)
        eater.components.fastwork:Reload()
    end

    if eater.components.locomotor then
        eater.components.locomotor:SetExternalSpeedMultiplier(eater, "grog_speed_buff", MOVESPEED_MULTIPLIER)
    end

    eater._grog_task = eater:DoTaskInTime(GROG_BUFF_DURATION, function()
        if eater.components.talker then
            eater.components.talker:Say("I think that left some permanent damage...")
        end
        reset_grog_effect(eater)
    end)
end

local function itemfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    inst.AnimState:SetBank("grog")
    inst.AnimState:SetBuild("grog")
    inst.AnimState:PlayAnimation("idle")

    ------------------------------------------------------------------------
    -- Periodisches Wackeln (shake)
    ------------------------------------------------------------------------
    if not TheNet:IsDedicated() then
        local function StartShakeTask(inst)
            if inst._shake_task then
                inst._shake_task:Cancel()
                inst._shake_task = nil
            end
            local function ScheduleNextShake()
                local delay = math.random(60, 120)
                inst._shake_task = inst:DoTaskInTime(delay, function()
                    if inst.AnimState then
                        inst.AnimState:PlayAnimation("shake", true)
                        if inst._shake_end_task then inst._shake_end_task:Cancel() end
                        inst._shake_end_task = inst:DoTaskInTime(30, function()
                            if inst.AnimState then
                                inst.AnimState:PlayAnimation("idle", true)
                            end
                            inst._shake_end_task = nil
                            ScheduleNextShake()
                        end)
                    end
                end)
            end
            ScheduleNextShake()
        end

        inst:DoTaskInTime(0, function() StartShakeTask(inst) end)

        inst:ListenForEvent("onremove", function()
            if inst._shake_task then inst._shake_task:Cancel() inst._shake_task = nil end
            if inst._shake_end_task then inst._shake_end_task:Cancel() inst._shake_end_task = nil end
        end)
    end

    inst:AddTag("edible")
    inst:AddTag("drink")

    MakeInventoryFloatable(inst, "med", 0.2, {0.75, 0.75, 0.75})

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/grog.xml"

    inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.GENERIC
    inst:AddTag("guletfood")
    inst.components.edible.healthvalue = 0
    inst.components.edible.hungervalue = 0
    inst.components.edible.sanityvalue = -5
    inst.components.edible:SetOnEatenFn(oneat)

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_SLOW)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

    ------------------------------------------------------------------------
    -- Integrate Fuel component
    ------------------------------------------------------------------------
    inst:AddComponent("fuel")
    inst.components.fuel.fueltype  = FUELTYPE.CHEMICAL
    inst.components.fuel.fuelvalue = 180  -- Adjust as needed

    return inst
end

return Prefab("grog", itemfn, assets)
