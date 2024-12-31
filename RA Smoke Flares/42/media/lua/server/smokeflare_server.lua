---@diagnostic disable: undefined-global
-- By bobodev the furious has a name 😊😊

local isSingleplayer = (not isClient() and not isServer());

-- Called when the player uses a smoke flare
function Recipe.OnGiveXP.CallAirdrop(craftRecipeData, player)
    -- Sending the client command to the server
    sendClientCommand("ServerSmokeFlare", "startsmokeflare", nil);
end

--#region lua utils
local function stringToList(str)
    local list = {}
    for item in string.gmatch(str, "([^/]+)") do
        table.insert(list, item)
    end
    return list
end
--#endregion

-- Performance variavels
local tickBeforeNextZed = 10; -- Ticks to spawn a zed
local actualTick = 0;         -- Actual server tick used with tickBeforeNextZed

-- This is all the zombies that should spawn when calling the smoke flare
local zombieOutfitTable = stringToList(SandboxVars.SmokeFlare.SmokeFlareCommonZombies);

-- This is the rare zombies
local zombieRareOutfitTable = stringToList(SandboxVars.SmokeFlare.SmokeFlareRareZombies);

-- All players that called any smoke flare will be stored here
-- [
--  "Test": {
--      "zombieCount": 100,
--      "zombieSpawned" 53,
--      "player": "Test",
--      "airdropArea": {
--          x: 100,
--          y: 50,
--          z: 0
--      }
--  }
-- ]
local playerSmokeFlares = {};

