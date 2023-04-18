require "conf"
local Vector = require "libs.vector"

local LevelController = require "assets.level"

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- load the level
    Level = LevelController()
end

function love.update(dt)
    Level:update(dt)
end

function love.draw()
    Level:draw()

    if Config.debug then
        love.graphics.setColor(1, 0, 0)
        love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
        love.graphics.setColor(1, 1, 1)
    end
end

function love.resize(w, h)
    Level:resize(w, h)
end