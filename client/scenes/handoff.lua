local Settings = NetScene.Config.HandOff

local HandOffScene = NetScene.Define('HandOff', {
    Dict = Settings.Dict,
    Stages = {
        Exchange = { Ped = Settings.GiverClip, Target = Settings.TakerClip },
    },
})

local function PropSpec(Prop)
    if not Prop then return nil end
    if type(Prop) ~= 'table' then return { Model = Prop } end
    return Prop
end

local function AttachToHand(Prop, Ped, Spec)
    local Offset = Spec.Offset or Settings.Offset
    local Rotation = Spec.Rotation or Settings.Rotation
    DetachEntity(Prop, false, false)
    AttachEntityToEntity(Prop, Ped, GetPedBoneIndex(Ped, Spec.Bone or Settings.Bone), Offset.x, Offset.y, Offset.z, Rotation.x, Rotation.y, Rotation.z, true, true, false, true, 1, true)
end

local function CreateHandProp(Spec, Ped)
    if not Spec then return nil end
    local Prop = NetScene.CreateProp(Spec.Model, GetEntityCoords(Ped))
    AttachToHand(Prop, Ped, Spec)
    return Prop
end

local function DeleteHandProp(Prop, Spec)
    if not Prop then return end
    if DoesEntityExist(Prop) then DeleteEntity(Prop) end
    SetModelAsNoLongerNeeded(joaat(Spec.Model))
end

local function EitherDead(Ped, Target)
    return IsPedDeadOrDying(Ped, true) or IsPedDeadOrDying(Target, true)
end

local function WalkTargetInFront(Ped, Target)
    local Spot = GetOffsetFromEntityInWorldCoords(Ped, 0.0, Settings.Distance, 0.0)
    if #(GetEntityCoords(Target) - Spot) < 0.3 then return end

    TaskGoStraightToCoord(Target, Spot.x, Spot.y, Spot.z, 1.0, Settings.WalkTimeout, GetEntityHeading(Ped) + 180.0, 0.1)
    local Deadline = GetGameTimer() + Settings.WalkTimeout
    while #(GetEntityCoords(Target) - Spot) > 0.4 and GetGameTimer() < Deadline do
        if EitherDead(Ped, Target) then return end
        Wait(100)
    end
end

local function FaceEachOther(Ped, Target)
    ClearPedTasks(Target)
    NetScene.FaceEntity(Target, Ped)
    NetScene.FaceEntity(Ped, Target)
end

local function PlayExchange(Ped, Target, Dict)
    TaskPlayAnim(Ped, Dict, Settings.GiverClip, 8.0, -8.0, -1, 0, 0.0, false, false, false)
    TaskPlayAnim(Target, Dict, Settings.TakerClip, 8.0, -8.0, -1, 0, 0.0, false, false, false)
end

local function WaitForAnimTime(Ped, Dict, Clip, Time, Target)
    local Deadline = GetGameTimer() + NetScene.ClipDuration(Dict, Clip) + 1000
    while GetGameTimer() < Deadline do
        if EitherDead(Ped, Target) then return false end
        if IsEntityPlayingAnim(Ped, Dict, Clip, 3) and GetEntityAnimCurrentTime(Ped, Dict, Clip) >= Time then return true end
        Wait(0)
    end
    return false
end

local function WaitForAnimEnd(Ped, Dict, Clip, Target)
    local Deadline = GetGameTimer() + NetScene.ClipDuration(Dict, Clip) + 1000
    while GetGameTimer() < Deadline and IsEntityPlayingAnim(Ped, Dict, Clip, 3) do
        if EitherDead(Ped, Target) then return false end
        if GetEntityAnimCurrentTime(Ped, Dict, Clip) >= 0.95 then return true end
        Wait(0)
    end
    return not EitherDead(Ped, Target)
end

local function SwapProps(Ped, Target, Give, Take, GiveSpec, TakeSpec)
    if Give then AttachToHand(Give, Target, GiveSpec) end
    if Take then AttachToHand(Take, Ped, TakeSpec) end
end

local function ValidatePeds(Ped, Target)
    if not DoesEntityExist(Ped) then return false end
    if Ped ~= cache.ped and NetworkGetEntityIsNetworked(Ped) and not NetScene.RequestControl(Ped) then return false end
    if not NetScene.ValidateTarget('HandOff', Target) then return false end
    if #(GetEntityCoords(Ped) - GetEntityCoords(Target)) > Settings.MaxDistance then
        NetScene.Unclaim(Target)
        return false
    end
    return true
end

local function HandOff(Ped, Target, Props, Options)
    Ped = Ped or cache.ped
    Props = Props or {}
    Options = Options or {}
    if not ValidatePeds(Ped, Target) then return false end

    local Dict = NetScene.ResolveDict(HandOffScene)
    lib.requestAnimDict(Dict)

    WalkTargetInFront(Ped, Target)
    FaceEachOther(Ped, Target)

    local GiveSpec, TakeSpec = PropSpec(Props.Give), PropSpec(Props.Take)
    local Give = CreateHandProp(GiveSpec, Ped)
    local Take = CreateHandProp(TakeSpec, Target)

    PlayExchange(Ped, Target, Dict)
    local Swapped = WaitForAnimTime(Ped, Dict, Settings.GiverClip, Options.SwapPhase or Settings.SwapPhase, Target)
    if Swapped then
        SwapProps(Ped, Target, Give, Take, GiveSpec, TakeSpec)
        if type(Options.OnSwap) == 'function' then Options.OnSwap() end
    end

    local Completed = Swapped and WaitForAnimEnd(Ped, Dict, Settings.GiverClip, Target)

    DeleteHandProp(Give, GiveSpec)
    DeleteHandProp(Take, TakeSpec)
    StopAnimTask(Ped, Dict, Settings.GiverClip, 1.0)
    StopAnimTask(Target, Dict, Settings.TakerClip, 1.0)
    RemoveAnimDict(Dict)
    NetScene.Unclaim(Target)

    return Swapped and Completed or false
end

exports('HandOff', HandOff)
