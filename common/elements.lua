
local helium = require("lib.helium")
local input = require("lib.helium.core.input")

local style = {
    default = {0, 0, 0, 1},
    hover = _G.CONF.main_color,
    border = _G.CONF.default_color,
    bg = {0, 0, 0, 1},
    fg = _G.CONF.default_color,
}

local function button(params, state, view)
	state.hovering = false
    input("clicked", function() return params.callback end)
    input("hover", function()
        state.hovering = true
        _G.ASSETS:get("squeek"):play()
        return function() state.hovering = false end
    end)
		
    return function()
        love.graphics.setFont(params.font or _G.ASSETS:get("font_regular_m"))
		if state.hovering then
			love.graphics.setColor(style.hover)
        else
			love.graphics.setColor(style.default)
		end
		love.graphics.rectangle("fill", 0, 0, view.w, view.h)
        love.graphics.setColor(style.border)
		love.graphics.rectangle("line", 0, 0, view.w, view.h)
        love.graphics.setColor(params.fg or style.fg)
        local h = love.graphics.getFont():getHeight()
		love.graphics.printf(params.text, 0, view.h / 2 - h / 2, view.w, "center")
	end
end

local function label(params, state, view)
    return function()
        love.graphics.setFont(params.font or _G.ASSETS:get("font_regular_s"))
        love.graphics.setColor(params.fg or style.fg)
        local h = love.graphics.getFont():getHeight()
		love.graphics.printf(params.text, 0, view.h / 2 - h / 2, view.w, params.align or "center")
	end
end

local function spacer(params, state, view)
    return function()
	end
end

local function vcontainer(params, state, view)
    local elems = {}
    for _, c in ipairs(params.children) do
        table.insert(elems, helium(c.elem)(c.params, c.width or view.w, c.height or view.h))
    end
    return function()
        love.graphics.setColor(style.bg)
        love.graphics.rectangle("fill", 0, 0, view.w, view.h)
        local step = 0
        for i, e in ipairs(elems) do
            e:draw(view.w / 2 - e.view.w / 2, step)
            step = step + params.children[i].height + (params.children[i].padding_v or 0) * view.h
        end
    end
end

return {
    style = style,
    button = button,
    label = label,
    spacer = spacer,
    vcontainer = vcontainer,
}