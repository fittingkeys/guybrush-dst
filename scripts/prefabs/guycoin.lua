local assets = {
    Asset("ANIM", "anim/guycoin.zip"),
    Asset("IMAGE", "images/inventoryimages/guycoin.tex"),
    Asset("ATLAS", "images/inventoryimages/guycoin.xml"),
}

local prefabs = {}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("guycoin")
    inst.AnimState:SetBuild("guycoin")
    inst.AnimState:PlayAnimation("idle")
    
    inst:AddTag("guycoin")
    
    MakeInventoryFloatable(inst, "small", 0.1, 0.8)

    inst.entity:SetPristine()
    
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")
    inst.components.inspectable.description = "Was ich wohl damit kaufen kann?"

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "guycoin"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/guycoin.xml"

    inst:AddComponent("tradable")

    MakeHauntableLaunch(inst)
    
    return inst
end

local function placer_postinit_fn(inst)
    inst.AnimState:SetScale(1.5, 1.5, 1.5)
end

return Prefab("guycoin", fn, assets, prefabs)
