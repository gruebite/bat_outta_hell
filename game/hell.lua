
local geom = require("common.geom")
local mobs = require(_P(..., "^mobs"))

local Wall = setmetatable({}, {__index = mobs.Mob})
Wall.__index = Wall

function Wall.new(pool, tl, br)
    local body = love.physics.newBody(pool.data.world, (br.x + tl.x) / 2, (br.y + tl.y) / 2, "static")
    local fixt = love.physics.newFixture(body, love.physics.newRectangleShape(br.x - tl.x, br.y - tl.y))
    fixt:setCategory(_G.CONSTS.category_fire)
    local self = setmetatable({
        is_wall = true,
        -- Turn into functions and use shape?
        tl = tl,
        br = br,
        pool = pool,
        body = body,
        echo_color = _G.CONF.wall_echo_color
    }, Wall)
    fixt:setUserData(self)
    return self
end

function Wall:draw()
    if _G.CONF.debug_mode then
        love.graphics.setColor(self.echo_color)
        love.graphics.rectangle("fill", self.tl.x, self.tl.y, self.br.x - self.tl.x, self.br.y - self.tl.y)
    end
end

local Fire = setmetatable({}, {__index = mobs.Mob})
Fire.__index = Fire

function Fire.new(pool, x, y, radius)
    local body = love.physics.newBody(pool.data.world, x, y, "static")
    local fixt = love.physics.newFixture(body, love.physics.newCircleShape(radius))
    fixt:setCategory(CONSTS.category_fire)
    local self = setmetatable({
        is_fire = true,
        pool = pool,
        body = body,
        echo_color = _G.CONF.fire_echo_color
    }, Fire)
    fixt:setUserData(self)
    return self
end

function Fire:draw()
    if _G.CONF.debug_mode then
        love.graphics.setColor(self.echo_color)
        local x, y = self.body:getPosition()
        love.graphics.circle("fill", x, y, self.body:getFixtures()[1]:getShape():getRadius())
    end
end

local Exit = setmetatable({}, {__index = mobs.Mob})
Exit.__index = Exit

function Exit.new(pool, x, y, radius)
    local body = love.physics.newBody(pool.data.world, x, y, "static")
    local fixt = love.physics.newFixture(body, love.physics.newCircleShape(radius))
    fixt:setCategory(CONSTS.category_fire)
    fixt:setMask(CONSTS.category_insect, CONSTS.category_hawk)
    local self = setmetatable({
        is_exit = true,
        pool = pool,
        body = body,
        echo_color = _G.CONF.exit_echo_color
    }, Fire)
    fixt:setUserData(self)
    return self
end

function Exit:draw()
    if _G.CONF.debug_mode then
        love.graphics.setColor(self.echo_color)
        local x, y = self.body:getPosition()
        love.graphics.circle("fill", x, y, self.body:getFixtures()[1]:getShape():getRadius())
    end
end

local Level = {}
Level.__index = Level

function Level.new(pool)
    return setmetatable({
        pool = pool,
    }, Level)
end

function Level:is_inside(pos)
    local tl_x = -self.width / 2
    local tl_y = -self.height / 2
    local br_x = self.width / 2
    local br_y = self.height / 2
    return pos.x > tl_x and pos.x < br_x and pos.y > tl_y and pos.y < br_y
end

function Level:construct_perimeter(width, height)
    local WALL_DEPTH = 20

    local tl_x = -width / 2
    local tl_y = -height / 2
    local br_x = width / 2
    local br_y = height / 2

    -- Left and right.
    self.pool:queue(Wall.new(self.pool,
        geom.Vec2.new(tl_x - WALL_DEPTH, tl_y),
        geom.Vec2.new(tl_x, tl_y + height)
    ))
    self.pool:queue(Wall.new(self.pool,
        geom.Vec2.new(tl_x + width, tl_y),
        geom.Vec2.new(tl_x + width + WALL_DEPTH, tl_y + height)
    ))
    -- Top and bottom.
    self.pool:queue(Wall.new(self.pool,
        geom.Vec2.new(tl_x, tl_y - WALL_DEPTH),
        geom.Vec2.new(tl_x + width, tl_y)
    ))
    self.pool:queue(Wall.new(self.pool,
        geom.Vec2.new(tl_x, tl_y + height),
        geom.Vec2.new(tl_x + width, tl_y + height + WALL_DEPTH)
    ))
