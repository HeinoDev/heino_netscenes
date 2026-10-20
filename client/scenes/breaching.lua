local ThermiteHandBone = 28422
local DrillHandBone = 57005
local VaultBomb = 'ch_prop_ch_explosive_01a'
local ExplosionStickybomb = 2

local ThermiteScene = NetScene.Define('Thermite', {
    Dict = 'anim@heists@ornate_bank@thermal_charge',
    Props = { Bag = NetScene.Bag },
    Models = { 'hei_prop_heist_thermite' },
    ChargeModel = 'hei_prop_heist_thermite',
    Speed = 1.3,
    Burn = { Asset = 'scr_ornate_heist', Name = 'scr_heist_ornate_thermal_burn' },
    AttachAt = 1500,
    PlacedAt = 5500,
    ExtraClips = { 'cover_eyes_intro', 'cover_eyes_loop' },
    Stages = {
        Plant = { Ped = 'thermal_charge', Bag = 'bag_thermal_charge' },
    },
})

local function VaultBombDefinition(Side)
    return {
        Dict = ('anim_heist@hs3f@ig8_vault_explosives@%s@male@'):format(Side),
        Props = { Bag = NetScene.Bag, ChargeA = VaultBomb, ChargeC = VaultBomb },
        ChargeB = { Model = VaultBomb, Clip = 'semtex_b_ig8_vault_explosive', HoldAt = 5350 },
        ExtraClips = { 'semtex_b_ig8_vault_explosive' },
        Stages = {
            Plant = { Ped = 'player_ig8_vault_explosive', Bag = 'bag_ig8_vault_explosive', ChargeA = 'semtex_a_ig8_vault_explosive', ChargeC = 'semtex_c_ig8_vault_explosive' },
        },
    }
end

local VaultBombScenes = {
    right = NetScene.Define('VaultBombsRight', VaultBombDefinition('right')),
    left = NetScene.Define('VaultBombsLeft', VaultBombDefinition('left')),
}

local ChargeScene = NetScene.Define('PlantCharge', {
    Dict = 'anim_heist@hs3f@ig13_thermal_charge@thermal_charge@male@',
    Props = { Bag = NetScene.Bag },
    Models = { 'prop_bomb_01' },
    ChargeModel = 'prop_bomb_01',
    Stages = {
        Plant = { Ped = 'thermal_charge_male_male', Charge = 'thermal_charge_male_hei_prop_heist_thermite', Bag = 'thermal_charge_male_p_m_bag_var22_arm_s' },
    },
})

local DrillScene = NetScene.Define('Drill', {
    Dict = 'anim@heists@fleeca_bank@drilling',
    Props = { Drill = 'hei_prop_heist_drill' },
    HandOffset = { Position = vec3(0.14, 0.0, -0.01), Rotation = vec3(90.0, -90.0, 180.0) },
    Sparks = { Asset = 'scr_tn_tr', Name = 'scr_tn_tr_angle_grinder_sparks', Offset = vec3(0.0, 0.3, 0.0) },
    Sound = { Name = 'Drill', Set = 'DLC_HEIST_FLEECA_SOUNDSET', Banks = { 'DLC_HEIST_FLEECA_DRILL', 'DLC_HEIST_FLEECA_DRILL_2' } },
    Stages = {
        Start = { Ped = 'drill_straight_start' },
        Idle = { Ped = 'drill_straight_idle' },
        End = { Ped = 'drill_straight_end' },
        Fail = { Ped = 'drill_straight_fail' },
    },
})

local function VaultDrillStages()
    return {
        Intro = { Ped = 'intro', Bag = 'bag_intro', Drill = 'intro_drill_bit' },
        Start = { Ped = 'drill_straight_start', Bag = 'bag_drill_straight_start', Drill = 'drill_straight_start_drill_bit' },
        Idle = { Ped = 'drill_straight_idle', Bag = 'bag_drill_straight_idle', Drill = 'drill_straight_idle_drill_bit' },
        End = { Ped = 'drill_straight_end', Bag = 'bag_drill_straight_end', Drill = 'drill_straight_end_drill_bit' },
        Fail = { Ped = 'drill_straight_fail', Bag = 'bag_drill_straight_fail', Drill = 'drill_straight_fail_drill_bit' },
        Exit = { Ped = 'exit', Bag = 'bag_exit', Drill = 'exit_drill_bit' },
    }
