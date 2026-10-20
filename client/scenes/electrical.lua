local ElectricBoxScene = NetScene.Define('ElectricBox', {
    Dict = 'anim@scripted@player@mission@tun_control_tower@male@',
    Stages = {
        Enter = { Ped = 'enter', Target = 'enter_electric_box' },
        Idle = { Ped = 'loop', Target = 'loop_electric_box' },
        Exit = { Ped = 'exit', Target = 'exit_electric_box' },
    },
})

local function RandomKey(Entries)
    if type(Entries) ~= 'table' then return nil end

    local Keys = {}
    for Key in pairs(Entries) do Keys[#Keys + 1] = Key end
    if #Keys == 0 then return nil end

    return Keys[math.random(#Keys)]
end

local function HeinoMinigame(Minigame, Seconds, Durations)
    return function()
        if GetResourceState('heino_minigames') ~= 'started' then
            lib.print.error('heino_minigames is not started')
            return false
        end

        return exports['heino_minigames']:Play({
            minigame = Minigame or RandomKey(Durations),
            seconds = tonumber(Seconds),
            durations = Durations,
        })
    end
end

local function ElectricBox(Entity, Cb, Time, Minigame, Durations, AfterWin)
    Cb = Cb or function() end
    if not NetScene.ValidateTarget('ElectricBox', Entity) then Cb(false) return false end

    local Context = NetScene.New(ElectricBoxScene, GetEntityCoords(Entity), GetEntityRotation(Entity), { Target = Entity })

    NetScene.Play(Context, 'Enter')
    NetScene.Start(Context, 'Idle', { Looped = true })

    local Game = type(Minigame) == 'function' and Minigame or HeinoMinigame(Minigame, Time, Durations)
    local HasWon, Result = NetScene.RunMinigame(Game)
    if HasWon and type(AfterWin) == 'function' then
        HasWon = AfterWin() and true or false
    end

    NetScene.Play(Context, 'Exit')
    NetScene.Finish(Context)
    Cb(HasWon, Result)
    return HasWon, Result
end

exports('ElectricBox', ElectricBox)
exports('EletricBox', ElectricBox)
