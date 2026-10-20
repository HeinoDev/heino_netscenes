local PedHackOffset = vec3(0.075, 0.84, 0.35)

local HackUsbScene = NetScene.Define('HackUSB', {
    Dict = 'anim@scripted@player@mission@tunf_hack_keypad@male@',
    Props = { Phone = 'prop_npc_phone', Usb = 'tr_prop_tr_usb_drive_01a' },
    Stages = {
        Action = { Ped = 'action', Phone = 'action_phone', Usb = 'action_usb_drive' },
        Loop = { Ped = 'hack_loop', Phone = 'hack_loop_phone', Usb = 'hack_loop_usb_drive' },
        Exit = { Ped = 'exit', Phone = 'exit_phone', Usb = 'exit_usb_drive' },
    },
})

local HackPhoneScene = NetScene.Define('HackPhone', {
    Dict = 'anim_heist@hs3f@ig1_hack_keypad@arcade@male@',
    Props = { Phone = 'prop_phone_ing' },
    Stages = {
        Loop = { Ped = 'hack_loop_var_01', Phone = 'hack_loop_var_01_prop_phone_ing' },
        Success = { Ped = 'success_react_exit_var_01', Phone = 'success_react_exit_var_01_prop_phone_ing' },
        Fail = { Ped = 'fail_react', Phone = 'fail_react_prop_phone_ing' },
    },
})

local HackLaptopScene = NetScene.Define('HackLaptop', {
    Dict = 'anim@heists@ornate_bank@hack',
    Props = { Bag = NetScene.Bag, Laptop = 'hei_prop_hst_laptop', Card = 'hei_prop_heist_card_hack_02' },
    Speed = 1.3,
    Stages = {
        Enter = { Ped = 'hack_enter', Bag = 'hack_enter_bag', Laptop = 'hack_enter_laptop', Card = 'hack_enter_card' },
        Loop = { Ped = 'hack_loop', Bag = 'hack_loop_bag', Laptop = 'hack_loop_laptop', Card = 'hack_loop_card' },
        Exit = { Ped = 'hack_exit', Bag = 'hack_exit_bag', Laptop = 'hack_exit_laptop', Card = 'hack_exit_card' },
    },
})

local CardSwipeScene = NetScene.Define('CardSwipe', {
    Dict = 'anim_heist@hs3f@ig3_cardswipe@female@',
    Props = { Card = 'p_ld_id_card_002' },
    SwipeAt = 2000,
    DropAt = 3800,
    Stages = {
        Success = { Ped = 'success_var01', Card = 'success_var01_card' },
        Drop = { Ped = 'drop_card_success_var02', Card = 'drop_card_success_var02_card' },
    },
})

local function PedHackOrigin()
    local Ped = cache.ped
    return GetOffsetFromEntityInWorldCoords(Ped, PedHackOffset.x, PedHackOffset.y, PedHackOffset.z), GetEntityRotation(Ped)
end

local function HackOrigin(Options)
    if Options.Coords then return NetScene.OriginFromCoords(Options.Coords) end
    if Options.Entity and DoesEntityExist(Options.Entity) then
        return GetEntityCoords(Options.Entity), GetEntityRotation(Options.Entity)
    end
    return PedHackOrigin()
end

local function HackGame(Minigame, Options)
    if type(Minigame) == 'function' then return Minigame end
    return NetScene.Varhack(type(Minigame) == 'table' and Minigame or Options)
end

local function HackUSB(Minigame, Cb, Options)
    Cb = Cb or function() end
    Options = Options or {}

    local Origin, Rotation = HackOrigin(Options)
    local Context = NetScene.New(HackUsbScene, Origin, Rotation)

    NetScene.Play(Context, 'Action')
    NetScene.Start(Context, 'Loop', { Looped = true })
    local Success, Result = NetScene.RunMinigame(HackGame(Minigame, Options))
    NetScene.Play(Context, 'Exit')

    NetScene.Finish(Context)
    Cb(Success, Result)
    return Success, Result
end

exports('HackUSB', HackUSB)

local function HackPhone(Minigame, Cb, Options)
    Cb = Cb or function() end
    Options = Options or {}

    local Origin, Rotation = HackOrigin(Options)
    local Context = NetScene.New(HackPhoneScene, Origin, Rotation)

    NetScene.Start(Context, 'Loop', { Looped = true })
    local Success, Result = NetScene.RunMinigame(HackGame(Minigame, Options))
    NetScene.Play(Context, Success and 'Success' or 'Fail')

    NetScene.Finish(Context)
    Cb(Success, Result)
    return Success, Result
end

exports('HackPhone', HackPhone)

local function LaptopOrigin(Options)
    if Options.Coords then return NetScene.OriginFromCoords(Options.Coords) end
    return NetScene.AnchorToPed(NetScene.ResolveDict(HackLaptopScene), HackLaptopScene.Stages.Enter.Ped)
end

local function HackLaptop(Minigame, Cb, Options)
    Cb = Cb or function() end
    Options = Options or {}

    local Origin, Rotation = LaptopOrigin(Options)
    local Context = NetScene.New(HackLaptopScene, Origin, Rotation, { Speed = Options.Speed })

    NetScene.Play(Context, 'Enter')
    NetScene.Start(Context, 'Loop', { Looped = true })
    local Success, Result = NetScene.RunMinigame(HackGame(Minigame, Options))
    NetScene.Play(Context, 'Exit')

    NetScene.Finish(Context)
    Cb(Success, Result)
    return Success, Result
end

exports('HackLaptop', HackLaptop)

local function ScheduleSwipeEvents(OnEvent, Dropped)
    if type(OnEvent) ~= 'function' then return end
    SetTimeout(CardSwipeScene.SwipeAt, function() OnEvent('swipe') end)
    if Dropped then SetTimeout(CardSwipeScene.DropAt, function() OnEvent('drop') end) end
end

local function SwipeOrigin(Entity, Stage)
    if Entity and DoesEntityExist(Entity) then
        return GetEntityCoords(Entity), GetEntityRotation(Entity)
    end
    return NetScene.AnchorToPed(NetScene.ResolveDict(CardSwipeScene), CardSwipeScene.Stages[Stage].Ped)
end

local function CardSwipe(Entity, Cb, Options)
    Cb = Cb or function() end
    Options = Options or {}

    local Passed = NetScene.RunMinigame(Options.Minigame)
    if not Passed then Cb(false, false) return false, false end

    local Dropped = math.random(1, 100) <= (Options.DropChance or 10)
    local Stage = Dropped and 'Drop' or 'Success'

    local Origin, Rotation = SwipeOrigin(Entity, Stage)
    local Context = NetScene.New(CardSwipeScene, Origin, Rotation)

    ScheduleSwipeEvents(Options.OnEvent, Dropped)
    NetScene.Play(Context, Stage)

    NetScene.Finish(Context)
    Cb(Dropped, true)
    return Dropped, true
end

exports('CardSwipe', CardSwipe)
