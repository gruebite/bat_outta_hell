
local flux = require("lib.flux")
local moonshine = require("lib.moonshine")
local nata = require("lib.nata")

local Anim = require("common").Anim
local Vec2 = require("common.geom").Vec2

-- Because sensors do not give us normals when they collide. :/
local function find_fixture_contact_point(pos, to_fixt)
    local m = to_fixt:getUserData()
    local fx, fy = to_fixt:getBody():getPosition()
    if m.is_wall then
        -- Adding/subtracting an arbitrary amount to cast past.
        -- TOP
        if pos.y < m.tl.y then
            -- LEFT
            if pos.x < m.tl.x then
                fx, fy = m.tl.x + 5, m.tl.y + 5
            -- RIGHT
            elseif pos.x > m.br.x then
                fx, fy = m.br.x - 5, m.tl.y + 5
            else
                fx, fy = pos.x, m.tl.y + 5
            end
        elseif pos.y > m.br.y then
            -- LEFT
            if pos.x < m.tl.x then
                fx, fy = m.tl.x + 5, m.br.y - 5
            -- RIGHT
            elseif pos.x > m.br.x then
                fx, fy = m.br.x - 5, m.tl.y - 5
            else
                fx, fy = pos.x, m.br.y - 5
            end
        elseif pos.x < m.tl.x then
            fx, fy = m.tl.x + 5, pos.y
        elseif pos.x > m.br.x then
            fx, fy = m.br.x - 5, pos.y
        else
            -- Inside. Use center of object in this case so insects can dodge walls.
        end
    end
    return fx, fy
end

local Mob = {}
Mob.__index = Mob

-- Defaults to white.
Mob.echo_color = _G.CONF.default_color

function Mob.new()
    return setmetatable({}, Mob)
end

function Mob:update(dt)
end

function Mob:draw()
end

function Mob:alive()
    return true
end

function Mob:destroy()
    -- If the mob has a body, destroy it.
    if self.body then
        self.body:destroy()
    end
end

local EffectMob = setmetatable({}, {__index = Mob})
EffectMob.__index = EffectMob

function EffectMob.new(pool, data, draw, alive, update)
    local self = setmetatable({
        is_effect = true,
        pool = pool,
        draw = draw,
        alive = alive,
        update = update,
    }, EffectMob)
    for k, v in pairs(data) do
        self[k] = v
    end
    return self
end

local Echo = setmetatable({}, {__index = Mob})
Echo.__index = Echo

function Echo.new(pool, source, color)
    return setmetatable({
        is_echo = true,
        pool = pool,
        source = source,
        color = color,
        size = 1,
        effect = moonshine(moonshine.effects.glow),
    }, Echo)
end

function Echo:update(dt)
    -- When hitting the bat we slow down.
    if self:_is_hitting() then
        self.size = self.size + self.pool.data:get_current_level_config().echo_speed_dampened * dt
    else
        self.size = self.size + self.pool.data:get_current_level_config().echo_speed * dt
    end
end

function Echo:alive()
    return not self:_is_outgoing()
end

function Echo:draw()
    --self.effect(function()
        local strength = 1 - math.pow(self.size / self.pool.data:get_current_level_config().echo_vanishing_distance, 1.5)
        love.graphics.setLineWidth(self.pool.data:get_current_level_config().echo_weight * strength)
        self.color[4] = strength
        love.graphics.setColor(self.color)
        love.graphics.circle("line", self.source.x, self.source.y, self.size)
    --end)
end

function Echo:_is_incoming()
    local x, y = self.pool.data.bat.body:getPosition()
    local dist = Vec2.new(x, y):distance(self.source.x, self.source.y)
    return self.size < (dist - self.pool.data:get_current_level_config().bat_ear_size * 2)
end

function Echo:_is_outgoing()
    local x, y = self.pool.data.bat.body:getPosition()
    local dist = Vec2.new(x, y):distance(self.source.x, self.source.y)
    return self.size > (dist + self.pool.data:get_current_level_config().bat_ear_size * 2)
end

function Echo:_is_hitting()
    return not self:_is_incoming() and not self:_is_outgoing()
end

