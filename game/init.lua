
local nata = require("lib.nata")
local flux = require("lib.flux")

local common = require("common")
local mobs = require(_P(..., "mobs"))
local hell = require(_P(..., "hell"))

local pool

--[[
Collision callbacks.
--]]

local function begin_contact(a, b, coll)
    local a_owner = a:getUserData()
    if a_owner and a_owner.begin_contact then
        a_owner:begin_contact(a, b, coll)
    end
    local b_owner = b:getUserData()
    if b_owner and b_owner.begin_contact then
        b_owner:begin_contact(b, a, coll)
    end
end

local function end_contact(a, b, coll)
    local a_owner = a:getUserData()
    if a_owner and a_owner.end_contact then
        a_owner:end_contact(a, b, coll)
    end
    local b_owner = b:getUserData()
    if b_owner and b_owner.end_contact then
        b_owner:end_contact(b, a, coll)
    end
end

local function pre_solve(a, b, coll)
    --[[if persisting == 0 then    -- only say when they first start touching
        text = text.."\n"..a:getUserData().." touching "..b:getUserData()
    elseif persisting < 20 then    -- then just start counting
        text = text.." "..persisting
    end
    persisting = persisting + 1    -- keep track of how many updates they've been touching for--]]
end

local function post_solve(a, b, coll, normalimpulse, tangentimpulse)
end

local function enter()

    love.physics.setMeter(16)
    local world = love.physics.newWorld(0, 0)
    world:setCallbacks(begin_contact, end_contact, pre_solve, post_solve)

    pool = nata.new({
        groups = {
        },
        systems = {
            nata.oop()
        }
    })
    pool.data = {
        world = world
    }

    local level = hell.Level.new(pool)
    level:construct({width = 1000, height = 1000})
    local bat = mobs.Bat.new(pool, level.entrance.x, level.entrance.y)
    pool:queue(bat)

    pool.data.camera = common.Camera.new()
    pool.data.camera:center_on(level.entrance.x, level.entrance.y)
    pool.data.bat = bat
    pool.data.level = level
end

function love.update(dt)
    pool:remove(function(e)
        local alive = e:alive()
        if not alive then
            e:destroy()
        end
        return not alive
    end)
    pool:flush()
    pool:emit('update', dt)
    flux.update(dt)
    pool.data.world:update(dt)
    local x, y = pool.data.bat.body:getPosition()
    -- +5 to give the camera some breathing room.
    pool.data.camera:follow(x, y)
end

function love.draw()
    pool.data.camera:apply()
    --love.graphics.circle("fill", 256, 256, 30)
    --love.graphics.circle("fill", 512, 512, 30)
    pool:emit("draw")

    -- Rulers
    --[[
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
    for x = math.multiple(pool.data.camera.x, 100), pool.data.camera.x + love.graphics.getWidth(), 100 do
        love.graphics.line(x, pool.data.camera.y, x, pool.data.camera.y + 5)
    end
    for y = math.multiple(pool.data.camera.y, 100), pool.data.camera.y + love.graphics.getHeight(), 100 do
        love.graphics.line(pool.data.camera.x, y, pool.data.camera.x + 5, y)
    end
    --]]
    pool.data.camera:unapply()

    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 1)
    --love.graphics.print(love.timer.getFPS(), 0, 0)
    --love.graphics.print(math.floor(collectgarbage("count")) .. "kb", 0, 12)

    local bar_width = 200
    local bar_width_h = bar_width / 2
    local bar_height = 10
    local bar_height_h = bar_height / 2
    local bottom_margin = 30
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", _G.CONF.WIDTH / 2 - bar_width_h, _G.CONF.HEIGHT - bar_height_h - bottom_margin, bar_width, bar_height)
    local energy = pool.data.bat.energy / 100
    love.graphics.rectangle("fill", _G.CONF.WIDTH / 2 - bar_width_h, _G.CONF.HEIGHT - bar_height_h - bottom_margin, bar_width * energy, bar_height)
end

return {
    enter = enter
}
