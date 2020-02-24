--[[
Bat outta Hell

TODO (- not started; + started; * finished)
* Player movement with the mouse.
* Collisions and physics.
* Bat sprites and basic sounds.
* Chirping and echoing with raycasting.
* Create finite world representation.
* Generate world function with:
    * Builds varying sized trunks.
    * Constructs outer wall.
    * Picks a start spawn and end location.
    + Configuration for difficulty, size, etc.
    - Builds boxes (houses).
* Insects, some run, some float.
* Hawks, which chase you for awhile.
* Speedy mode for bat which burns energy by holding chirp button.
* Improve stunned and taking damage feedback. (removed: Add invulnerability.)
- Levels, scoring, progression.
- Sound effects.
+ Title screen. (removed: settings.)
    - Animated
- Update UI to be more squishy..
- Scoreboard.
--]]

--[[
Relative pathing.

First parameter is path to file (...). Second is the path.

"path.to.file"
    Will search the current path (append). For requires in init.lua
    it will search for modules in the same directory.

"^path.to.file"
    Will go one directory up and append `path.to.file`. As many carets can
    be added as needed: "^^double.up"
--]]
function _G._P(this, path)
    local i = 1
    while path:sub(i, i) == "^" do
        if this == "" then error("invalid path: cannot go up past root directory", 2) end
        this = this:match("(.-)[^%.]+$") or ""
        i = i + 1
    end
    if this ~= "" and this:sub(#this, #this) ~= "." then this = this .. "." end
    return this .. path:sub(i)
end

-- Globals are all caps.
_G.ASSETS = require("common").Assets.new()
_G.CONF = require("conf")
_G.CONSTS = {
    category_bat = 1,
    category_object = 2,
    category_insect = 3,
    category_hawk = 4,
    category_sensor = 5,
}
_G.CONTROL_KEYS = function(key, scancode, isrepeat)
    if key == "m" and not isrepeat then
        love.audio.setVolume(1 - love.audio.getVolume())
    end
end

function math.round(n, deci) deci = 10^(deci or 0) return math.floor(n * deci + .5) / deci end
function math.multiple(n, size) size = size or 10 return math.round(n / size) * size end

local bitser = require("lib.bitser")

function table.serialize(tab)
    return bitser.dumps(tab)
end

function table.deserialize(str)
    return bitser.loads(str)
end

function table.deepcopy(t, into)
    into = into or {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            into[k] = into[k] or {}
            table.deepcopy(v, into[k])
        else
            into[k] = v
        end
    end
    return into
end

require("common.state").switch("title")