-- Add single zombie randomly on the player
local function SpawnOneZombie(player)
    local pLocation = player:getCurrentSquare();
    local zLocationX = 0;
    local zLocationY = 0;
    local canSpawn = false;
    local sandboxDistance = SandboxVars.SmokeFlare.SmokeFlareHordeDistanceSpawn;
    for i = 0, 100 do
        if ZombRand(2) == 0 then
            zLocationX = ZombRand(10) - 10 + sandboxDistance;
            zLocationY = ZombRand(sandboxDistance * 2) - sandboxDistance;
            if ZombRand(2) == 0 then
                zLocationX = 0 - zLocationX;
            end
        else
            zLocationY = ZombRand(10) - 10 + sandboxDistance;
            zLocationX = ZombRand(sandboxDistance * 2) - sandboxDistance;
            if ZombRand(2) == 0 then
                zLocationY = 0 - zLocationY;
            end
        end
        zLocationX = zLocationX + pLocation:getX();
        zLocationY = zLocationY + pLocation:getY();
        local spawnSpace = getWorld():getCell():getGridSquare(zLocationX, zLocationY, 0);
        if spawnSpace then
            local isSafehouse = SafeHouse.getSafeHouse(spawnSpace);
            if spawnSpace:isSafeToSpawn() and spawnSpace:isOutside() and isSafehouse == nil then
                canSpawn = true;
                break
            end
        else
            print("[Smoke Flare] Zombie: Space not Loaded " .. player:getUsername());
        end
        if i == 100 then
            print("[Smoke Flare] Zombie: Can't find a place to spawn " .. player:getUsername());
        end
    end
    if canSpawn then
        -- Rare zombies has 1% chance to spawn
        local outfit
        if ZombRand(100) + 1 == 1 then
            outfit = zombieRareOutfitTable[ZombRand(#zombieRareOutfitTable) + 1];
        else
            outfit = zombieOutfitTable[ZombRand(#zombieOutfitTable) + 1];
        end
        -- Adding the zombie
        print("X" .. zLocationX, "  Y" ..zLocationY )
        addZombiesInOutfit(zLocationX, zLocationY, 0, 1, outfit, 50, false, false, false, false, false, false, 1.5);
        -- Adding the zombie to the spawned table list
        playerSmokeFlares[player:getUsername()]["zombieSpawned"] = playerSmokeFlares[player:getUsername()]
            ["zombieSpawned"] +
            1;
        -- Adding the sound to the player to make the zombies hunt him
        getWorldSoundManager():addSound(player, player:getCurrentSquare():getX(),
            player:getCurrentSquare():getY(), player:getCurrentSquare():getZ(), 200, 10);
    end
end

-- Start the horde, to the player in parameter
function StartHorde(specificPlayer)
    -- Smoke flare zombie count
    local zombieCount = SandboxVars.SmokeFlare.SmokeFlareHorde * ((ZombRand(150) / 100) + 0.5);

    -- Difficulty calculation
    local difficulty
    if SandboxVars.SmokeFlare.SmokeFlareHorde > zombieCount then
        difficulty = "Easy";
    else
        difficulty = "Hard";
    end

    -- Creates the player table
    playerSmokeFlares[specificPlayer:getUsername()] = {};
    playerSmokeFlares[specificPlayer:getUsername()]["zombieCount"] = zombieCount;
    playerSmokeFlares[specificPlayer:getUsername()]["zombieSpawned"] = 0;
    playerSmokeFlares[specificPlayer:getUsername()]["player"] = specificPlayer:getUsername();
    playerSmokeFlares[specificPlayer:getUsername()]["airdropArea"] = {
        x = specificPlayer:getX(),
        y = specificPlayer:getY(),
        z = specificPlayer:getZ()
    };

    -- Send any alert to the playerEmite o alerta ao jogador
    sendServerCommand(specificPlayer, "ServerSmokeFlare", "smokeflare", { difficulty = difficulty });

    --Mensagem de log
    print("[Smoke Flare] Smoke Flare called, spawning on: " ..
        specificPlayer:getUsername() .. " quantity: " .. zombieCount);

    -- Adicionamos o OnTick para spawnar os zumbis
    Events.OnTick.Add(CheckHordeRemainingForSmokeFlare);
end

-- Check if the horde is over
function CheckHordeRemainingForSmokeFlare()
    -- Tick update
    if actualTick <= tickBeforeNextZed then
        actualTick = actualTick + 1;
        return
    end
    actualTick = 0;

    -- Swipe to check if all zombies has spawned for the player
    local allZombiesSpawned = true;
    for playerUsername, playerSpawns in pairs(playerSmokeFlares) do
        if isSingleplayer then -- Singleplayer treatment
            if playerSpawns.zombieSpawned < playerSpawns.zombieCount then
                allZombiesSpawned = false;
                SpawnOneZombie(getPlayer());
            end
        else -- Dedicated Server
            -- Getting online players
            local players = getOnlinePlayers();

            local found = false;
            for i = 0, players:size() - 1 do
                -- Getting player by index
                local player = players:get(i);
                -- Checking if the username is the same
                if player:getUsername() == playerUsername then
                    found = true;
                    -- Checking if the player finished spawning
                    if playerSpawns.zombieSpawned < playerSpawns.zombieCount then
                        allZombiesSpawned = false;
                        SpawnOneZombie(player);
                    end
                end
            end
            -- If not found the player, remove it because hes probably exited from the server
            if not found then
                playerSmokeFlares[playerUsername] = nil;
            end
        end
    end

    -- Disposing the function if all zombies has spawned
    if allZombiesSpawned then
        -- Removing the event
        Events.OnTick.Remove(CheckHordeRemainingForSmokeFlare);
        -- Swipe all players to spawn the airdrop and alerts
        for playerUsername, playerSpawns in pairs(playerSmokeFlares) do
            local players = getOnlinePlayers();
            -- Singleplayer treatment
            if isSingleplayer then
                -- Getting the sound file
                local alarmSound = "airdrop" .. tostring(ZombRand(1));

                -- Alocating in memory
                local sound = getSoundManager():PlaySound(alarmSound, false, 0);
                -- Playing the sound to the player
                getSoundManager():PlayAsMusic(alarmSound, sound, false, 0);
                sound:setVolume(0.1);
                SpawnSpecificAirdrop(playerSpawns.airdropArea);
                playerSmokeFlares = {};
                return;
            end
            -- Sending the mesage to the player
            for i = 0, players:size() - 1 do
                -- Getting the player by index
                local player = players:get(i);
                -- Checking if is the same as the smoke flare caller
                if player:getUsername() == playerUsername then
                    sendServerCommand(player, "ServerSmokeFlare", "smokeflare_finished", nil);
                end
            end
            SpawnSpecificAirdrop(playerSpawns.airdropArea);
            print("[Smoke Flare] Smoke Flare finished airdrop has been Spawned in X: " ..
                playerSpawns.airdropArea.x ..
                " Y: " .. playerSpawns.airdropArea.y .. " Z: " .. playerSpawns.airdropArea.z);
        end
        playerSmokeFlares = {};
        return
    end
end

-- Player message handler
Events.OnClientCommand.Add(function(module, command, player, args)
    if module == "ServerSmokeFlare" and command == "startsmokeflare" then
        -- Checking if the player has already called any airdrop
        for playerUsername, playerSpawns in pairs(playerSmokeFlares) do
            if player:getUsername() == playerUsername then
                print("[Smoke Flare] " .. player:getUsername() .. " trying to use a smoke flare again...");
                player:getInventory():AddItem('Base.SmokeFlare');
                return;
            end
        end
        StartHorde(player);
    end
end)
