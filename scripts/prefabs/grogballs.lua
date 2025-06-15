-- grogballs.lua
local assets = {
    -- Your own animations/sprites
    Asset("ANIM", "anim/grogballs.zip"),
    -- Your inventory icon
    Asset("ATLAS", "images/inventoryimages/grogballs.xml"),
    Asset("IMAGE", "images/inventoryimages/grogballs.tex"),
}

local function OnEaten(inst, eater)
    -- 50% of Grog's drunkenness increase = 15 * 0.5 = 7.5
    if eater.components and eater.components.drunkenness then
        eater.components.drunkenness:DoDelta(7.5)
        eater:PushEvent("drunkennesschanged")
    end

    -- Small speech text
    if eater.components.talker then
        eater.components.talker:Say("Urgh...")
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    -- Play custom animation
    inst.AnimState:SetBank("grogballs")
    inst.AnimState:SetBuild("grogballs")
    inst.AnimState:PlayAnimation("idle")

    -- Edible values:
    inst:AddComponent("edible")
    inst.components.edible.foodtype    = FOODTYPE.MEAT
    inst.components.edible.healthvalue = 3         -- like Meatballs
    inst.components.edible.hungervalue = 50    -- less than Meatballs
    inst.components.edible.sanityvalue = 5         -- like Meatballs
    inst.components.edible:SetOnEatenFn(OnEaten)

    -- Make it float on water
    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    -- Inspection and inventory components
    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/grogballs.xml"

    inst:AddTag("guletfood")

    -- Perishability
    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_SLOW)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"
 
    -- Stackable
    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

    return inst
end

return Prefab("grogballs", fn, assets)
