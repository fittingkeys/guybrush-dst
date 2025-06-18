--------------------------------------------------------------------------------
-- Zeitkonstanten (in Sekunden)
--------------------------------------------------------------------------------
local PERIODIC_INTERVAL = 120      -- Debug: 6s, normal: 60s
local SOUND_KILL_DELAY = 3        -- Sound wird nach 3s gestoppt
local TOKEN_INTERVAL = 5          -- Alle 5 Perioden wird der Token-Spruch genutzt

--------------------------------------------------------------------------------
local assets =
{
    Asset("ANIM", "anim/secret.zip"),
    Asset("IMAGE", "images/inventoryimages/secret.tex"),
    Asset("ATLAS", "images/inventoryimages/secret.xml"),
}

local sayings = {
    "I am the curse of Monkey Island – and you are wearing it!",
    "Your outfit for dark dominion!",   
    "The ghosts of the island flee from my scent!",
    "My smell sweeps across the Caribbean like a storm!",
    "Why do I only come in size M?",
    "Do you feel the curse? Muahahahaha!",
    "I am the stuff of legends!",
    "No one escapes my curse!",
    "An alliance of devil and fabric!",
    "Even LeChuck trembles before my madness!",
    "The curses of the Caribbean pulse in my fibers!",
    "Made in China - The wages on Mêlée were too expensive.",
    "Wally made me an offer - I'll be part of his next collection!"
}

local TOKEN_SAYING = "I have sealed my madness into a cursed relic... now hidden in your inventory!"

--------------------------------------------------------------------------------
-- HILFSFUNKTIONEN (Gegenstände droppen)
--------------------------------------------------------------------------------

local function DropItem(owner, item)
    if item then
        owner.components.inventory:DropItem(item, true, true)
    end
end

local function DropItemFromOverflow(overflow, slot)
    local dropped_item = overflow:RemoveItemBySlot(slot)
    if dropped_item then
        dropped_item.Transform:SetPosition(overflow.inst.Transform:GetWorldPosition())
    end
end

local function DropAllRocks(owner)
    local removedAny = false
    local inv = owner.components.inventory

    -- Hauptinventar nach rocks durchsuchen
    for slot, item in pairs(inv.itemslots) do
        if item and item.prefab == "rocks" then
            DropItem(owner, item)
            removedAny = true
        end
    end

    -- Falls Rucksack oder Overflow vorhanden ist, auch dort durchsuchen
    local overflow = inv:GetOverflowContainer()
    if overflow then
        for slot = 1, overflow:GetNumSlots() do
            local item = overflow:GetItemInSlot(slot)
            if item and item.prefab == "rocks" then
                DropItemFromOverflow(overflow, slot)
                removedAny = true
            end
        end
    end
    
    return removedAny
end

local function DropFirstNonTokenItem(owner)
    local inv = owner.components.inventory

    -- Erst im Hauptinventar nach dem ersten Nicht-Token-Item suchen
    for slot, item in pairs(inv.itemslots) do
        if item and item.prefab ~= "cursed_monkey_token" then
            DropItem(owner, item)
            return
        end
    end

    -- Dann ggf. im Rucksack (Overflow)
    local overflow = inv:GetOverflowContainer()
    if overflow then
        for slot = 1, overflow:GetNumSlots() do
            local item = overflow:GetItemInSlot(slot)
            if item and item.prefab ~= "cursed_monkey_token" then
                DropItemFromOverflow(overflow, slot)
                return
            end
        end
    end
end

