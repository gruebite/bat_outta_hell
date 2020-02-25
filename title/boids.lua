
local geom = require("common.geom")

local BoidsSystem = {}

BoidsSystem.SWARM_CHANCE = 0.005
BoidsSystem.SENSE_RADIUS_2 = 30*30
BoidsSystem.CHIRP_CHANCE = 0.01

function BoidsSystem:init()
    self.cohesion = function(of)
        local part = geom.Vec2.new()
        local n = 0
        for _, e in ipairs(self.pool.groups.boids.entities) do
            if e ~= of and e.pos:distance2(of.pos) < BoidsSystem.SENSE_RADIUS_2 then
                n = n + 1
                part = part:add(e.pos)
            end
        end
        if n == 0 then
            return part
        end
        part = part:scale(1 / n)
        return part:subtract(of.pos):scale(1 / 100)
    end

    self.separation = function(of)
        local part = geom.Vec2.new()
        for _, e in ipairs(self.pool.groups.boids.entities) do
            if e ~= of and e.pos:distance2(of.pos) < BoidsSystem.SENSE_RADIUS_2 then
                if e.pos:distance2(of.pos) < 1000 then
                    part = part:subtract(e.pos:subtract(of.pos))
                end
            end
        end
        return part
    end

    self.alignment = function(of)
        local part = geom.Vec2.new()
        local n = 0
        for _, e in ipairs(self.pool.groups.boids.entities) do
            if e ~= of and e.pos:distance2(of.pos) < BoidsSystem.SENSE_RADIUS_2 then
                n = n + 1
                part = part:add(e.vel)
            end
        end
        if n == 0 then
            return part
        end
        part = part:scale(1 / n)

        return part:subtract(of.vel):scale(1 / 8)
    end

    self.towards = function(of, to, sc)
        to = to or geom.Vec2.new(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
		return to:subtract(of.pos):scale(sc or (1 / 1000))
    end

    self.swarm_to = nil
    self.swarm_timer = 0
end

function BoidsSystem:update(dt)
    if self.swarm_to then
        self.swarm_timer = self.swarm_timer - dt
        if self.swarm_timer < 0 then
            self.swarm_to = nil
        end
    end

    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()

    if not self.swarm_to and love.math.random() < BoidsSystem.SWARM_CHANCE then
        self.swarm_to = geom.Vec2.new(love.math.random(1, w), love.math.random(1, h))
        self.swarm_timer = love.math.random(3, 10)
    end

    local picked = 0
    if love.math.random() < BoidsSystem.CHIRP_CHANCE then
        picked = love.math.random(#self.pool.groups.boids.entities)
    end

    for i, e in ipairs(self.pool.groups.boids.entities) do
        local v = self.cohesion(e)
        v = v:add(self.separation(e))
        v = v:add(self.alignment(e))
        if self.swarm_to then
            v = v:add(self.towards(e, self.swarm_to, 1 / 500))
        else
            v = v:add(self.towards(e))
        end

        e.vel = e.vel:add(v)
        -- Max speed.
        local limit = e.speed
        if self.swarm_to then
            limit = limit * 1.5
        end
        if e.vel:magnitude() > limit then
            e.vel = e.vel:normalize():scale(limit)
        end

        local tl = geom.Vec2.new(0, 0)
        local br = geom.Vec2.new(w, h)

        if e.pos.x < tl.x then
            e.vel.x = 10
        elseif e.pos.x > br.x then
            e.vel.x = -10
        end
        if e.pos.y < tl.y then
            e.vel.y = 10
        elseif e.pos.y > br.y then
            e.vel.y = -10
        end

        e.pos = e.pos:add(e.vel:scale(dt))

        if i == picked then
            self.pool:queue {
                pos = e.pos:copy(),
                size = 0,
                color = _G.CONF.colors[love.math.random(1, #_G.CONF.colors)]
            }
        end
    end
end

local AnimationSystem = {}

function AnimationSystem:update(dt)
    for _, e in ipairs(self.pool.groups.anims.entities) do
        for _, a in ipairs(e.anims) do
            a:update(dt)
        end
    end
end

function AnimationSystem:draw()
    for _, e in ipairs(self.pool.groups.anims.entities) do
        for _, a in ipairs(e.anims) do
            a:draw()
        end
    end
end

local ChirpSystem = {}

function ChirpSystem:update(dt)
    for _, e in ipairs(self.pool.groups.chirps.entities) do
        e.size = e.size + 400 * dt
        if e.size > 400 then
            e.dead = true
        end
    end
end

function ChirpSystem:draw()
    for _, e in ipairs(self.pool.groups.chirps.entities) do
        love.graphics.setColor(e.color[1], e.color[2], e.color[3], 0.5)
        love.graphics.setLineWidth(1)
        love.graphics.circle("line", e.pos.x, e.pos.y, e.size)
    end
end

return {
    BoidsSystem = BoidsSystem,
    AnimationSystem = AnimationSystem,
    ChirpSystem = ChirpSystem
}