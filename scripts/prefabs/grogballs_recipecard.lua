-- File: grogballs_recipecard.lua

local assets = {
    -- You need a custom animation for the recipe card
    -- or you can use the default animation from the game (cookingrecipecard).
    -- Here we assume you have "grogballs_recipecard.zip":
    Asset("ANIM", "anim/grogballs_recipecard.zip"),

    -- Custom inventory graphic:
    Asset("ATLAS", "images/inventoryimages/grogballs_recipecard.xml"),
    Asset("IMAGE", "images/inventoryimages/grogballs_recipecard.tex"),
}

------------------------------------------------------------------------------
-- 2) The Prefab itself
------------------------------------------------------------------------------

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    -- Physics, to make it a pick-up-able item:
    MakeInventoryPhysics(inst)

    -- Animation:
    -- You can also use the DST default "cookingrecipecard", e.g.:
    --    inst.AnimState:SetBank("cookingrecipecard")
    --    inst.AnimState:SetBuild("cookingrecipecard")
    inst.AnimState:SetBank("grogballs_recipecard")
    inst.AnimState:SetBuild("grogballs_recipecard")
    inst.AnimState:PlayAnimation("idle")

    -- Tag for all recipe cards:
    inst:AddTag("recipe_card")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    --------------------
    -- Inspectable
    --------------------
    inst:AddComponent("inspectable")
    -- When inspecting, the character only shows the name, for example
    -- or you override getdescription.

    --------------------
    -- Inventory Item
    --------------------
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/grogballs_recipecard.xml"
    -- Stackable is usually not desired for recipe cards, DST cards do not stack.

    --------------------
    -- UseableItem (so you can "use" the card)
    --------------------
    inst:AddComponent("useableitem")
    -- Defines how the item behaves when you, for example, 
    -- right-click it in the inventory ("Use").

    return inst
end

------------------------------------------------------------------------------
-- 3) Return: Prefab
------------------------------------------------------------------------------

return Prefab("grogballs_recipecard", fn, assets)
