
local slam = require("lib.slam")
local flux = require("lib.flux")
local geom = require(_P(..., "geom"))

local Assets = {}
Assets.__index = Assets

local loaders = {
    [".tga"] = love.graphics.newImage,
    [".png"] = love.graphics.newImage,
    [".jpg"] = love.graphics.newImage,
    [".bmp"] = love.graphics.newImage,
    [".ttf"] = love.graphics.newFont,
    [".wav"] = love.audio.newSource,
}

function Assets.new(basename)
    local self = setmetatable({}, Assets)
    self.basename = basename or "assets/"
    self:clear()
    return self
end

function Assets:get(key, index)
    return self._cache[key][index or 1]
end

function Assets:load(key, index, filename, ...)
    local ext = filename:match("^.+(%..+)$")
    assert(loaders[ext], ext .. " not supported")
    if not self._cache[key] then
        self._cache[key] = {}
    end
    self._cache[key][index or (#self._cache[key] + 1)] = loaders[ext](self.basename .. filename, ...)
    return self._cache[key][#self._cache[key]]
end

function Assets:clear()
    self._cache = {
        default_font = {love.graphics.newFont()}
    }
end

local Anim = {}
Anim.__index = Anim

function Anim.new(time_step, playing, looping, frame_count, draw)
    return setmetatable({
        time_step = time_step or 0.1,
        playing = playing,
        looping = looping,
        accum_t = 0,
        frame = 1,
        prev_frame = 0,
        frame_count = frame_count or 0,
        frames = {},
        draw = draw,
    }, Anim)
end

function Anim:add_frame(frame_index, func)
    if not self.frames[frame_index] then
        self.frames[frame_index] = {}
    end
    if frame_index > self.frame_count then
        self.frame_count = frame_index
    end
    table.insert(self.frames[frame_index], func)
end

function Anim:update(dt)
    if not self.playing then
        return
    end
    if self.frame ~= self.prev_frame and self.frame <= self.frame_count then
        -- Update.
        self.prev_frame = self.frame
        if not self.frames[self.frame] then
            return
        end
        for i, f in ipairs(self.frames[self.frame]) do
            if f then
                f(self.frame, i)
            end
        end
    end

    self.accum_t = self.accum_t + dt
    if self.accum_t < self.time_step then
        return
    end
    if self.frame + 1 > self.frame_count then
        if self.looping then
            self.frame = 1
            self.accum_t = 0
        end
        return
    end
    self.accum_t = self.accum_t - self.time_step
    self.frame = self.frame + 1
end

function Anim:draw()
    -- This can be set.
end

function Anim:stop()
    self.accum_t = 0
    self.frame = 1
    self.prev_frame = 0
    self.playing = false
end

function Anim:play()
    self.playing = true
end

function Anim:pause()
    self.playing = true
end

function Anim:seek(to)
    self.frame = to
end

function Anim:seek_end()
    self.frame = self.frame_count
end

function Anim:tell()
    return self.frame
end

function Anim:length()
    return self.frame_count
end

function Anim:finished()
    return self.frame >= self.frame_count and self.accum_t >= self.time_step
end

local Camera = {}
Camera.__index = Camera

function Camera.new()
    return setmetatable({
        x = 0,
        y = 0,
        scale_x = 1,
        scale_y = 1,
        rotation = 0,
        -- Percent of the screen
        bounds_x = 0.25,
        bounds_y = 0.25,
    }, Camera)
end

function Camera:apply()
  love.graphics.push()
  love.graphics.rotate(-self.rotation)
  love.graphics.scale(1 / self.scale_x, 1 / self.scale_y)
  love.graphics.translate(-self.x, -self.y)
end

function Camera:unapply()
  love.graphics.pop()
end

function Camera:move(dx, dy)
  self.x = self.x + (dx or 0)
  self.y = self.y + (dy or 0)
end

function Camera:rotate(dr)
  self.rotation = self.rotation + dr
end

function Camera:scale(sx, sy)
    sx = sx or 1
    self.scale_x = self.scale_x * sx
    self.scale_y = self.scale_y * (sy or sx)
end

function Camera:set_position(x, y)
  self.x = x or self.x
  self.y = y or self.y
end

function Camera:set_scale(sx, sy)
  self.scale_x = sx or self.scale_x
  self.scale_y = sy or self.scale_y
end

function Camera:unproject(x, y)
    local v = geom.Vec2.new(x, y):scale(self.scale_x, self.scale_y):add(self.x, self.y):rotate(self.rotation)
    return v.x, v.y
end

function Camera:project(x, y)
    local v = geom.Vec2.new(x, y):rotate(-self.rotation):subtract(self.x, self.y):scale(1 / self.scale_x, 1 / self.scale_y)
    return v.x, v.y
end

function Camera:mouse_position()
    return self:unproject(love.mouse.getX(), love.mouse.getY())
end

function Camera:center_on(x, y)
    self:set_position(x - love.graphics.getWidth() / 2, y - love.graphics.getHeight() / 2)
end

function Camera:follow(x, y)
    local screen_x, screen_y = self:project(x, y)
    local screen_w, screen_h = love.graphics.getWidth(), love.graphics.getHeight()
    local moving = geom.Vec2.new(0, 0)
    if screen_x < screen_w * self.bounds_x then
        local diff = screen_w * self.bounds_x - screen_x
        self:move(-diff, 0)
        moving.x = -1
    elseif screen_x > screen_w * (1 - self.bounds_x) then
        local diff = screen_x - screen_w * (1 - self.bounds_x)
        self:move(diff, 0)
        moving.x = 1
    end
    if screen_y < screen_h * self.bounds_y then
        local diff = screen_h * self.bounds_y - screen_y
        self:move(0, -diff)
        moving.y = -1
    elseif screen_y > screen_h * (1 - self.bounds_y) then
        local diff = screen_y - screen_h * (1 - self.bounds_y)
        self:move(0, diff)
        moving.y = 1
    end
    return moving
end

return {
    Assets = Assets,
    Anim = Anim,
    Camera = Camera,
}
