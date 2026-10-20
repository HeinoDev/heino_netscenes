local DumpsterScene = NetScene.Define('GrabDumpster', {
    Dict = 'heino_dumpster',
    OriginOffset = vec3(0.0, -0.95, 0.0),
    RootHeight = 1.0,
    GrabAt = 0.5,
    EntityClip = 'prop_dumpster_01a_1',
    ExtraClips = { 'prop_dumpster_01a_1' },
    Stages = {
        Grab = { Ped = 'ped_dumpster_01a_1' },
    },
})

local function SceneOrigin(Entity)
    local Offset = DumpsterScene.OriginOffset
    local Spot = GetOffsetFromEntityInWorldCoords(Entity, Offset.x, Offset.y, Offset.z)
    local Found, GroundZ = GetGroundZFor_3dCoord(Spot.x, Spot.y, Spot.z + 2.0, false)
    local Base = Found and GroundZ or Spot.z

    return vec3(Spot.x, Spot.y, Base + DumpsterScene.RootHeight)
end

local function PlayDumpsterClip(Entity, Dict)
    PlayEntityAnim(Entity, DumpsterScene.EntityClip, Dict, 1000.0, false, true, true, 0, 136704)
end

local function GrabDumpster(Entity, Cb)
    Cb = Cb or function() end
    if not NetScene.ValidateTarget('GrabDumpster', Entity) then Cb(false) return false end

    local Origin = SceneOrigin(Entity)
    local Rotation = vec3(0.0, 0.0, GetEntityHeading(Entity))
    local Context = NetScene.New(DumpsterScene, Origin, Rotation, { Target = Entity })

    local StartedAt = GetGameTimer()
    local Duration = NetScene.Start(Context, 'Grab')
    PlayDumpsterClip(Entity, Context.Dict)

    NetScene.WaitRemaining(StartedAt, math.floor(Duration * DumpsterScene.GrabAt))
    Cb(true)
    NetScene.WaitRemaining(StartedAt, Duration)

    NetScene.Finish(Context)
    return true
end

exports('GrabDumpster', GrabDumpster)
