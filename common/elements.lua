
local helium = require("lib.helium")
local input = require("lib.helium.core.input")

local style = {
    default = {0, 0, 0, 1},
    hover = {1, 0, 0, 1},
    border = {1, 1, 1, 1},
    bg = {0, 0, 0, 1},
    fg = {1, 1, 1, 1},
}

local function button(params, state, view)
	state.hovering = false
    input("clicked", function() return params.callback end)
    input("hover", function() state.hovering = true; return function() state.hovering = false end end)
		
    return function()
		if state.hovering then
			love.graphics.setColor(style.hover)
        else
			love.graphics.setColor(style.default)
		end
		love.graphics.rectangle("fill", 0, 0, view.w, view.h)
        love.graphics.setColor(style.border)
		love.graphics.rectangle("line", 0, 0, view.w, view.h)
        love.graphics.setColor(style.fg)
        local h = love.graphics.getFont():getHeight()
		love.graphics.printf(params.text, 0, view.h / 2 - h / 2, view.w, "center")
	end
end

return {
    style = style,
    button = button,
}