--------------------------------------------------------------------------
-- Guybrush Threepwood – Character Prefab (Gulet Form, Drunkenness)
--------------------------------------------------------------------------
local MakePlayerCharacter = require("prefabs/player_common")

--------------------------------------------------------------------------
-- Assets & Prefabs
--------------------------------------------------------------------------
local assets = {
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
    Asset("ANIM",   "anim/guybrush.zip"),
    Asset("ANIM",   "anim/ghost_guybrush_build.zip"),
    Asset("ANIM",   "anim/gulet.zip"),
}
local prefabs = {}

-- Declare WORLD_TILES and MARSH_TILES globally (like Wurt)
local MARSH_TILES = { WORLD_TILES.MARSH }
local SWAMP_SANITY = 0.05  -- Test value

--------------------------------------------------------------------------
-- Starting Inventory
--------------------------------------------------------------------------
TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.GUYBRUSH = {
    "cutless","goldnugget","goldnugget",
    "grog","grogballs_recipecard",
}
local start_inv = TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.GUYBRUSH

--------------------------------------------------------------------------
-- Helper tags for recipes
--------------------------------------------------------------------------

-- Dummy-Funktion, um Crash zu verhindern
local function RefreshEquippedBodyArmorVisuals(inst)
    -- Dummy: verhindert Crash, kann später erweitert werden
end

local function AddGuletBuilderTag(inst)
    if not inst:HasTag("gulet_builder") then
        inst:AddTag("gulet_builder")
    end
end

local function RemoveGuletBuilderTag(inst)
    inst:RemoveTag("gulet_builder")
end

--------------------------------------------------------------------------
-- Return from ghost state
--------------------------------------------------------------------------
local function ForceGuybrushVisuals(inst)
    inst.AnimState:SetBuild("guybrush")
    inst.AnimState:SetBank("wilson")
    print("[DEBUG] ForceGuybrushVisuals() - Build/Bank set: guybrush/wilson.")
    RefreshEquippedBodyArmorVisuals(inst)
end

local function onbecamehuman(inst)
    if inst.components.drunkenness and inst.components.drunkenness.transformed then
        print("[DEBUG] onbecamehuman() - Drunkenness.transformed is true. Assuming drunkenness component handles Gulet visuals.")
        if inst.isGulet then -- Ensure Gulet visuals if state implies it
            ForceGuletVisuals(inst)
        end
        return
    end
    print("[DEBUG] onbecamehuman() called: Not transformed by drunkenness, becoming Guybrush.")
    ForceGuybrushVisuals(inst) -- This sets build and refreshes armor
    inst.isGulet = false -- Ensure state consistency
end

--------------------------------------------------------------------------
-- KILL Bonus (Powder Monkey)
--------------------------------------------------------------------------
local function OnKill(inst, data)
    local victim = data and data.victim
    if victim and victim:HasTag("monkey") and inst.components.sanity then
        print("[DEBUG] OnKill() - Powder Monkey killed, +5 Sanity.")
        inst.components.sanity:DoDelta(5)
        if math.random() <= .05 then
            (victim.components.lootdropper or victim:AddComponent("lootdropper"))
                :SpawnLootPrefab("guycoin", victim:GetPosition())
        end
    end
end

--------------------------------------------------------------------------
-- EATING Effects (incl. Drunkenness)
--------------------------------------------------------------------------
local dish_effects = {
    -- Grog additionally increases Drunkenness
    grog  = { drunkenness = 18 },
    grogballs = { drunkenness = 4 },
    seeds = { spawn  = "poop" },
}

local function oneat(inst, food)
    local e = dish_effects[food.prefab]
    if not e then
        print("[DEBUG] oneat() - No entry in dish_effects for:", food.prefab)
        return
    end

    print("[DEBUG] oneat() - Consuming:", food.prefab)

    -- (1) Increase Drunkenness, if defined
    if e.drunkenness and inst.components.drunkenness then
        print(" Drank Grog! Increasing Drunkenness by", e.drunkenness)
        inst.components.drunkenness:DoDelta(e.drunkenness)
    end

    -- (2) Other spawn effects
    if e.spawn and food.prefab == "seeds" then
        inst.seedsEaten = (inst.seedsEaten or 0) + 1
        print("[DEBUG] oneat() - Eaten seeds. Counter:", inst.seedsEaten)

        if inst.seedsEaten >= 3 then
            inst.seedsEaten = 0
            SpawnPrefab(e.spawn).Transform:SetPosition(inst.Transform:GetWorldPosition())
            print("[DEBUG] oneat() - Eaten third seed. SpawnPrefab:", e.spawn)
        end
    elseif e.spawn and food.prefab ~= "seeds" then
        SpawnPrefab(e.spawn).Transform:SetPosition(inst.Transform:GetWorldPosition())
        print("[DEBUG] oneat() - SpawnPrefab:", e.spawn)
    end