end

function Level:clear()
    self.pool:remove(function(e)
        -- Everything but the bat.
        local yes = not e.is_bat
        if yes then
            e:destroy()
        end
        return yes
    end)
    self.pool:flush()
end

function Level:construct(with_amethyst)
    self:clear()
    self.width = self.pool.data:get_current_level_config().width
    self.height = self.pool.data:get_current_level_config().height
    self:construct_perimeter(self.width, self.height)

    -- Chance to cull a tree.
    local culling = self.pool.data:get_current_level_config().culling or 0
    -- Threshold for r2 minimun guaranteed distance (scaled).
    local spacing = self.pool.data:get_current_level_config().spacing or 200

    local fire_radius_min = self.pool.data:get_current_level_config().fire_radius_min or 20
    local fire_radius_max = self.pool.data:get_current_level_config().fire_radius_max or 30
    -- Number of mob start positions generated.
    local insect_count = self.pool.data:get_current_level_config().insect_count or 3
    local hawk_count = self.pool.data:get_current_level_config().hawk_count or 1
    local num_mobs = insect_count + hawk_count

    -- Prevents playing from spawning next to wall. This should change if width/height are
    local bat_radius = self.pool.data:get_current_level_config().bat_radius
    local buffer_width = self.width - (bat_radius * 2 + 2)
    local buffer_height = self.height - (bat_radius * 2 + 2)
    local buffer_x = (bat_radius  + 1)
    local buffer_y = (bat_radius  + 1)

    local new_r2_point = function(index)
        local x, y = self:_r2(index)
        return geom.Vec2.new(x, y):scale(buffer_width, buffer_height):add(buffer_x, buffer_y):subtract(self.width / 2, self.height / 2)
    end

    local start = love.math.random(0, math.pow(2, 31) / 2)
    local index = start + 1
    while true do
        if self:_r2d(index - start) * math.min(self.width, self.height) < spacing then
            break
        end
        if love.math.random() >= culling then
            local pos = new_r2_point(index)
            local radius = love.math.random() * (fire_radius_max - fire_radius_min) + fire_radius_min
            self.pool:queue(Fire.new(self.pool, pos.x, pos.y, radius))
        end
        index = index + 1
    end

    index = index + 1
    self.entrance = new_r2_point(index)

    index = index + 1
    local exit_pos = new_r2_point(index)
    local radius = love.math.random() * (fire_radius_max - fire_radius_min) + fire_radius_min
    self.pool:queue(Exit.new(self.pool, exit_pos.x, exit_pos.y, radius))

    if with_amethyst then
        index = index + 1
        local am_pos = new_r2_point(index)
        self.pool:queue(mobs.Amethyst.new(self.pool, am_pos.x, am_pos.y))
    end

    for i = 1, num_mobs do
        local pos = new_r2_point(index)
        if insect_count > 0 and hawk_count > 0 then
            if love.math.random() * (insect_count + hawk_count) < insect_count then
                insect_count = insect_count - 1
                self.pool:queue(mobs.Insect.new(self.pool, pos.x, pos.y))
            else
                hawk_count = hawk_count - 1
                self.pool:queue(mobs.Hawk.new(self.pool, pos.x, pos.y))
            end
        elseif insect_count > 0 then
            insect_count = insect_count - 1
            self.pool:queue(mobs.Insect.new(self.pool, pos.x, pos.y))
        elseif hawk_count > 0 then
            hawk_count = hawk_count - 1
            self.pool:queue(mobs.Hawk.new(self.pool, pos.x, pos.y))
        else
            error("bug")
        end
        index = index + 1
    end
end

function Level:_r2(index)
    local x = 0.7548776662466927 * index
    local y = 0.5698402909980532 * index
    x = x - math.floor(x)
    y = y - math.floor(y)
    return x, y
end

function Level:_r2d(index)
    -- Optimal.
    --return 0.868 / math.sqrt(index)
    -- Suboptimal.
    return 0.549 / math.sqrt(index)
end

return {
    Level = Level
}