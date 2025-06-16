require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/guychest.zip"),
}

local prefabs_regular =
{
	"collapse_small",
	"collapsed_treasurechest",
}

local SUNKEN_PHYSICS_RADIUS = .45

local SOUNDS = {
    open  = "dontstarve/wilson/chest_open",
    close = "dontstarve/wilson/chest_close",
    built = "dontstarve/common/chest_craft",
}

local function UpdateKeyholeSymbol(inst)
    if not inst or not inst.components or not inst.components.container then return end
    local total_gold_amount = 0
    local items = inst.components.container:FindItems(function(item)
        return item.prefab == "goldnugget"
    end)

    for _, item_stack in ipairs(items) do
        if item_stack.components.stackable then
            total_gold_amount = total_gold_amount + item_stack.components.stackable:StackSize()
        end
    end

    local symbol = "keyhole" -- Default symbol (e.g., for 0 gold)
    if total_gold_amount >= 10 then
        symbol = "keyhole3"
    elseif total_gold_amount >= 5 then
        symbol = "keyhole2"
    elseif total_gold_amount < 5 then
        symbol = "keyhole1"
    end
    inst.AnimState:OverrideSymbol("keyhole", "guychest", symbol)
end

local function onopen(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("open")
        UpdateKeyholeSymbol(inst)
        inst.SoundEmitter:PlaySound(inst.sounds.open)
    end
end 

local function onclose(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("close")
        inst.AnimState:PushAnimation("closed", false)
        UpdateKeyholeSymbol(inst)
        inst.SoundEmitter:PlaySound(inst.sounds.close)
    end
end 

local function onhammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    inst.components.lootdropper:DropLoot()
    if inst.components.container ~= nil then
        inst.components.container:DropEverything()
    end
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function onhit(inst, worker)
    if not inst:HasTag("burnt") then
        if inst.components.container ~= nil then
            inst.components.container:DropEverything()
            inst.components.container:Close()
        end
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("closed", false)
    end
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("rebuild")
    inst.AnimState:PushAnimation("closed", false)
    inst.SoundEmitter:PlaySound(inst.sounds.built)
end

local function onsave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end
end

local function onload(inst, data)
    if data ~= nil and data.burnt and inst.components.burnable ~= nil then
        inst.components.burnable.onburnt(inst)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.4)

    inst.MiniMapEntity:SetIcon("chest.png")

    inst:AddTag("structure")
    inst:AddTag("chest")
    inst:AddTag("heavy")
    inst.AnimState:SetBank("guychest")
    inst.AnimState:SetBuild("guychest")
    inst.AnimState:PlayAnimation("closed")

    MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.sounds = SOUNDS

    inst:AddComponent("inspectable")
    inst:AddComponent("container")
    
    inst.components.container:WidgetSetup("guychest")
    inst.components.container.onopenfn = onopen
    inst.components.container.onclosefn = onclose
    inst.components.container.skipclosesnd = true
    inst.components.container.skipopensnd = true

    -- Initiales Setzen beim Spawn
    inst:DoTaskInTime(0, function() UpdateKeyholeSymbol(inst) end)

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(10)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit) 

    AddHauntableDropItemOrWork(inst)

    inst:ListenForEvent("onbuilt", onbuilt)
    inst:ListenForEvent("itemget", function() UpdateKeyholeSymbol(inst) end)
    inst:ListenForEvent("itemlose", function() UpdateKeyholeSymbol(inst) end)
    MakeSnowCovered(inst)   

    MakeSmallBurnable(inst, nil, nil, true)
    MakeMediumPropagator(inst)

    inst.OnSave = onsave 
    inst.OnLoad = onload
    
    return inst
end

return Prefab("guychest", fn, assets),
        MakePlacer("guychest_placer", "guychest", "guychest", "closed")