end

--------------------------------------------------------------------------
-- EDIBLE Tests
--------------------------------------------------------------------------
local function NormalTestFood(_, f) return f.prefab ~= "meatballs" end
local function GuletTestFood (_, f) return f:HasTag("guletfood")   end

--------------------------------------------------------------------------
-- Additional helpers for setting graphics
--------------------------------------------------------------------------
local function RefreshEquippedBodyArmorVisuals(inst)
    if inst.components.inventory then
        local body_item = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
        if body_item and body_item.components.equippable then
            -- Simulate re-equipping visuals
            if body_item.components.equippable.onunequipfn then
                body_item.components.equippable.onunequipfn(body_item, inst)
            end
            if body_item.components.equippable.onequipfn then
                body_item.components.equippable.onequipfn(body_item, inst)
            end
            print("[DEBUG] Refreshed body armor visuals for build:", inst.AnimState:GetBuild())
        end
    end
end

local function ForceGuletVisuals(inst)
    inst.AnimState:SetBuild("gulet")
    inst.AnimState:SetBank("wilson")
    print("[DEBUG] ForceGuletVisuals() - Build/Bank set: gulet/wilson.")
    RefreshEquippedBodyArmorVisuals(inst)
end

local function ForceGuybrushVisuals(inst)
    inst.AnimState:SetBuild("guybrush")
    inst.AnimState:SetBank("wilson")
    print("[DEBUG] ForceGuybrushVisuals() - Build/Bank set: guybrush/wilson.")
    RefreshEquippedBodyArmorVisuals(inst)
end

--------------------------------------------------------------------------
-- FORM CHANGE
--------------------------------------------------------------------------
local FASTWORK_MULT         = .5
local WALK_SLOW ,RUN_SLOW   = 3.2 ,4.8
local WALK_NORM ,RUN_NORM   = 4   ,6

local function ChangeToGulet(inst)
    if inst.isGulet then
        -- Character was already Gulet, resetting Gulet graphics
        print("[DEBUG] ChangeToGulet() - Character is already Gulet, updating Build/Bank again.")
        ForceGuletVisuals(inst)
        return
    end

    print("[DEBUG] ChangeToGulet() - Changing to Gulet form.")
    inst.isGulet = true
    -- Set swamp speed buff directly here (like Wurt)
    if inst.components.locomotor then
        for _, tile in ipairs(MARSH_TILES) do
            print("[DEBUG][Gulet] SetFasterOnGroundTile", tile, true)
            inst.components.locomotor:SetFasterOnGroundTile(tile, true)
        end
    end

    SpawnPrefab("explode_small").Transform:SetPosition(inst.Transform:GetWorldPosition())

    -- Update graphics immediately
    ForceGuletVisuals(inst)

    -- Speed/Work adjustment
    inst.components.locomotor:SetExternalSpeedMultiplier(inst, "gulet", WALK_SLOW / WALK_NORM)
    inst.components.locomotor.walkspeed ,inst.components.locomotor.runspeed = WALK_SLOW, RUN_SLOW

    if inst.components.fastwork then
        inst.components.fastwork:SetActionSpeed("chop", FASTWORK_MULT)
        inst.components.fastwork:SetActionSpeed("mine", FASTWORK_MULT)
        inst.components.fastwork:Reload()
        print("[DEBUG] ChangeToGulet() - Fast work accelerated.")
    end

    -- Damage multiplier in Gulet form
    if inst.components.combat then
        inst.components.combat.damagemultiplier = 1.2
        print("[DEBUG] ChangeToGulet() - Damage increased by 20%.")
    end

    -- Gulet is immune to swamp
    inst:AddTag("swamp_immunity")
    AddGuletBuilderTag(inst)

    if inst.components.eater then
        inst.components.eater.TestFood = GuletTestFood
        print("[DEBUG] ChangeToGulet() - Eating behavior changed: GuletTestFood.")
    end
end

