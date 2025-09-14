RASmokeFlareCompatibility = true;
RASmokeFlareName = "RASmokeFlare";
RASmokeFlareIsSinglePlayer = false;

if not isClient() and not isServer() then
    RASmokeFlareIsSinglePlayer = true;
end

function DebugPrintRASmokeFlare(log)
    if RASmokeFlareIsSinglePlayer then
        print("[" .. RASmokeFlareName .. "] " .. log);
    else
        if isClient() then
            print("[" .. RASmokeFlareName .. "-Client] " .. log);
        else
            if isServer() then
                print("[" .. RASmokeFlareName .. "-Server] " .. log);
            else
                print("[" .. RASmokeFlareName .. "-Unkown] " .. log);
            end
        end
    end
end