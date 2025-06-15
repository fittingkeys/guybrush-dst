local utils = {}

utils.Bind = function(fn, ...)
    local args = {...}
    return function(...)
        local placeholders = {...}
        return fn(unpack(args), unpack(placeholders))
    end
end

utils.RunFunctionServerOnly = function(fn, ...)
    local args = {...}
    if TheSim:GetGameID() == "DST" then
        if TheWorld.ismastersim then
            fn(unpack(args))
        end
    else
        fn(unpack(args))
    end
end

utils.DropLootRandom = function(inst, prefab, chance)
    local rand = math.random() - chance
    if rand <= 0 then
        inst.components.lootdropper:SpawnLootPrefab(prefab)
        return true
    end
end
utils.DropLootRandomPick = function(inst, prefab_list, chances)
    assert(#prefab_list == #chances, "Number of prefab_list specified does not match number of chances specified")
    local rand = math.random(#prefab_list)
    return utils.DropLootRandom(inst, prefab_list[rand], chances[rand])
end

utils.GiveLootRandom = function(owner, prefab, chance)
    local rand = math.random() - chance
    if rand <= 0 then
        owner.components.inventory:GiveItem(SpawnPrefab(prefab), nil)
        return true
    end
end
utils.GiveLootRandomPick = function(owner, prefab_list, chances)
    assert(#prefab_list == #chances, "Number of prefab_list specified does not match number of chances specified")
    local rand = math.random(#prefab_list)
    return utils.GiveLootRandom(owner, prefab_list[rand], chances[rand])
end

utils.DoTimes = function(times, fn, ...)
    if times == 0 then
        return
    end
    for i = 1, times do
        fn(...)
    end
end

utils.PrintMembers = function(object)
    for i,v in pairs(object) do
        print(v)
    end
end

return utils
