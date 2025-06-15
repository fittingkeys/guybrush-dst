--===================================================================
--  modmain.lua
--===================================================================

--------------------------------------------------------------------------
-- (1) FastWork Code
--------------------------------------------------------------------------

local _D = GetModConfigData("debug_mode") or false -- Debug Mode
local _G = GLOBAL
local TheNet = _G.TheNet
local TUNING = _G.TUNING
local IsServer = TheNet:GetIsServer() or TheNet:IsDedicated()

-- Configuration for FastWork speeds
local CON_FAST_WORK = {
    ["chop"] = GetModConfigData("fast_work_chop") or 0.3,
    ["mine"] = GetModConfigData("fast_work_mine") or 0.3,
}

-- Configuration for number of hits (Times Work)
local CON_TIMES_WORK = {
    ["chop"] = GetModConfigData("times_work_chop") or 1,
    ["mine"] = GetModConfigData("times_work_mine") or 1,
}

-- Helper function for multipliers
local function TuningMultiplier(var, multi)
    if var then
        if multi == 0 or multi == nil or type(multi) ~= "number" then
            return 1
        else
            return math.ceil(var * multi)
        end
    end
end

-- Find player by name
local function GetPlayerByName(playername)
    for _, player in ipairs(_G.AllPlayers) do
        if player.name == playername and player.prefab == "guybrush" and player.components and player.components.fastwork then
            return player
        end
    end
end

-- Debugging and standard messages
local function MsgPrint(str, deb, source)
    if deb then
        if _D and source then
            print("[Fast Work] Debug(" .. source .. "): " .. str .. ".")
        end
    else
        print("[Fast Work] " .. str .. ".")
    end
end

-- Set work speed for Guybrush
local function SetWorkSpeed(player, tar, multi)
    if player
       and player.prefab == "guybrush"
       and player.sg
       and player.sg.sg
       and player.components
       and player.components.fastwork
    then
        player.components.fastwork:Reload()
        if tar == nil or tar == "all" then
            for k, v in pairs(CON_FAST_WORK) do
                player.components.fastwork:SetActionSpeed(k, multi or v)
            end
        else
            if CON_FAST_WORK[tar] then
                player.components.fastwork:SetActionSpeed(tar, multi or CON_FAST_WORK[tar])
            else
                MsgPrint("Target '" .. tostring(tar) .. "' is not valid.", true, "SetWorkSpeed")
            end
        end
    end
end

-- Set number of hits for specific jobs
local function SetWorkTimes(tar, multi)
    if not TUNING then return end

    if tar == nil or tar == "all" then
        for k, v in pairs(CON_TIMES_WORK) do
            SetWorkTimes(k, multi or v)
        end
    elseif tar == "chop" then
        TUNING.EVERGREEN_CHOPS_SMALL  = TuningMultiplier(TUNING.EVERGREEN_CHOPS_SMALL,  multi)
        TUNING.EVERGREEN_CHOPS_NORMAL = TuningMultiplier(TUNING.EVERGREEN_CHOPS_NORMAL, multi)
        TUNING.EVERGREEN_CHOPS_TALL   = TuningMultiplier(TUNING.EVERGREEN_CHOPS_TALL,   multi)
        TUNING.MUSHTREE_CHOPS_SMALL   = TuningMultiplier(TUNING.MUSHTREE_CHOPS_SMALL,   multi)
        TUNING.MUSHTREE_CHOPS_NORMAL  = TuningMultiplier(TUNING.MUSHTREE_CHOPS_NORMAL,  multi)
        TUNING.MUSHTREE_CHOPS_TALL    = TuningMultiplier(TUNING.MUSHTREE_CHOPS_TALL,    multi)
        TUNING.SPIKETREE_CHOPS        = TuningMultiplier(TUNING.SPIKETREE_CHOPS,        multi)
    elseif tar == "mine" then
        TUNING.ROCKS_MINE       = TuningMultiplier(TUNING.ROCKS_MINE,       multi)
        TUNING.ROCKS_MINE_MED   = TuningMultiplier(TUNING.ROCKS_MINE_MED,   multi)
        TUNING.ROCKS_MINE_LOW   = TuningMultiplier(TUNING.ROCKS_MINE_LOW,   multi)
        TUNING.SPILAGMITE_ROCK  = TuningMultiplier(TUNING.SPILAGMITE_ROCK,  multi)
    else
        MsgPrint("SetWorkTimes target '" .. tostring(tar) .. "' is not valid.", true)
    end
end

-- Event: Player Spawning
local function OnPlayerSpawn(_, player)
    if IsServer and player.prefab == "guybrush" and player.components and player.components.fastwork == nil then
        player:AddComponent("fastwork")
        SetWorkSpeed(player)
    end
    MsgPrint("Player '" .. player.name .. "' Spawned", true, "OnPlayerSpawn")
end

-- Event: World Initialization
local function OnWorldInit(inst)
    SetWorkTimes()
end

-- Server Initialization
if IsServer then
    AddComponentPostInit("playerspawner", function(_, inst)
        inst:ListenForEvent("ms_playerjoined", OnPlayerSpawn)
    end)

    AddPrefabPostInit("world", OnWorldInit)

    _G.global("fastwork")
    _G.fastwork = function(playername, multi, tar)
        local player = GetPlayerByName(playername)
        if player then
            SetWorkSpeed(player, tar, multi)
            MsgPrint("Configured successfully")
        else
            MsgPrint("Player '" .. tostring(playername) .. "' is not valid")
        end
    end

    _G.global("timeswork")
    _G.timeswork = function(_, tar, multi)
        SetWorkTimes(tar, multi)
    end
end