local Chirp = setmetatable({}, {__index = Mob})
Chirp.__index = Chirp

function Chirp.new(pool)
    local x, y = pool.data.bat.body:getPosition()
    local body = love.physics.newBody(pool.data.world, x, y, "dynamic")
    local fixt = love.physics.newFixture(body, love.physics.newCircleShape(0))
    fixt:setSensor(true)
    fixt:setCategory(CONSTS.category_sensor)
    fixt:setMask(CONSTS.category_bat, CONSTS.category_sensor)
    local self = setmetatable({
        is_chirp = true,
        pool = pool,
        body = body,
        _sensor = fixt,
    }, Chirp)
    fixt:setUserData(self)
    return self
end

function Chirp:draw()
    love.graphics.setLineWidth(1)
    love.graphics.setColor(0.4, 0.4, 0.4, 1.0)
    local x, y = self.body:getPosition()
    love.graphics.circle("line", x, y, self._sensor:getShape():getRadius())
end

function Chirp:update(dt)
    -- For sensors that move without the body moving.
    self.body:setAwake(true)
    local new_radius = self._sensor:getShape():getRadius() + self.pool.data:get_current_level_config().chirp_speed * dt
    self._sensor:getShape():setRadius(new_radius)
end

function Chirp:alive()
    return self._sensor:getShape():getRadius() < self.pool.data:get_current_level_config().echo_vanishing_distance
end

function Chirp:begin_contact(fixt, other, coll)
    local self_x, self_y = self.body:getPosition()
    local fx, fy = find_fixture_contact_point(Vec2.new(self_x, self_y), other)
    self.pool.data.bat.body:getWorld():rayCast(self_x, self_y, fx, fy, function(hit, x, y, xn, yn, fraction)
        if hit:getUserData().is_chirp or hit:getUserData().is_bat then
            return 1
        end
        if hit == other then
            local data = other:getUserData()
            -- We use x, y from contact.
            self.pool.data.bat.echo_pool:queue(Echo.new(self.pool, Vec2.new(x, y), data.echo_color and table.deepcopy(data.echo_color) or {1.0, 1.0, 1.0, 1.0}))
        end
        -- Only hit the first one.
        return 0
    end)
end

local Bat = setmetatable({}, {__index = Mob})
Bat.__index = Bat

function Bat.new(pool, x, y)
    local body = love.physics.newBody(pool.data.world, x, y, "dynamic")
    local shape = love.physics.newCircleShape(pool.data:get_current_level_config().bat_radius)
    local fixt = love.physics.newFixture(body, shape)
    fixt:setCategory(_G.CONSTS.category_bat)

    local self = setmetatable({
        is_bat = true,
        chirp_pool = nata.new(),
        echo_pool = nata.new(),
        pool = pool,
        body = body,
        -- Prevents bat from moving until mouse is released.
        stunned = false,
        energy = 100,

        _dir = 0,
        _anim = Anim.new(1 / 20.0, true, true, 3),

        _boosting = false,
        _stun_timer = 0,
        _boosting_timer = 0,
        _boosting_decay = 0,
        _chirping = false,
    }, Bat)
    fixt:setUserData(self)

    return self
end

