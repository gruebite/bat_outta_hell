
local flux = require("lib.flux")
local moonshine = require("lib.moonshine")
local nata = require("lib.nata")

local Anim = require("common").Anim
local Vec2 = require("common.geom").Vec2

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

local VANISHING_SIZE = 400
local STARTING_WEIGHT = 6

local Echo = setmetatable({}, {__index = Mob})
Echo.__index = Echo

function Echo.new(bat, source, color)
    return setmetatable({
        is_echo = true,
        bat = bat,
        source = source,
        color = color,
        size = 1,
        effect = moonshine(moonshine.effects.glow),
        speed = VANISHING_SIZE,
    }, Echo)
end

function Echo:update(dt)
    -- When hitting the bat we slow down.
    if self:_is_hitting() then
        self.size = self.size + (self.speed / 3) * dt
    else
        self.size = self.size + self.speed * dt
    end
end

function Echo:alive()
    return not self:_is_outgoing(50)
end

function Echo:draw()
    --self.effect(function()
        local strength = 1 - math.pow(self.size / VANISHING_SIZE, 1.5)
        love.graphics.setLineWidth(STARTING_WEIGHT * strength)
        self.color[4] = strength
        love.graphics.setColor(self.color)
        love.graphics.circle("line", self.source[1], self.source[2], self.size)
    --end)
end

function Echo:_is_incoming()
    local x, y = self.bat.body:getPosition()
    local dist = Vec2.new(x, y):distance(self.source[1], self.source[2])
    return self.size < (dist - self.bat.ear_size * 2)
end

