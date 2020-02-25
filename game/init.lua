
local nata = require("lib.nata")
local flux = require("lib.flux")

local common = require("common")
local state = require("common.state")
local mobs = require(_P(..., "mobs"))
local hell = require(_P(..., "hell"))

local paused = false
-- Current running animation. Usually a driver for more animations/transitions.
local anim
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
    local a_owner = a:getUserData()
    if a_owner and a_owner.pre_solve then
        a_owner:pre_solve(a, b, coll)
    end
    local b_owner = b:getUserData()
    if b_owner and b_owner.pre_solve then
        b_owner:pre_solve(b, a, coll)
    end
end

local function post_solve(a, b, coll, normalimpulse, tangentimpulse)
    local a_owner = a:getUserData()
    if a_owner and a_owner.post_solve then
        a_owner:post_solve(a, b, coll, normalimpulse, tangentimpulse)
    end
    local b_owner = b:getUserData()
    if b_owner and b_owner.post_solve then
        b_owner:post_solve(b, a, coll, normalimpulse, tangentimpulse)
    end
end

local function construct_and_enter_level()
    local intro_data
    local intro_draw = function(self)
        local w = love.graphics.getWidth()
        local h = love.graphics.getHeight()
        local fg = _G.CONF.main_color
        love.graphics.setColor(fg[1], fg[2], fg[3], intro_data.title_alpha)
        love.graphics.setFont(_G.ASSETS:get("font_inverted_l"))
        love.graphics.printf("Level " .. tostring(pool.data.current_level), 0, h * 1 / 5, w, "center")
        local afg = _G.CONF.accent_color
        love.graphics.setColor(afg[1], afg[2], afg[3], intro_data.title_alpha)
        love.graphics.setFont(_G.ASSETS:get("font_italics_m"))
        love.graphics.printf(pool.data:get_current_level_config().description, w * 1 / 3, h * 2 / 5, w * 1 / 3, "center")
    end

    anim = common.Anim.new(0.1, true)
    anim:add_frame(1, function()
        intro_data = {
            title_alpha = 0.0,
            subtitle_alpha = 0.0,
        }
        anim.draw = intro_draw
        flux.to(intro_data, 1, {title_alpha = 1.0})
        pool.data.bat.invisible = true
    end)
    anim:add_frame(5, function()
        flux.to(intro_data, 1, {subtitle_alpha = 1.0})
    end)
    anim:add_frame(25, function()
        flux.to(intro_data, 1, {title_alpha = 0, subtitle_alpha = 0})
    end)
    anim:add_frame(35, function()
        pool.data.bat.invisible = false
        print(pool.data.amethyst_level == pool.data.current_level)
        pool.data.level:construct(pool.data.amethyst_level == pool.data.current_level)
        pool.data.clock = pool.data:get_current_level_config().time_limit
        pool.data.camera:center_on(pool.data.level.entrance.x, pool.data.level.entrance.y)
        pool.data.bat.body:setPosition(pool.data.level.entrance.x, pool.data.level.entrance.y)
        _G.ASSETS:get("enter"):play()
    end)
end

