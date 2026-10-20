local SafeDict = 'anim@scripted@heist@ig15_safe_crack@male@'

local SafeCrackScene = NetScene.Define('SafeCrack', {
    Dict = SafeDict,
    Models = { 'h4_prop_h4_safe_01b' },
    OpenedModel = 'h4_prop_h4_safe_01b',
    OriginOffset = vec3(0.0, 0.0, -0.05),
    Stages = {
        Enter = { Ped = 'enter_player', Target = 'enter_safe', Cam = 'enter_cam' },
        Idle = { Ped = 'idle_player', Target = 'idle_safe', Cam = 'idle_cam' },
        DoorOpen = { Ped = 'door_open_player', Target = 'door_open_safe', Cam = 'door_open_cam' },
    },
})

local StrongboxScene = NetScene.Define('CrackStrongbox', {
    Dict = SafeDict,
    Props = { Bag = NetScene.Bag },
    Stages = {
        Enter = { Ped = 'enter_player', Bag = 'enter_bag', Target = 'enter_safe' },
        Idle = { Ped = 'idle_player', Bag = 'idle_bag', Target = 'idle_safe' },
        DoorOpen = { Ped = 'door_open_player', Bag = 'door_open_bag', Target = 'door_open_safe' },
        Loot = { Ped = 'success_with_metal_cylinder_player', Bag = 'success_with_metal_cylinder_bag', Target = 'success_with_metal_cylinder_safe' },
        Exit = { Ped = 'exit_player', Bag = 'exit_bag', Target = 'exit_safe' },
    },
})

local function SafeCrackMinigame(Locks, Positions)
    return function(Settle)
        if GetResourceState('st_minigames') ~= 'started' then
            lib.print.error('st_minigames is not started')
            return Settle(false)
        end

        exports['st_minigames']:SafeCrack(true, Locks, function(HasWon)
            Settle(HasWon == true)
        end, Positions)
    end
end

local function SafeCrack(Entity, Locks, Cb, CreateCam, Positions, Options)
    Cb = Cb or function() end
    Options = Options or {}
    if not NetScene.ValidateTarget('SafeCrack', Entity) then Cb(false) return false end

    local Origin = GetEntityCoords(Entity) + (Options.OriginOffset or SafeCrackScene.OriginOffset)
    local Context = NetScene.New(SafeCrackScene, Origin, GetEntityRotation(Entity), { Target = Entity, Camera = CreateCam })

    NetScene.Play(Context, 'Enter')
    NetScene.Start(Context, 'Idle', { Looped = true })
    local Cracked = NetScene.RunMinigame(Options.Minigame or SafeCrackMinigame(Locks, Positions))

    local OpenedSafe
    if Cracked then
        NetScene.Play(Context, 'DoorOpen')
        if not Options.KeepEntity then
            OpenedSafe = NetScene.ReplaceEntity(Entity, Options.OpenedModel or SafeCrackScene.OpenedModel)
        end
    end

    NetScene.Finish(Context)
    Cb(Cracked, OpenedSafe)
    return Cracked, OpenedSafe
end

exports('SafeCrack', SafeCrack)

local function CrackStrongbox(Entity, Cb, Options)
    Cb = Cb or function() end
    Options = Options or {}
    if not NetScene.ValidateTarget('CrackStrongbox', Entity) then Cb(false) return false end

    local RestoreBag = NetScene.HidePedBag()
    local Context = NetScene.New(StrongboxScene, GetEntityCoords(Entity), GetEntityRotation(Entity), { Target = Entity })

    NetScene.Play(Context, 'Enter')
    NetScene.Start(Context, 'Idle', { Looped = true })
    local Cracked = NetScene.RunMinigame(Options.Minigame or SafeCrackMinigame(Options.Locks or 3, Options.Positions))

    if Cracked then
        NetScene.Play(Context, 'DoorOpen')
        NetScene.Play(Context, 'Loot')
    end
    NetScene.Play(Context, 'Exit')

    NetScene.Finish(Context)
    RestoreBag()
    Cb(Cracked)
    return Cracked
end

exports('CrackStrongbox', CrackStrongbox)