--------------------------------------------------------------------------
-- (2) Prefab and Asset Registration
--------------------------------------------------------------------------

PrefabFiles = {
    "guybrush",
    "guybrush_none",
    "gummihuhn",
    "guysword",
    "secret",
    "guycoin",
    "grog",
    "grogomat",
    "monkeygraph",
    "dummylechuck",
    "monkeycompass",
    "grogballs",
    "grogballs_recipecard",
    "amgulet",
    "armor_pirate",
    "leather_repairkit",
    "boat_bumpers",
    "gummi",
    "guychest",
    "guyhat",
    "walkinglight"
}

Assets = {

    Asset("IMAGE", "images/saveslot_portraits/guybrush.tex"),
    Asset("ATLAS", "images/saveslot_portraits/guybrush.xml"),

    Asset("IMAGE", "images/selectscreen_portraits/guybrush.tex"),
    Asset("ATLAS", "images/selectscreen_portraits/guybrush.xml"),
    
    Asset("IMAGE", "images/selectscreen_portraits/guybrush_silho.tex"),
    Asset("ATLAS", "images/selectscreen_portraits/guybrush_silho.xml"),

    Asset("IMAGE", "bigportraits/guybrush.tex"),
    Asset("ATLAS", "bigportraits/guybrush.xml"),
    
    Asset("IMAGE", "images/map_icons/guybrush.tex"),
    Asset("ATLAS", "images/map_icons/guybrush.xml"),
    
    Asset("IMAGE", "images/avatars/avatar_guybrush.tex"),
    Asset("ATLAS", "images/avatars/avatar_guybrush.xml"),
    
    Asset("IMAGE", "images/avatars/avatar_ghost_guybrush.tex"),
    Asset("ATLAS", "images/avatars/avatar_ghost_guybrush.xml"),

    Asset("IMAGE", "images/avatars/avatar_gulet.tex"),
    Asset("ATLAS", "images/avatars/avatar_gulet.xml"),

    Asset("IMAGE", "images/names_guybrush.tex"),
    Asset("ATLAS", "images/names_guybrush.xml"),
    
    Asset("IMAGE", "images/names_gold_guybrush.tex"),
    Asset("ATLAS", "images/names_gold_guybrush.xml"),

    Asset("IMAGE", "images/cookbook_grogballs.tex"),
    Asset("ATLAS", "images/cookbook_grogballs.xml"),

    Asset("IMAGE", "images/inventoryimages/grog.tex"),
    Asset("ATLAS", "images/inventoryimages/grog.xml"),

    Asset("IMAGE", "images/inventoryimages/boat_bumper_guybrush_kit.tex"),
    Asset("ATLAS", "images/inventoryimages/boat_bumper_guybrush_kit.xml"),
    Asset("ANIM", "anim/boat_bumper_guybrush.zip"),

    Asset("ANIM", "anim/drunkenness_grog.zip"),
    Asset("ANIM", "anim/drunkenness_body.zip"),

    Asset("ANIM", "anim/monkeycompass_bg.zip"),
    Asset("ANIM", "anim/monkeycompass_hud.zip"),

    Asset("ATLAS", "images/inventoryimages/guychest.xml"),
    Asset("IMAGE", "images/inventoryimages/guychest.tex"),
    Asset("ANIM", "anim/ui_largechest_5x5.zip"),

    Asset("IMAGE", "images/inventoryimages/guycoin.tex"),
    Asset("ATLAS", "images/inventoryimages/guycoin.xml"),

    Asset("SOUNDPACKAGE", "sound/guyswordequip.fev"),
    Asset("SOUND",        "sound/guyswordequip.fsb"),

    Asset("SOUNDPACKAGE", "sound/chickenkweek.fev"),
    Asset("SOUND",        "sound/chickenkweek.fsb"),

    Asset("SOUNDPACKAGE", "sound/grog_drink.fev"),
    Asset("SOUND",        "sound/grog_drink.fsb"),

    Asset("SOUNDPACKAGE", "sound/vendingmachine.fev"),
    Asset("SOUND",        "sound/vendingmachine.fsb"),

    Asset("SOUNDPACKAGE", "sound/soundtrack.fev"),
    Asset("SOUND",        "sound/soundtrack.fsb"),

    Asset("SOUNDPACKAGE", "sound/dummyhit.fev"),
    Asset("SOUND",        "sound/dummyhit.fsb"),

    Asset("SOUNDPACKAGE", "sound/murrayequip.fev"),
    Asset("SOUND",        "sound/murrayequip.fsb"),

}

AddMinimapAtlas("images/map_icons/guybrush.xml")

local require       = _G.require
local State         = _G.State
local Action        = _G.Action
local ActionHandler = _G.ActionHandler
local ACTIONS       = _G.ACTIONS
local CanEntitySeeTarget = _G.CanEntitySeeTarget
local RECIPETABS    = _G.RECIPETABS
local TECH          = _G.TECH
local STRINGS       = _G.STRINGS
local Ingredient = _G.Ingredient
local cooking                    = _G.require("cooking")
local AddCookerRecipe            = _G.AddCookerRecipe
local AddIngredientValues        = _G.AddIngredientValues
local RegisterInventoryItemAtlas = _G.RegisterInventoryItemAtlas
local FOODTYPE                   = _G.FOODTYPE

--------------------------------------------------------------------------
-- (5) Guybrush-specific Recipes
--------------------------------------------------------------------------

local CHAR_TAG   = "guybrush"
local TAB_WAR    = RECIPETABS.WAR
local SORT_BASE  = -64360

