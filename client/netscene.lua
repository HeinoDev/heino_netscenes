local Config = lib.load('config')

NetScene = {}
NetScene.Config = Config
NetScene.Definitions = {}
NetScene.Bag = Config.Bag
NetScene.Active = {}
NetScene.Claimed = {}

function NetScene.Debug(Message, ...)
    if Config.Debug then print(('[heino_netscenes] ' .. Message):format(...)) end
end

local DebugBanner = {
    ' ____   _____  ____   _   _   ____ ',
    '|  _ \\ | ____|| __ ) | | | | / ___|',
    '| | | ||  _|  |  _ \\ | | | || |  _ ',
    '| |_| || |___ | |_) || |_| || |_| |',
    '|____/ |_____|____/  \\___/  \\____|',
}

if Config.Debug then
    for _, Line in ipairs(DebugBanner) do print(('^1%s^7'):format(Line)) end
    print('^1[heino_netscenes] debug is enabled^7')
end

function NetScene.Define(Name, Definition)
    NetScene.Definitions[Name] = Definition
    return Definition
end

function NetScene.RequestControl(Entity, Timeout)
    local Deadline = GetGameTimer() + (Timeout or Config.ControlTimeout)
    NetworkRequestControlOfEntity(Entity)

    while not NetworkHasControlOfEntity(Entity) do
        if GetGameTimer() > Deadline then return false end
        NetworkRequestControlOfEntity(Entity)
        Wait(50)
    end

    return true
end

function NetScene.Claim(Name, Entity)
    if not NetworkGetEntityIsNetworked(Entity) then return true end

    local NetId = NetworkGetNetworkIdFromEntity(Entity)
    local Claimed = lib.callback.await('heino_netscenes:Claim', false, Name, NetId)
    if Claimed then NetScene.Claimed[Entity] = NetId end
    return Claimed
end

function NetScene.Unclaim(Entity)
    local NetId = NetScene.Claimed[Entity]
    if not NetId then return end

    NetScene.Claimed[Entity] = nil
    TriggerServerEvent('heino_netscenes:Unclaim', NetId)
end

function NetScene.ValidateTarget(Name, Entity)
    if not Entity or not DoesEntityExist(Entity) then
        lib.print.error(('%s: Entity does not exist'):format(Name))
        return false
    end

    if NetworkGetEntityIsNetworked(Entity) and not NetScene.RequestControl(Entity) then
        lib.print.error(('%s: Could not get control of entity'):format(Name))
        return false
    end

    if not NetScene.Claim(Name, Entity) then
        lib.print.warn(('%s: Entity is already in use'):format(Name))
        return false
    end

    return true
end

function NetScene.ResolveDict(Definition)
    local Dict = Definition.Dict
    if type(Dict) ~= 'table' then return Dict end
    return IsPedMale(cache.ped) and Dict.Male or Dict.Female or Dict.Male
end

