
local this = ...

function love.load()
    for i = 1, 3 do
        _G.ASSETS:load("bat", i, "bat".. i .. ".png")
    end
    _G.ASSETS:load("chirp", 1, "chirp.wav", "static")
    _G.ASSETS:load("echo", 1, "echo.wav", "static")
    _G.ASSETS:load("squeek", 1, "squeek.wav", "static")
    require("common.state").switch("game")
end