local ContainerScene = NetScene.Define('OpenContainer', {
    Dict = 'anim@scripted@player@mission@tunf_train_ig1_container_p1@male@',
    Props = { Bag = NetScene.Bag, Grinder = 'tr_prop_tr_grinder_01a', Lock = 'tr_prop_tr_lock_01a' },
    OriginOffset = vec3(0.0, 0.0, -0.05),
    Sparks = { Asset = 'scr_tn_tr', Name = 'scr_tn_tr_angle_grinder_sparks', Offset = vec3(0.0, 0.25, 0.0), StartAt = 4000, Duration = 1000 },
    OpenedAt = 7000,
    Stages = {
        Action = { Ped = 'action', Bag = 'action_bag', Grinder = 'action_angle_grinder', Lock = 'action_lock', Target = 'action_container' },
    },
})

local CrateScene = NetScene.Define('OpenCrate', {
    Dict = 'anim@scripted@player@mission@trn_ig2_empty@male@',
    Props = { Crowbar = 'w_me_crowbar' },
    OriginOffset = vec3(0.0, 0.0, -0.05),
    OpenedAt = 5000,
    Stages = {
        Empty = { Ped = 'empty', Crowbar = 'empty_crowbar', Target = 'empty_crate' },
    },
})

local LootCrateScene = NetScene.Define('LootCrate', {
    Dict = 'anim@scripted@player@mission@trn_ig2_loot@male@',
    Props = { Crowbar = 'w_me_crowbar' },
    OriginOffset = vec3(0.0, 0.0, -0.05),
    Stages = {
        Loot = { Ped = 'loot', Crowbar = 'loot_crowbar', Target = 'loot_crate' },
    },
})

local function PlayGrinderSparks(Grinder, Sparks)
    Wait(Sparks.StartAt)
    local Stop = NetScene.StartLoopedPtfxOnEntity(Sparks, Grinder)
    Wait(Sparks.Duration)
    Stop()
end

local function OpenContainer(Entity, Cb)
    Cb = Cb or function() end
    if not NetScene.ValidateTarget('OpenContainer', Entity) then return false end

    local Origin = GetEntityCoords(Entity) + ContainerScene.OriginOffset
    local Context = NetScene.New(ContainerScene, Origin, GetEntityRotation(Entity), { Target = Entity })

    local StartedAt = GetGameTimer()
    local Duration = NetScene.Start(Context, 'Action')
    PlayGrinderSparks(Context.Props.Grinder, ContainerScene.Sparks)

    NetScene.WaitRemaining(StartedAt, ContainerScene.OpenedAt)
    Cb()
    NetScene.WaitRemaining(StartedAt, Duration)

    NetScene.Finish(Context)
    SetEntityCollision(Entity, false, true)
    return true
end

exports('OpenContainer', OpenContainer)

local function OpenCrate(Entity, Cb)
    Cb = Cb or function() end
    if not NetScene.ValidateTarget('OpenCrate', Entity) then return false end

    local Origin = GetEntityCoords(Entity) + CrateScene.OriginOffset
    local Context = NetScene.New(CrateScene, Origin, GetEntityRotation(Entity), { Target = Entity })

    local StartedAt = GetGameTimer()
    local Duration = NetScene.Start(Context, 'Empty')

    NetScene.WaitRemaining(StartedAt, CrateScene.OpenedAt)
    Cb()
    NetScene.WaitRemaining(StartedAt, Duration)

    NetScene.Finish(Context)
    return true
end

exports('OpenCrate', OpenCrate)

local function LootCrate(Entity, Cb)
    Cb = Cb or function() end
    if not NetScene.ValidateTarget('LootCrate', Entity) then Cb(false) return false end

    local Origin = GetEntityCoords(Entity) + LootCrateScene.OriginOffset
    local Context = NetScene.New(LootCrateScene, Origin, GetEntityRotation(Entity), { Target = Entity })

    NetScene.Play(Context, 'Loot')

    NetScene.Finish(Context)
    Cb(true)
    return true
end

exports('LootCrate', LootCrate)