function Bat:update(dt)
    if self.paused then
        return
    end
    self._anim:update(dt)
    -- Update echos.
    self.echo_pool:remove(function(e)
        local alive = e:alive()
        if not alive then
            e:destroy()
        end
        return not alive
    end)
    self.echo_pool:flush()
    self.echo_pool:emit("update", dt)
    self.chirp_pool:remove(function(e)
        local alive = e:alive()
        if not alive then
            e:destroy()
        end
        return not alive
    end)
    self.chirp_pool:flush()
    self.chirp_pool:emit("update", dt)

    if self._stun_timer > 0 then
        self.body:setLinearVelocity(self._stun_throwback.x, self._stun_throwback.y)
        self._stun_timer = self._stun_timer - dt
        return
    end
    if not love.mouse.isDown(1) then
        -- Releasing mouse prevents movement lock.
        self.stunned = false
    end

    if love.mouse.isDown(1) and not self.stunned then
        local mx, my = self.pool.data.camera:mouse_position()
        local vel = Vec2.new(mx, my):subtract(self.body:getPosition())
        if vel:magnitude() > 0 then
            local speed
            if self._boosting then
                speed = self.pool.data:get_current_level_config().bat_boost_speed
            else
                speed = self.pool.data:get_current_level_config().bat_speed
            end
            vel = vel:normalize():scale(speed)
        end
        self.body:setLinearVelocity(vel.x, vel.y)
        self._dir = vel:angle()
    else
        self.body:setLinearVelocity(0, 0)
    end

    if love.mouse.isDown(2) and not self.stunned then
        if  not self._chirping and #self.chirp_pool.entities < self.pool.data:get_current_level_config().bat_chirp_limit then
            self._chirping = true
            _G.ASSETS:get("chirp"):play()
            self.chirp_pool:queue(Chirp.new(self.pool))
        end
        self._boosting_timer = self._boosting_timer + dt
        if self._boosting_timer >= self.pool.data:get_current_level_config().bat_boost_delay then
            self._boosting = true
            self._boosting_decay = self._boosting_decay + dt * self.pool.data:get_current_level_config().bat_boost_energy_decay
            if self._boosting_decay > 1 then
                local amount = math.floor(self._boosting_decay)
                self._boosting_decay = self._boosting_decay - amount
                self:adjust_energy(-amount, nil)
            end
        end
    end
    if not love.mouse.isDown(2) then
        self._chirping = false
        self._boosting = false
        self._boosting_timer = 0
    end
end

function Bat:draw()
    self.body:setAwake(true)
    if self.invisible then
        return
    end
    local x, y = self.body:getPosition()
    love.graphics.setLineWidth(1)

    love.graphics.stencil(function()
        love.graphics.circle("fill", x, y, self.pool.data:get_current_level_config().bat_ear_size)
    end, "replace", 1)
    -- Only allow rendering on pixels which have a stencil value greater than 0.
    if not _G.CONF.debug_mode then
        love.graphics.setStencilTest("greater", 0)
    end
    -- Draw echos.
    self.echo_pool:emit("draw")
    love.graphics.setStencilTest()

    love.graphics.setColor(1.0, 1.0, 1.0)
    if (self.stunned and love.math.random() > 0.2) then
        love.graphics.setColor(_G.CONF.main_color)
    end
    love.graphics.draw(_G.ASSETS:get("bat", math.floor(self._anim.frame)), x, y, self._dir, 1, 1, 8, 8)

    -- Draw chirps.
    self.chirp_pool:emit("draw")
end

function Bat:begin_contact(fixt, other, coll)
    -- Ignore sensors.
    if other:isSensor() then return end

    local owner = other:getUserData()
    if owner.is_exit then
        self.pool:emit("reached_exit")
        return
    end
    if owner.is_insect then
        self:adjust_energy(self.pool.data:get_current_level_config().insect_consume_energy, owner)
        _G.ASSETS:get("crunch"):play()
        owner:kill()
        return
    end
    _G.ASSETS:get("squeek"):play()
    local x, y = coll:getNormal()
    -- Determine if the normal points to us or the object. We want it to point away from object.
    local bx, by = self.body:getPosition()
    local ox, oy = other:getBody():getPosition()
    -- If direction from us to object is pointing in the same direction as the normal, flip.
    if Vec2.new(x, y):dot(Vec2.new(ox, oy):subtract(bx, by)) > 0 then
        x = -x
        y = -y
    end

    self._stun_throwback = Vec2.new(x * 400, y * 400)
    self._stun_timer = 0.1
    self.stunned = true
    if owner.is_hawk then
        self:adjust_energy(-self.pool.data:get_current_level_config().hawk_bump_damage, owner)
    else
        self:adjust_energy(-self.pool.data:get_current_level_config().object_bump_damage, owner)
    end
end

