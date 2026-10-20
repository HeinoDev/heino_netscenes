local Config = {}

Config.Debug = false

Config.Bag = 'hei_p_m_bag_var22_arm_s'
Config.BagComponent = 5
Config.ControlTimeout = 3000
Config.ClaimDuration = 120000

Config.GrabPrompt = {
    Limited = 'Samler (%d/%d)  [X] Stop',
    Unlimited = 'Samler (%d)  [X] Stop',
}

Config.HandOff = {
    Dict = 'mp_common',
    GiverClip = 'givetake1_a',
    TakerClip = 'givetake1_b',
    SwapPhase = 0.45,
    Distance = 0.9,
    MaxDistance = 3.0,
    WalkTimeout = 3000,
    Bone = 57005,
    Offset = vec3(0.13, 0.03, -0.02),
    Rotation = vec3(-80.0, 0.0, 0.0),
}

Config.TruckScene = {
    Truck = 'packer',
    Trailer = 'tr4',
    HitchOffset = vec3(-0.00281182, -9.76194, 0.332852),
    TruckColours = { 45, 40 },
    TruckExtraColours = { 35, 156 },

    Cars = {
        { Model = 'monroe', Offset = vec3(0.0, -5.00, 0.82), Rotation = vec3(3.80, 0.0, 0.0), Colours = { 89, 89 }, ExtraColours = { 88, 0 }, Plate = ' FA5T66 ' },
        { Model = 'cheetah', Offset = vec3(0.0, 0.00, 0.95), Rotation = vec3(-2.60, 0.0, 0.0), Colours = { 62, 62 }, ExtraColours = { 68, 0 }, Plate = ' SDTM1YP' },
        { Model = 'stinger', Offset = vec3(0.0, 5.00, 0.85), Rotation = vec3(0.09, 0.0, 0.0), Colours = { 27, 27 }, ExtraColours = { 36, 0 }, Plate = 'ALPHADOG', Extra = 1 },
        { Model = 'jb700', Offset = vec3(0.0, -5.00, 3.35), Rotation = vec3(0.09, 0.0, 0.0), Colours = { 3, 3 }, ExtraColours = { 3, 3 }, Plate = '  4G3NT' },
        { Model = 'entityxf', Offset = vec3(0.0, -0.25, 2.95), Rotation = vec3(-4.67, 0.0, 0.0), Colours = { 38, 38 }, ExtraColours = { 37, 0 }, Plate = ' MKB652 ' },
        { Model = 'ztype', Offset = vec3(0.0, 5.00, 2.91), Rotation = vec3(4.00, 0.0, 0.0), Colours = { 0, 0 }, ExtraColours = { 10, 0 }, Plate = ' V1NTAG3' },
    },
    TargetCar = 4,

    CrawlerModel = 'player_one',
    DriverModel = 's_m_m_trucker_01',

    SpawnForward = 15.0,
    DriveSpeed = 16.0,
    DriveStyle = 786603,
    DriveDistance = 1500.0,
    DriveWarmupMs = 2500,
    CleanupMs = 60000,

    Dicts = {
        ig8 = 'misscarstealfinalecar_5_ig_8',
        ig6 = 'misscarstealfinalecar_5_ig_6',
        ig4 = 'misscarstealfinalecar_5_ig_4',
    },

    Steps = {
        { Name = 'exit', Dict = 'ig8', Clip = 'ig_8_part_01_exit', Cam = 'ig_8_part_01_exit_cam', Attach = 'truck', BlendIn = 1000.0, Flags = 5, Rate = 1.0, Looped = false, Phase = 0.0 },
        { Name = 'hang', Dict = 'ig8', Clip = 'ig_8_part_02_loop', Cam = 'ig_8_part_02_loop_cam', Attach = 'truck', BlendIn = 1000.0, Flags = 5, Rate = 1.15, Looped = true, Phase = 0.0 },
        { Name = 'jump', Dict = 'ig8', Clip = 'ig_8_part_03_jump', Cam = 'ig_8_part_03_jump_cam', Attach = 'truck', BlendIn = 4.0, Flags = 5, Rate = 1.15, Looped = false, Phase = 0.0 },
        { Name = 'jump_alt', Dict = 'ig8', Clip = 'ig_8_part_03_jump_alt_trailer', Attach = 'trailer', BlendIn = 1000.0, Flags = 5, Rate = 1.15, Looped = false, SeedPhase = true },
        { Name = 'crawl', Dict = 'ig4', Clip = 'car_5_ig_4', Cam = 'car_5_ig_4_cam', Attach = 'trailer', BlendIn = 1000.0, Flags = 13, Rate = 1.15, Looped = false, Phase = 0.0 },
        { Name = 'enter', Dict = 'ig6', Clip = 'car_5_ig_6', Cam = 'car_5_ig_6_cam', Attach = 'trailer', BlendIn = 1000.0, Flags = 5, Rate = 1.0, Looped = false, Phase = 0.0, EndPhase = 1.0, CarClip = 'car_5_ig_6_car' },
    },

    SceneAudio = false,

    DropCarAtEnd = true,
    DropDelayMs = 1200,
    DropCollisionOffMs = 150,
    DropForce = vec3(0.0, -40.0, 0.0),
    ScrapeAsset = 'scr_carsteal4',
    ScrapeEffect = 'scr_carsteal4_trailer_scrape',
    ScrapeOffsets = { vec3(0.75, -10.85, -1.0), vec3(-0.75, -10.85, -1.0) },
    ScrapeMs = 2500,

    PhaseEpsilon = 0.01,
    SceneEndGraceMs = 400,
    PhaseStallMs = 1500,
    HeadingTolerance = 10.0,
    HeadingHoldMs = 1000,
    MinStepMs = 500,
    AbortRollDeg = 45.0,
    StepTimeoutMs = 30000,
    TimeoutSlack = 1.5,
}

return Config