function NetScene.AllDicts(Definition)
    local Dict = Definition.Dict
    if type(Dict) ~= 'table' then return { Dict } end

    local Dicts = {}
    for _, Value in pairs(Dict) do Dicts[#Dicts + 1] = Value end
    return Dicts
end

function NetScene.ClipDuration(Dict, Clip)
    return math.floor(GetAnimDuration(Dict, Clip) * 1000)
end

function NetScene.HasClip(Dict, Clip)
    return Clip ~= nil and GetAnimDuration(Dict, Clip) > 0.0
end

function NetScene.WaitRemaining(StartedAt, Duration)
    Wait(math.max(0, StartedAt + Duration - GetGameTimer()))
end

function NetScene.Phase(Scene)
    local LocalScene = NetworkGetLocalSceneFromNetworkId(Scene)
    if LocalScene == -1 then return nil end
    return GetSynchronizedScenePhase(LocalScene)
end

function NetScene.WaitForPhase(Scene, Phase, Timeout)
    local Deadline = GetGameTimer() + Timeout
    while GetGameTimer() < Deadline do
        local Current = NetScene.Phase(Scene)
        if Current and Current >= Phase then return end
        Wait(0)
    end
end

function NetScene.CreateProp(Model, Coords)
    local Hash = type(Model) == 'string' and joaat(Model) or Model
    lib.requestModel(Hash)
    local Prop = CreateObject(Hash, Coords.x, Coords.y, Coords.z, true, true, false)
    SetEntityCollision(Prop, false, true)
    return Prop
end

local function CreateSceneProps(Models, Coords)
    local Props = {}
    for Name, Model in pairs(Models) do
        Props[Name] = NetScene.CreateProp(Model, Coords)
    end
    return Props
end

local function DeleteSceneProps(Props)
    for _, Entity in pairs(Props) do
        if DoesEntityExist(Entity) then DeleteEntity(Entity) end
    end
end

local function ReleaseModels(Models)
    for _, Model in pairs(Models) do
        SetModelAsNoLongerNeeded(joaat(Model))
    end
end

function NetScene.New(Definition, Origin, Rotation, Options)
    Options = Options or {}
    local Dict = NetScene.ResolveDict(Definition)
    lib.requestAnimDict(Dict)

    local Models = Definition.Props or {}
    local Context = {
        Dict = Dict,
        Stages = Definition.Stages or {},
        Origin = Origin,
        Rotation = Rotation,
        Models = Models,
        Props = CreateSceneProps(Models, Origin),
        Target = Options.Target,
        Entities = Options.Entities or {},
        Camera = Options.Camera,
        Speed = Options.Speed or Definition.Speed or 1.0,
    }

    NetScene.Active[Context] = true
    return Context
end

local function AddEntityToStage(Scene, Dict, Entity, Clip)
    if not Entity or not DoesEntityExist(Entity) or not NetScene.HasClip(Dict, Clip) then return end
    NetworkAddEntityToSynchronisedScene(Entity, Scene, Dict, Clip, 1.0, 1.0, 1)
end

function NetScene.Start(Context, StageName, Settings)
    Settings = Settings or {}
    local Clips = Context.Stages[StageName]
    if not Clips then
        lib.print.error(('Scene stage %s does not exist in %s'):format(tostring(StageName), Context.Dict))
        return 0
    end

    local Origin, Rotation = Context.Origin, Context.Rotation
    local Speed = Settings.Speed or Context.Speed
    local Phase = Settings.Phase or 0.0

    local Scene = NetworkCreateSynchronisedScene(Origin.x, Origin.y, Origin.z, Rotation.x, Rotation.y, Rotation.z, 2, true, Settings.Looped or false, -1, Phase, Speed)
    NetworkAddPedToSynchronisedScene(cache.ped, Scene, Context.Dict, Clips.Ped, 1.5, -4.0, 1, 16, 1148846080, 0)

    for Name, Entity in pairs(Context.Props) do
        AddEntityToStage(Scene, Context.Dict, Entity, Clips[Name])
    end
    for Name, Entity in pairs(Context.Entities) do
        AddEntityToStage(Scene, Context.Dict, Entity, Clips[Name])
    end
    AddEntityToStage(Scene, Context.Dict, Context.Target, Clips.Target)

    if Context.Camera and NetScene.HasClip(Context.Dict, Clips.Cam) then
        NetworkAddSynchronisedSceneCamera(Scene, Context.Dict, Clips.Cam)
    end

    NetworkStartSynchronisedScene(Scene)
    Context.Scene = Scene

    if Speed <= 0.0 then return 0 end
    return math.floor(NetScene.ClipDuration(Context.Dict, Clips.Ped) * (1.0 - Phase) / Speed)
end

function NetScene.Play(Context, StageName, Settings)
    Wait(NetScene.Start(Context, StageName, Settings))
end

function NetScene.PlayUntil(Context, StageName, ShouldAbort, Settings)
    local Deadline = GetGameTimer() + NetScene.Start(Context, StageName, Settings)

    while GetGameTimer() < Deadline do
        if type(ShouldAbort) == 'function' and ShouldAbort() then return false end
        Wait(100)
    end

    return true
end

function NetScene.Release(Context, Name)
    local Entity = Context.Props[Name]
    Context.Props[Name] = nil
    return Entity
end

local function UnclaimContext(Context)
    NetScene.Unclaim(Context.Target)
    for _, Entity in pairs(Context.Entities) do NetScene.Unclaim(Entity) end
end

function NetScene.Finish(Context)
    if Context.Finished then return end
    Context.Finished = true
    NetScene.Active[Context] = nil

    if Context.Scene then NetworkStopSynchronisedScene(Context.Scene) end
    DeleteSceneProps(Context.Props)
    ReleaseModels(Context.Models)
    RemoveAnimDict(Context.Dict)
    UnclaimContext(Context)
end

function NetScene.Abort()
    for Context in pairs(NetScene.Active) do NetScene.Finish(Context) end
end

CreateThread(function()
    while true do
        if next(NetScene.Active) then
            if IsPedDeadOrDying(cache.ped, true) then NetScene.Abort() end
            Wait(250)
        else
            Wait(1000)
        end
    end
end)

AddEventHandler('onResourceStop', function(Resource)
    if Resource == GetCurrentResourceName() then NetScene.Abort() end
end)

function NetScene.AnchorToPed(Dict, Clip, Heading)
    lib.requestAnimDict(Dict)
    local Ped = cache.ped
    local Coords = GetEntityCoords(Ped)
    local Rotation = vec3(0.0, 0.0, Heading or GetEntityHeading(Ped))
    if not NetScene.HasClip(Dict, Clip) then return Coords, Rotation end

    local Start = GetAnimInitialOffsetPosition(Dict, Clip, Coords.x, Coords.y, Coords.z, Rotation.x, Rotation.y, Rotation.z, 0.0, 2)
    return Coords - (Start - Coords), Rotation
end

function NetScene.OriginFromCoords(Coords)
    return vec3(Coords.x, Coords.y, Coords.z), vec3(0.0, 0.0, Coords.w or 0.0)
end

function NetScene.RunMinigame(Minigame)
    if type(Minigame) ~= 'function' then return true, nil end

    local Result, Settled = promise.new(), false
    local function Settle(Value)
        if Settled then return end
        Settled = true
        Result:resolve(Value == nil and false or Value)
    end

    local Returned = Minigame(Settle)
    if Returned ~= nil then Settle(Returned) end

    local Value = Citizen.Await(Result)
    return Value ~= false, Value
end

function NetScene.RunTimedMinigame(Minigame, FallbackTime)
    if type(Minigame) == 'function' then return NetScene.RunMinigame(Minigame) end
    Wait(FallbackTime)
    return true, nil
end

function NetScene.Varhack(Settings)
    Settings = Settings or {}
    return function(Settle)
        if GetResourceState('varhack') ~= 'started' then
            lib.print.error('varhack is not started')
            return Settle(false)
        end

        exports['varhack']:OpenHackingGame(function(Success)
            Settle(Success == true)
        end, Settings.Blocks or 6, Settings.Speed or 4)
    end
end

function NetScene.ReplaceEntity(Entity, Model)
    local Coords = GetEntityCoords(Entity)
    local Heading = GetEntityHeading(Entity)
    local Replacement = NetScene.CreateObject(joaat(Model), vec4(Coords.x, Coords.y, Coords.z, Heading))
    DeleteEntity(Entity)
    if Replacement then FreezeEntityPosition(Replacement, true) end
    return Replacement
end

function NetScene.DeleteOwnedEntity(Entity)
    if Entity and DoesEntityExist(Entity) and NetScene.RequestControl(Entity) then DeleteEntity(Entity) end
end

function NetScene.FaceEntity(Entity, Ped)
    Ped = Ped or cache.ped
    local PedCoords = GetEntityCoords(Ped)
    local TargetCoords = GetEntityCoords(Entity)
    local Heading = GetHeadingFromVector_2d(TargetCoords.x - PedCoords.x, TargetCoords.y - PedCoords.y)
    SetEntityHeading(Ped, Heading)
    Wait(0)
    return Heading
end

function NetScene.MovePed(Coords)
    local Ped = cache.ped
    SetEntityCoords(Ped, Coords.x, Coords.y, Coords.z, false, false, false, false)
    SetEntityHeading(Ped, Coords.w or GetEntityHeading(Ped))
    Wait(0)
end

function NetScene.HidePedBag()
    local Ped = cache.ped
    local Drawable = GetPedDrawableVariation(Ped, Config.BagComponent)
    local Texture = GetPedTextureVariation(Ped, Config.BagComponent)
    SetPedComponentVariation(Ped, Config.BagComponent, 0, 0, 0)

    return function()
        SetPedComponentVariation(Ped, Config.BagComponent, Drawable, Texture, 0)
    end
end

function NetScene.PlayNetworkedPtfx(Ptfx, Coords)
    lib.requestNamedPtfxAsset(Ptfx.Asset)
    UseParticleFxAssetNextCall(Ptfx.Asset)
    StartNetworkedParticleFxNonLoopedAtCoord(Ptfx.Name, Coords.x, Coords.y, Coords.z, 0.0, 0.0, 0.0, Ptfx.Scale or 1.0, false, false, false)
end

function NetScene.StartLoopedPtfxOnEntity(Ptfx, Entity)
    lib.requestNamedPtfxAsset(Ptfx.Asset)
    UseParticleFxAssetNextCall(Ptfx.Asset)
    local Offset = Ptfx.Offset or vec3(0.0, 0.0, 0.0)
    local Effect = StartNetworkedParticleFxLoopedOnEntity(Ptfx.Name, Entity, Offset.x, Offset.y, Offset.z, 0.0, 0.0, 0.0, Ptfx.Scale or 1.0, false, false, false)

    return function()
        StopParticleFxLooped(Effect, false)
        RemoveNamedPtfxAsset(Ptfx.Asset)
    end
end

local function CollectClips(Definition)
    local Clips = {}
    for _, Stage in pairs(Definition.Stages or {}) do
        for _, Clip in pairs(Stage) do Clips[#Clips + 1] = Clip end
    end
    for _, Clip in ipairs(Definition.Variants or {}) do Clips[#Clips + 1] = Clip end
    for _, Clip in ipairs(Definition.ExtraClips or {}) do Clips[#Clips + 1] = Clip end
    return Clips
end

local function CollectModels(Definition)
    local Models = {}
    for _, Model in pairs(Definition.Props or {}) do Models[#Models + 1] = Model end
    for _, Model in ipairs(Definition.Models or {}) do Models[#Models + 1] = Model end
    return Models
end

local function CheckDict(Name, Dict, Definition, Problems)
    if not DoesAnimDictExist(Dict) then
        Problems[#Problems + 1] = ('%s: dict %s does not exist'):format(Name, Dict)
        return
    end

    lib.requestAnimDict(Dict)
    for _, Clip in ipairs(CollectClips(Definition)) do
        if not NetScene.HasClip(Dict, Clip) then
            Problems[#Problems + 1] = ('%s: clip %s missing in %s'):format(Name, Clip, Dict)
        end
    end
    RemoveAnimDict(Dict)
end

local function CheckDefinition(Name, Definition, Problems)
    for _, Model in ipairs(CollectModels(Definition)) do
        if not IsModelInCdimage(joaat(Model)) then
            Problems[#Problems + 1] = ('%s: model %s is missing'):format(Name, Model)
        end
    end

    for _, Dict in ipairs(NetScene.AllDicts(Definition)) do
        CheckDict(Name, Dict, Definition, Problems)
    end
end

local function CheckSceneClips()
    local Problems = {}
    for Name, Definition in pairs(NetScene.Definitions) do
        CheckDefinition(Name, Definition, Problems)
    end
    table.sort(Problems)
    return Problems
end

exports('CheckSceneClips', CheckSceneClips)