--------------------------------------------------------------------------------
-- HILFSFUNKTION: Richtigen Spieler ermitteln (auch bei Rucksack)
--------------------------------------------------------------------------------
local function GetActualPlayerOwner(inst)
    -- Gibt nil zurück, wenn kein Spieler als 'richtiger' Träger ermittelt werden kann.
    if not inst.components.inventoryitem then
        return nil
    end

    -- Der "ganz oben" stehende Owner (Spieler oder etwas anderes)
    local grandOwner = inst.components.inventoryitem:GetGrandOwner()
    
    -- Prüfen, ob es sich um einen Spieler handelt
    if grandOwner and grandOwner:HasTag("player") then
        -- Wer ist der direkte Owner? Das kann der Spieler selbst sein oder ein Container (z.B. Backpack)
        local directOwner = inst.components.inventoryitem.owner

        -- Liegt das Secret direkt im Spieler-Inventar?
        if directOwner == grandOwner then
            return grandOwner  -- Spieler gefunden
        end

        -- Oder ist directOwner ein Rucksack, den der Spieler tatsächlich trägt?
        if directOwner and directOwner:HasTag("backpack") then
            -- Checken, ob der Rucksack im Body-Slot ist
            local equipped = grandOwner.components.inventory:GetEquippedItem("body")
            if equipped == directOwner then
                return grandOwner  -- Rucksack wird getragen → Spieler als Owner
            end
        end
    end

    -- Kein passender Spieler-Owner
    return nil
end

--------------------------------------------------------------------------------
-- TOKEN ERZEUGEN
--------------------------------------------------------------------------------
-----------------------------------------------------------------
-- Hilfsfunktion: Prüfen, ob 'inventory' den 'item' noch stapeln
-- oder in einem freien Slot unterbringen kann
-----------------------------------------------------------------
local function InventoryCanAdd(inventory, item)
    -- 1) Prüfen, ob wir einen Teil-Stapel im Hauptinventar finden
    for slot, existing_item in pairs(inventory.itemslots) do
        if existing_item.prefab == item.prefab and
           existing_item.components.stackable and
           not existing_item.components.stackable:IsFull() then
            return true
        end
    end

    -- 2) Falls ein Rucksack o.Ä. vorhanden ist, dort ebenfalls prüfen
    local overflow = inventory:GetOverflowContainer()
    if overflow then
        for slot = 1, overflow:GetNumSlots() do
            local existing_item = overflow:GetItemInSlot(slot)
            if existing_item 
               and existing_item.prefab == item.prefab
               and existing_item.components.stackable
               and not existing_item.components.stackable:IsFull() then
                return true
            end
        end
    end

    -- 3) Falls kein teilbarer Stapel da ist, prüfen wir auf freie Slots
    if not inventory:IsFull() then
        return true
    end

    if overflow and not overflow:IsFull() then
        return true
    end

    -- Nirgendwo Platz
    return false
end

-----------------------------------------------------------------
-- Dein SpawnCursedToken-Code, angepasst ohne CanTakeItemInInventory
-----------------------------------------------------------------
local function SpawnCursedToken(owner)
    if owner and owner.components.inventory then
        local token = SpawnPrefab("cursed_monkey_token")
        if token == nil then
            return
        end

        -- Prüfen, ob wir das Item ins Inventar aufnehmen können (inkl. Stapel)
        if not InventoryCanAdd(owner.components.inventory, token) then
            -- Falls kein Stapel und kein Platz => Steine droppen
            local foundRocks = DropAllRocks(owner)
            if not foundRocks then
                DropFirstNonTokenItem(owner)
            end
        end

        -- Jetzt nochmal prüfen, ob jetzt ein Platz frei ist:
        if InventoryCanAdd(owner.components.inventory, token) then
            owner.components.inventory:GiveItem(token)
        else
            -- Immer noch voll -> Token droppen
            owner.components.inventory:DropItem(token, true, true)
        end
    end
end


--------------------------------------------------------------------------------
-- PERIODISCHE AUFGABE: Sprechen und Token spawnen
--------------------------------------------------------------------------------
local function PeriodicTask(inst)
    inst.talk_minutes = (inst.talk_minutes or 0) + 1

    -- Wir bestimmen den "richtigen" Spieler-Owner, nur wenn er das Item wirklich trägt
    local playerOwner = GetActualPlayerOwner(inst)

    if inst.talk_minutes % TOKEN_INTERVAL == 0 then
        if playerOwner and playerOwner.components.inventory then
            SpawnCursedToken(playerOwner)

            -- Spruch für den Token
            local rpc = GetClientModRPC("secret", "SayCurseMessage")
local is_connected = false
if playerOwner and playerOwner.userid and playerOwner:IsValid() then
    if playerOwner.Network and type(playerOwner.Network.IsConnected) == "function" then
        is_connected = playerOwner.Network:IsConnected()
    else
        -- Im MasterSim oder bei fehlender Methode reicht die Prüfung auf IsValid und userid
        is_connected = true
    end
