local Settings = NetScene.Config.TruckScene
local Config = NetScene.Config
local Steps = Settings.Steps
local CarClip = Steps[#Steps].CarClip

local function NewRig()
    return { Cars = {} }
end

local Rig = NewRig()
local Active = false
local Busy = false
local PlayerDriven = false
local Camera = nil
local ActiveScene = nil

local function DeleteLocal(Entity)
    if not Entity or not DoesEntityExist(Entity) then return end
    SetEntityAsMissionEntity(Entity, true, true)
    DeleteEntity(Entity)
end

local function LoadModel(Model)
    local Hash = type(Model) == 'string' and joaat(Model) or Model
    if not IsModelValid(Hash) then return nil end
    if not pcall(lib.requestModel, Hash, 10000) then return nil end
    return Hash
end

local function LoadDicts()
    for _, Dict in pairs(Settings.Dicts) do
        if not pcall(lib.requestAnimDict, Dict, 15000) then
            lib.print.error(('TruckScene: could not load anim dict %s'):format(Dict))
            return false
        end
    end
    return true
end

local function WaitForPhysics(Vehicle)
    local Deadline = GetGameTimer() + 2000
    while not DoesEntityHavePhysics(Vehicle) and GetGameTimer() < Deadline do Wait(0) end
end

local function CreateLocalVehicle(Model, Coords, Heading, AwaitPhysics)
    local Hash = LoadModel(Model)
    if not Hash then
        lib.print.error(('TruckScene: could not load model %s'):format(Model))
        return nil
    end

    local Vehicle = CreateVehicle(Hash, Coords.x, Coords.y, Coords.z, Heading, false, false)
    SetModelAsNoLongerNeeded(Hash)
    if AwaitPhysics then WaitForPhysics(Vehicle) end
    return Vehicle
end

local function DressTruck(Truck)
    SetVehicleOnGroundProperly(Truck)
    SetVehicleColours(Truck, Settings.TruckColours[1], Settings.TruckColours[2])
    SetVehicleExtraColours(Truck, Settings.TruckExtraColours[1], Settings.TruckExtraColours[2])
    SetVehicleDoorsLocked(Truck, 3)
    SetVehicleStrong(Truck, true)
    SetVehicleHasStrongAxles(Truck, true)
    SetVehicleTyresCanBurst(Truck, false)
    SetVehicleDirtLevel(Truck, 0.0)
    FreezeEntityPosition(Truck, true)
end

local function PlaceTrailer(Trailer, Spot, Heading)
    SetEntityCoordsNoOffset(Trailer, Spot.x, Spot.y, Spot.z, false, false, true)
    SetEntityHeading(Trailer, Heading)
end

local function DressTrailer(Trailer, Spot, Heading)
    PlaceTrailer(Trailer, Spot, Heading)
    SetVehicleDoorsLocked(Trailer, 3)
    SetVehicleIsConsideredByPlayer(Trailer, false)
    SetVehicleTyresCanBurst(Trailer, false)
    SetVehicleExtra(Trailer, 7, true)
    SetVehicleDirtLevel(Trailer, 0.0)
end

local function HitchTrailer(Truck, Trailer, Spot, Heading)
    FreezeEntityPosition(Truck, false)
    AttachVehicleToTrailer(Truck, Trailer, 1.0)
    SetVehicleDoorShut(Trailer, 5, true)
    Wait(100)

    if IsVehicleAttachedToTrailer(Truck) then return end

    PlaceTrailer(Trailer, Spot, Heading)
    AttachVehicleToTrailer(Truck, Trailer, 1.0)
    Wait(100)
end

local function DressCar(Car, Spec)
    SetVehicleColours(Car, Spec.Colours[1], Spec.Colours[2])
    SetVehicleExtraColours(Car, Spec.ExtraColours[1], Spec.ExtraColours[2])
    SetVehicleNumberPlateText(Car, Spec.Plate)
    SetVehicleDirtLevel(Car, 0.0)
    if Spec.Extra then SetVehicleExtra(Car, Spec.Extra, true) end

    SetVehicleAutomaticallyAttaches(Car, false, 0)
    SetVehicleTyresCanBurst(Car, false)
    SetVehicleStrong(Car, true)
    SetVehicleHasStrongAxles(Car, true)
    SetHornEnabled(Car, false)
    SetVehicleEngineOn(Car, false, true, false)
    SetVehicleIsConsideredByPlayer(Car, false)
end

local function LoadCar(Trailer, Spec, Heading)
    local Spot = GetOffsetFromEntityInWorldCoords(Trailer, Spec.Offset.x, Spec.Offset.y, Spec.Offset.z + 8.0)
    local Car = CreateLocalVehicle(Spec.Model, Spot, Heading)
    if not Car then return nil end

    DressCar(Car, Spec)
    AttachVehicleOnToTrailer(Car, Trailer, 0.0, 0.0, 0.0, Spec.Offset.x, Spec.Offset.y, Spec.Offset.z, Spec.Rotation.x, Spec.Rotation.y, Spec.Rotation.z, -1.0)
    return Car
end

local function LoadCars(Trailer, Heading)
    for Index, Spec in ipairs(Settings.Cars) do
        local Car = LoadCar(Trailer, Spec, Heading)
        if Car then
            Rig.Cars[#Rig.Cars + 1] = Car
            if Index == Settings.TargetCar then Rig.Target = Car end
        end
    end
end

local function BuildRig()
    local Ped = cache.ped
    local Origin = GetOffsetFromEntityInWorldCoords(Ped, 0.0, Settings.SpawnForward, 0.0)
    local Heading = GetEntityHeading(Ped)

    Rig.Truck = CreateLocalVehicle(Settings.Truck, Origin, Heading, true)
    if not Rig.Truck then return false end
    DressTruck(Rig.Truck)

    local Hitch = GetOffsetFromEntityInWorldCoords(Rig.Truck, Settings.HitchOffset.x, Settings.HitchOffset.y, Settings.HitchOffset.z)
    Rig.Trailer = CreateLocalVehicle(Settings.Trailer, Hitch, Heading, true)
    if not Rig.Trailer then return false end
    DressTrailer(Rig.Trailer, Hitch, Heading)

    HitchTrailer(Rig.Truck, Rig.Trailer, Hitch, Heading)
    LoadCars(Rig.Trailer, Heading)

    return Rig.Target ~= nil
end

local function CreateRigPed(Model, Seat)
    local Hash = LoadModel(Model)
    if not Hash then
        lib.print.error(('TruckScene: could not load model %s'):format(Model))
        return nil
    end

    local Coords = GetEntityCoords(Rig.Truck)
    local Ped = CreatePed(26, Hash, Coords.x, Coords.y, Coords.z, GetEntityHeading(Rig.Truck), false, false)
    SetModelAsNoLongerNeeded(Hash)

    SetPedIntoVehicle(Ped, Rig.Truck, Seat)
    SetBlockingOfNonTemporaryEvents(Ped, true)
    SetPedCanBeDraggedOut(Ped, false)
    SetEntityInvincible(Ped, true)
    return Ped
end

local function SpawnDriver()
    local Driver = CreateRigPed(Settings.DriverModel, -1)
    if not Driver then return end

    Rig.Driver = Driver
    SetPedCanRagdoll(Driver, false)
    SetDriverAbility(Driver, 1.0)
    SetDriverAggressiveness(Driver, 0.0)

    local Target = GetOffsetFromEntityInWorldCoords(Rig.Truck, 0.0, Settings.DriveDistance, 0.0)
    SetVehicleEngineOn(Rig.Truck, true, true, false)
    TaskVehicleDriveToCoordLongrange(Driver, Rig.Truck, Target.x, Target.y, Target.z, Settings.DriveSpeed, Settings.DriveStyle, 5.0)
    SetPedKeepTask(Driver, true)
end

local function SpawnCrawler()
    Rig.Crawler = CreateRigPed(Settings.CrawlerModel, 0)
    return Rig.Crawler
end

local function ReleaseCamera(Duration)
    if not Camera then return end

    RenderScriptCams(false, false, Duration, true, false)
    DestroyAllCams(true)
    Camera = nil
end

local function RestorePlayer()
    SetPlayerControl(PlayerId(), true, 0)
    DisplayRadar(true)
    if not PlayerDriven then return end

    local Ped = cache.ped
    ClearPedTasksImmediately(Ped)
    SetBlockingOfNonTemporaryEvents(Ped, false)
    PlayerDriven = false
end

local function ClearRig()
    Active = false
    ReleaseCamera(0)
    RestorePlayer()

    DeleteLocal(Rig.Driver)
    DeleteLocal(Rig.Crawler)
    for _, Car in ipairs(Rig.Cars) do DeleteLocal(Car) end
    DeleteLocal(Rig.Trailer)
    DeleteLocal(Rig.Truck)

    for _, Dict in pairs(Settings.Dicts) do RemoveAnimDict(Dict) end

    Rig = NewRig()
    ActiveScene = nil
end

local function StartStep(Index, Ped, PhaseNow)
    local Step = Steps[Index]
    local Dict = Settings.Dicts[Step.Dict]
    local Scene = CreateSynchronizedScene(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2)

    if Step.Attach == 'truck' then
        AttachSynchronizedSceneToEntity(Scene, Rig.Truck, GetEntityBoneIndexByName(Rig.Truck, 'seat_pside_f'))
    else
        AttachSynchronizedSceneToEntity(Scene, Rig.Trailer, 0)
    end

    TaskSynchronizedScene(Ped, Scene, Dict, Step.Clip, Step.BlendIn, -1000.0, Step.Flags, 9843, 1000.0, 0)

    if Step.SeedPhase then
        SetSynchronizedScenePhase(Scene, PhaseNow)
    elseif Step.Phase then
        SetSynchronizedScenePhase(Scene, Step.Phase)
    end

    SetSynchronizedSceneLooped(Scene, Step.Looped)
    if Step.Rate then SetSynchronizedSceneRate(Scene, Step.Rate) end

    ActiveScene = Scene
    if Step.Cam and Camera then PlaySynchronizedCamAnim(Camera, Scene, Step.Cam, Dict) end

    return Scene
end

local function RestoreCollisions(Ped)
    for _, Car in ipairs(Rig.Cars) do
        if DoesEntityExist(Car) then SetEntityNoCollisionEntity(Ped, Car, true) end
    end
end

local function AbortPed(Ped)
    StopSynchronizedEntityAnim(Ped, -8.0, true)
    ClearPedTasksImmediately(Ped)
    RestoreCollisions(Ped)

    if IsEntityAttached(Ped) then DetachEntity(Ped, true, false) end

    SetPedCanRagdoll(Ped, true)
    SetPedToRagdoll(Ped, 3000, 10000, 2, true, true, false)
    ReleaseCamera(3000)
end

local function FinishPed(Ped)
    NetScene.Debug('finish, seating ped in the target car')

    StopSynchronizedEntityAnim(Ped, -1000.0, true)
    ClearPedTasksImmediately(Ped)
    RestoreCollisions(Ped)

    SetPedIntoVehicle(Ped, Rig.Target, -1)
    SetVehicleIsConsideredByPlayer(Rig.Target, true)
    SetVehicleDoorsLocked(Rig.Target, 1)
    ReleaseCamera(3000)
end

local function TrailerAlive()
    return Rig.Trailer and DoesEntityExist(Rig.Trailer)
end

local function StartScrapeSparks()
    local Handles = {}
    if not TrailerAlive() then return Handles end
    if not pcall(lib.requestNamedPtfxAsset, Settings.ScrapeAsset, 5000) then return Handles end

    for _, Offset in ipairs(Settings.ScrapeOffsets) do
        UseParticleFxAsset(Settings.ScrapeAsset)
        Handles[#Handles + 1] = StartParticleFxLoopedOnEntity(Settings.ScrapeEffect, Rig.Trailer, Offset.x, Offset.y, Offset.z, 0.0, 0.0, 0.0, 1.0, false, false, false)
    end
    return Handles
end

local function ReleaseCar(Car)
    DetachEntity(Car, true, false)
    SetEntityCollision(Car, false, false)
    Wait(Settings.DropCollisionOffMs)
    SetEntityCollision(Car, true, false)

    if TrailerAlive() then SetVehicleForwardSpeed(Car, GetEntitySpeed(Rig.Trailer)) end

    local Force = Settings.DropForce
    ApplyForceToEntity(Car, 2, Force.x, Force.y, Force.z, 0.0, 0.0, 0.0, 0, true, true, true, false, true)

    SetVehicleEngineOn(Car, true, true, false)
    SetVehicleIsConsideredByPlayer(Car, true)
    SetVehicleDoorsLocked(Car, 1)
end

local function DropCar()
    local Car = Rig.Target
    if not Car or not DoesEntityExist(Car) then return end

    NetScene.Debug('drop, releasing the car off the trailer')

    if TrailerAlive() then
        SetVehicleDoorsLocked(Rig.Trailer, 1)
        SetVehicleDoorOpen(Rig.Trailer, 5, false, false)
    end

    local Sparks = StartScrapeSparks()
    ReleaseCar(Car)
    Wait(Settings.ScrapeMs)

    for _, Handle in ipairs(Sparks) do StopParticleFxLooped(Handle, false) end
    if TrailerAlive() then SetVehicleDoorShut(Rig.Trailer, 5, false) end
end

local function DetachTargetFromRig()
    for Index, Car in ipairs(Rig.Cars) do
        if Car == Rig.Target then
            table.remove(Rig.Cars, Index)
            break
        end
    end
    Rig.Target = nil
end

local function ScheduleCleanup()
    local Finished = Rig
    SetTimeout(Settings.CleanupMs, function()
        if Rig == Finished and not Busy then ClearRig() end
    end)
end

local function NewState(Ped, UseCamera)
    return {
        Ped = Ped,
        UseCamera = UseCamera,
        Stage = 0,
        Phase = 0.0,
        LastPhase = -1.0,
        EnteredAt = GetGameTimer(),
        PhaseMovedAt = GetGameTimer(),
        Timeout = Settings.StepTimeoutMs,
        HeadingSince = 0,
        SceneStarted = false,
        SceneEnded = false,
        DoorOpened = false,
        DoorClosed = false,
        DoneReason = '',
        Done = false,
        Completed = false,
    }
end

local function ExpectedTimeout(Step)
    local Seconds = GetAnimDuration(Settings.Dicts[Step.Dict], Step.Clip)
    if not Seconds or Seconds <= 0.0 then return Settings.StepTimeoutMs end

    local Expected = Seconds * 1000.0 / (Step.Rate or 1.0)
    return math.max(Settings.StepTimeoutMs, Expected * Settings.TimeoutSlack)
end

local function Advance(State, To, NewPhase)
    local Step = Steps[To]
    NetScene.Debug('stage %d -> %d (%s) after %dms, phase %.3f %s', State.Stage, To, Step and Step.Name or 'done', GetGameTimer() - State.EnteredAt, State.Phase, State.DoneReason)

    State.Stage = To
    State.EnteredAt = GetGameTimer()
    State.PhaseMovedAt = GetGameTimer()
    State.LastPhase = -1.0
    State.SceneStarted = false
    State.SceneEnded = false
    State.DoneReason = ''
    State.Timeout = (Step and not Step.Looped) and ExpectedTimeout(Step) or Settings.StepTimeoutMs

    if NewPhase then State.Phase = NewPhase end
end

local function SceneReallyEnded(State)
    return State.SceneEnded and GetGameTimer() - State.EnteredAt > Settings.SceneEndGraceMs
end

local function StepDone(State)
    local Step = Steps[State.Stage]
    local Target = Step and Step.EndPhase or 1.0

    if State.Phase >= Target - Settings.PhaseEpsilon then
        State.DoneReason = Target < 1.0 and 'reached end phase' or 'complete'
        return true
    end

    if SceneReallyEnded(State) then
        State.DoneReason = 'scene ended'
        return true
    end

    if State.SceneStarted and GetGameTimer() - State.PhaseMovedAt > Settings.PhaseStallMs then
        State.DoneReason = 'phase stalled'
        return true
    end

    return false
end

local function TruckAndTrailerAligned(State)
    local Delta = math.abs(GetEntityHeading(Rig.Truck) - GetEntityHeading(Rig.Trailer))
    if Delta > 180.0 then Delta = 360.0 - Delta end

    if Delta >= Settings.HeadingTolerance then
        State.HeadingSince = 0
        return false
    end

    if State.HeadingSince == 0 then State.HeadingSince = GetGameTimer() end
    return GetGameTimer() - State.HeadingSince > Settings.HeadingHoldMs
end

local function BeginClimb(State)
    local Ped = State.Ped

    StopSynchronizedEntityAnim(Ped, -1000.0, true)
    ClearPedTasksImmediately(Ped)
    SetBlockingOfNonTemporaryEvents(Ped, true)

    if IsEntityAttached(Ped) then DetachEntity(Ped, true, true) end
    for _, Car in ipairs(Rig.Cars) do SetEntityNoCollisionEntity(Ped, Car, false) end

    if State.UseCamera then
        DestroyAllCams(true)
        Camera = CreateCam('DEFAULT_ANIMATED_CAMERA', true)
    end

    StartStep(1, Ped, State.Phase)
    ForcePedAiAndAnimationUpdate(Ped)
    PlayEntityAnim(Rig.Truck, 'ig_8_part_01_exit_door', Settings.Dicts.ig8, 8.0, false, false, false, 0.0, 0)

    if State.UseCamera then RenderScriptCams(true, false, 3000, true, false) end

    Advance(State, 1, 0.0)
end

local StageHandlers = {}

StageHandlers[0] = function(State)
    if IsVehicleAttachedToTrailer(Rig.Truck) then BeginClimb(State) end
end

StageHandlers[1] = function(State)
    if not State.DoorOpened and State.Phase >= 0.05 then
        PlayVehicleDoorOpenSound(Rig.Truck, 1)
        State.DoorOpened = true
    end

    if not State.DoorClosed and State.Phase >= 0.535 then
        PlayVehicleDoorCloseSound(Rig.Truck, 1)
        State.DoorClosed = true
    end

    if not StepDone(State) then return end

    StartStep(2, State.Ped, State.Phase)
    if Settings.SceneAudio then InitSynchSceneAudioWithEntity('CAR_5_IG_6', State.Ped) end
    Advance(State, 2, 0.0)
end

StageHandlers[2] = function(State)
    local Steady = TruckAndTrailerAligned(State)
    local Held = GetGameTimer() - State.EnteredAt > Settings.MinStepMs

    if Steady and Held and IsVehicleAttachedToTrailer(Rig.Truck) then
        StartStep(3, State.Ped, State.Phase)
        Advance(State, 3, 0.0)
    end
end

StageHandlers[3] = function(State)
    if State.Phase < 0.5 and not SceneReallyEnded(State) then return end

    StartStep(4, State.Ped, State.Phase)
    ForcePedAiAndAnimationUpdate(State.Ped)
    Advance(State, 4)
end

StageHandlers[4] = function(State)
    if not StepDone(State) then return end

    StartStep(5, State.Ped, State.Phase)
    Advance(State, 5, 0.0)
end

StageHandlers[5] = function(State)
    if not StepDone(State) then return end

    local Scene = StartStep(6, State.Ped, State.Phase)

    if DoesEntityExist(Rig.Target) then
        PlayEntityAnim(Rig.Target, CarClip, Settings.Dicts.ig6, 1000.0, false, false, false, 0.0, 0)
        ForceEntityAiAndAnimationUpdate(Rig.Target)
    end

    if Settings.SceneAudio then PlaySynchronizedAudioEvent(Scene) end
    Advance(State, 6, 0.0)
end

StageHandlers[6] = function(State)
    local Dict = Settings.Dicts.ig6

    if DoesEntityExist(Rig.Target) and IsEntityPlayingAnim(Rig.Target, Dict, CarClip, 3) then
        SetEntityAnimCurrentTime(Rig.Target, Dict, CarClip, State.Phase)
    end

    if not StepDone(State) then return end

    FinishPed(State.Ped)
    State.Completed = true
    State.Done = true
end

local function RigBroken(State)
    return not DoesEntityExist(Rig.Truck) or not DoesEntityExist(Rig.Trailer) or not DoesEntityExist(State.Ped) or IsPedInjured(State.Ped)
end

local function StageStalled(State)
    if GetGameTimer() - State.EnteredAt <= State.Timeout then return false end

    lib.print.warn(('TruckScene: stage %d stalled for %dms at phase %.3f'):format(State.Stage, State.Timeout, State.Phase))

    if State.Stage >= 3 then
        FinishPed(State.Ped)
        State.Completed = true
    else
        AbortPed(State.Ped)
    end
    return true
end

local function TrackPhase(State)
    if ActiveScene and IsSynchronizedSceneRunning(ActiveScene) then
        State.Phase = GetSynchronizedScenePhase(ActiveScene)
        State.SceneStarted = true
    elseif State.SceneStarted then
        State.SceneEnded = true
    end

    if math.abs(State.Phase - State.LastPhase) > 0.0005 then
        State.LastPhase = State.Phase
        State.PhaseMovedAt = GetGameTimer()
    end
end

local function Tick(State)
    if RigBroken(State) then return true end

    if math.abs(GetEntityRoll(Rig.Trailer)) > Settings.AbortRollDeg then
        AbortPed(State.Ped)
        return true
    end

    if StageStalled(State) then return true end

    TrackPhase(State)
    StageHandlers[State.Stage](State)
    return State.Done
end

local function PreparePed(Ped)
    SetPedCanRagdoll(Ped, false)

    if PlayerDriven then
        SetPlayerControl(PlayerId(), false, 0)
        DisplayRadar(false)
        return
    end

    SetPedMaxHealth(Ped, 1800)
    SetEntityHealth(Ped, 1800)
end

local function RunSequence(Ped, UseCamera)
    local State = NewState(Ped, UseCamera)
    ActiveScene = nil
    Active = true
    PreparePed(Ped)

    while Active do
        Wait(0)
        if Tick(State) then break end
    end

    if State.Completed and Settings.DropCarAtEnd then
        Wait(Settings.DropDelayMs)
        DropCar()
    end

    if DoesEntityExist(Ped) then SetPedCanRagdoll(Ped, true) end
    if PlayerDriven then RestorePlayer() end

    Active = false
    return State.Completed
end

local function SetupRig()
    ClearRig()
    if BuildRig() then return true end

    lib.print.error('TruckScene: could not build the rig, a model would not load')
    ClearRig()
    return false
end

local function SeatPed(IsPlayer)
    if not IsPlayer then return SpawnCrawler() end

    local Ped = cache.ped
    SetPedIntoVehicle(Ped, Rig.Truck, 0)
    SetPedCanBeDraggedOut(Ped, false)
    PlayerDriven = true
    return Ped
end

local function StillInTruck(Ped, IsPlayer)
    return not IsPlayer or IsPedInVehicle(Ped, Rig.Truck, false)
end

local function Run(IsPlayer, UseCamera)
    if not SetupRig() then return false end

    SpawnDriver()

    local Ped = SeatPed(IsPlayer)
    if not Ped then
        lib.print.error('TruckScene: could not spawn the crawler ped')
        ClearRig()
        return false
    end

    Wait(Settings.DriveWarmupMs)

    if not StillInTruck(Ped, IsPlayer) then
        ClearRig()
        return false
    end

    if not LoadDicts() then
        ClearRig()
        return false
    end

    return RunSequence(Ped, UseCamera)
end

local function TruckScene(Options, Cb)
    Options = Options or {}
    Cb = Cb or function() end
    if Busy then Cb(false) return false end

    Busy = true
    local Completed = Run(Options.Player ~= false, Options.Camera ~= false)
    Busy = false

    if Completed then
        DetachTargetFromRig()
        ScheduleCleanup()
    else
        ClearRig()
    end

    Cb(Completed)
    return Completed
end

exports('TruckScene', TruckScene)

exports('ClearTruckScene', function()
    ClearRig()
end)

AddEventHandler('onResourceStop', function(Resource)
    if Resource == GetCurrentResourceName() then ClearRig() end
end)

if Config.Debug then
    RegisterCommand('truckscene', function(_, Args)
        TruckScene({ Player = false, Camera = Args[1] ~= 'nocam' })
    end, false)

    RegisterCommand('truckscene_me', function(_, Args)
        TruckScene({ Player = true, Camera = Args[1] ~= 'nocam' })
    end, false)

    RegisterCommand('truckscene_clear', function()
        ClearRig()
        Busy = false
    end, false)
end
