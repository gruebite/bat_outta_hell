
local helium = require("lib.helium")

local common = require("common")
local state = require("common.state")
local elements = require("common.elements")

local function container(params, state, view)
    local elems = {}
    for _, c in ipairs(params.children) do
        table.insert(elems, helium(c.elem)(c.params, view.w, 50))
    end
    return function()
        love.graphics.setColor(elements.style.bg)
        love.graphics.rectangle("fill", 0, 0, view.w, view.h)
        local step = 1 / #elems
        for i, e in ipairs(elems) do
            e:draw(0, (i - 1) * step * view.h)
        end
    end
end
local Container = helium(container)

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
    _G.ASSETS:load("luciferius_regular_small", 1, "luciferius_regular.ttf", 12)
    _G.ASSETS:load("luciferius_italics_small", 1, "luciferius_italics.ttf", 12)
    _G.ASSETS:load("luciferius_inverted_small", 1, "luciferius_inverted.ttf", 12)
    _G.ASSETS:load("luciferius_inverted_medium", 1, "luciferius_inverted.ttf", 24)
    _G.ASSETS:load("luciferius_inverted_large", 1, "luciferius_inverted.ttf", 128)

    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()

    container = Container({children = {
        {elem = elements.button, params = {text = "Play!", callback = switch("game")}},
        {elem = elements.button, params = {text = "Settings"}},
        {elem = elements.button, params = {text = "Help"}},
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
    love.graphics.setFont(_G.ASSETS:get("luciferius_inverted_large"))
    love.graphics.print("Bat", w / 8, h * 2 / 12)
    love.graphics.print("outta", w / 8, h * 4 / 12)
    love.graphics.print("Hell", w / 8, h * 6 / 12)
    love.graphics.setFont(_G.ASSETS:get("luciferius_regular_small"))
end

return {
    enter = enter,
    exit = exit
}
