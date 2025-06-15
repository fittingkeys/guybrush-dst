--------------------------------------------------------------------------
--  Amgulet – permanent intoxication talisman
--------------------------------------------------------------------------
local assets = {
    Asset("ANIM",  "anim/swap_amgulet.zip"),   -- Hand/body symbol
    Asset("ANIM",  "anim/ground_amgulet.zip"), -- Ground sprite
    Asset("ATLAS", "images/inventoryimages/amgulet.xml"),
    Asset("IMAGE", "images/inventoryimages/amgulet.tex"),
}

local _G = _G or GLOBAL
local EQUIPSLOTS   = _G.EQUIPSLOTS
local FUELTYPE     = _G.FUELTYPE

-- If CHEMICAL doesn't exist yet, create it
if not FUELTYPE.CHEMICAL then
    FUELTYPE.CHEMICAL = "CHEMICAL"
end

-- If the other mod loads before you, EQUIPSLOTS.NECK already exists
-- If not, use the body slot as a fallback
local NECK_SLOT = (EQUIPSLOTS and EQUIPSLOTS.NECK) or EQUIPSLOTS.BODY

--------------------------------------------------------------------------
-- Equip / Unequip
--------------------------------------------------------------------------
local function OnEquip(inst, owner)
    print("[DEBUG] Amgulet:OnEquip() - Equipped by:", owner:GetDisplayName())
    owner.AnimState:OverrideSymbol("swap_body", "swap_amgulet", "swap_body")

    inst.components.fueled:StartConsuming()
    print("[DEBUG] Amgulet:OnEquip() - Fuel consumption started.")

    if owner.components.drunkenness then
        owner.components.drunkenness:BlockDecrease(true)
        print("[DEBUG] Amgulet:OnEquip() - Drunkenness decay blocked.")
    end
end

local function OnUnequip(inst, owner)
    print("[DEBUG] Amgulet:OnUnequip() - Unequipped by:", owner:GetDisplayName())
    owner.AnimState:ClearOverrideSymbol("swap_body")

    inst.components.fueled:StopConsuming()
    print("[DEBUG] Amgulet:OnUnequip() - Fuel consumption stopped.")

    if owner.components.drunkenness then
        owner.components.drunkenness:BlockDecrease(false)
        print("[DEBUG] Amgulet:OnUnequip() - Drunkenness decay allowed again.")
    end
end

--------------------------------------------------------------------------
-- Fuel Callbacks
--------------------------------------------------------------------------
local function OnDepleted(inst)
    print("[DEBUG] Amgulet:OnDepleted() - Out of fuel.")
    local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner
    if owner then
        print("[DEBUG] Amgulet:OnDepleted() - Taking the item from the slot.")
        -- Better: Specify instance's own slot
        owner.components.inventory:Unequip(inst.components.equippable.equipslot, true)
    end
end

local function OnTakeFuel(inst)
    local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner
    print("[DEBUG] Amgulet:OnTakeFuel() - Fuel added. Owner:", owner and owner:GetDisplayName() or "nil")
end

--------------------------------------------------------------------------
-- Main Prefab Function
--------------------------------------------------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    inst.AnimState:SetBank("ground_amgulet")
    inst.AnimState:SetBuild("ground_amgulet")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("amulet")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/amgulet.xml"

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = NECK_SLOT
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype     = FUELTYPE.CHEMICAL
    inst.components.fueled:InitializeFuelLevel(1200)  -- e.g. 20 minutes
    inst.components.fueled.accepting    = true
    inst.components.fueled:SetDepletedFn(OnDepleted)
    inst.components.fueled.ontakefuelfn = OnTakeFuel

    -- Stop fuel consumption as long as it is not worn
    inst.components.fueled:StopConsuming()

    -- Delayed check after loading
    inst:DoTaskInTime(0, function(inst)
        print("[DEBUG] Amgulet:DoTaskInTime(0) - Checking if it is already equipped.")
        local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner
        if owner
           and owner.components.inventory
           and owner.components.inventory:GetEquippedItem(inst.components.equippable.equipslot) == inst
        then
            print("[DEBUG] Amgulet:DoTaskInTime(0) - Item is already equipped, calling OnEquip() again.")
            OnEquip(inst, owner)
        end
    end)

    return inst
end

return Prefab("amgulet", fn, assets)