-- Helper function for recipes
local function AddGuybrushRecipe(name, ing, tab, sortstep, desc, pretty)
    local atlas = ("images/inventoryimages/%s.xml"):format(name)
    local tex   = ("%s.tex"):format(name)

    local rec = AddRecipe(
        name,
        ing,
        tab or TAB_WAR,
        TECH.NONE,
        nil, 1.0, nil, nil,
        CHAR_TAG,
        atlas, tex
    )

    rec.sortkey = SORT_BASE - sortstep

    local up = string.upper(name)
    STRINGS.NAMES[up]       = pretty or name:gsub("^%l", string.upper)
    STRINGS.RECIPE_DESC[up] = desc or " "
    return rec
end

-- 1) Mighty Sword
local guysword = AddGuybrushRecipe(
    "guysword",
    {
        Ingredient("cutless",    1),
        Ingredient("goldnugget", 1),
        Ingredient("blackflag",  1),
    },
    TAB_WAR, 1,
    "Soon you'll be wearing my sword like a shish kebab!",
    "Mighty Sword"
)
STRINGS.CHARACTERS.GENERIC.DESCRIBE.GUYSWORD = "Arrr, that's sharp!"

-- 2) Rubber Chicken
local gummihuhn = AddGuybrushRecipe(
    "gummihuhn",
    {
        Ingredient("spear",         1),
        Ingredient("torch",         1),
        Ingredient("gummi", 1),
    },
    TAB_WAR, 2,
    "I'm rubber, you're glue...",
    "Rubber Chicken"
)
STRINGS.CHARACTERS.GENERIC.DESCRIBE.GUMMIHUHN = "The famous rubber chicken with a pulley in the middle."

-- 3) Guycoin (10 pieces)
local guycoin = AddGuybrushRecipe(
    "guycoin",
    {
        Ingredient("goldnugget", 1),
        Ingredient("marble",     3),
    },
    RECIPETABS.TOOLS, 3,
    "Official currency of the Moon Quay Trading Company.",
    "Guycoin"
)
guycoin.numtogive = 10
STRINGS.CHARACTERS.GENERIC.DESCRIBE.GUYCOIN = "Golden monkey coins."

-- 4) Grog-o-Mat
local grogomat = AddGuybrushRecipe(
    "grogomat",
    {
        Ingredient("boards",       6),
        Ingredient("slurtleslime", 1),
        Ingredient("gears",        1),
    },
    TAB_WAR, 4,
    "Money in, grog out - a fair trade!",
    "Grog-o-Mat"
)
grogomat.placer = "grogomat_placer"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.GROGOMAT = "A vending machine full of grog."

-- 5) Monkeygraph
local monkeygraph = AddGuybrushRecipe(
    "monkeygraph",
    {
        Ingredient("nightmarefuel",  2),
        Ingredient("palmcone_scale", 6),
        Ingredient("gears",          1),
    },
    TAB_WAR, 5,
    "A phonograph with a monkey head in the middle?",
    "Monkeygraph"
)
monkeygraph.placer = "monkeygraph_placer"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MONKEYGRAPH = "Music for pirates!"

-- 6) LeChuck Punchbag
local dummylechuck = AddGuybrushRecipe(
    "dummylechuck",
    {
        Ingredient("gummi",           2),
        Ingredient("palmcone_scale",  10),
        Ingredient("monkey_mediumhat", 1),
        Ingredient("lightbulb",        1),
    },
    TAB_WAR, 6,
    "Here I can let out my frustration.",
    "LeChuck Punchbag"
)
dummylechuck.placer = "dummylechuck_placer"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.DUMMYLECHUCK = "Take this LeChuck!"

-- 7) Monkey Compass
local monkeycompass = AddGuybrushRecipe(
    "monkeycompass",
    {
        Ingredient("compass",     1),
        Ingredient("cave_banana", 1),
        Ingredient("boneshard",   4),
    },
    TAB_WAR, 7,
    "MonkeyKidsTracker2000 - As good monkey parents, don't leave anything to chance.",
    "Monkey Compass"
)
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MONKEYCOMPASS = "Shows me the way to Monkey Island!"

-- 8) Amgulet (only for Gulet)
local amg = AddGuybrushRecipe(
    "amgulet",
    {
        Ingredient("houndstooth", 5),
        Ingredient("greengem",    1),
        Ingredient("grog",        5),
    },
    TAB_WAR, 8,
    "Drowned in grog, untouched by fear.",
    "Amgulet"
)
amg.builder_tag = "gulet_builder"
amg.nounlock    = true
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AMGULET = "A mysterious amulet."

-- 9) Blue Leather Planks
local armor_pirate = AddGuybrushRecipe(
    "armor_pirate",
    {
        Ingredient("armorwood", 1),
        Ingredient("rope",      1),
        Ingredient("papyrus",   8),
    },
    TAB_WAR, 9,
    "Robust fabric-reinforced planks for the pirate look.",
    "Blue Leather Planks"
)
STRINGS.CHARACTERS.GENERIC.DESCRIBE.ARMOR_PIRATE = "An armor made of leather and pirate pride."

-- 10) Guybrush Hat
local guyhat = AddGuybrushRecipe(
    "guyhat",
    {
        Ingredient("guycoin",         100),
        Ingredient("monkey_mediumhat", 1),
    },
    TAB_WAR, 10,
    "A stylish hat for the greatest pirate of the Caribbean!",
    "Blue Tricorn"
)
STRINGS.CHARACTERS.GENERIC.DESCRIBE.GUYHAT = "A hat that looks good on any pirate."

-- 11) Guybrush Walking Light

local walkinglight = AddGuybrushRecipe(
    "walkinglight",
    {
        Ingredient("driftwood_log", 5),
        Ingredient("cane", 1),
        Ingredient("deerclops_eyeball", 1),
        Ingredient("guycoin", 80)
    },
    TAB_WAR, 
    11,
    "Take a walk with Murray!",
    "Murray"
)

