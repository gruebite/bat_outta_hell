
require("boot")
--[[
local o_ten_one = require("lib.o-ten-one")
local splash

function love.load()
    splash = o_ten_one()
    splash.onDone = function() end
end

function love.update(dt)
    splash:update(dt)
end

function love.draw()
    splash:draw()
end

function love.keypressed()
    splash:skip()
end
-]]