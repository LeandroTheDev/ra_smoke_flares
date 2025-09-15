-- All players that called any smoke flare will be stored here
-- [
--  "Test": {
--      "player": "Test",
--      "airdropArea": {
--          x: 100,
--          y: 50,
--          z: 0
--      }
--  }
-- ]
local playerSmokeFlares = {};

--#region Horde Spawn
local tickBeforeNextZed = getSandboxOptions():getOptionByName("SmokeFlare.TicksToSpawnZombie"):getValue(); -- Ticks to spawn a zed
local actualTick = 0;                                                                                      -- Actual server tick used with tickBeforeNextZed

-- playerUsername => zombiesRemaining
local outgoingHordes = {};

-- table list of rare zombies to spawn
local rareZombiesList = {}

local rareZombiesListStr = getSandboxOptions():getOptionByName("SmokeFlare.RareZombies"):getValue();
for item in rareZombiesListStr:gmatch("[^/]+") do
    table.insert(rareZombiesList, item);
end

local function SpawnZombieToPlayer(player)
    local square = player:getCurrentSquare();
    local zLocationX = 0;
    local zLocationY = 0;
    local canSpawn = true;
    local distance = getSandboxOptions():getOptionByName("SmokeFlare.SpawnDistance"):getValue();

    -- Pickup spawn position
    for i = 0, 100 do
        if ZombRand(2) == 0 then
            zLocationX = ZombRand(10) - 10 + distance;
            zLocationY = ZombRand(distance * 2) - distance;
            if ZombRand(2) == 0 then
                zLocationX = 0 - zLocationX;
            end
        else
            zLocationY = ZombRand(10) - 10 + distance;
            zLocationX = ZombRand(distance * 2) - distance;
            if ZombRand(2) == 0 then
                zLocationY = 0 - zLocationY;
            end
        end
        zLocationX = zLocationX + square:getX();
        zLocationY = zLocationY + square:getY();

        local zombieSquare = getWorld():getCell():getGridSquare(zLocationX, zLocationY, 0);
        if canSpawn and not zombieSquare then
            DebugPrintRASmokeFlare(player:getUsername() ..
                " cannot spawn zombie in X:" .. zLocationX .. " Y: " .. zLocationY .. ", not a valid square");
            canSpawn = false;
        end

        if canSpawn and SafeHouse.getSafeHouse(zombieSquare) then
            DebugPrintRASmokeFlare(player:getUsername() ..
                " cannot spawn zombie in X:" .. zLocationX .. " Y: " .. zLocationY .. ", is a safehouse");
            canSpawn = false;
        end

        if canSpawn and not zombieSquare:isSafeToSpawn() then
            DebugPrintRASmokeFlare(player:getUsername() ..
                " cannot spawn zombie in X:" .. zLocationX .. " Y: " .. zLocationY .. ", is not safe to spawn");
            canSpawn = false;
        end

        if canSpawn and not zombieSquare:isOutside() then
            DebugPrintRASmokeFlare(player:getUsername() ..
                " cannot spawn zombie in X:" .. zLocationX .. " Y: " .. zLocationY .. ", is not outside");
            canSpawn = false;
        end

        if canSpawn then
            break;
        end
    end

    outgoingHordes[player:getUsername()] = outgoingHordes[player:getUsername()] - 1;

    if not canSpawn then
        DebugPrintRASmokeFlare(player:getUsername() .. " ZOMBIE NOT SPAWNED!");
        return;
    end

    -- Rare Zombie Spawn
    if ZombRand(0, 1000) + 1 <= getSandboxOptions():getOptionByName("SmokeFlare.RareZombiesChance"):getValue() then
        DebugPrintRASmokeFlare(player:getUsername() .. " RARE ZOMBIE SPAWNED! X: " .. zLocationX .. " Y: " .. zLocationY);

        local outfit = rareZombiesList[ZombRand(0, #rareZombiesList) + 1];

        addZombiesInOutfit(zLocationX, zLocationY, 0, 1, outfit, 50, false, false, false, false, false, false, 100, false,
            0);
    else -- Normal Zombie SPawn
        DebugPrintRASmokeFlare(player:getUsername() .. " ZOMBIE SPAWNED! X: " .. zLocationX .. " Y: " .. zLocationY);
        addZombiesInOutfit(zLocationX, zLocationY, 0, 1, nil, 50, false, false, false, false, false, false, 100, false,
            0);
    end

    DebugPrintRASmokeFlare(player:getUsername() .. " REMAINING: " .. outgoingHordes[player:getUsername()])

    addSound(player, player:getX(), player:getY(), player:getZ(), 200, 10);
end

local function SpawnSmokeFlareAidrop(player)
    -- Creates the player table
    playerSmokeFlares[player:getUsername()] = {};
    playerSmokeFlares[player:getUsername()]["player"] = player:getUsername();
    playerSmokeFlares[player:getUsername()]["airdropArea"] = {
        x = player:getX(),
        y = player:getY(),
        z = player:getZ()
    };

    if RASmokeFlareIsSinglePlayer then
        -- Alert sound
        local alarmSound = "smokeflareradio" .. tostring(ZombRand(1));
        local sound = getSoundManager():PlaySound(alarmSound, false, 0);
        getSoundManager():PlayAsMusic(alarmSound, sound, false, 0);
        sound:setVolume(0.4);

        -- You should awake the player if a horde is coming right?
        player:forceAwake();

        -- And speed to normal if the player is fast forwarding
        setGameSpeed(1);
    else
        -- Send any alert to the player
        sendServerCommand(player, "ServerSmokeFlare", "smokeFlare", nil);
    end

    playerSmokeFlares[player:getUsername()]["zombieCount"] = ZombRand(
        getSandboxOptions():getOptionByName("SmokeFlare.MinimumQuantity"):getValue(),
        getSandboxOptions():getOptionByName("SmokeFlare.MaximumQuantity"):getValue() + 1);

    outgoingHordes[player:getUsername()] = playerSmokeFlares[player:getUsername()]["zombieCount"];

    DebugPrintRandomHorde(player:getUsername() ..
        " airdrop spawned, zombies hunting: " .. outgoingHordes[player:getUsername()]);
end

local function CheckZombiesToSpawn()
    actualTick = actualTick + 1;
    if actualTick >= tickBeforeNextZed then
        actualTick = 0;

        if RASmokeFlareIsSinglePlayer then
            local player = getPlayer();
            if (outgoingHordes[player:getUsername()] or 0) > 0 then
                SpawnZombieToPlayer(player);
            elseif outgoingHordes[player:getUsername()] == 0 then
                outgoingHordes[player:getUsername()] = nil;
                local airdropArea = playerSmokeFlares[player:getUsername()]["airdropArea"];
                playerSmokeFlares[player:getUsername()] = nil;
                SpawnSpecificAirdrop({ x = airdropArea.x, y = airdropArea.y, z = airdropArea.z }, player:getUsername(),
                    "Unkown");
            end
        else
            for playerUsername, zombiesRemaining in pairs(outgoingHordes) do
                local player = getPlayerFromUsername(playerUsername);
                if player then
                    if (outgoingHordes[playerUsername] or 0) > 0 then
                        SpawnZombieToPlayer(player);
                    elseif outgoingHordes[playerUsername] == 0 then
                        outgoingHordes[playerUsername] = nil;
                        local airdropArea = playerSmokeFlares[playerUsername]["airdropArea"];
                        playerSmokeFlares[playerUsername] = nil;
                        SpawnSpecificAirdrop({ x = airdropArea.x, y = airdropArea.y, z = airdropArea.z }, playerUsername,
                            "Unkown");
                    end
                else
                    outgoingHordes[playerUsername] = nil;
                    playerSmokeFlares[playerUsername] = nil;
                    DebugPrintRASmokeFlare("IsoPlayer from " ..
                        playerUsername .. ", cannot be found, ignoring airdrop spawn...");
                end
            end
        end
    end
end

Events.OnTick.Add(CheckZombiesToSpawn);
--#endregion

--#region Smoke Flare

RASmokeFlareRecipe = RASmokeFlareRecipe or {};
RASmokeFlareRecipe.CallAirdrop = function(craftRecipeData, player)
    DebugPrintRASmokeFlare(player:getUsername() .. " requesting airdrop!");

    -- Checking if the player has already called any airdrop
    for playerUsername, playerSpawns in pairs(playerSmokeFlares) do
        if player:getUsername() == playerUsername then
            DebugPrintRASmokeFlare(player:getUsername() .. " trying to use a smoke flare again...");
            player:getInventory():AddItem('Base.SmokeFlare');
            return;
        end
    end

    SpawnSmokeFlareAidrop(player);
end

--#endregion