local function enter()
    love.physics.setMeter(16)
    local world = love.physics.newWorld(0, 0)
    world:setCallbacks(begin_contact, end_contact, pre_solve, post_solve)

    pool = nata.new({
        groups = {
        },
        systems = {
            nata.oop {
                include = {"update", "draw"}
            }
        }
    })
    pool.data = {
        world = world,
        current_level = 1,
        score = 0,
        -- Animated.
        display_score = 0,
        display_energy = 100,
        -- Disabled.
        clock = -1,
        get_current_level_config = function(self)
            return _G.CONF.levels[self.current_level]
        end,
        adjust_score = function(self, by)
            pool:emit("score_adjusted", by)
            self.score = self.score + by * pool.data:get_current_level_config().score_multiplier
        end,
    }

    local level = hell.Level.new(pool)
    pool.data.camera = common.Camera.new()
    pool.data.bat = pool:queue(mobs.Bat.new(pool, 0, 0))
    pool.data.level = level
    pool.data.amethyst_level = math.floor(love.math.random() * 9) + 1

    construct_and_enter_level()

    pool:on("score_adjusted", function(by)
    end)
    pool:on("energy_adjusted", function(by, prev, curr, from)
        if curr > 0 then
            return
        end
        pool.data.level:clear()

        local color = _G.CONF.default_color
        if from then
            color = from.echo_color
        end

        anim = common.Anim.new(0.1, true)
        local data = {radius = 0, alpha = 1}
        flux.to(data, 2.0, {radius = 400, alpha = 0.0})
        anim.draw = function(self)
            pool.data.camera:apply()
            love.graphics.setColor(color[1], color[2], color[3], data.alpha)
            local x, y = pool.data.bat.body:getPosition()
            love.graphics.circle("line", x, y, data.radius)
            pool.data.camera:unapply()
        end
        anim:add_frame(15, function()
            state.switch("title", "attempt_n", "death", {
                message = "You died!",
                score = pool.data.score
            })
        end)
    end)
    pool:on("reached_exit", function()
        pool.data:adjust_score(pool.data:get_current_level_config().level_complete_score)

        pool.data.level:clear()
        -- Previous level artifacts.
        pool.data.bat:clear_echos_and_chirps()

        local circle_data
        local circle_draw = function(self)
            pool.data.camera:apply()
            love.graphics.setColor(0, 1, 0, circle_data.alpha)
            local x, y = pool.data.bat.body:getPosition()
            love.graphics.circle("line", x, y, circle_data.radius)
            pool.data.camera:unapply()
        end
    
        anim = common.Anim.new(0.1, true)
        anim:add_frame(1, function() 
            circle_data = {radius = 0, alpha = 1}
            flux.to(circle_data, 2.0, {radius = 400, alpha = 0.0})
            anim.draw = circle_draw
        end)
        anim:add_frame(15, function()
            pool.data.current_level = pool.data.current_level + 1
            if pool.data.current_level == 10 then
                state.switch("title", "attempt_n", "escape", {
                    message = "You escaped!",
                    score = pool.data.score
                })
                return
            end

            construct_and_enter_level()
        end)
    end)
end

function love.update(dt)
    if paused then
        return
    end
    -- UI stuff.
    flux.update(dt)
    if anim then
        anim:update(dt)
        if anim:finished() then
            anim = nil
        else
            return
        end
    end

    -- Game stuff.

    if pool.data.clock >= 0 then
        pool.data.clock = pool.data.clock - dt
        if pool.data.clock <= 0 then
            pool.data.bat:adjust_energy(-110)
        end
    end

    pool:remove(function(e)
        local alive = e:alive()
        if not alive then
            e:destroy()
        end
        return not alive
    end)
    pool:flush()
    pool:emit('update', dt)
    pool.data.world:update(dt)
    local x, y = pool.data.bat.body:getPosition()
    pool.data.camera:follow(x, y)
end