end

local VaultDrillScenes = {
    laser = NetScene.Define('LaserDrill', {
        Dict = 'anim_heist@hs3f@ig9_vault_drill@laser_drill@',
        Props = { Bag = NetScene.Bag, Drill = 'ch_prop_laserdrill_01a' },
        Stages = VaultDrillStages(),
    }),
    vault = NetScene.Define('VaultDrill', {
        Dict = 'anim_heist@hs3f@ig9_vault_drill@drill@',
        Props = { Bag = NetScene.Bag, Drill = 'ch_prop_vault_drill_01a' },
        Stages = VaultDrillStages(),
    }),
}

local function CapturePlacement(Entity)
    local Coords = GetEntityCoords(Entity)
    local Rotation = GetEntityRotation(Entity, 2)

    return function()
        SetEntityCoordsNoOffset(Entity, Coords.x, Coords.y, Coords.z, false, false, false)
        SetEntityRotation(Entity, Rotation.x, Rotation.y, Rotation.z, 2, false)
        FreezeEntityPosition(Entity, true)
    end
end

local function PlantThermite()
    local Ped = cache.ped
    local Context = NetScene.New(ThermiteScene, GetEntityCoords(Ped), GetEntityRotation(Ped))

    local StartedAt = GetGameTimer()
    NetScene.Start(Context, 'Plant')
    NetScene.WaitRemaining(StartedAt, ThermiteScene.AttachAt)

    local Charge = NetScene.CreateProp(ThermiteScene.ChargeModel, GetEntityCoords(Ped) + vec3(0.0, 0.0, 0.2))
    AttachEntityToEntity(Charge, Ped, GetPedBoneIndex(Ped, ThermiteHandBone), 0.0, 0.0, 0.0, 0.0, 0.0, 200.0, true, true, false, true, 1, true)
    NetScene.WaitRemaining(StartedAt, ThermiteScene.PlacedAt)

    DetachEntity(Charge, true, true)
    FreezeEntityPosition(Charge, true)
    Wait(100)

    NetScene.Finish(Context)
    ClearPedTasks(Ped)
    return Charge
end

local function BurnThermite(Charge, Options)
    local Ped = cache.ped
    local Dict = NetScene.ResolveDict(ThermiteScene)
    lib.requestAnimDict(Dict)

    local Burn = ThermiteScene.Burn
    local StopBurn = NetScene.StartLoopedPtfxOnEntity({ Asset = Burn.Asset, Name = Burn.Name, Offset = Options.EffectOffset }, Charge)

    TaskPlayAnim(Ped, Dict, 'cover_eyes_intro', 8.0, 8.0, 1000, 36, 1.0, false, false, false)
    Wait(1000)
    TaskPlayAnim(Ped, Dict, 'cover_eyes_loop', 8.0, 8.0, -1, 49, 1.0, false, false, false)

    if type(Options.OnBurnStart) == 'function' then Options.OnBurnStart(Charge) end
    Wait(Options.BurnTime or 10000)

    StopBurn()
    if type(Options.OnBurnEnd) == 'function' then Options.OnBurnEnd(Charge) end
    StopAnimTask(Ped, Dict, 'cover_eyes_loop', 1.0)
    DeleteEntity(Charge)
    RemoveAnimDict(Dict)
end

local function MovePedToEntity(Entity, Offset)
    local Coords = GetOffsetFromEntityInWorldCoords(Entity, Offset.x, Offset.y, Offset.z)
    NetScene.MovePed(Coords)
    NetScene.FaceEntity(Entity)
end

local function PlacePedForThermite(Options)
    if Options.Entity and DoesEntityExist(Options.Entity) then
        return MovePedToEntity(Options.Entity, Options.PedOffset or vec3(0.0, -0.6, 0.0))
    end
    if Options.Coords then NetScene.MovePed(Options.Coords) end
