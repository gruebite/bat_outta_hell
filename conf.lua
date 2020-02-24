
local level_defaults = {
    description = [[No description provided.]],
    time_limit = -1,
    score_multiplier = 1,
    level_complete_score = 50,
    time_remaining_score = 1, -- Per second remaining. Only counts on timed levels.
    no_consume_score = 10,
    no_hit_hawk_score = 20,
    no_hit_object_score = 30,

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
    bat_boost_energy_decay = 5, -- Energy/second.
    -- How large the visible waves are. This should remain pretty constant.
    bat_ear_size = 24,

    insect_radius = 8,
    insect_consume_energy = 20,
    insect_consume_score = 8, -- Score.
    insect_speed_min = 40,
    insect_speed_max = 80,
    insect_oblivious_chance = 0.5,
    insect_sensor_radius = 80,

    hawk_radius = 8,
    hawk_speed_min = 80,
    hawk_speed_max = 140,
    hawk_sensor_radius = 160,
    hawk_homing_time_min = 2,
    hawk_homing_time_max = 5,
    hawk_homing_cooldown = 8,
    hawk_bump_damage = 10,

    object_bump_damage = 10,

    -- Level generation.
    width = 1000,
    height = 1000,
    culling = 0.0,
    spacing = 400,
    trunk_radius_min = 20,
    trunk_radius_max = 30,
    insect_count = 1,
    hawk_count = 0,
}

local conf = {
    width = 800,
    height = 600,

    debug_mode = true,
    display_diagnostics = true,
    display_rulers = true,

    -- 9 levels of hell. Level configuration matches `Level` config parameter.
    levels = {
        setmetatable({
            description = [[The easiest level of hell, but do not get comfortable.]],
        }, {__index = level_defaults}),
        setmetatable({
            description = [[More objects. Are they trees or pillars of fire?]],
            spacing = 200,
            culling = 0.1,
        }, {__index = level_defaults}),
        setmetatable({
            description = [[Don't get lost.]],
            width = 2000,
            height = 2000,
            insect_count = 3,
        }, {__index = level_defaults}),
        setmetatable({
            description = [[You have a friend.]],
            spacing = 200,
            culling = 0.2,
            insect_count = 2,
            hawk_count = 1,
        }, {__index = level_defaults}),
        setmetatable({
            description = [[]],
        }, {__index = level_defaults}),
        setmetatable({
            description = [[]],
        }, {__index = level_defaults}),
        setmetatable({
            description = [[]],
        }, {__index = level_defaults}),
        setmetatable({
            description = [[]],
        }, {__index = level_defaults}),
        setmetatable({
            description = [[]],
        }, {__index = level_defaults}),
    },
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
    t.console = true
    t.accelerometerjoystick = true
    t.externalstorage = false
    t.gammacorrect = false

    t.window.title = "Bat Outta Hell"
    t.window.icon = nil
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