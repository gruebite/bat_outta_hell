
local conf = {
    WIDTH = 800,
    HEIGHT = 600,
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
    t.window.width = conf.WIDTH
    t.window.height = conf.HEIGHT
    t.window.borderless = false
    t.window.resizable = false
    t.window.minWIDTH = 1
    t.window.minHEIGHT = 1
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