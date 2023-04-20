require "conf"

local GameController = require "assets.controller"
local GameManager = require "assets.manager"

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- load the controller
    Controller = GameController()

    -- Load the manager
    Manager = GameManager()
end

function love.update(dt)
    Manager:update(dt)
    Controller:update(dt)
end

function love.draw()
    Controller:draw()
    Manager:draw()

    if Config.debug then
        love.graphics.setColor(1, 0, 0)
        love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
        love.graphics.setColor(1, 1, 1)
    end
end