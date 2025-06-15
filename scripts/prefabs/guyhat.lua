local assets = {
    Asset("ANIM", "anim/guyhat.zip"),
    Asset("ATLAS", "images/inventoryimages/guyhat.xml"),
    Asset("IMAGE", "images/inventoryimages/guyhat.tex"),
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_hat", "guyhat", "swap_hat")
    owner.AnimState:Show("HAT")
    owner.AnimState:Show("HAIR_HAT")
    owner.AnimState:Hide("HAIR_NOHAT")
    owner.AnimState:Hide("HAIR")
    
    if owner:HasTag("player") then
        owner.AnimState:Hide("HEAD")
        owner.AnimState:Show("HEAD_HAT")
    end
    if inst.components.fueled ~= nil then
        inst.components.fueled:StartConsuming()
    end
    owner:AddTag("boat_health_buffer")
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_hat")
    owner.AnimState:Hide("HAT")
    owner.AnimState:Hide("HAIR_HAT")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")
    
    if owner:HasTag("player") then
        owner.AnimState:Show("HEAD")
        owner.AnimState:Hide("HEAD_HAT")
    end

    if inst.components.fueled ~= nil then
        inst.components.fueled:StopConsuming()
    end
    owner:RemoveTag("boat_health_buffer")
end

local function MainFunction()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
	inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)
	-- This is the name visible on the top of hierarchy in Spriter.
    inst.AnimState:SetBank("guyhat")
    -- This is the name of your compiled*.zip file.
    inst.AnimState:SetBuild("guyhat")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("guyhat")
	inst:AddTag("waterproofer")
	
	MakeInventoryFloatable(inst, "small", 0.1, 1.12)
	
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
		-- If we're not the host - stop performing further functions.
		-- Only server functions below.
        return inst
    end
    -- Inventory properties
    inst:AddComponent("inspectable")
	-- Allow "trading" the hat - used for giving the hat to Pigmen.
    inst:AddComponent("tradable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "guyhat"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/guyhat.xml"

    -- Equippable component
    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
	inst:AddComponent("fueled")
	-- This fuel type will allow us to use Sewing Kit to repair our hat.
	inst.components.fueled.fueltype = FUELTYPE.USAGE
	-- Our custom hat should last about 5 days of constant wearing (480 seconds is 1 day in DST).
	inst.components.fueled:InitializeFuelLevel(480*20)
	-- What should happen when we reach 0% usage - remove the item.
	inst.components.fueled:SetDepletedFn(inst.Remove)

	inst:AddComponent("waterproofer")
	-- Our hat shall grant 100% water resistance to the wearer!
    inst.components.waterproofer:SetEffectiveness(1.0)

    inst:AddComponent("insulator")
    inst.components.insulator:SetSummer()
    inst.components.insulator:SetInsulation(TUNING.INSULATION_SMALL)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("guyhat", MainFunction, assets)
