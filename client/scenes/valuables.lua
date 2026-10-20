local Config = NetScene.Config

local LeftHandBone = 60309
local StopControl = 73
local BlockedControls = { 24, 25, 47, 58, 140, 141, 142, 143, 263, 264 }
local FullPhase = 0.97
local SceneWaitTimeout = 1000
local GrabEventDebounce = 400

local PaintingOffset = { Back = -0.43, Down = 1.17 }

local TrolleyPickups = {
    [GetHashKey('hei_prop_hei_cash_trolly_01')] = 'hei_prop_heist_cash_pile',
    [GetHashKey('ch_prop_gold_trolly_01a')] = 'ch_prop_gold_bar_01a',
    [GetHashKey('ch_prop_diamond_trolly_01a')] = 'ch_prop_vault_dimaondbox_01a',
}

local JewelCaseBroken = {
    [GetHashKey('des_jewel_cab_start')] = 'des_jewel_cab_end',
    [GetHashKey('des_jewel_cab2_start')] = 'des_jewel_cab2_end',
    [GetHashKey('des_jewel_cab3_start')] = 'des_jewel_cab3_end',
    [GetHashKey('des_jewel_cab4_start')] = 'des_jewel_cab4_end',
}

local GoldStack = GetHashKey('h4_prop_h4_gold_stack_01a')
local CashAppearEvent = GetHashKey('CASH_APPEAR')
local CashReleaseEvent = GetHashKey('RELEASE_CASH_DESTROY')

local function PaintingStage(Name, Cam)
    return {
        Ped = Name,
        Target = ('%s_ch_prop_vault_painting_01a'):format(Name),
        Bag = ('%s_hei_p_m_bag_var22_arm_s'):format(Name),
        Cam = Cam,
    }
end

local PaintingScene = NetScene.Define('StealPainting', {
    Dict = 'anim_heist@hs3f@ig11_steal_painting@male@',
    Props = { Bag = NetScene.Bag },
    Order = { 'Enter', 'TopLeftToRight', 'RightTopToBottom', 'BottomRightToLeft', 'LeftTopToBottom', 'Exit' },
    Stages = {
        Enter = PaintingStage('ver_01_top_left_enter', 'ver_01_top_left_enter_cam_ble'),
        TopLeftToRight = PaintingStage('ver_01_cutting_top_left_to_right', 'ver_01_cutting_top_left_to_right_cam'),
        RightTopToBottom = PaintingStage('ver_01_cutting_right_top_to_bottom', 'ver_01_cutting_right_top_to_bottom_cam'),
        BottomRightToLeft = PaintingStage('ver_01_cutting_bottom_right_to_left', 'ver_01_cutting_bottom_right_to_left_cam'),
        LeftTopToBottom = PaintingStage('ver_01_re-enter_cutting_left_top_to_bottom', 'ver_01_re-enter_cutting_left_top_to_bottom_cam'),
        Exit = PaintingStage('ver_01_with_painting_exit', 'ver_01_with_painting_exit_cam_re1'),
    },
})

local CashTrolleyScene = NetScene.Define('CashTrolley', {
    Dict = 'anim@heists@ornate_bank@grab_cash',
    Props = { Bag = NetScene.Bag },
    Models = { 'hei_prop_heist_cash_pile', 'ch_prop_gold_bar_01a', 'ch_prop_vault_dimaondbox_01a', 'hei_prop_hei_cash_trolly_03' },
    DefaultPickup = 'hei_prop_heist_cash_pile',
    EmptyModel = 'hei_prop_hei_cash_trolly_03',
    Stages = {
        Intro = { Ped = 'intro', Bag = 'bag_intro' },
        Grab = { Ped = 'grab', Bag = 'bag_grab', Target = 'cart_cash_dissapear' },
        Exit = { Ped = 'exit', Bag = 'bag_exit' },
    },
})