function Bat:adjust_energy(by, from)
    local current = self.energy
    self.energy = math.min(100, math.max(0, self.energy + by))
    self.pool:emit("energy_adjusted", by, current, self.energy, from)

    -- Animate if from is something.
    if not from then
        return
    end
    local x, y = self.body:getPosition()
    local max_size = 20
    if from.is_insect then
        self.pool.data:adjust_score(self.pool.data:get_current_level_config().insect_consume_score)
        max_size = 300
    else
        -- Clear current chirps and echos. Too noisy if hit.
        self.chirp_pool:remove(function() return true end)
        self.echo_pool:remove(function() return true end)
    end
    local effect = self.pool:queue(EffectMob.new(self.pool, {radius = 0, alpha = 1.0},
    function(effect)
        love.graphics.setColor(from.echo_color[1], from.echo_color[2], from.echo_color[3], effect.alpha)
        love.graphics.setLineWidth(3)
        love.graphics.circle("line", x, y, effect.radius)
    end,
    function(effect)
        return effect.radius < max_size
    end))
    flux.to(effect, 0.5, {radius = max_size, alpha = 0.2})
end

local Insect = setmetatable({}, {__index = Mob})
Insect.__index = Insect

function Insect.new(pool, x, y)
    local radius = pool.data:get_current_level_config().insect_radius
    local body = love.physics.newBody(pool.data.world, x, y, "dynamic")
    local fixt = love.physics.newFixture(body, love.physics.newCircleShape(radius))
    fixt:setCategory(CONSTS.category_insect)
    fixt:setMask(CONSTS.category_insect, CONSTS.category_hawk)

    local sensor_fixt = love.physics.newFixture(body, love.physics.newCircleShape(pool.data:get_current_level_config().insect_sensor_radius))
    sensor_fixt:setCategory(CONSTS.category_sensor)
    -- Only alter behavior for objects and player
    sensor_fixt:setMask(CONSTS.category_insect, CONSTS.category_hawk, CONSTS.category_sensor)
    sensor_fixt:setSensor(true)

    local speed = love.math.random(pool.data:get_current_level_config().insect_speed_min, pool.data:get_current_level_config().insect_speed_max)
    local dir = Vec2.new(-1, 0):rotate(love.math.random() * math.pi * 2):scale(speed)
    body:setLinearVelocity(dir.x, dir.y)
    local self = setmetatable({
        is_insect = true,
        pool = pool,
        body = body,
        speed = speed,
        ignores_bat = math.random() < pool.data:get_current_level_config().insect_oblivious_chance,
        echo_color = {0.0, 1.0, 1.0, 1.0},

        _sensed = {}
    }, Insect)
    fixt:setUserData(self)
    sensor_fixt:setUserData(self)
    return self
end

function Insect:update(dt)
    local avoid_dir = Vec2.new()
    local x, y = self.body:getPosition()
    local pos = Vec2.new(x, y)
    local n = 0
    for other, _ in pairs(self._sensed) do
        if not other:getUserData().is_bat or not self.ignores_bat then
            n = n + 1
            local fx, fy = find_fixture_contact_point(pos, other)
            local opos = Vec2.new(fx, fy)
            avoid_dir = avoid_dir:subtract(opos:subtract(pos))
        end
    end
    if n ~= 0 then
        avoid_dir = avoid_dir:scale(1 / n)
    end
    local vx, vy = self.body:getLinearVelocity()
    local dir = Vec2.new(vx, vy):add(avoid_dir)
    if dir:magnitude() > self.speed then
        dir = dir:normalize():scale(self.speed)
    end
    self.body:setLinearVelocity(dir.x, dir.y)
end

function Insect:draw()
    if _G.CONF.debug_mode then
        love.graphics.setColor(self.echo_color)
        local x, y = self.body:getPosition()
        love.graphics.setLineWidth(2)
        love.graphics.circle("fill", x, y, self.body:getFixtures()[2]:getShape():getRadius())
    end
end

function Insect:kill()
    self.dead = true
end

function Insect:alive()
    return not self.dead
end

function Insect:begin_contact(fixt, other, coll)
    self._sensed[other] = true
end

function Insect:end_contact(fixt, other, coll)
    self._sensed[other] = nil
end

-- A lot of this class shares behavior with insect.
local Hawk = setmetatable({}, {__index = Mob})
Hawk.__index = Hawk