local function ChangeToGuybrush(inst)
    if not inst.isGulet then
        -- Character was already Guybrush, resetting Guybrush graphics
        print("[DEBUG] ChangeToGuybrush() - Character is not Gulet, updating Build/Bank again.")
        ForceGuybrushVisuals(inst)
        return
    end

    print("[DEBUG] ChangeToGuybrush() - Changing back to Guybrush.")
    inst.isGulet = false
    -- Remove swamp speed buff directly here
    if inst.components.locomotor then
        for _, tile in ipairs(MARSH_TILES) do
            print("[DEBUG][Gulet] SetFasterOnGroundTile", tile, false)
            inst.components.locomotor:SetFasterOnGroundTile(tile, false)
        end
    end

    SpawnPrefab("explode_small").Transform:SetPosition(inst.Transform:GetWorldPosition())

    -- Update graphics immediately
    ForceGuybrushVisuals(inst)

    -- Speed/Work adjustment
    inst.components.locomotor:SetExternalSpeedMultiplier(inst, "gulet", 1)
    inst.components.locomotor.walkspeed ,inst.components.locomotor.runspeed = WALK_NORM, RUN_NORM

    if inst.components.fastwork then
        inst.components.fastwork:SetActionSpeed("chop", 1)
        inst.components.fastwork:SetActionSpeed("mine", 1)
        inst.components.fastwork:Reload()
        print("[DEBUG] ChangeToGuybrush() - Fast work reset to normal.")
    end

    -- Damage multiplier to default
    if inst.components.combat then
        inst.components.combat.damagemultiplier = 1
        print("[DEBUG] ChangeToGuybrush() - Damage reset to normal.")
    end

    inst:RemoveTag("swamp_immunity")
    RemoveGuletBuilderTag(inst)

    if inst.components.eater then
        inst.components.eater.TestFood = NormalTestFood
        print("[DEBUG] ChangeToGuybrush() - Eating behavior changed: NormalTestFood.")
    end
end

--------------------------------------------------------------------------
-- CLIENT Init
--------------------------------------------------------------------------
local function common_postinit(inst)
    print("[DEBUG] common_postinit() - Client init for Guybrush.")
    inst:AddTag("guybrush")
    inst.MiniMapEntity:SetIcon("guybrush.tex")
    inst:AddTag("nowormholesanityloss")

    -- Replica of the Drunkenness component
    inst.replica.drunkenness = require("components/drunkenness_replica")(inst)
end

