require "prefabutil"

local assets =
{
    Asset("SOUND", "sound/common.fsb"), -- Sound set for rumbling noise
    Asset("ANIM", "anim/grogomat.zip"), -- Animations of the machine
    Asset("IMAGE", "images/inventoryimages/grogomat.tex"),
    Asset("ATLAS", "images/inventoryimages/grogomat.xml"),
}

local prefabs =
{
    "goldnugget",
    "grog",
}

local function onhammered(inst, worker)
    local pos = inst:GetPosition()
    for i = 1, 6 do
        local grog = SpawnPrefab("grog")
        if grog then
            -- Random angle (in radians) and a random radius between 0.5 and 1.5
            local angle = math.random() * 2 * math.pi
            local radius = 0.5 + math.random() * 1.0
            local offset_x = math.cos(angle) * radius
            local offset_z = math.sin(angle) * radius
            grog.Transform:SetPosition(pos.x + offset_x, pos.y, pos.z + offset_z)
        end
    end
    SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
    inst:Remove()
end

local function onhit(inst, worker)
    inst.AnimState:PlayAnimation("hammered")
    inst.AnimState:PushAnimation("idle", true)
end

-- Gibt in zufälligen Intervallen automatisch eine Dose Grog aus
local function OnTrade(inst, giver, item)
    -- Wenn kein Item übergeben wurde (Auto-Dispense), trotzdem Grog ausgeben
    if item == nil or (item and item.prefab == "guycoin") then
        -- Animation "shake" während der Soundausgabe
        if inst._shake_task then inst._shake_task:Cancel() inst._shake_task = nil end
        inst.AnimState:PlayAnimation("shake", true)
        inst._shake_task = inst:DoTaskInTime(4.0, function()
            inst.AnimState:PlayAnimation("idle", true)
            inst._shake_task = nil
        end)
        inst.SoundEmitter:PlaySound("vendingmachine/custom/vending") -- Rumbling noise ideally
        inst:DoTaskInTime(4.0, function()
            local grog = SpawnPrefab("grog") -- Create Grog
            if grog then
                local pos = inst:GetPosition()
                 -- Calculate the offset in the direction the machine is facing
                local offset = 2.5
                local angle = inst.Transform:GetRotation()
                local rad = math.rad(angle)
                pos.x = pos.x + offset * math.cos(rad)
                pos.z = pos.z - offset * math.sin(rad)
                grog.Transform:SetPosition(pos.x, pos.y, pos.z)
                
                local puff = SpawnPrefab("explode_small") -- Alternatively "explode_small" for a larger effect
                
                if puff then
                    puff.Transform:SetPosition(pos.x, pos.y, pos.z)
                end

                -- Optional: Additional sound effect for the puff
                inst.SoundEmitter:PlaySound("dontstarve/common/ghost_despawn")


            end
        end)
    end
end

local function StartGrogomatAutoDispense(inst)
    if inst._grogomat_autotask ~= nil then
        inst._grogomat_autotask:Cancel()
    end
    local function schedule()
        local interval = 300 + math.random() * 600 -- 300 bis 900 Sekunden (5-15 Minuten)
        inst._grogomat_autotask = inst:DoTaskInTime(interval, function()
            if inst:IsValid() then
                -- Gibt Grog aus, als ob jemand eine Münze eingeworfen hätte, aber ohne Spieler
                OnTrade(inst, nil, nil)
                schedule() -- Nächstes Intervall starten
            end
        end)
    end
    schedule()
end

local function OnTrade(inst, giver, item)
    -- Wenn kein Item übergeben wurde (Auto-Dispense), trotzdem Grog ausgeben
    if item == nil or (item and item.prefab == "guycoin") then
        -- Animation "shake" während der Soundausgabe
        if inst._shake_task then inst._shake_task:Cancel() inst._shake_task = nil end
        inst.AnimState:PlayAnimation("shake", true)
        inst._shake_task = inst:DoTaskInTime(4.0, function()
            inst.AnimState:PlayAnimation("idle", true)
            inst._shake_task = nil
        end)
        inst.SoundEmitter:PlaySound("vendingmachine/custom/vending") -- Rumbling noise ideally
        inst:DoTaskInTime(4.0, function()
            local grog = SpawnPrefab("grog") -- Create Grog
            if grog then
                local pos = inst:GetPosition()
                 -- Calculate the offset in the direction the machine is facing
                local offset = 2.5
                local angle = inst.Transform:GetRotation()
                local rad = math.rad(angle)
                pos.x = pos.x + offset * math.cos(rad)
                pos.z = pos.z - offset * math.sin(rad)
                grog.Transform:SetPosition(pos.x, pos.y, pos.z)
                
                local puff = SpawnPrefab("explode_small") -- Alternatively "explode_small" for a larger effect
                
                if puff then
                    puff.Transform:SetPosition(pos.x, pos.y, pos.z)
                end

                -- Optional: Additional sound effect for the puff
                inst.SoundEmitter:PlaySound("dontstarve/common/ghost_despawn")


            end
        end)
    end
end

local function OnBuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle", true)
    inst._isbuilt:set(true) -- Set synchronization variable

    -- Reset collision after placing
    MakeObstaclePhysics(inst, 1.0)
end

local function fn()
    local inst = CreateEntity()

    inst:AddTag("structure")

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    -- Set MiniMap icon
    inst.MiniMapEntity:SetIcon("grogomat.tex")

    -- Set animation
    inst.AnimState:SetBank("grogomat")
    inst.AnimState:SetBuild("grogomat")
    inst.AnimState:PlayAnimation("idle", true)

    -- Set collision
    MakeObstaclePhysics(inst, 1.0)

    -- Initialize snow cover (pristine phase)
    MakeSnowCoveredPristine(inst)

    -- Initialize network variable: indicates if the object has been built
    inst._isbuilt = net_bool(inst.GUID, "grogomat._isbuilt", "isbuiltdirty")
    inst._isbuilt:set(false)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        -- On clients, react to the dirty event of the network variable:
        inst:ListenForEvent("isbuiltdirty", function(inst)
            if inst._isbuilt:value() then
                inst.AnimState:PlayAnimation("place")
                inst.AnimState:PushAnimation("idle", true)
            end
        end)
        return inst
    end

    -- Master simulation: activate snow cover
    MakeSnowCovered(inst)

    inst:AddComponent("inspectable")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(5)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(function(inst, item)
        return item.prefab == "guycoin"
    end)
    inst.components.trader.onaccept = OnTrade

    -- Starte den Auto-Dispense Task
    StartGrogomatAutoDispense(inst)

    inst:AddComponent("lootdropper")

    -- Event for placing
    inst:ListenForEvent("onbuilt", OnBuilt)

    return inst
end

return Prefab("grogomat", fn, assets, prefabs),
    MakePlacer("grogomat_placer", "grogomat", "grogomat", "idle")
