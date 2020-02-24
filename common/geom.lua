
local Vec2 = {}
Vec2.__index = Vec2

function Vec2.new(x, y)
    if type(x) == "table" then
        return setmetatable({ x = x.x, y = x.y }, Vec2)
    else
        return setmetatable({ x = x or 0, y = y or 0 }, Vec2)
    end
end

function Vec2.from_angle(rads, mag)
    local self = Vec2.new(mag or 1, 0)
    return self:rotate(rads)
end

function Vec2.random_angle(mag)
    return Vec2.from_angle(math.random(math.pi * 2), mag)
end

function Vec2.random_spread(angle, variance, mag)
    return Vec2.from_angle(math.random() * variance * 2 - variance + angle, mag)
end

function Vec2:copy()
    return Vec2.new(self)
end

function Vec2:set(x, y)
    if type(x) == "table" then
        self.x = x.x
        self.y = x.y
    else
        self.x = x
        self.y = y
    end
end

function Vec2:as_ints()
    local x = self.x > 0 and math.floor(self.x) or math.ceil(self.x)
    local y = self.y > 0 and math.floor(self.y) or math.ceil(self.y)
    return Vec2.new(x, y)
end

function Vec2:dot(v)
    return self.x * v.x + self.y * v.y
end

function Vec2:cross(x, y)
    if type(x) == "table" then
        return self.x * x.y - self.y * x.x
    else
        return self.x * y - self.y * x
    end
end

function Vec2:magnitude()
    return math.sqrt(self:dot(self))
end

function Vec2:normalize()
    local len = self:magnitude()
    assert(len ~= 0, "cannot normalize vector with zero magnitude", 2)
    return Vec2.new(self.x / len, self.y / len)
end

function Vec2:subtract(x, y)
    if type(x) == "table" then
        return Vec2.new(self.x - x.x, self.y - x.y)
    else
        return Vec2.new(self.x - x, self.y - y)
    end
end

function Vec2:add(x, y)
    if type(x) == "table" then
        return Vec2.new(self.x + x.x, self.y + x.y)
    else
        return Vec2.new(self.x + x, self.y + y)
    end
end

function Vec2:scale(x, y)
    if type(x) == "table" then
        return Vec2.new(self.x * x.x, self.y * x.y)
    elseif not y then
        return Vec2.new(self.x * x, self.y * x)
    else
        return Vec2.new(self.x * x, self.y * y)
    end
end

function Vec2:distance(x, y)
    local dx
    local dy
    if type(x) == "table" then
        dx = self.x - x.x
        dy = self.y - x.y
    else
        dx = self.x - x
        dy = self.y - y
    end
    return math.sqrt(dx * dx + dy * dy)
end

function Vec2:distance2(x, y)
    local dx
    local dy
    if type(x) == "table" then
        dx = self.x - x.x
        dy = self.y - x.y
    else
        dx = self.x - x
        dy = self.y - y
    end
    return dx * dx + dy * dy
end

function Vec2:angle(ref)
    if ref then
        return math.atan2(self:cross(ref), self:dot(ref))
    else
        local angle = math.atan2(self.y, self.x)
        if angle < 0 then
            angle = angle + math.pi * 2
        end
        return angle
    end
end

function Vec2:rotate(rads)
    local c = math.cos(rads)
    local s = math.sin(rads)

    local nx = self.x * c - self.y * s
    local ny = self.x * s + self.y * c

    return Vec2.new(nx, ny)
end

function Vec2:rotate90(dir)
    if dir >= 0 then
        return Vec2.new(-self.y, self.x)
    else
        return Vec2.new(-self.y, -self.x)
    end
end

function Vec2:lerp(target, alpha)
    local invalpha = 1 - alpha
    return Vec2.new(self.x * invalpha + target.x * alpha, self.y * invalpha + target.y * alpha)
end

function Vec2:__tostring()
    return "<" .. self.x .. "," .. self.y .. ">"
end

return {
    Vec2 = Vec2
}