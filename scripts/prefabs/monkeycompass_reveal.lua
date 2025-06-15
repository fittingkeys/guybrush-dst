local assets = {
    Asset("ANIM", "anim/monkeycompass.zip"),
    Asset("IMAGE", "images/inventoryimages/monkeycompass.tex"),
    Asset("ATLAS", "images/inventoryimages/monkeycompass.xml"),
}

------------------------------------------------------------------
-- CLIENTSEITIGE AUFDECKUNG: Nur Kreis um Zielpunkt
------------------------------------------------------------------
local function RevealCircleAroundCoordinates(caster, target_x, target_z, radius)
    if caster and caster.player_classified and caster.player_classified.MapExplorer then
        for angle = 0, 360, 10 do
            local offset_x = radius * math.cos(angle * DEGREES)
            local offset_z = radius * math.sin(angle * DEGREES)
            local x = target_x + offset_x
            local z = target_z + offset_z
            caster.player_classified.MapExplorer:RevealArea(x, 0, z)
        end
        -- optional: Zentrum aufdecken
        caster.player_classified.MapExplorer:RevealArea(target_x, 0, target_z)

        print(string.format("[monkeycompass] Kreis entnebelt um %.1f / %.1f (Radius %.1f)", target_x, target_z, radius))
    end
end

------------------------------------------------------------------
-- SERVER-SEITIGE HILFSFUNKTION:
-- Sucht alle  Monkeys und startet Aufdeckung
------------------------------------------------------------------
local function RevealMonkeysWithTelescope(inst, doer)
    if not TheWorld.ismastersim or doer == nil then return end

    local x, y, z = doer.Transform:GetWorldPosition()
    local monkeys = TheSim:FindEntities(x, y, z, 10000, {"monkey"})
    if #monkeys > 0 then
        if inst.components.telescopable and inst.components.telescopable.ontelescopefn then
            for _, monkey in ipairs(monkeys) do
                local x, _, z = monkey.Transform:GetWorldPosition()
                inst.components.telescopable.ontelescopefn(inst, Vector3(x, 0, z), doer)
                print("[monkeycompass] RevealMonkeysWithTelescope: Aufdeckung gestartet Richtung", x, z)
            end
        end
    else
        if doer.components.talker then
            doer.components.talker:Say("Mhhm. Nichts passiert.")
        end
        print("[monkeycompass] Keine Monkeys gefunden!")
    end
end

------------------------------------------------------------------
-- SPELL-FUNKTION
------------------------------------------------------------------
local function OnCastSpell(inst, target, pos, doer)
    if doer and doer.components.talker then
        doer.components.talker:Say("Da wurde etwas auf meiner Karte eingezeichnet!")
    end

    doer.SoundEmitter:PlaySound("compass_reveal/custom/reveal", "monkeycompassreveal")
    -- Verzögerte Sprachausgabe nach 3.5 Sekunden
    doer:DoTaskInTime(3.5, function()
        if doer and doer.components.talker then
            doer.components.talker:Say("Hört ihr das auch?")
        end
    end)

    RevealMonkeysWithTelescope(inst, doer)

    inst:Remove()
end

------------------------------------------------------------------
-- PREFAB-DEFINITION
------------------------------------------------------------------
local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    inst.AnimState:SetBank("monkeycompass")
    inst.AnimState:SetBuild("monkeycompass")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "monkeycompass"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/monkeycompass.xml"

    inst:AddComponent("spellcaster")
    inst.components.spellcaster.canusefrominventory = true
    inst.components.spellcaster:SetSpellFn(OnCastSpell)

    -- ✨ Telescope-Komponente
    inst:AddComponent("telescopable")
    inst.components.telescopable.ontelescopefn = function(_, pt, caster)
        if pt and caster then
            RevealCircleAroundCoordinates(caster, pt.x, pt.z, 1)
        end
    end

    return inst
end

return Prefab("monkeycompass", fn, assets)