function Echo:_is_outgoing(buffer)
    local x, y = self.bat.body:getPosition()
    local dist = Vec2.new(x, y):distance(self.source[1], self.source[2])
    return self.size > (dist + self.bat.ear_size * 2 * (buffer or 1))
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
    fixt:setCategory(CONSTS.CATEGORY_SENSOR)
    fixt:setMask(CONSTS.CATEGORY_BAT)
    local self = setmetatable({
        is_chirp = true,
        pool = pool,
        body = body,
        _sensor = fixt,
        _speed = VANISHING_SIZE,
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
    self._sensor:getShape():setRadius(self._sensor:getShape():getRadius() + self._speed * dt)
end

function Chirp:alive()
    return self._sensor:getShape():getRadius() < VANISHING_SIZE
end

function Chirp:destroy()
    self._sensor:destroy()
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
            self.pool.data.bat.echo_pool:queue(Echo.new(self.pool.data.bat, {x, y}, data.echo_color and table.deepcopy(data.echo_color) or {1.0, 1.0, 1.0, 1.0}))
        end
        -- Only hit the first one.
        return 0
    end)
end

local Bat = setmetatable({}, {__index = Mob})
Bat.__index = Bat

Bat.RADIUS = 8

Bat.CHIRP_LIMIT = 3

function Bat.new(pool, x, y)
    local body = love.physics.newBody(pool.data.world, x, y, "dynamic")
    local shape = love.physics.newCircleShape(Bat.RADIUS)
    local fixt = love.physics.newFixture(body, shape)
    fixt:setCategory(CONSTS.CATEGORY_BAT)

    local self = setmetatable({
        is_bat = true,
        chirp_pool = nata.new(),
        echo_pool = nata.new(),
        pool = pool,
        body = body,
        size = 8,
        ear_size = 16,
        speed = 120,
        stunned = 0,
        energy = 100,

        _dir = 0,
        _anim = Anim.new(1 / 20.0, true, true, 3),

        _chirping = false,
    }, Bat)
    fixt:setUserData(self)

    return self
end

function Bat:update(dt)
    self.body:setAwake(true)
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

    if self.stunned > 0 then
        self.stunned = self.stunned - dt
        return
    end
    if love.mouse.isDown(1) then
        local mx, my = self.pool.data.camera:mouse_position()
        local vel = Vec2.new(mx, my):subtract(self.body:getPosition())
        if vel:magnitude() > 0 then
            vel = vel:normalize():scale(self.speed)
        end
        self.body:setLinearVelocity(vel.x, vel.y)
        self._dir = vel:angle()
    else
        self.body:setLinearVelocity(0, 0)
    end

    if love.mouse.isDown(2) and not self._chirping then
        if #self.chirp_pool.entities < Bat.CHIRP_LIMIT then
            self._chirping = true
            --_G.ASSETS:get("chirp"):play()
            self.chirp_pool:queue(Chirp.new(self.pool))
        end
    end
    if not love.mouse.isDown(2) then
        self._chirping = false
    end
end

function Bat:draw()
    local x, y = self.body:getPosition()
    love.graphics.setLineWidth(1)

    love.graphics.stencil(function()
        love.graphics.setLineWidth(self.ear_size / 2)
        love.graphics.circle("fill", x, y, self.ear_size)
    end, "replace", 1)
    -- Only allow rendering on pixels which have a stencil value greater than 0.
    love.graphics.setStencilTest("greater", 0)
    -- Draw echos.
    self.echo_pool:emit("draw")
    love.graphics.setStencilTest()

    love.graphics.setColor(1.0, 1.0, 1.0)
    love.graphics.draw(_G.ASSETS:get("bat", math.floor(self._anim.frame)), x, y, self._dir, 1, 1, 8, 8)

    -- Draw chirps.
    self.chirp_pool:emit("draw")
end

function Bat:destroy()
    self.body:destroy()
end

function Bat:begin_contact(fixt, other, coll)
    -- Ignore sensors.
    if other:isSensor() then return end

    local owner = other:getUserData()
    if owner.is_exit then
        -- Exit world.
        return
    end
    if owner.is_insect then
        self:adjust_energy(20)
        owner:kill()
        local effect = self.pool:queue(EffectMob.new(self.pool, {radius = 0, alpha = 1.0},
        function(effect)
            love.graphics.setColor(owner.echo_color[1], owner.echo_color[2], owner.echo_color[3], effect.alpha)
            love.graphics.setLineWidth(3)
            local x, y = self.body:getPosition()
            love.graphics.circle("line", x, y, effect.radius)
        end,
        function(effect)
            return effect.radius < VANISHING_SIZE
        end))
        flux.to(effect, 0.5, {radius = VANISHING_SIZE, alpha = 0.2})
        return
    end
    if owner.is_hawk then
    end
    --_G.ASSETS:get("squeek"):play()
    local x, y = coll:getNormal()
    self.body:setLinearVelocity(x * 400, y * 400)
    self.stunned = 0.1
    self:adjust_energy(-10)
end

function Bat:end_contact(fixt, other, coll)
end

function Bat:adjust_energy(by)
    local current = self.energy
    self.energy = math.min(100, math.max(0, self.energy + by))
    self.pool:emit("energy_adjusted", by, current, self.energy)
end

local Insect = setmetatable({}, {__index = Mob})
Insect.__index = Insect

Insect.RADIUS = 8

function Insect.new(pool, x, y)
    local body = love.physics.newBody(pool.data.world, x, y, "dynamic")
    local fixt = love.physics.newFixture(body, love.physics.newCircleShape(Insect.RADIUS))
    fixt:setCategory(CONSTS.CATEGORY_INSECT)
    fixt:setMask(CONSTS.CATEGORY_INSECT, CONSTS.CATEGORY_HAWK)

    local sensor_fixt = love.physics.newFixture(body, love.physics.newCircleShape(Insect.RADIUS * 10))
    sensor_fixt:setCategory(CONSTS.CATEGORY_SENSOR)
    -- Only alter behavior for objects and player
    sensor_fixt:setMask(CONSTS.CATEGORY_INSECT, CONSTS.CATEGORY_HAWK, CONSTS.CATEGORY_SENSOR)
    sensor_fixt:setSensor(true)

    local speed = love.math.random(40, 120)
    local dir = Vec2.LEFT:rotate(love.math.random() * math.pi * 2):scale(speed)
    body:setLinearVelocity(dir.x, dir.y)
    local self = setmetatable({
        is_insect = true,
        pool = pool,
        body = body,
        speed = speed,
        visible = true,
        ignores_bat = math.random() > 0.5,
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
    if self.visible then
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

function Insect:destroy()
    self.body:destroy()
end

function Insect:begin_contact(fixt, other, coll)
    self._sensed[other] = true
end

function Insect:end_contact(fixt, other, coll)
    self._sensed[other] = nil
end

local Hawk = setmetatable({}, {__index = Mob})
Hawk.__index = Hawk

Hawk.RADIUS = 8

function Hawk.new(pool, x, y)
    local body = love.physics.newBody(pool.data.world, x, y, "dynamic")
    local shape = love.physics.newCircleShape(Hawk.RADIUS)
    local fixt = love.physics.newFixture(body, shape)
    fixt:setCategory(CONSTS.CATEGORY_HAWK)
    fixt:setMask(CONSTS.CATEGORY_INSECT, CONSTS.CATEGORY_HAWK)
    fixt:setSensor(true)
    local self = setmetatable({
        is_hawk = true,
        pool = pool,
        body = body,
        visible = true,
        echo_color = {1.0, 0.0, 0.0, 1.0},
    }, Hawk)
    fixt:setUserData(self)
    return self
end

function Hawk:draw()
    if self.visible then
        love.graphics.setColor(self.echo_color)
        local x, y = self.body:getPosition()
        love.graphics.circle("fill", x, y, self.body:getFixtures()[1]:getShape():getRadius())
    end
end

function Hawk:kill()
    self.dead = true
end

function Hawk:alive()
    return not self.dead
end

function Hawk:destroy()
    self.body:destroy()
end

return {
    Mob = Mob,
    Bat = Bat,
    Insect = Insect,
    Hawk = Hawk,
}
