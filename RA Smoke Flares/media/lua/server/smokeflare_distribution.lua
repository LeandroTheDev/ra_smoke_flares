---@diagnostic disable: undefined-global
require "Items/SuburbsDistributions"
require "Items/ProceduralDistributions"
require "Vehicles/VehicleDistributions"
require "Items/Distributions"

-- Gun Stores
if SandboxVars.SmokeFlare.SmokeFlareEnableGunStoreSpawn then
    table.insert(ProceduralDistributions.list["GunStoreShelf"].items, "Base.SmokeFlare");
    table.insert(ProceduralDistributions.list["GunStoreShelf"].items,
        SandboxVars.SmokeFlare.SmokeFlareGunStoreSpawnChance);
end

-- Zombies
if SandboxVars.SmokeFlare.SmokeFlareEnableZombieSpawn then
    table.insert(SuburbsDistributions["all"]["inventorymale"].items, "Base.SmokeFlare");
    table.insert(SuburbsDistributions["all"]["inventorymale"].items, SandboxVars.SmokeFlare.SmokeFlareZombieSpawnChance);

    table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, "Base.SmokeFlare");
    table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, SandboxVars.SmokeFlare
    .SmokeFlareZombieSpawnChance);
end