end
if is_connected then
    if rpc then
        SendModRPCToClient(rpc, playerOwner.userid, TOKEN_SAYING, 3, 140/255, 15/255, 100/255, 1)
    end
else
    print("[Secret][RPC] WARN: RPC Call an ungültigen oder nicht verbundenen Spieler unterdrückt (TOKEN_SAYING)")
end
            inst.SoundEmitter:PlaySound("dontstarve/characters/woodie/lucytalk_LP", "talk")
        end
    else
        -- Zufälligen Fluch-Spruch nur ausgeben, wenn ein Player-Owner vorhanden ist
        if playerOwner and playerOwner.userid then
            local text = sayings[math.random(#sayings)]
            local rpc = GetClientModRPC("secret", "SayCurseMessage")
local is_connected = false
if playerOwner and playerOwner.userid and playerOwner:IsValid() then
    if playerOwner.Network and type(playerOwner.Network.IsConnected) == "function" then
        is_connected = playerOwner.Network:IsConnected()
    else
        is_connected = true
    end
end
if is_connected then
    if rpc then
        SendModRPCToClient(rpc, playerOwner.userid, text, 3, 140/255, 15/255, 100/255, 1)
    end
else
    print("[Secret][RPC] WARN: RPC Call an ungültigen oder nicht verbundenen Spieler unterdrückt (text)")
end
            inst.SoundEmitter:PlaySound("dontstarve/characters/woodie/lucytalk_LP", "talk")
        end
    end

    inst:DoTaskInTime(SOUND_KILL_DELAY, function()
        inst.SoundEmitter:KillSound("talk")
    end)
end

--------------------------------------------------------------------------------
-- PERIODISCHE AUFGABE Start und Ende
--------------------------------------------------------------------------------
local function StartPeriodicTask(inst)
    if not inst.periodic_task then
        inst.talk_minutes = 0
        inst.periodic_task = inst:DoPeriodicTask(PERIODIC_INTERVAL, PeriodicTask)
    end
end

local function StopPeriodicTask(inst)
    if inst.periodic_task then
        inst.periodic_task:Cancel()
        inst.periodic_task = nil
    end
end

--------------------------------------------------------------------------------
-- INVENTAR-EVENTS
--------------------------------------------------------------------------------
local function OnPutInInventory(inst)
    local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner
    if owner and owner:HasTag("player") and not owner:HasTag("monkey") then
        owner:AddTag("monkey")
    end
    StartPeriodicTask(inst)
    local owner = inst.components.inventoryitem.owner
    if TheWorld.ismastersim and owner and owner.userid then
        local rpc = GetClientModRPC("secret", "SayCurseMessage")
local is_connected = false
if owner and owner.userid and owner:IsValid() then
    if owner.Network and type(owner.Network.IsConnected) == "function" then
        is_connected = owner.Network:IsConnected()
    else
        is_connected = true
    end
end
if is_connected then
    if rpc then
        SendModRPCToClient(rpc, owner.userid, "Irgendwas stimmt nicht mit diesem T-Shirt", 3, 255/255, 255/255, 255/255, 1)
    end
else
    print("[Secret][RPC] WARN: RPC Call an ungültigen oder nicht verbundenen Spieler unterdrückt (OnPutInInventory)")
end
    end
end

local function OnRemovedFromInventory(inst)
    StopPeriodicTask(inst)
end

--------------------------------------------------------------------------------
-- HAUPTPREFAB-FUNKTION
--------------------------------------------------------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("secret")
    inst.AnimState:SetBuild("secret")
    inst.AnimState:PlayAnimation("idle")
    inst:AddTag("secret")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "secret"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/secret.xml"

    inst:AddComponent("inspectable")
    inst.components.inspectable.nameoverride = "Secret of Monkey Island"

    inst:ListenForEvent("onputininventory", OnPutInInventory)
    inst:ListenForEvent("ondropped", OnRemovedFromInventory)
    inst:ListenForEvent("onremove", OnRemovedFromInventory)

    return inst
end

return Prefab("secret", fn, assets)
