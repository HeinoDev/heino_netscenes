local TakeChemicalScene = NetScene.Define('TakeChemical', {
    Dict = 'missfbi5ig_22',
    OriginOffset = vec3(-1.636963, 5.204346, -1.382074),
    Rotation = vec3(0.0, 0.0, 170.0),
    Stages = {
        Take = { Ped = 'take_chemical_player0', Tube = 'take_chemical_vial', Vial = 'take_chemical_tube' },
    },
})

local function TakeChemical(Tube, Vial, Cb, Options)
    Cb = Cb or function() end
    Options = Options or {}
    if not NetScene.ValidateTarget('TakeChemical', Tube) or not NetScene.ValidateTarget('TakeChemical', Vial) then Cb(false) return false end

    FreezeEntityPosition(Tube, false)
    FreezeEntityPosition(Vial, false)

    local Origin = GetEntityCoords(Tube) + (Options.Offset or TakeChemicalScene.OriginOffset)
    local Context = NetScene.New(TakeChemicalScene, Origin, Options.Rotation or TakeChemicalScene.Rotation, { Entities = { Tube = Tube, Vial = Vial } })

    local Completed = NetScene.PlayUntil(Context, 'Take', Options.ShouldAbort)

    NetScene.Finish(Context)
    Cb(Completed)
    return Completed
end

exports('TakeChemical', TakeChemical)