--------------------------------------------------------------------------
-- SERVER Init
--------------------------------------------------------------------------
local function master_postinit(inst)

    ----------------------------------------------------------------------
    -- Base stats
    ----------------------------------------------------------------------
    inst.soundsname = "wilson"
    inst.components.health:SetMaxHealth(150)
    inst.components.hunger:SetMax(250)
    inst.components.sanity:SetMax(150)

    inst.components.locomotor.walkspeed ,inst.components.locomotor.runspeed = WALK_NORM, RUN_NORM
    inst.components.builder.science_bonus = 1

    inst.components.eater:SetDiet({FOODGROUP.OMNI},{FOODGROUP.OMNI})
    inst.components.eater:SetOnEatFn(oneat)
    inst.components.eater.TestFood = NormalTestFood

    ----------------------------------------------------------------------
    -- Drunkenness component
    ----------------------------------------------------------------------
    print("[DEBUG] master_postinit() - Adding Drunkenness component.")
    inst:AddComponent("drunkenness")

    ----------------------------------------------------------------------
    -- Extend OnSave / OnLoad (Wrapping)
    ----------------------------------------------------------------------
    local old_OnSave = inst.OnSave
    inst.OnSave = function(inst, data)
        if old_OnSave then
            old_OnSave(inst, data)
        end
        if inst.components.drunkenness then
            data.drunkenness = inst.components.drunkenness:OnSave()
            print("[DEBUG] OnSave() - Saving Drunkenness:", data.drunkenness.current)
        end
        data.isGulet = inst.isGulet
        print("[DEBUG] OnSave() - Saving isGulet:", inst.isGulet)
    end

    local old_OnLoad = inst.OnLoad
    inst.OnLoad = function(inst, data)
        if old_OnLoad then
            old_OnLoad(inst, data)
        end
        if data then
            if data.drunkenness and inst.components.drunkenness then
                print("[DEBUG] OnLoad() - Loading Drunkenness:", data.drunkenness.current)
                inst.components.drunkenness:OnLoad(data.drunkenness)
            end
            if data.isGulet ~= nil then
                inst.isGulet = data.isGulet
                print("[DEBUG] OnLoad() - Loaded isGulet:", inst.isGulet)
            else
                inst.isGulet = false -- Default if not saved from a previous session with this logic
                print("[DEBUG] OnLoad() - isGulet not found in save data, defaulting to false.")
            end
        else
            inst.isGulet = false -- Default if no data (e.g. new character)
            print("[DEBUG] OnLoad() - No save data, defaulting isGulet to false.")
        end

        -- Ensure correct visuals after all loading, based on the definitive isGulet state
        if inst.isGulet then
            ForceGuletVisuals(inst)
        else
            ForceGuybrushVisuals(inst)
        end
        print("[DEBUG] OnLoad() in guybrush.lua finished. Ensured visuals are synced based on isGulet.")
    end

    ----------------------------------------------------------------------
    -- Form callbacks
    ----------------------------------------------------------------------
    inst.ChangeToGulet    = ChangeToGulet
    inst.ChangeToGuybrush = ChangeToGuybrush

    inst:ListenForEvent("transform_gulet", function() 
        print("[DEBUG] Event transform_gulet heard - calling ChangeToGulet.")
        inst:ChangeToGulet()
    end)
    inst:ListenForEvent("transform_guybrush", function() 
        print("[DEBUG] Event transform_guybrush heard - calling ChangeToGuybrush.")
        inst:ChangeToGuybrush()
    end)

    ----------------------------------------------------------------------
    -- Disable Monkey Curse completely
    ----------------------------------------------------------------------
    if inst.components.monkeycurse then
        inst:RemoveComponent("monkeycurse")
        print("[DEBUG] Monkey Curse component removed.")
    end

    ----------------------------------------------------------------------
    -- Swamp sanity modifier for Gulet: Arrow in HUD like with flowers
    ----------------------------------------------------------------------
    local SWAMP_SANITY_MODIFIER = "gulet_swamp"
    local SWAMP_SANITY_RATE = SWAMP_SANITY -- can be adjusted
    inst:DoPeriodicTask(1, function()
        if inst.components.sanity and inst.isGulet then
            local x, y, z = inst.Transform:GetWorldPosition()
            local tile = TheWorld.Map:GetTileAtPoint(x, 0, z)
            local on_swamp = false
            for _, t in ipairs(MARSH_TILES) do
                if tile == t then
                    on_swamp = true
                    break
                end
            end
            if on_swamp then
                if not inst._gulet_swamp_sanity then
                    inst.components.sanity.externalmodifiers:SetModifier(SWAMP_SANITY_MODIFIER, SWAMP_SANITY_RATE, "gulet_swamp")
                    inst._gulet_swamp_sanity = true
                    print("[DEBUG][Gulet] Sanity modifier for swamp set (arrow in HUD)")
                end
            else
                if inst._gulet_swamp_sanity then
                    inst.components.sanity.externalmodifiers:RemoveModifier(SWAMP_SANITY_MODIFIER, "gulet_swamp")
                    inst._gulet_swamp_sanity = nil
                    print("[DEBUG][Gulet] Sanity modifier for swamp removed")
                end
            end
        elseif inst._gulet_swamp_sanity then
            inst.components.sanity.externalmodifiers:RemoveModifier(SWAMP_SANITY_MODIFIER, "gulet_swamp")
            inst._gulet_swamp_sanity = nil
            print("[DEBUG][Gulet] Sanity modifier for swamp removed (form change)")
        end
    end)

    -- Other listeners
    ----------------------------------------------------------------------
    inst:ListenForEvent("killed", OnKill)
    inst:ListenForEvent("death", function() 
        print("[DEBUG] Event death - SetBuild to ghost_guybrush_build.")
        inst.AnimState:SetBuild("ghost_guybrush_build") 
    end)
    -- DON'T call "onbecamehuman(inst)" immediately anymore -> avoid collision with Gulet state
    inst:ListenForEvent("ms_respawnedfromghost", onbecamehuman)

end

--------------------------------------------------------------------------
-- Create player prefab
--------------------------------------------------------------------------
local guybrush = MakePlayerCharacter(
    "guybrush",
    prefabs,
    assets,
    common_postinit,
    master_postinit,
    start_inv
)

return guybrush
