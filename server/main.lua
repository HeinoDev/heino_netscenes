local Config = lib.load('config')

local Claims = {}

local function IsClaimedByOther(NetId, Source)
    local Claim = Claims[NetId]
    if not Claim then return false end
    if GetGameTimer() > Claim.ExpiresAt then return false end
    return Claim.Source ~= Source
end

lib.callback.register('heino_netscenes:Claim', function(Source, Name, NetId)
    if type(Name) ~= 'string' or type(NetId) ~= 'number' then return false end
    if IsClaimedByOther(NetId, Source) then return false end

    Claims[NetId] = { Source = Source, Name = Name, ExpiresAt = GetGameTimer() + Config.ClaimDuration }
    NetSceneLogs.SceneStarted(Source, Name)
    return true
end)

RegisterNetEvent('heino_netscenes:Unclaim', function(NetId)
    local Source = source
    local Claim = Claims[NetId]
    if not Claim or Claim.Source ~= Source then return end

    Claims[NetId] = nil
    NetSceneLogs.SceneFinished(Source, Claim.Name)
end)

AddEventHandler('playerDropped', function()
    local Source = source
    for NetId, Claim in pairs(Claims) do
        if Claim.Source == Source then Claims[NetId] = nil end
    end
end)