function Hawk.new(pool, x, y)
    local body = love.physics.newBody(pool.data.world, x, y, "dynamic")
    local shape = love.physics.newCircleShape(pool.data:get_current_level_config().hawk_radius)
    local fixt = love.physics.newFixture(body, shape)
    fixt:setCategory(CONSTS.category_hawk)
    fixt:setMask(CONSTS.category_insect, CONSTS.category_hawk)

    local sensor_fixt = love.physics.newFixture(body, love.physics.newCircleShape(pool.data:get_current_level_config().hawk_sensor_radius))
    sensor_fixt:setCategory(CONSTS.category_sensor)
    -- Only alter behavior for objects and player
    sensor_fixt:setMask(CONSTS.category_insect, CONSTS.category_hawk, CONSTS.category_sensor)
    sensor_fixt:setSensor(true)

    local speed = love.math.random(pool.data:get_current_level_config().hawk_speed_min, pool.data:get_current_level_config().hawk_speed_max)
    local dir = Vec2.new(-1, 0):rotate(love.math.random() * math.pi * 2):scale(speed)
    body:setLinearVelocity(dir.x, dir.y)
    local self = setmetatable({
        is_hawk = true,
        pool = pool,
        body = body,

        speed = speed,
        -- 0 means not homing, negatives indicate homing cooldown.
        homing_timer = 0,
        echo_color = {1.0, 0.0, 0.0, 1.0},

        _sensor_fixt = sensor_fixt,
        _sensed = {},
    }, Hawk)
    fixt:setUserData(self)
    sensor_fixt:setUserData(self)
    return self
end

function Hawk:update(dt)
    local avoid_dir = Vec2.new()
    local x, y = self.body:getPosition()
    local pos = Vec2.new(x, y)
    local n = 0
    -- Adjust homing timer if it's on cooldown.
    if self.homing_timer < 0 then
        self.homing_timer = math.min(0, self.homing_timer + dt)
    end
    for other, _ in pairs(self._sensed) do
        local fx, fy = find_fixture_contact_point(pos, other)
        local opos = Vec2.new(fx, fy)
        if other:getUserData().is_bat then
            if self.homing_timer > 0 then
                self.homing_timer = self.homing_timer - dt
                if self.homing_timer <= 0 then
                    self.homing_timer = -self.pool.data:get_current_level_config().hawk_homing_cooldown
                else
                    -- Double weighted towards bat.
                    n = n + 1
                    avoid_dir = avoid_dir:add(opos:subtract(pos):scale(2))
                end
            elseif self.homing_timer == 0 then
                -- 0 means we aren't homing but can.
                local mini = self.pool.data:get_current_level_config().hawk_homing_time_min
                local maxi = self.pool.data:get_current_level_config().hawk_homing_time_max
                self.homing_timer = love.math.random() * (maxi - mini) + mini
            end
        else
            n = n + 1
            avoid_dir = avoid_dir:subtract(opos:subtract(pos))
        end
    end
    if n ~= 0 then
        avoid_dir = avoid_dir:scale(1 / n)
    end
    local vx, vy = self.body:getLinearVelocity()
    local dir = Vec2.new(vx, vy):add(avoid_dir)
    if dir:magnitude() > self.speed then
        dir = dir:normalize():scale(self.speed)
    end
    self.body:setLinearVelocity(dir.x, dir.y)
end

function Hawk:draw()
    if _G.CONF.debug_mode then
        love.graphics.setColor(self.echo_color)
        local x, y = self.body:getPosition()
        love.graphics.circle("fill", x, y, self.body:getFixtures()[2]:getShape():getRadius())
        love.graphics.circle("line", x, y, self.body:getFixtures()[1]:getShape():getRadius())
    end
end

function Hawk:kill()
    self.dead = true
end

function Hawk:alive()
    return not self.dead
end

function Hawk:begin_contact(fixt, other, coll)
    if other:getUserData().is_bat and fixt ~= self._sensor_fixt then
        -- Hit, so stop following.
        self.homing_timer = -self.pool.data:get_current_level_config().hawk_homing_cooldown
    end
    self._sensed[other] = true
end

function Hawk:end_contact(fixt, other, coll)
    self._sensed[other] = nil
end

return {
    Mob = Mob,
    Bat = Bat,
    Insect = Insect,
    Hawk = Hawk,
}