STRINGS.CHARACTERS.GENERIC.DESCRIBE.WALKINGLIGHT = "A practical companion for dark nights."

-- 12) Guybrush Boat Bumper
local bumperkit = AddGuybrushRecipe(
    "boat_bumper_guybrush_kit",
    {
        Ingredient("rope",  1),
        Ingredient("gummi", 6),
        Ingredient("guycoin", 10),
    },
    RECIPETABS.SEAFARING, 12,
    "Protects your boat Guybrush-style!",
    "Guybrush Bumper"
)

-- 13) Leather Repair Kit
local leather_repairkit = AddGuybrushRecipe(
    "leather_repairkit",
    {   
        Ingredient("papyrus", 8), 
        Ingredient("silk", 4)
    },
    TAB_WAR, 12,
    "Mends any hole, no matter how big.",
    "Leather Repair Kit"
)

STRINGS.CHARACTERS.GENERIC.DESCRIBE.LEATHER_REPAIRKIT = "Makes my armor last longer!"

-- 14) Guybrush Chest
AddGuybrushRecipe(
    "guychest",
    {
        Ingredient("driftwood_log",  10),
        Ingredient("gears", 1),
        Ingredient("guycoin", 40)
    },
    TAB_WAR, 
    13,
    "Protected against thieving monkeys.",
    "Guychest"
).placer = "guychest_placer"

STRINGS.CHARACTERS.GENERIC.DESCRIBE.GUYCHEST = "Looks like i need to insert a coin..."
--------------------------------------------------------------------------
-- ACTUAL BUMPER NOT THE KIT
--------------------------------------------------------------------------
STRINGS.NAMES.BOAT_BUMPER_GUYBRUSH  = "Carnival Bumper"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.BOAT_BUMPER_GUYBRUSH = "Left over from the Carnival of the Damned!"

AddPrefabPostInit("boat_bumper_guybrush", function(inst)
    if not _G.TheWorld.ismastersim then return end
    inst.sg.mem.bumpertype = "guybrush"
end)

--------------------------------------------------------------------------
-- (6) Crock-Pot Recipe "Grogballs"
--------------------------------------------------------------------------

-- Mark grog as an ingredient
STRINGS.NAMES.GROG                       = "Grog"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.GROG = "Arrr … burns like hell, tastes like freedom!"

AddIngredientValues({ "grog" }, { inedible = 1 }, true)

if cooking.ingredients.grog then
    local ing = cooking.ingredients.grog
    ing.atlas = "images/inventoryimages/grog.xml"
    ing.image = "grog.tex"
    ing.name  = "Grog"
end
RegisterInventoryItemAtlas("images/inventoryimages/grog.xml", "grog.tex")

-- Meatballs as a Crock-Pot ingredient
AddIngredientValues({ "meatballs" }, { meat = 1 }, true)

AddPrefabPostInit("meatballs", function(inst)
    if not inst:HasTag("cookable") then
        inst:AddTag("cookable")
    end
end)

-- Grogballs recipe
local function grogballs_test(_, names)
    return (names.meatballs or 0) >= 1 and (names.grog or 0) >= 1
end

local grogballs_recipe = {
    name         = "grogballs",
    test         = grogballs_test,
    priority     = 70,
    weight       = 1,
    foodtype     = FOODTYPE.MEAT,
    health       = 3,
    hunger       = 55,
    sanity       = 5,
    perishtime   = TUNING.PERISH_SLOW,
    cooktime     = 3,
    potlevel     = "high",
    floater      = { "med", nil, 0.8 },

    overridebuild   = "grogballs",
    overridesymbols = { ["swap_food"] = "swap_grogballs" },

    no_cookbook       = false,
    cookbook_category = "cookpot",
    card_def = {
        name  = "Grogballs",
        atlas = "images/cookbook_grogballs.xml",
        image = "cookbook_grogballs.tex",
        anim  = "idle",
        bank  = "grogballs",
        build = "grogballs",
    },
}

for _, pot in ipairs({ "cookpot", "portablecookpot", "archive_cookpot", "portablespicer" }) do
    AddCookerRecipe(pot, grogballs_recipe, true)
end

RegisterInventoryItemAtlas("images/inventoryimages/grogballs.xml", "grogballs.tex")
RegisterInventoryItemAtlas("images/inventoryimages/guycoin.xml", "guycoin.tex")

STRINGS.NAMES.GROGBALLS                       = "Grogballs"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.GROGBALLS = "Do I really have to eat this?"

STRINGS.NAMES.GROGBALLS_RECIPECARD = "Recipe: Grogballs"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.GROGBALLS_RECIPECARD =
    "Grandmas Grogballs – 1× Meatballs, 1× Grog, 2× Filler"

RegisterInventoryItemAtlas("images/inventoryimages/grogballs_recipecard.xml", "grogballs_recipecard.tex")

--------------------------------------------------------------------------
-- SECRET
--------------------------------------------------------------------------  

STRINGS.NAMES.SECRET = "Secret of Monkey Island"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.SECRET = "IS THIS THE SECRET?!"

--------------------------------------------------------------------------
-- ARMOR REPAIRS Action for leather_repairkit component (Papyrus as repair item)

AddAction("ARMORREPAIRS", "Repair", function(act)
    if act.target
        and act.target:HasTag("armorrepairable")
        and act.target:HasTag("leather")
        and act.target.components.armor
        and act.invobject
        and act.invobject.prefab == "leather_repairkit"
        and act.invobject.components.armorrepairing then
        return act.invobject.components.armorrepairing:DoReparation(act.target, act.doer)
    end
end)