end

local function Thermite(Options, Cb)
    Options = Options or {}
    Cb = Cb or function() end

    if not NetScene.RunMinigame(Options.Minigame) then Cb(false) return false end
    PlacePedForThermite(Options)

    local Charge = PlantThermite()
    BurnThermite(Charge, Options)
    SetModelAsNoLongerNeeded(joaat(ThermiteScene.ChargeModel))

    Cb(true)
    return true
end

exports('Thermite', Thermite)

local function StartSingleEntityScene(Context, Entity, Clip)
    local Origin, Rotation = Context.Origin, Context.Rotation
    local Scene = NetworkCreateSynchronisedScene(Origin.x, Origin.y, Origin.z, Rotation.x, Rotation.y, Rotation.z, 2, true, false, -1, 0.0, 1.0)
    NetworkAddEntityToSynchronisedScene(Entity, Scene, Context.Dict, Clip, 1.0, 1.0, 1)
    NetworkStartSynchronisedScene(Scene)
    return Scene
end

local function VaultBombOrigin(Definition, Coords)
    if Coords then return NetScene.OriginFromCoords(Coords) end
    return NetScene.AnchorToPed(NetScene.ResolveDict(Definition), Definition.Stages.Plant.Ped)
end

local function PlantVaultBombs(Coords, Cb, Options)
    Cb = Cb or function() end
    Options = Options or {}

    local Definition = VaultBombScenes[Options.Side or 'right'] or VaultBombScenes.right
    local Origin, Rotation = VaultBombOrigin(Definition, Coords)
    local Context = NetScene.New(Definition, Origin, Rotation)
    local ChargeB = NetScene.CreateProp(Definition.ChargeB.Model, Origin)

    local StartedAt = GetGameTimer()
    local Duration = NetScene.Start(Context, 'Plant')
    local ChargeSceneId = StartSingleEntityScene(Context, ChargeB, Definition.ChargeB.Clip)

    NetScene.WaitRemaining(StartedAt, Definition.ChargeB.HoldAt)
    local PlaceChargeB = CapturePlacement(ChargeB)
    NetworkStopSynchronisedScene(ChargeSceneId)
    PlaceChargeB()

    NetScene.WaitRemaining(StartedAt, Duration)

    local ChargeA, ChargeC = NetScene.Release(Context, 'ChargeA'), NetScene.Release(Context, 'ChargeC')
    local PlaceChargeA, PlaceChargeC = CapturePlacement(ChargeA), CapturePlacement(ChargeC)
    NetScene.Finish(Context)
    PlaceChargeA()
    PlaceChargeC()

    local Charges = { ChargeA, ChargeB, ChargeC }
    Cb(true, Charges)
    return true, Charges
end

exports('PlantVaultBombs', PlantVaultBombs)

local function DetonateVaultBombs(Charges, Options)
    Options = Options or {}

    for _, Charge in ipairs(Charges or {}) do
        if DoesEntityExist(Charge) then
            local Coords = GetEntityCoords(Charge)
            NetScene.DeleteOwnedEntity(Charge)
            AddExplosion(Coords.x, Coords.y, Coords.z, Options.ExplosionType or ExplosionStickybomb, Options.Damage or 0.0, true, false, Options.Shake or 1.0)
        end
    end
end

exports('DetonateVaultBombs', DetonateVaultBombs)
exports('DetonateCharges', DetonateVaultBombs)

local function ChargeOrigin(Coords)
    if Coords then return NetScene.OriginFromCoords(Coords) end
    return NetScene.AnchorToPed(NetScene.ResolveDict(ChargeScene), ChargeScene.Stages.Plant.Ped)
end