local GlassCutScene = NetScene.Define('GlassCut', {
    Dict = 'anim@scripted@heist@ig16_glass_cut@male@',
    Props = { Bag = NetScene.Bag, Cutter = 'h4_prop_h4_cutter_01a' },
    Models = { 'h4_prop_h4_glass_disp_01b' },
    BrokenModel = 'h4_prop_h4_glass_disp_01b',
    Stages = {
        Enter = { Ped = 'enter', Bag = 'enter_bag', Cutter = 'enter_cutter', Target = 'enter_glass_display' },
        Cutting = { Ped = 'cutting_loop', Bag = 'cutting_loop_bag', Cutter = 'cutting_loop_cutter', Target = 'cutting_loop_glass_display' },
        Overheat = { Ped = 'overheat_react_01', Bag = 'overheat_react_01_bag', Cutter = 'overheat_react_01_cutter', Target = 'overheat_react_01_glass_display' },
        Success = { Ped = 'success', Bag = 'success_bag', Cutter = 'success_cutter', Target = 'success_glass_display_cut' },
        Exit = { Ped = 'exit', Bag = 'exit_bag', Cutter = 'exit_cutter' },
    },
})

local SmashCaseScene = NetScene.Define('SmashCase', {
    Dict = 'missheist_jewel',
    Models = { 'des_jewel_cab_end', 'des_jewel_cab2_end', 'des_jewel_cab3_end', 'des_jewel_cab4_end' },
    Variants = { 'smash_case', 'smash_case_b', 'smash_case_c', 'smash_case_d', 'smash_case_e', 'smash_case_f', 'smash_case_necklace', 'smash_case_tray' },
    SmashPhase = 0.3,
    Ptfx = { Asset = 'scr_jewelheist', Name = 'scr_jewel_cab_smash' },
})

local function TableGrabStages(TargetClip)
    return {
        Enter = { Ped = 'enter', Bag = 'enter_bag' },
        Grab = { Ped = 'grab', Bag = 'grab_bag', Target = TargetClip },
        Exit = { Ped = 'exit', Bag = 'exit_bag' },
    }
end

local TableGrabGoldScene = NetScene.Define('TableGrabGold', {
    Dict = 'anim@scripted@heist@ig1_table_grab@gold@male@',
    Props = { Bag = NetScene.Bag },
    Stages = TableGrabStages('grab_gold'),
})

local TableGrabCashScene = NetScene.Define('TableGrabCash', {
    Dict = 'anim@scripted@heist@ig1_table_grab@cash@male@',
    Props = { Bag = NetScene.Bag },
    Stages = TableGrabStages('grab_cash'),
})

local function StealPainting(Entity, Cb, CreateCam)
    Cb = Cb or function() end
    if not NetScene.ValidateTarget('StealPainting', Entity) then return false end

    local Coords = GetEntityCoords(Entity)
    local Back = Coords + GetEntityForwardVector(Entity) * PaintingOffset.Back
    local Origin = vec3(Back.x, Back.y, Coords.z - PaintingOffset.Down)
    local Context = NetScene.New(PaintingScene, Origin, GetEntityRotation(Entity), { Target = Entity, Camera = CreateCam })

    for _, Stage in ipairs(PaintingScene.Order) do
        NetScene.Play(Context, Stage)
    end

    NetScene.Finish(Context)
    Cb(true)
    return true
end

exports('StealPainting', StealPainting)

local function CreateHandPickup(Model)
    local Ped = cache.ped
    local Pickup = NetScene.CreateProp(Model, GetEntityCoords(Ped))
    SetEntityVisible(Pickup, false, false)
    AttachEntityToEntity(Pickup, Ped, GetPedBoneIndex(Ped, LeftHandBone), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 0, true)
    return Pickup
end

local function DefaultGrabPrompt(Grabs, MaxGrabs)
    if MaxGrabs then return Config.GrabPrompt.Limited:format(Grabs, MaxGrabs) end
    return Config.GrabPrompt.Unlimited:format(Grabs)
end

local function BlockGrabControls()
    for Index = 1, #BlockedControls do
        DisableControlAction(0, BlockedControls[Index], true)
    end
end

local function WaitForLocalScene(Context)
    local Deadline = GetGameTimer() + SceneWaitTimeout

    while NetworkGetLocalSceneFromNetworkId(Context.Scene) == -1 and GetGameTimer() < Deadline do
        Wait(0)
    end
