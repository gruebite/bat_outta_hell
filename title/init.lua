
local helium = require("lib.helium")

local common = require("common")
local state = require("common.state")
local elements = require("common.elements")

local playing = "intro"

local container

local show

local shows = {
    main = function()
        local w = love.graphics.getWidth()
        local h = love.graphics.getHeight()
    
        container = helium(elements.vcontainer)({children = {
            {elem = elements.button, width = 260, height = 50, padding_v = 1/10, params = {text = "Fly!", callback = function()
                state.switch("game")
            end}},
            --{elem = elements.button, width = 260, height = 50, params = {text = "Attempts", callback = function() show("attempts") end}},
            {elem = elements.button, width = 260, height = 50, padding_v = 1/10, params = {text = "Manual", callback = function() show("manual") end}},
            {elem = elements.button, width = 260, height = 50, padding_v = 1/10, params = {text = "Credits", callback = function() show("credits") end}},
            {elem = elements.button, width = 260, height = 50, params = {text = "Quit", callback = function() love.event.quit() end}},
        }}, w * 2 / 4, h * 2 / 4)
        container:draw(w * 2 / 4, h * 1 / 4)
        _G.ASSETS:get(playing):play()
    end,
    attempts = function()
    end,
    attempt_n = function(data)
        local w = love.graphics.getWidth()
        local h = love.graphics.getHeight()
    
        container = helium(elements.vcontainer)({children = {
            {elem = elements.label, height = 50, padding_v = 0.2, params = {text = data.message, font = _G.ASSETS:get("font_italics_m"), fg = _G.CONF.accent_color}},
            {elem = elements.label, height = 300, padding_v = 0.2, params = {text = "Total score: " .. tostring(data.score)}},
            {elem = elements.button, width = 120, height = 40, params = {text = "Main Menu", font = _G.ASSETS:get("font_regular_s"), callback = function() show("main") end}},
        }}, w * 2 / 4, h * 6 / 8)
        container:draw(w * 2 / 4, h * 1 / 8)
        _G.ASSETS:get(playing):play()
    end,
    credits = function()
        local w = love.graphics.getWidth()
        local h = love.graphics.getHeight()
    
        container = helium(elements.vcontainer)({children = {
            {elem = elements.label, height = 50, padding_v = 0.1, params = {text = "Credits", font = _G.ASSETS:get("font_italics_m"), fg = _G.CONF.accent_color}},
            {elem = elements.label, height = 25, params = {text = "gruebite - programmer"}},
            {elem = elements.label, height = 50, padding_v = 0.3, params = {text = "jestbubbles - music"}},
            {elem = elements.button, width = 120, height = 40, params = {text = "Main Menu", font = _G.ASSETS:get("font_regular_s"), callback = function() show("main") end}},
        }}, w * 2 / 4, h * 6 / 8)
        container:draw(w * 2 / 4, h * 1 / 8)
    end,
    manual = function()
        local w = love.graphics.getWidth()
        local h = love.graphics.getHeight()
    
        container = helium(elements.vcontainer)({children = {
            {elem = elements.label, height = 50, padding_v = 0.1, params = {text = "Manual", font = _G.ASSETS:get("font_italics_m"), fg = _G.CONF.accent_color}},
            {elem = elements.button, width = 120, height = 40, params = {text = "Main Menu", font = _G.ASSETS:get("font_regular_s"), callback = function() show("main") end}},
        }}, w * 2 / 4, h * 6 / 8)
        container:draw(w * 2 / 4, h * 1 / 8)
    end
}

show = function(name, ...)
    if container then
        container:undraw()
    end
    shows[name](...)
end

local function enter(into, play, ...)
    for i = 1, 3 do
        _G.ASSETS:load("bat", i, "bat".. i .. ".png")
    end
    _G.ASSETS:load("chirp", 1, "chirp.wav", "stream")
    _G.ASSETS:load("squeek", 1, "squeek.wav", "stream")
    _G.ASSETS:load("crunch", 1, "crunch.wav", "stream")
    _G.ASSETS:load("flutter", 1, "flutter.wav", "stream")
    _G.ASSETS:load("intro", 1, "intro.wav", "stream")
    _G.ASSETS:load("intro_loop", 1, "intro_loop.wav", "stream")
    _G.ASSETS:load("death", 1, "death.wav", "stream")
    _G.ASSETS:load("enter", 1, "enter.wav", "stream")
    _G.ASSETS:load("success", 1, "success.wav", "stream")
    _G.ASSETS:load("font_regular_s", 1, "luciferius_regular.ttf", 16)
    _G.ASSETS:load("font_regular_m", 1, "luciferius_regular.ttf", 24)
    _G.ASSETS:load("font_italics_s", 1, "luciferius_italics.ttf", 16)
    _G.ASSETS:load("font_italics_m", 1, "luciferius_italics.ttf", 24)
    _G.ASSETS:load("font_inverted_s", 1, "luciferius_inverted.ttf", 16)
    _G.ASSETS:load("font_inverted_m", 1, "luciferius_inverted.ttf", 24)
    _G.ASSETS:load("font_inverted_l", 1, "luciferius_inverted.ttf", 64)
    _G.ASSETS:load("font_inverted_xl", 1, "luciferius_inverted.ttf", 128)

    playing = play or playing
    show(into or "main", ...)
end

local function exit()
    container:undraw()
    _G.ASSETS:get(playing):stop()
end

function love.update(dt)
    if not _G.ASSETS:get(playing):isPlaying() then
        playing = "intro_loop"
        _G.ASSETS:get(playing):play()
    end
end

function love.draw()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    love.graphics.setColor(_G.CONF.main_color)
    love.graphics.setFont(_G.ASSETS:get("font_inverted_xl"))
    love.graphics.print("Bat", w / 16, h * 2 / 12)
    love.graphics.print("outta", w / 16, h * 4 / 12)
    love.graphics.print("Hell", w / 16, h * 6 / 12)
end

function love.keypressed(key, scancode, isrepeat)
    _G.CONTROL_KEYS(key, scancode, isrepeat)
end

return {
    enter = enter,
    exit = exit
}