AddStategraphActionHandler("wilson", ActionHandler(_G.ACTIONS.ARMORREPAIRS, "dolongaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(_G.ACTIONS.ARMORREPAIRS, "dolongaction"))

print("[DEBUG] Registering USEITEM action for armorrepairing (should appear on EVERY world load, client+server)")
AddComponentAction("USEITEM", "armorrepairing", function(inst, doer, target, actions)
    if target:HasTag("armorrepairable")
      and not (doer.replica.rider ~= nil and doer.replica.rider:IsRiding() and not (target.replica.inventoryitem ~= nil and target.replica.inventoryitem:IsGrandOwner(doer))) then
        table.insert(actions, _G.ACTIONS.ARMORREPAIRS)
    end
end)

-- List of all repairable armors (DST + armor_pirate)
local Armors = {
    "armor_pirate",
}
for _, v in ipairs(Armors) do
    AddPrefabPostInit(v, function(inst)
        if not inst:HasTag("armorrepairable") then
            inst:AddTag("armorrepairable")
        end
    end)
end

--------------------------------------------------------------------------
-- (6b) Guybrush Bumper Repair Action
--------------------------------------------------------------------------

local REPAIR_GUYBRUSH_BUMPER = Action({
    priority = 10,
    rmb = true,
    mount_valid = true,
    canforce = true,
    strfn = function(act)
        return "REPAIR"
    end,
})
REPAIR_GUYBRUSH_BUMPER.id = "REPAIR_GUYBRUSH_BUMPER"
REPAIR_GUYBRUSH_BUMPER.str = STRINGS.ACTIONS.REPAIR or "Repair"
REPAIR_GUYBRUSH_BUMPER.fn = function(act)
    if act.target and act.target.components.guybrush_bumperrepair then
        return act.target.components.guybrush_bumperrepair:Repair(act.target, act.doer)
    end
    return false
end

AddAction(REPAIR_GUYBRUSH_BUMPER)

AddComponentAction("USEITEM", "inventoryitem", function(inst, doer, target, actions, right)
    if right and target ~= nil and target:HasTag("boat_bumper_guybrush") and inst:HasTag("gummi") then
        -- No additional health check, as the repairable component handles that
        table.insert(actions, ACTIONS.REPAIR)
    end
end)

--------------------------------------------------------------------------
-- (3) Character Settings & Strings
--------------------------------------------------------------------------

STRINGS.CHARACTER_TITLES.guybrush      = "The Mighty Pirate"
STRINGS.CHARACTER_NAMES.guybrush       = "Guybrush"
STRINGS.CHARACTER_DESCRIPTIONS.guybrush= "*Searching for the Secret of Monkey Island\n*His sword is cursed\n*Addicted to grog"
STRINGS.CHARACTER_QUOTES.guybrush      = "\"Behind you.... a three-headed monkey!...\""
STRINGS.CHARACTERS.GUYBRUSH            = require "speech_guybrush"
STRINGS.NAMES.GUYBRUSH                 = "Guybrush"

AddModCharacter("guybrush", "MALE")

--------------------------------------------------------------------------
-- (4) Drunkenness Widget
--------------------------------------------------------------------------

local DrunkennessMeter = require("widgets/drunkenness_meter")
print("✅ AddDrunkennessMeter was registered!")

local function AddDrunkennessMeter(self)
    print("📌 AddDrunkennessMeter was called!") -- Debug

    if self.owner and self.owner:HasTag("guybrush") then
        print("✅ Owner is Guybrush!") -- Debug

        if self.status then
            self.drunkenness_meter = self.status:AddChild(DrunkennessMeter(self.owner))
            print("✅ DrunkennessMeter was created!") -- Debug

            self.drunkenness_meter:SetPosition(-80, -40, 0)

            print("📌 Widget Position:", self.drunkenness_meter:GetPosition())
            print("📌 Widget Sichtbarkeit:", self.drunkenness_meter:IsVisible() and "Ja" or "Nein")
        else
            print("❌ ERROR: self.status does not exist! DrunkennessMeter could not be added.")
        end
    else
        print("❌ ERROR: Owner is not Guybrush!")
    end
end

local function ReAddDrunkennessMeter(inst)
    if inst and inst == ThePlayer then
        local controls = ThePlayer.HUD and ThePlayer.HUD.controls
        if controls and controls.status then
            print("📌 Character transformed! DrunkennessMeter will be re-added.")

            if controls.drunkenness_meter then
                controls.drunkenness_meter:Kill()
                controls.drunkenness_meter = nil
            end

            controls.drunkenness_meter = controls.status:AddChild(DrunkennessMeter(inst))
            controls.drunkenness_meter:SetPosition(-80, -40, 0)
        else
            print("❌ ERROR: HUD could not be found!")
        end
    end
end

AddPlayerPostInit(function(inst)
    inst:ListenForEvent("transform_gulet", function(inst)
        inst:ChangeToGulet()
        ReAddDrunkennessMeter(inst)
    end)
    inst:ListenForEvent("transform_guybrush", function(inst)
        inst:ChangeToGuybrush()
        ReAddDrunkennessMeter(inst)
    end)
end)

AddClassPostConstruct("widgets/controls", AddDrunkennessMeter)


local function MakeGuletFoodOverride(prefabname, values)
    AddPrefabPostInit(prefabname, function(inst)
        if not inst:HasTag("guletfood") then
            inst:AddTag("guletfood")
        end
        if inst.components.edible then
            local old_oneaten = inst.components.edible.oneaten
            inst.components.edible.oneaten = function(food, eater)
                if eater and eater.prefab == "guybrush" and eater.isGulet then
                    local edible = food.components and food.components.edible
                    if edible then
                        if values.health then
                            eater.components.health:DoDelta(-edible.healthvalue)
                            eater.components.health:DoDelta(values.health)
                        end
                        if values.hunger then
                            eater.components.hunger:DoDelta(-edible.hungervalue)
                            eater.components.hunger:DoDelta(values.hunger)
                        end
                        if values.sanity then
                            eater.components.sanity:DoDelta(-edible.sanityvalue)
                            eater.components.sanity:DoDelta(values.sanity)
                        end
                    end
                    -- No negative effects, no monster penalty, etc.
                    if old_oneaten then old_oneaten(food, eater) end
                else
                    if old_oneaten then old_oneaten(food, eater) end
                end
            end
        end
    end)
end

MakeGuletFoodOverride("monstermeat",   { health = 0, hunger = 15, sanity = 0 })
MakeGuletFoodOverride("monsterlasagna", { health = 0, hunger = 55, sanity = 0 })




local utils = require("utils")

local ImproveTree = require("trees")

-- Add resources from trees
local trees = {"palmconetree", "palmconetree_short", "palmconetree_normal", "palmconetree_tall"}
for i,v in pairs(trees) do
    AddPrefabPostInit(v, utils.Bind(utils.RunFunctionServerOnly, ImproveTree))
end

RegisterInventoryItemAtlas("images/inventoryimages/gummi.xml", "gummi.tex")
STRINGS.NAMES.GUMMI = "Rubber"
STRINGS.RECIPE_DESC.GUMMI = "A flexible, buoyant material."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.GUMMI = "Hopefully it doesn't squeak too loudly."

----

local TheSim = GLOBAL.TheSim
local Vector3 = GLOBAL.Vector3

--------------------------------------------------------------------------

-- Source modified from containers.lua

local containers = require "containers"

local params = {}

local containers_widgetsetup_base = containers.widgetsetup
function containers.widgetsetup(container, prefab, data, ...)
    local t = params[prefab or container.inst.prefab]
    if t ~= nil then
        for k, v in pairs(t) do
            container[k] = v
        end
        container:SetNumSlots(container.widget.slotpos ~= nil and #container.widget.slotpos or 0)
    else
        containers_widgetsetup_base(container, prefab, data, ...)
    end
end

local function makeChest()
    local container =
    {
        widget =
        {
            slotpos = {},
            animbank = "ui_largechest_5x5",
            animbuild = "ui_largechest_5x5",
            pos = GLOBAL.Vector3(0, 200, 0),
            side_align_tip = 160,
        },
        type = "chest",
    }

    for y = 3, -1, -1 do
        for x = -1, 3 do
            table.insert(container.widget.slotpos, GLOBAL.Vector3(80 * x - 80 * 2 + 80, 80 * y - 80 * 2 + 80, 0))
        end
    end

    return container
end

params.guychest = makeChest()

for k, v in pairs(params) do
    containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, v.widget.slotpos ~= nil and #v.widget.slotpos or 0)
end

--------------------------------------------------------------------------
-- (7) Monkey Queen – Patch for Secret of Monkey Island
--------------------------------------------------------------------------

AddPrefabPostInit("monkeyqueen", function(inst)
    if not _G.TheWorld.ismastersim then
        return
    end

    if inst and inst.components.trader then
        local old_accepttest = inst.components.trader.test
        local old_onaccept   = inst.components.trader.onaccept

        if not inst._playersGivenSecret then
            inst._playersGivenSecret = {}
        end

        inst.OnSave = function(inst, data)
            data.playersGivenSecret = inst._playersGivenSecret
        end

        inst.OnLoad = function(inst, data)
            if data and data.playersGivenSecret then
                inst._playersGivenSecret = data.playersGivenSecret
            end
        end

        local function CustomOnGetItem(inst, giver, item)
            inst._playersGivenSecret[giver.userid] = true

            local secret = _G.SpawnPrefab("secret")
            if secret ~= nil then
                secret.Transform:SetPosition(inst.Transform:GetWorldPosition())
            end

            local rpc = GetClientModRPC("secret", "SayCurseMessage")
            if giver and giver.userid and giver:IsValid() then
                if rpc then
                    SendModRPCToClient(
                        rpc,
                        giver.userid,
                        ">>> SECRET OF MONKEY ISLAND OBTAINED! <<<",
                        3,
                        230/255,
                        228/255,
                        112/255,
                        1
                    )
                end
            else
                print("[Fast Work][RPC] WARN: RPC call to invalid player suppressed (giver)")
            end

            if inst.SoundEmitter then
                inst.SoundEmitter:PlaySound("monkeyisland/monkeyqueen/speak")
            end
        end

        inst.components.trader:SetAcceptTest(function(inst, item, giver)
            if item.prefab == "guycoin" then
                if inst._playersGivenSecret[giver.userid] then
                    return false
                end
                return true
            end
            if old_accepttest then
                return old_accepttest(inst, item, giver)
            end
            return false
        end)

        inst.components.trader.onaccept = function(inst, giver, item)
            if item.prefab == "guycoin" then
                CustomOnGetItem(inst, giver, item)
            else
                if old_onaccept then
                    old_onaccept(inst, giver, item)
                end
            end
        end
    end
end)

--------------------------------------------------------------------------
-- (8) Monkey Curse completely neutralized
--------------------------------------------------------------------------

-- 5·1  Wonkey threshold shifted to infinity
TUNING.MONKEY_TOKEN_COUNTS.LEVEL_4 = math.huge

-- 5·2  Skin changes to Guybrush/Gulet disabled
local function DisableMonkeySkin(inst)
    if inst.prefab ~= "guybrush" then return end

    local sk = inst.components.skinner
    if sk and not sk._gb_monkey_patched then
        function sk:SetMonkeyCurse(...) end
        function sk:ClearMonkeyCurse(...) end
        sk._gb_monkey_patched = true
    end

    inst:RemoveTag("MONKEY_CURSE_1")
    inst:RemoveTag("MONKEY_CURSE_2")
    inst:RemoveTag("MONKEY_CURSE_3")
end

AddPlayerPostInit(function(inst)
    inst:DoTaskInTime(0, DisableMonkeySkin)
end)

-- 5·3  Knock-Up event "monkeycursehit" neutralized
AddPlayerPostInit(function(inst)
    inst:ListenForEvent("monkeycursehit", function(self, data)
        if self.prefab == "guybrush"
           or self.AnimState:GetBuild() == "gulet"
        then
            return true
        end
    end)
end)

--------------------------------------------------------------------------
-- (9) Tentacle Immunity & Sanity Aura Patch for Gulet
--------------------------------------------------------------------------
local function IgnoreSwampImmunityTarget(tentacle)
    -- Targeting: Ignore Gulet
    local combat = tentacle.components and tentacle.components.combat
    if combat and combat.targetfn then
        local oldRetargetFn = combat.targetfn
        combat:SetRetargetFunction(3, function(tentacle_inst)
            local target = oldRetargetFn(tentacle_inst)
            if target ~= nil and target:HasTag("swamp_immunity") then
                return nil
            end
            return target
        end)
    end
    -- Sanity Aura: No negative aura for Gulet
    if tentacle.components and tentacle.components.sanityaura then
        local old_aurafn = tentacle.components.sanityaura.aurafn
        tentacle.components.sanityaura.aurafn = function(inst, observer)
            if observer and observer.isGulet then
                return 0 -- No negative sanity aura for Gulet
            end
            if old_aurafn then
                return old_aurafn(inst, observer)
            end
            return tentacle.components.sanityaura.aura or 0
        end
    end
end
AddPrefabPostInit("tentacle", IgnoreSwampImmunityTarget)
AddPrefabPostInit("tentacle_pillar", IgnoreSwampImmunityTarget)
AddPrefabPostInit("tentacle_pillar_arm", IgnoreSwampImmunityTarget)

--------------------------------------------------------------------------
-- (10) Registration of RPC handler
--------------------------------------------------------------------------

local function SetupRPC(inst)
    if inst.components.talker then
        AddClientModRPCHandler("secret", "SayCurseMessage", function(message, duration, a, b, c, d)
            local color = { a, b, c, d }
            inst.components.talker:Say(message, duration, nil, nil, nil, color)
        end)
        print("RPC handler was registered in PlayerPostInit.")
    else
        print("talker component missing in PlayerPostInit.")
    end
end

AddPlayerPostInit(SetupRPC)

--------------------------------------------------------------------------
-- Ab hier Code, der das Anzeigen und die Ziellokalisierung steuert
-- (vereinfacht auf den Monkey Compass und die Monkey Queen)
--------------------------------------------------------------------------
local json = require "json"
local specialsCompassesPrefabs = { "monkeycompass" }
local prefabsToBeListenSpawn = { "monkeyqueen" }

local cache = {
    entities = {},       -- Gespeicherte Entitäten (z.B. monkeyqueen)
    entitiesPos = {},    -- Nächstgelegene Position bestimmter Prefabs
    huds = {},           -- Compass-HUD-Instanzen
    playerPos = nil,
    cameraRotation = nil,
}

local function NormalizeHeading(heading)
    while heading < -180 do heading = heading + 360 end
    while heading > 180 do heading = heading -360 end
    return heading
end

local function IsEquiped(prefab_name)
    local player = GLOBAL.ThePlayer
    if player and player.replica.inventory then
        local item = player.replica.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS)
        return (item and item.prefab == prefab_name) or false
    end
    return false
end

local function HeadingSpinner(self)
    local heading = (self.displayheading or 0) + 20
    return { runSuper = false, heading = heading }
end

local function GetHeadingToPosition(pos)
    local player = GLOBAL.ThePlayer
    if not player or not pos then
        return 0
    end
    local px, py, pz = player.Transform:GetWorldPosition()
    local dx, dz = pos.x - px, pos.z - pz
    return math.atan2(dz, -dx) / math.pi * 180
end

local function AdjustHeadingByCamera(heading)
    local camera = GLOBAL.TheCamera
    if camera then
        local rot = camera:GetHeadingTarget()
        return NormalizeHeading(heading + rot)
    end
    return heading
end

local function GetEntityPos(prefab_name)
    return cache.entitiesPos[prefab_name]
end

-- Nadelrichtung für unseren Monkey Compass (Ziel: Monkey Queen)
local function GetMonkeyCompassHeading(self, dt)
    local targetPos = GetEntityPos("monkeyqueen")
    if targetPos == nil then
        return HeadingSpinner(self)
    end
    local heading = GetHeadingToPosition(targetPos)
    heading = AdjustHeadingByCamera(heading)
    return { runSuper = false, heading = heading }
end

--------------------------------------------------------------------------
-- Ergänzungen am Compass-HUD:
--------------------------------------------------------------------------
AddClassPostConstruct("widgets/hudcompass", function(self)
    local superGetCompassHeading = self.GetCompassHeading
    local superShow = self.Show
    local superOpenCompass = self.OpenCompass

    self.equiped_compass = "compass"
    cache.huds[self] = true

    function self:GetCompassHeading(dt)
        if IsEquiped("monkeycompass") then
            local response = GetMonkeyCompassHeading(self, dt)
            if response.runSuper then
                return superGetCompassHeading(self, dt)
            else
                return response.heading
            end
        end
        -- Falls kein Monkey Compass angelegt ist, normaler Kompass-Code
        return superGetCompassHeading(self, dt)
    end

    function self:UpdateBgAnim(force)
        -- Aktiviere Monkeycompass-Grafik
        if (force or self.isopen) and self.equiped_compass ~= "monkeycompass" and IsEquiped("monkeycompass") then
            if self.isattached then
                self.bg:GetAnimState():SetBank("monkeycompass_hud")
                self.bg:GetAnimState():SetBuild("monkeycompass_hud")
            else
                self.bg:GetAnimState():SetBank("monkeycompass_bg")
                self.bg:GetAnimState():SetBuild("monkeycompass_bg")
            end
            self.equiped_compass = "monkeycompass"

        -- Fallback auf normalen Kompass
        elseif (force or self.isopen) and not IsEquiped("monkeycompass") then
            self.bg:GetAnimState():SetBank("compass_bg")
            self.bg:GetAnimState():SetBuild("compass_bg")
            self.equiped_compass = "compass"
        end
    end

    function self:UpdateAllBgAnim(force)
        for hud, _ in pairs(cache.huds) do
            hud:UpdateBgAnim(force)
        end
    end

    function self:Show()
        self:UpdateAllBgAnim(true)
        superShow(self)
    end

    function self:OpenCompass()
        self:UpdateAllBgAnim(true)
        superOpenCompass(self)
    end
end)

--------------------------------------------------------------------------
-- Serverseitige Logik zum Aufspüren der Monkey Queen
--------------------------------------------------------------------------
local function CountCachedEntities()
    local count = 0
    for _, entities in pairs(cache.entities) do
        count = count + #entities
    end
    return count
end

local function LoadEntity(ent)
    if ent.prefab and ent.Transform and ent:IsValid() and table.contains(prefabsToBeListenSpawn, ent.prefab) then
        if not cache.entities[ent.prefab] then
            cache.entities[ent.prefab] = {}
        end
        table.insert(cache.entities[ent.prefab], ent)
        print("[MonkeyCompass] Geladene Entität:", ent.prefab, ent.GUID,
              "Anzahl bisher:", CountCachedEntities())
    end
end

local function ToVector3(x, y, z)
    return GLOBAL.Vector3(x, y, z)
end

local function SyncEntitiesPosToAllPlayer()
    for _, player in ipairs(GLOBAL.AllPlayers) do
        local entitiesPos = {}
        local px, py, pz = player.Transform:GetWorldPosition()

        for prefab, entities in pairs(cache.entities) do
            local closestPos = nil
            local closestDist = math.huge

            for _, v in ipairs(entities) do
                if v:IsValid() then
                    local entX, entY, entZ = v.Transform:GetWorldPosition()
                    local distSq = (entX - px)*(entX - px) + (entZ - pz)*(entZ - pz)
                    if distSq < closestDist then
                        closestDist = distSq
                        closestPos = ToVector3(entX, entY, entZ)
                    end
                end
            end
            if closestPos then
                entitiesPos[prefab] = closestPos
            end
        end

        local serializedData = json.encode(entitiesPos)
        SendModRPCToClient(GetClientModRPC("specialCompasses", "entities_pos_sync"), player, serializedData)
    end
end

AddPrefabPostInitAny(function(inst)
    if _G.TheWorld and _G.TheWorld.ismastersim then
        LoadEntity(inst)
    end
end)

AddSimPostInit(function()
    if _G.TheWorld and _G.TheWorld.ismastersim then
        print("[MonkeyCompass] Periodischer Sync der Monkey Queen-Position alle 15s.")
        _G.TheWorld:DoPeriodicTask(15, SyncEntitiesPosToAllPlayer)
    end
end)

AddModRPCHandler("specialCompasses", "compass_equipped", function(player)
    -- Schicke sofort beim Ausrüsten alle relevanten Positionen zurück
    local singleList = {}
    local px, py, pz = player.Transform:GetWorldPosition()

    for prefab, entities in pairs(cache.entities) do
        local closestPos = nil
        local closestDist = math.huge

        for _, v in ipairs(entities) do
            if v:IsValid() then
                local entX, entY, entZ = v.Transform:GetWorldPosition()
                local distSq = (entX - px)*(entX - px) + (entZ - pz)*(entZ - pz)
                if distSq < closestDist then
                    closestDist = distSq
                    closestPos = ToVector3(entX, entY, entZ)
                end
            end

        end

        if closestPos then
            singleList[prefab] = closestPos
        end
    end

    local serializedData = json.encode(singleList)
    SendModRPCToClient(GetClientModRPC("specialCompasses", "entities_pos_sync"), player, serializedData)
end)

--------------------------------------------------------------------------
-- Clientseitiger Empfang der Positionen
--------------------------------------------------------------------------
AddClientModRPCHandler("specialCompasses", "entities_pos_sync", function(serializedData)
    if serializedData then
        cache.entitiesPos = json.decode(serializedData)
    end
end)

local function NotifyServerCompassEquipped()
    SendModRPCToServer(GetModRPC("specialCompasses", "compass_equipped"))
end

local function OnEquip(inst, data)
    if data and data.item and data.item.prefab == "monkeycompass" then
        print("[MonkeyCompass] Ausgerüstet:", data.item.prefab)
        NotifyServerCompassEquipped()
    end
end

AddPlayerPostInit(function(inst)
    if _G.TheWorld.ismastersim then
        inst:ListenForEvent("equipped", OnEquip)
    end
end)

--===================================================================
--  ENDE modmain.lua
--===================================================================






