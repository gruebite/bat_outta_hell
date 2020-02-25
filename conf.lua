
local level_defaults = {
    description = [[No description provided.]],
    time_limit = -1,
    score_multiplier = 1,
    level_complete_score = 50,
    time_remaining_score = 1, -- Per second remaining. Only counts on timed levels.
    no_consume_score = 10,
    no_hit_hawk_score = 20,
    no_hit_fire_score = 30,

    echo_speed = 400,
    -- Echos are slowed down when passing over the bat. This is a good number.
    echo_speed_dampened = 150,
    echo_vanishing_distance = 400,
    echo_weight = 6,

    chirp_speed = 400,

    -- This shouldn't change unless the sprite does.
    bat_radius = 8,
    bat_chirp_limit = 3,
    bat_speed = 120,
    bat_boost_speed = 200,
    bat_boost_delay = 0.2, -- Before boosting occurs.
    bat_boost_energy_decay = 2, -- Energy/second.
    -- How large the visible waves are. This should remain pretty constant.
    bat_ear_size = 32,
    bat_invulnerability = 2.0,

    insect_radius = 8,
    insect_consume_energy = 5,
    insect_consume_score = 8, -- Score.
    insect_speed_min = 40,
    insect_speed_max = 80,
    insect_oblivious_chance = 0.5,
    insect_sensor_radius = 16,

    amethyst_radius = 8,
    amethyst_consume_score = 100,

    hawk_radius = 8,
    hawk_speed_min = 80,
    hawk_speed_max = 140,
    hawk_avoid_radius = 20,
    hawk_sensor_radius = 160,
    hawk_homing_time_min = 2,
    hawk_homing_time_max = 5,
    hawk_homing_cooldown = 8,
    hawk_bump_damage = 10,

    fire_bump_damage = 5,
    wall_bump_damage = 1,

    -- Level generation.
    width = 1000,
    height = 1000,
    culling = 0.0,
    spacing = 400,
    fire_radius_min = 20,
    fire_radius_max = 30,
    insect_count = 1,
    hawk_count = 0,
}

local conf = {
    width = 960,
    height = 720,
    fullscreen = false,

    debug_mode = false,
    display_diagnostics = false,
    display_rulers = false,

    main_color = {0.87, 0.33, 0.09, 1.0},
    accent_color = {0.09, 0.64, 0.87, 1.0},
    default_color = {0.86, 0.87, 0.86, 1.0}, -- White
    
    hawk_echo_color = {0.87, 0.33, 0.09, 1.0}, -- Main color - red
    insect_echo_color = {0.09, 0.64, 0.87, 1.0}, -- Accent color - cyan
    wall_echo_color = {0.86, 0.87, 0.86, 1.0}, -- Default color - white
    fire_echo_color = {0.87, 0.85, 0.09, 1.0}, -- Yellow
    exit_echo_color = {0.09, 0.87, 0.18, 1.0}, -- Green
    amethyst_echo_color = {0.87, 0.09, 0.67, 1.0}, -- Purple


    -- 9 levels of hell. Level configuration matches `Level` config parameter.
    levels = {
        setmetatable({
            description = [[The easiest level. Take your time.]],
        }, {__index = level_defaults}),
        setmetatable({
            description = [[This level has more fire.]],
            spacing = 200,
            culling = 0.1,
            fire_bump_damage = 20,
        }, {__index = level_defaults}),
        setmetatable({
            description = [[Don't get lost.]],
            width = 2000,
            height = 2000,
            insect_count = 3,
        }, {__index = level_defaults}),
        setmetatable({
            description = [[Something is hunting you.]],
            spacing = 200,
            culling = 0.2,
            insect_count = 2,
            hawk_count = 1,
        }, {__index = level_defaults}),
        setmetatable({
            description = [[There's more of them.]],
            spacing = 300,
            culling = 0.2,
            insect_count = 2,
            hawk_count = 3,
        }, {__index = level_defaults}),
        setmetatable({
            description = [[It's hot down here, better be quick.]],
            time_limit = 120,
            width = 1500,
            height = 1500,
            spacing = 300,
            culling = 0.2,
            fire_bump_damage = 30,
            insect_count = 7,
            insect_consume_energy = 10,
            insect_consume_score = 16,
        }, {__index = level_defaults}),
        setmetatable({
            description = [[This hellhawk is stronger and faster than the others.]],
            width = 800,
            height = 800,
            spacing = 800, -- No fires.
            insect_count = 0,
            hawk_count = 1,
            hawk_speed_min = 100,
            hawk_speed_max = 140,
            hawk_homing_cooldown = 2,
            hawk_bump_damage = 30,
        }, {__index = level_defaults}),
        setmetatable({
            description = [[A swarm.]],
            time_limit = 180,
            width = 1500,
            height = 1500,
            spacing = 300,
            culling = 0.2,
            insect_count = 7,
            insect_consume_energy = 10,
            insect_consume_score = 16,
            hawk_count = 9,
        }, {__index = level_defaults}),
        setmetatable({
            description = [[You feel weak.]],
            time_limit = 180,
            width = 1500,
            height = 1500,
            spacing = 300,
            culling = 0.2,
            bat_speed = 80,
            bat_boost_speed = 120,
            echo_vanishing_distance = 200,
            insect_count = 7,
            insect_consume_energy = 4,
            hawk_count = 9,
            hawk_bump_damage = 20,
        }, {__index = level_defaults}),
    },
}

conf.colors = {
    conf.hawk_echo_color, 
    conf.insect_echo_color, 
    conf.hawk_echo_color,
    conf.insect_echo_color,
    conf.wall_echo_color,
    conf.fire_echo_color,
    conf.exit_echo_color,
    conf.amethyst_echo_color,
}

local i = 2
while i <= #arg do
    if arg[i] == "--test" then
        conf.TEST = true
    end
    i = i + 1
end

function love.conf(t)
    t.identity = "BatOuttaHell"
    t.version = "11.2"
    t.console = false
    t.accelerometerjoystick = true
    t.externalstorage = false
    t.gammacorrect = false

    t.window.title = "Bat Outta Hell"
    t.window.icon = "assets/icon.png"
    t.window.width = conf.width
    t.window.height = conf.height
    t.window.borderless = false
    t.window.resizable = false
    t.window.minwidth = 1
    t.window.minheight = 1
    t.window.fullscreen = false
    t.window.fullscreentype = "desktop"
    t.window.vsync = true
    t.window.msaa = 0
    t.window.display = 1
    t.window.highdpi = false
    t.window.x = nil
    t.window.y = nil

    t.modules.audio = true
    t.modules.event = true
    t.modules.graphics = true
    t.modules.image = true
    t.modules.joystick = true
    t.modules.keyboard = true
    t.modules.math = true
    t.modules.mouse = true
    t.modules.physics = true
    t.modules.sound = true
    t.modules.system = true
    t.modules.timer = true
    t.modules.touch = true
    t.modules.video = true
    t.modules.window = true
    t.modules.thread = true
end

return conf