end

local function StopPressed()
    return IsControlJustPressed(0, StopControl) or IsDisabledControlJustPressed(0, StopControl)
end

local function ReachedMax(Grabs, MaxGrabs)
    return MaxGrabs ~= nil and Grabs >= MaxGrabs
end

local function GrabUntilDone(Context, Pickup, Options)
    local Ped = cache.ped
    local Prompt = Options.Prompt or DefaultGrabPrompt
    local Grabs, Phase = 0, Options.StartPhase or 0.0
    local LastRelease = 0

    NetScene.Start(Context, 'Grab', { Phase = Phase })
    WaitForLocalScene(Context)
    lib.showTextUI(Prompt(Grabs, Options.MaxGrabs))

    while Phase < FullPhase and not ReachedMax(Grabs, Options.MaxGrabs) do
        BlockGrabControls()
        if StopPressed() then break end

        if HasAnimEventFired(Ped, CashAppearEvent) then SetEntityVisible(Pickup, true, false) end

        local Now = GetGameTimer()

        if Now - LastRelease > GrabEventDebounce and HasAnimEventFired(Ped, CashReleaseEvent) then
            LastRelease = Now
            Grabs = Grabs + 1
            SetEntityVisible(Pickup, false, false)
            lib.showTextUI(Prompt(Grabs, Options.MaxGrabs))

            if type(Options.OnGrab) == 'function' and Options.OnGrab(Grabs) == false then break end
        end

        local Current = NetScene.Phase(Context.Scene)
        if not Current then break end

        Phase = Current
        Wait(0)
    end

    SetEntityVisible(Pickup, false, false)
    lib.hideTextUI()
    return Grabs, Phase
end

local function HoldTrolley(Context, Trolley, Phase)
    local Origin, Rotation = Context.Origin, Context.Rotation
    local Scene = NetworkCreateSynchronisedScene(Origin.x, Origin.y, Origin.z, Rotation.x, Rotation.y, Rotation.z, 2, true, false, -1, math.min(Phase, 1.0), 0.0)
    NetworkAddEntityToSynchronisedScene(Trolley, Scene, Context.Dict, CashTrolleyScene.Stages.Grab.Target, 1.0, 1.0, 1)
    NetworkStartSynchronisedScene(Scene)
end

local function TrolleyRotation(Entity, Flip)
    local Rotation = GetEntityRotation(Entity)
    if not Flip then return Rotation end
    return vec3(Rotation.x, Rotation.y, (Rotation.z + 180.0) % 360.0)
end

local function CashTrolley(Entity, Cb, Options)
    Cb = Cb or function() end
    Options = Options or {}
    if not NetScene.ValidateTarget('CashTrolley', Entity) then Cb(false) return false end

    local AnimateTrolley = Options.AnimateTrolley ~= false
    local PickupModel = Options.Pickup or TrolleyPickups[GetEntityModel(Entity)] or CashTrolleyScene.DefaultPickup
    local Context = NetScene.New(CashTrolleyScene, GetEntityCoords(Entity), TrolleyRotation(Entity, Options.Flip), { Target = AnimateTrolley and Entity or nil })
    local Pickup = CreateHandPickup(PickupModel)

    NetScene.Play(Context, 'Intro')
    local Grabs, Phase = GrabUntilDone(Context, Pickup, Options)
    DeleteEntity(Pickup)
    SetModelAsNoLongerNeeded(joaat(PickupModel))

    Context.Target = nil
    local StartedAt = GetGameTimer()
    local Duration = NetScene.Start(Context, 'Exit')

    local Trolley = Entity
    if AnimateTrolley then HoldTrolley(Context, Entity, Phase) end
    if Phase >= FullPhase and Options.EmptyModel ~= false then
        Trolley = NetScene.ReplaceEntity(Entity, Options.EmptyModel or CashTrolleyScene.EmptyModel)
    end
    NetScene.WaitRemaining(StartedAt, Duration)

    NetScene.Finish(Context)
    Cb(true, Trolley, Grabs, Phase)
    return true, Trolley, Grabs, Phase
end

exports('CashTrolley', CashTrolley)

