------------------------------------------------------------------
-- monkeygraph.lua  – komplett
------------------------------------------------------------------
require "prefabutil"

------------------------------------------------------------------
-- Assets
------------------------------------------------------------------
local assets = {
    Asset("ANIM",  "anim/monkeygraph.zip"),
    Asset("IMAGE", "images/inventoryimages/monkeygraph.tex"),
    Asset("ATLAS", "images/inventoryimages/monkeygraph.xml"),
}

------------------------------------------------------------------
-- Konstanten
------------------------------------------------------------------
local SPAWN_RADIUS        = 15
local RETURN_RADIUS       = 20
local PLAYER_CHECK_RADIUS = 15
local LOOP_HANDLE         = "monkeygraph_loop"   -- eindeutiger Sound‑Handle

------------------------------------------------------------------
-- Hilfsfunktionen
------------------------------------------------------------------
local function GetRandomSpawnPosition(inst)
    if not TheWorld.ismastersim then return 0,0,0 end
    local x,y,z = inst.Transform:GetWorldPosition()
    local a = math.random()*2*math.pi
    local d = math.random()*SPAWN_RADIUS
    return x+math.cos(a)*d, 0, z+math.sin(a)*d
end

local function IsGuybrushDrunk(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    local players = TheSim:FindEntities(x,y,z, PLAYER_CHECK_RADIUS, {"player"})
    for _,p in ipairs(players) do
        if p.prefab=="guybrush"
           and p.components.drunkenness
           and (p.components.drunkenness.current or 0) > 50 then
            return true
        end
    end
    return false
end

local function AttractMonkeys(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    local list  = TheSim:FindEntities(x,y,z, RETURN_RADIUS, {"powder_monkey"})
    for _,m in ipairs(list) do
        if m.components.locomotor then
            m.components.locomotor:GoToPoint(Vector3(x,y,z))
        end
    end
    inst:DoTaskInTime(10, AttractMonkeys)
end

local function SpawnMonkey(inst)
    if inst.components.machine.ison
       and not inst:HasTag("stopped")
       and IsGuybrushDrunk(inst) then
        local x,y,z = GetRandomSpawnPosition(inst)
        local m = SpawnPrefab("powder_monkey")
        if m then m.Transform:SetPosition(x,y,z) end
    end
    inst.spawn_task = inst:DoTaskInTime(60, SpawnMonkey)
end

local function StopSpawnLoop(inst)
    if inst.spawn_task then
        inst.spawn_task:Cancel()
        inst.spawn_task = nil
    end
    inst:AddTag("stopped")
end

------------------------------------------------------------------
-- Ein‑ / Ausschalten
------------------------------------------------------------------
local function onTurnOn(inst)
    if inst.SoundEmitter then
        inst.SoundEmitter:PlaySound("soundtrack/custom/monkeytracks",
                                    LOOP_HANDLE, nil, true)
        inst:DoTaskInTime(.1, function()
            if inst.SoundEmitter then
                inst.SoundEmitter:SetVolume(LOOP_HANDLE, 0.05)
            end
        end)
    end

    inst.AnimState:PlayAnimation("play_loop", true)
    inst.components.machine.ison = true
    inst:RemoveTag("stopped")

    ----------------------------------------------------------------
    -- ► wichtig: Objekt darf nicht schlafen, sonst stoppt der Loop
    ----------------------------------------------------------------
    inst.entity:SetCanSleep(false)

    inst.spawn_task = inst:DoTaskInTime(60, SpawnMonkey)
    AttractMonkeys(inst)
end

local function onTurnOff(inst)
    if inst.SoundEmitter then
        inst.SoundEmitter:KillSound(LOOP_HANDLE)
    end
    inst.AnimState:PlayAnimation("idle")
    inst.components.machine.ison = false

    ----------------------------------------------------------------
    -- ► Schlafen wieder zulassen
    ----------------------------------------------------------------
    inst.entity:SetCanSleep(true)

    StopSpawnLoop(inst)
end

------------------------------------------------------------------
-- Zerstörungs‑ / Arbeits‑Callbacks
------------------------------------------------------------------
local function onHammered(inst)
    SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
    StopSpawnLoop(inst)
    inst:Remove()
end

local function onWorked(inst, worker, workleft)
    if workleft <= 0 then
        onHammered(inst)
    else
        inst.AnimState:PlayAnimation("shifted")
        inst.AnimState:PushAnimation("idle", false)
    end
end

local function onBurnt(inst)
    inst.AnimState:PlayAnimation("burnt")
    StopSpawnLoop(inst)
    inst:DoTaskInTime(3.5, inst.Remove)
end

------------------------------------------------------------------
-- Prefab‑Factory
------------------------------------------------------------------
local function fn()
    local inst = CreateEntity()

    inst:AddTag("structure")

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("monkeygraph.tex")

    inst.AnimState:SetBank("monkeygraph")
    inst.AnimState:SetBuild("monkeygraph")
    inst.AnimState:PlayAnimation("idle")

    MakeObstaclePhysics(inst, 1.0)
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    --------------------------------------------------------------
    -- Komponenten
    --------------------------------------------------------------
    inst:AddComponent("inspectable")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(6)
    inst.components.workable:SetOnFinishCallback(onHammered)
    inst.components.workable:SetOnWorkCallback(onWorked)

    inst:AddComponent("machine")
    inst.components.machine.turnonfn   = onTurnOn
    inst.components.machine.turnofffn  = onTurnOff
    inst.components.machine.canturnoff = true
    inst.components.machine.ison       = false

    inst:AddComponent("lootdropper")

    inst:AddComponent("burnable")
    inst.components.burnable:SetOnBurntFn(onBurnt)

    return inst
end

return Prefab("monkeygraph", fn, assets),
       MakePlacer("monkeygraph_placer", "monkeygraph", "monkeygraph", "idle")
