local M = {}

function M.unload_love()
    -- Unload everything!
    love.draw = nil
    love.errorhandler = nil
    love.load = nil
    love.lowmemory = nil
    love.quit = nil
    love.run = nil
    love.threaderror = nil
    love.update = nil
    love.directorydropped = nil
    love.filedropped = nil
    love.focus = nil
    love.mousefocus = nil
    love.resize = nil
    love.visible = nil
    love.keypressed = nil
    love.keyreleased = nil
    love.textedited = nil
    love.textinput = nil
    love.mousemoved = nil
    love.mousepressed = nil
    love.mousereleased = nil
    love.wheelmoved = nil
    love.gamepadaxis = nil
    love.gamepadpressed = nil
    love.gamepadreleased = nil
    love.joystickadded = nil
    love.joystickaxis = nil
    love.joystickhat = nil
    love.joystickpressed = nil
    love.joystickreleased = nil
    love.joystickremoved = nil
    love.touchmoved = nil
    love.touchpressed = nil
    love.touchreleased = nil
end

function M.switch(name, ...)
    if M._current and M._current.exit then
        M._current.exit()
    else
        M.unload_love()
    end
    package.loaded[name] = nil
    M._current = require(name)
    if type(M._current) == "table" and M._current.enter then
        M._current.enter(...)
    end
end

return M