local function GlassCut(Entity, Cb, Options)
    Cb = Cb or function() end
    Options = Options or {}
    if not NetScene.ValidateTarget('GlassCut', Entity) then Cb(false) return false end

    local Context = NetScene.New(GlassCutScene, GetEntityCoords(Entity), GetEntityRotation(Entity), { Target = Entity })

    NetScene.Play(Context, 'Enter')
    NetScene.Start(Context, 'Cutting', { Looped = true })
    local Success = NetScene.RunTimedMinigame(Options.Minigame, Options.CutTime or 8000)

    local BrokenDisplay
    if Success then
        BrokenDisplay = NetScene.ReplaceEntity(Entity, Options.BrokenModel or GlassCutScene.BrokenModel)
        Context.Target = BrokenDisplay
        NetScene.Play(Context, 'Success')
        NetScene.DeleteOwnedEntity(Options.Loot)
    else
        NetScene.Play(Context, 'Overheat')
    end

    Context.Target = nil
    NetScene.Play(Context, 'Exit')

    NetScene.Finish(Context)
    Cb(Success, BrokenDisplay)
    return Success, BrokenDisplay
end

exports('GlassCut', GlassCut)

local function PickExistingClip(Dict, Clips)
    local Available = {}
    for _, Clip in ipairs(Clips) do
        if NetScene.HasClip(Dict, Clip) then Available[#Available + 1] = Clip end
    end
    if #Available == 0 then return Clips[1] end
    return Available[math.random(#Available)]
end

local function BreakJewelCase(Entity, BrokenModel)
    local Model = BrokenModel or JewelCaseBroken[GetEntityModel(Entity)]
    if not Model or not NetworkGetEntityIsNetworked(Entity) or not NetScene.RequestControl(Entity) then return nil end
    return NetScene.ReplaceEntity(Entity, Model)
end

local function SmashCase(Entity, Cb, Options)
    Cb = Cb or function() end
    Options = Options or {}
    if not Entity or not DoesEntityExist(Entity) then
        lib.print.error('SmashCase: Entity does not exist')
        Cb(false)
        return false
    end

    local SmashDict = NetScene.ResolveDict(SmashCaseScene)
    lib.requestAnimDict(SmashDict)
    local Clip = Options.Clip or PickExistingClip(SmashDict, SmashCaseScene.Variants)
    local Origin, Rotation = NetScene.AnchorToPed(SmashDict, Clip, NetScene.FaceEntity(Entity))
    local Context = NetScene.New({ Dict = SmashDict, Stages = { Smash = { Ped = Clip } } }, Origin, Rotation)

    local StartedAt = GetGameTimer()
    local Duration = NetScene.Start(Context, 'Smash')
    NetScene.WaitForPhase(Context.Scene, SmashCaseScene.SmashPhase, Duration)
    NetScene.PlayNetworkedPtfx(SmashCaseScene.Ptfx, GetEntityCoords(Entity))
    local BrokenCase = BreakJewelCase(Entity, Options.BrokenModel)
    NetScene.WaitRemaining(StartedAt, Duration)

    NetScene.Finish(Context)
    RemoveNamedPtfxAsset(SmashCaseScene.Ptfx.Asset)
    Cb(true, BrokenCase)
    return true, BrokenCase
end

exports('SmashCase', SmashCase)

local function TableGrab(Entity, Cb, Options)
    Cb = Cb or function() end
    Options = Options or {}
    if not NetScene.ValidateTarget('TableGrab', Entity) then Cb(false) return false end

    local IsGold = Options.Kind == 'gold' or (Options.Kind == nil and GetEntityModel(Entity) == GoldStack)
    local Definition = IsGold and TableGrabGoldScene or TableGrabCashScene
    local Context = NetScene.New(Definition, GetEntityCoords(Entity), GetEntityRotation(Entity), { Target = Entity })

    NetScene.Play(Context, 'Enter')
    NetScene.Play(Context, 'Grab')
    DeleteEntity(Entity)
    Context.Target = nil
    NetScene.Play(Context, 'Exit')

    NetScene.Finish(Context)
    Cb(true)
    return true
end

exports('TableGrab', TableGrab)
