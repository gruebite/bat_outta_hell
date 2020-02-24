
local helium = require("lib.helium")

local common = require("common")
local state = require("common.state")
local elements = require("common.elements")

local container

local function switch(to)
    return function()
        state.switch(to)
    end
end

local function enter()
    for i = 1, 3 do
        _G.ASSETS:load("bat", i, "bat".. i .. ".png")
    end
    _G.ASSETS:load("chirp", 1, "chirp.wav", "static")
    _G.ASSETS:load("echo", 1, "echo.wav", "static")
    _G.ASSETS:load("squeek", 1, "squeek.wav", "static")
    _G.ASSETS:load("luciferius_regular_s", 1, "luciferius_regular.ttf", 12)
    _G.ASSETS:load("luciferius_regular_m", 1, "luciferius_regular.ttf", 24)
    _G.ASSETS:load("luciferius_italics_s", 1, "luciferius_italics.ttf", 12)
    _G.ASSETS:load("luciferius_italics_m", 1, "luciferius_italics.ttf", 24)
    _G.ASSETS:load("luciferius_inverted_s", 1, "luciferius_inverted.ttf", 12)
    _G.ASSETS:load("luciferius_inverted_m", 1, "luciferius_inverted.ttf", 24)
    _G.ASSETS:load("luciferius_inverted_l", 1, "luciferius_inverted.ttf", 64)
    _G.ASSETS:load("luciferius_inverted_xl", 1, "luciferius_inverted.ttf", 128)

    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()

    container = helium(elements.vcontainer)({children = {
        {elem = elements.button, params = {text = "Fly!", callback = switch("game")}},
        {elem = elements.button, params = {text = "Attempts"}},
        {elem = elements.button, params = {text = "Manual"}},
        {elem = elements.button, params = {text = "Quit", callback = function() love.event.quit() end}},
    }}, w * 1 / 4, h * 2 / 4)
    container:draw(w * 2.5 / 4, h * 1 / 4)
end

local function exit()
    container:undraw()
end

function love.update(dt)
end

function love.draw()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    love.graphics.setColor(0.8, 0.5, 0.3, 1.0)
    love.graphics.setFont(_G.ASSETS:get("luciferius_inverted_xl"))
    love.graphics.print("Bat", w / 8, h * 2 / 12)
    love.graphics.print("outta", w / 8, h * 4 / 12)
    love.graphics.print("Hell", w / 8, h * 6 / 12)
    love.graphics.setFont(_G.ASSETS:get("luciferius_regular_s"))
end

return {
    enter = enter,
    exit = exit
}