function love.draw()
    -- Game draws.

    pool.data.camera:apply()
    pool:emit("draw")

    -- Rulers
    if _G.CONF.display_rulers then
        love.graphics.setColor(_G.CONF.default_color)
        love.graphics.setLineWidth(1)
        for x = math.multiple(pool.data.camera.x, 100), pool.data.camera.x + love.graphics.getWidth(), 100 do
            love.graphics.line(x, pool.data.camera.y, x, pool.data.camera.y + 5)
        end
        for y = math.multiple(pool.data.camera.y, 100), pool.data.camera.y + love.graphics.getHeight(), 100 do
            love.graphics.line(pool.data.camera.x, y, pool.data.camera.x + 5, y)
        end
    end
    pool.data.camera:unapply()

    -- UI draws.
    if anim then
        anim:draw()
    end

    if _G.CONF.display_diagnostics then
        love.graphics.setFont(_G.ASSETS:get("default_font"))
        love.graphics.setLineWidth(1)
        love.graphics.setColor(_G.CONF.default_color)
        love.graphics.print(love.timer.getFPS(), 0, 0)
        love.graphics.print(math.floor(collectgarbage("count")) .. "kb", 0, 12)
    end

    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()

    local bar_width = 200
    local bar_width_h = bar_width / 2
    local bar_height = 10
    local bar_height_h = bar_height / 2
    local bottom_margin = 30
    love.graphics.setLineWidth(1)
    love.graphics.setColor(_G.CONF.default_color)
    love.graphics.rectangle("line", w / 2 - bar_width_h, h - bar_height_h - bottom_margin, bar_width, bar_height)
    local energy = pool.data.bat.energy / 100
    love.graphics.rectangle("fill", w / 2 - bar_width_h, h - bar_height_h - bottom_margin, bar_width * energy, bar_height)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("line", w / 2 - bar_width_h - 1, h - bar_height_h - bottom_margin - 1, bar_width + 2, bar_height + 2)

    love.graphics.setColor(_G.CONF.default_color)
    local fhh = _G.ASSETS:get("font_regular_s"):getHeight() / 2
    love.graphics.setFont(_G.ASSETS:get("font_regular_s"))
    if pool.data.clock >= 0 then
        love.graphics.printf(tostring(pool.data.score),  w / 2 - bar_width_h, h - bottom_margin / 2 - fhh, bar_width / 2, "left")
        if pool.data.clock < 30 then
            love.graphics.setColor(_G.CONF.main_color)
        end
        if pool.data.clock >= 10 or math.random() > 0.2 then
            local time_string = ("%02d:%02d"):format(math.floor(pool.data.clock / 60), math.floor(pool.data.clock) % 60)
            love.graphics.printf(time_string,  w / 2, h - bottom_margin / 2 - fhh, bar_width / 2, "right")
        end
    else
        love.graphics.printf("Score: " .. tostring(pool.data.score),  w / 2 - bar_width_h, h - bottom_margin / 2 - fhh, bar_width, "center")
    end
end

function love.keypressed(key, scancode, isrepeat)
    _G.CONTROL_KEYS(key, scancode, isrepeat)
    if key == "r" and not isrepeat then
        _G.CONF.display_rulers = not _G.CONF.display_rulers
    end
    if key == "i" and love.keyboard.isDown("lctrl") and not isrepeat then
        _G.CONF.display_diagnostics = not _G.CONF.display_diagnostics
    end

    if key == "d" and love.keyboard.isDown("lctrl") and not isrepeat then
        _G.CONF.debug_mode = not _G.CONF.debug_mode
    end
    if key == "r" and love.keyboard.isDown("lctrl") and not isrepeat then
        construct_and_enter_level()
    end
    if key == "x" and love.keyboard.isDown("lctrl") and not isrepeat then
        pool.data.bat:adjust_energy(-100)
    end
    if key == "f" and love.keyboard.isDown("lctrl") and not isrepeat then
        pool:emit("reached_exit")
    end
    if key == "w" and love.keyboard.isDown("lctrl") and not isrepeat then
        pool.data.current_level = 9
        pool:emit("reached_exit")
    end
    if key == "q" and love.keyboard.isDown("lctrl") and not isrepeat then
        pool.data.bat.energy = 100
    end
    if key == "space" and not isrepeat then
        paused = not paused
    end
end

function love.wheelmoved(x, y)
    if _G.CONF.debug_mode then
        if y > 0 then
            pool.data.camera:scale(0.9)
        else
            pool.data.camera:scale(1.11111111)
        end
    end
end

function love.resize(w, h)
    local cw, ch = love.graphics.getWidth(), love.graphics.getHeight()
    pool.data.camera:scale(w / cw, h / cw)
end

return {
    enter = enter
}