local function PlantCharge(Coords, Cb, Options)
    Cb = Cb or function() end
    Options = Options or {}

    local Origin, Rotation = ChargeOrigin(Coords)
    local ChargeModel = Options.ChargeModel or ChargeScene.ChargeModel
    local Charge = NetScene.CreateProp(ChargeModel, Origin)
    local Context = NetScene.New(ChargeScene, Origin, Rotation, { Entities = { Charge = Charge } })

    NetScene.Play(Context, 'Plant')

    local PlaceCharge = CapturePlacement(Charge)
    NetScene.Finish(Context)
    PlaceCharge()
    SetModelAsNoLongerNeeded(joaat(ChargeModel))

    Cb(true, Charge)
    return true, Charge
end

exports('PlantCharge', PlantCharge)

local function AttachDrillToHand(Drill, Offset)
    local Ped = cache.ped
    local Position, Rotation = Offset.Position, Offset.Rotation
    AttachEntityToEntity(Drill, Ped, GetPedBoneIndex(Ped, DrillHandBone), Position.x, Position.y, Position.z, Rotation.x, Rotation.y, Rotation.z, true, true, false, true, 1, true)
end

local function StartDrillEffects(Drill)
    local Sound = DrillScene.Sound
    for _, Bank in ipairs(Sound.Banks) do RequestAmbientAudioBank(Bank, false) end

    local SoundId = GetSoundId()
    PlaySoundFromEntity(SoundId, Sound.Name, Drill, Sound.Set, true, 0)
    local StopSparks = NetScene.StartLoopedPtfxOnEntity(DrillScene.Sparks, Drill)

    return function()
        StopSound(SoundId)
        ReleaseSoundId(SoundId)
        StopSparks()
        ReleaseAmbientAudioBank()
    end
end

local function DrillBroke(Success, Options)
    if not Success then return false end
    return math.random(1, 100) <= (Options.BreakChance or 0)
end

local function DrillReason(Broke)
    if Broke then return 'broken' end
end

local function Drill(Cb, Options)
    Cb = Cb or function() end
    Options = Options or {}
    if Options.Coords then NetScene.MovePed(Options.Coords) end

    local Origin, Rotation = NetScene.AnchorToPed(NetScene.ResolveDict(DrillScene), DrillScene.Stages.Start.Ped)
    local Context = NetScene.New(DrillScene, Origin, Rotation)
    AttachDrillToHand(Context.Props.Drill, DrillScene.HandOffset)

    NetScene.Play(Context, 'Start')
    NetScene.Start(Context, 'Idle', { Looped = true })
    local StopEffects = StartDrillEffects(Context.Props.Drill)
    local Success = NetScene.RunTimedMinigame(Options.Minigame, Options.DrillTime or 10000)
    StopEffects()
    local Broke = DrillBroke(Success, Options)
    Success = Success and not Broke
    NetScene.Play(Context, Success and 'End' or 'Fail')

    NetScene.Finish(Context)
    Cb(Success, DrillReason(Broke))
    return Success, DrillReason(Broke)
end

exports('Drill', Drill)

local function VaultDrillOrigin(Definition, Coords)
    if Coords then return NetScene.OriginFromCoords(Coords) end
    return NetScene.AnchorToPed(NetScene.ResolveDict(Definition), Definition.Stages.Intro.Ped)
end

local function VaultDrill(Coords, Cb, Options)
    Cb = Cb or function() end
    Options = Options or {}

    local Definition = VaultDrillScenes[Options.Variant or 'laser'] or VaultDrillScenes.laser
    local Origin, Rotation = VaultDrillOrigin(Definition, Coords)
    local Context = NetScene.New(Definition, Origin, Rotation)

    NetScene.Play(Context, 'Intro')
    NetScene.Play(Context, 'Start')
    NetScene.Start(Context, 'Idle', { Looped = true })
    local Success = NetScene.RunTimedMinigame(Options.Minigame, Options.DrillTime or 10000)
    local Broke = DrillBroke(Success, Options)
    Success = Success and not Broke
    NetScene.Play(Context, Success and 'End' or 'Fail')
    NetScene.Play(Context, 'Exit')

    NetScene.Finish(Context)
    Cb(Success, DrillReason(Broke))
    return Success, DrillReason(Broke)
end

exports('VaultDrill', VaultDrill)
