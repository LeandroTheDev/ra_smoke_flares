---@diagnostic disable: undefined-global
-- Gun Stores
if getSandboxOptions():getOptionByName("SmokeFlare.EnableGunStoreSpawn"):getValue() then
    table.insert(ProceduralDistributions.list["GunStoreShelf"].items, "Base.SmokeFlare");
    table.insert(ProceduralDistributions.list["GunStoreShelf"].items,
        getSandboxOptions():getOptionByName("SmokeFlare.GunStoreSpawnChance"):getValue());
end

-- Zombies
if getSandboxOptions():getOptionByName("SmokeFlare.EnableZombieSpawn"):getValue() then
    table.insert(SuburbsDistributions["all"]["inventorymale"].items, "Base.SmokeFlare");
    table.insert(SuburbsDistributions["all"]["inventorymale"].items,
        getSandboxOptions():getOptionByName("SmokeFlare.ZombieSpawnChance"):getValue());

    table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, "Base.SmokeFlare");
    table.insert(SuburbsDistributions["all"]["inventoryfemale"].items,
        getSandboxOptions():getOptionByName("SmokeFlare.ZombieSpawnChance"):getValue());
end
