local Creating = false

local function Lock()
    while Creating do Wait(100) end
    Creating = true
end

local function Unlock()
    Creating = false
end

local function LoadModel(Model)
    if not IsModelInCdimage(Model) or not IsModelValid(Model) then
        lib.print.error(('heino_netscenes: invalid model %s'):format(Model))
        return false
    end
    return pcall(lib.requestModel, Model)
end

local function Networked(Entity)
    while not DoesEntityExist(Entity) do Wait(100) end

    while not NetworkGetEntityIsNetworked(Entity) do
        NetworkRegisterEntityAsNetworked(Entity)
        Wait(0)
    end

    local NetworkId = NetworkGetNetworkIdFromEntity(Entity)
    while not NetworkDoesEntityExistWithNetworkId(NetworkId) do Wait(100) end

    SetNetworkIdCanMigrate(NetworkId, true)
    SetNetworkIdExistsOnAllMachines(NetworkId, true)
    SetEntityAsMissionEntity(Entity, true, true)

    return NetworkId
end

local function Resolve(NetworkId)
    local Entity = NetworkGetEntityFromNetworkId(NetworkId)
    while not DoesEntityExist(Entity) do Wait(100) end
    return Entity, NetworkGetNetworkIdFromEntity(Entity)
end

local function Finish(Model, NetworkId)
    local Entity, ResolvedId = Resolve(NetworkId)
    Wait(100)
    Unlock()
    SetModelAsNoLongerNeeded(Model)
    return Entity, ResolvedId
end

local function CreateVeh(Coords, Model, Props)
    Lock()
    if not LoadModel(Model) then return Unlock() end

    local Vehicle = CreateVehicle(Model, Coords.x, Coords.y, Coords.z, Coords.w, true, true)
    local NetworkId = Networked(Vehicle)
    SetEntityVisible(Vehicle, true)

    if Props then lib.setVehicleProperties(Vehicle, Props) end

    return Finish(Model, NetworkId)
end

exports('CreateVeh', CreateVeh)

local function CreateObj(Model, Coords, Hidden)
    Lock()
    if not LoadModel(Model) then return Unlock() end

    local Object = CreateObjectNoOffset(Model, Coords.x, Coords.y, Coords.z, true, true, true)
    SetEntityVisible(Object, not Hidden)
    SetEntityCollision(Object, not Hidden, true)
    local NetworkId = Networked(Object)
    SetEntityHeading(Object, Coords.w or 0.0)

    return Finish(Model, NetworkId)
end

exports('CreateObj', CreateObj)
NetScene.CreateObject = CreateObj

local function SpawnPed(Model, Coords, InsideVehicle)
    if InsideVehicle and next(InsideVehicle) then
        return CreatePedInsideVehicle(InsideVehicle.entity, 26, Model, InsideVehicle.seat, true, true)
    end
    return CreatePed(26, Model, Coords.x, Coords.y, Coords.z, Coords.w, true, true)
end

local function CreateNPC(Model, Coords, InsideVehicle)
    Lock()
    if not LoadModel(Model) then return Unlock() end

    local Npc = SpawnPed(Model, Coords, InsideVehicle)
    local NetworkId = Networked(Npc)
    SetEntityVisible(Npc, true)
    SetPedCanSwitchWeapon(Npc, true)
    SetPedDropsWeaponsWhenDead(Npc, false)
    SetPedFleeAttributes(Npc, 0, false)

    return Finish(Model, NetworkId)
end

exports('CreateNPC', CreateNPC)
