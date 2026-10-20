local DumpsterScene = NetScene.Define('GrabDumpster', {
    Dict = 'heino_dumpster',
    OriginOffset = vec3(0.0, -0.95, 0.0),
    GrabAt = 0.5,
    Stages = {
        Grab = { Ped = 'ped_dumpster_01a_1', Target = 'prop_dumpster_01a_1' },
    },
})

local function GrabDumpster(Entity, Cb)
    Cb = Cb or function() end
    if not NetScene.ValidateTarget('GrabDumpster', Entity) then Cb(false) return false end

    local Offset = DumpsterScene.OriginOffset
    local Origin = GetOffsetFromEntityInWorldCoords(Entity, Offset.x, Offset.y, Offset.z)
    local Context = NetScene.New(DumpsterScene, Origin, GetEntityRotation(Entity), { Target = Entity })

    local StartedAt = GetGameTimer()
    local Duration = NetScene.Start(Context, 'Grab')

    NetScene.WaitRemaining(StartedAt, math.floor(Duration * DumpsterScene.GrabAt))
    Cb(true)
    NetScene.WaitRemaining(StartedAt, Duration)

    NetScene.Finish(Context)
    return true
end

exports('GrabDumpster', GrabDumpster)
