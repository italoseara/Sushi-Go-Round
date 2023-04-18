local Class = require "libs.classic"
local Vector = require "libs.vector"
local Anim8 = require "libs.anim8"

local Level = Class:extend()
local Player = require "assets.player"

function Level:new()
    self.lastSize = Vector(love.graphics:getWidth(), love.graphics:getHeight())
    self.background = {
        image = love.graphics.newImage(Config.image.background),
        collider = {
            x = love.graphics.getWidth() / 2,
            y = love.graphics.getHeight() / 2 + 60,
            radius = 150
        }
    }

    self.players = {}
    
    -- Load sushi sprites
    SushiSprite = love.graphics.newImage(Config.image.sushi)
    local grid = Anim8.newGrid(16, 16, SushiSprite:getWidth(), SushiSprite:getHeight())

    self.foodSprites = {
        plate = Anim8.newAnimation(grid(1, 1), 1),
        sushi = {}
    }

    for i = 2, 8 do
        table.insert(self.foodSprites.sushi, Anim8.newAnimation(grid(i, 1), 1))
    end

    -- Load player sprites
    PlayerSprite = love.graphics.newImage(Config.image.player)

    local grid = Anim8.newGrid(16, 16, PlayerSprite:getWidth(), PlayerSprite:getHeight())

    local center = Vector(love.graphics:getWidth() / 2, love.graphics:getHeight() / 2 + 60)
    local possiblePositions = {
        Vector(center.x - 100, center.y),
        Vector(center.x + 100, center.y),
        Vector(center.x, center.y - 100),
        Vector(center.x, center.y + 100)
    }

    for i, keybind in ipairs(Config.keybinds) do
        local index = (i - 1) * 3 + 1

        table.insert(self.players, Player(possiblePositions[i], keybind, {
            idle = {
                up = Anim8.newAnimation(grid(index + 1, 4), 1),
                down = Anim8.newAnimation(grid(index + 1, 1), 1),
                left = Anim8.newAnimation(grid(index + 1, 2), 1),
                right = Anim8.newAnimation(grid(index + 1, 3), 1)
            },
            walk = {
                up = Anim8.newAnimation(grid(index .. "-" .. index + 2, 4), 0.15),
                down = Anim8.newAnimation(grid(index .. "-" .. index + 2, 1), 0.15),
                left = Anim8.newAnimation(grid(index .. "-" .. index + 2, 2), 0.15),
                right = Anim8.newAnimation(grid(index .. "-" .. index + 2, 3), 0.15)
            }
        }))
    end

    -- Create the plates
    self.plates = {}
    self.platesAngle = 0
    self.platesAmount = 10

    for i = 1, self.platesAmount do
        local angle = math.rad(360 / self.platesAmount * i + self.platesAngle)
        local x = math.cos(angle) * (self.background.collider.radius + 20) + self.background.collider.x
        local y = math.sin(angle) * (self.background.collider.radius + 20) + self.background.collider.y - 10

        table.insert(self.plates, {
            position = Vector(x, y),
            food = {}
        })
    end
end

function Level:update(dt)
    -- Sort the players by their y position
    table.sort(self.players, function(a, b)
        return a.position.y < b.position.y
    end)

    for _, player in ipairs(self.players) do
        player:update(dt)
    end

    -- Update the plates
    self.platesAngle = self.platesAngle + 20 * dt

    for i, plate in ipairs(self.plates) do
        local angle = math.rad(360 / self.platesAmount * i + self.platesAngle)
        local x = math.cos(angle) * (self.background.collider.radius + 20) + self.background.collider.x
        local y = math.sin(angle) * (self.background.collider.radius + 20) + self.background.collider.y - 10

        plate.position.x = x
        plate.position.y = y
    end
end

function Level:draw()
    -- draw the background
    love.graphics.draw(self.background.image,
        love.graphics.getWidth() / 2 - self.background.image:getWidth() * Config.image.scale / 2,
        love.graphics.getHeight() / 2 - self.background.image:getHeight() * Config.image.scale / 2,
        0, Config.image.scale, Config.image.scale)

    -- draw the players
    for _, player in ipairs(self.players) do
        player:draw()
    end

    -- draw the plates
    for _, plate in ipairs(self.plates) do
        self.foodSprites.plate:draw(SushiSprite, plate.position.x, plate.position.y, 0, Config.image.scale * 0.8, Config.image.scale * 0.8, 8, 8)

        for _, food in ipairs(plate.food) do
            self.foodSprites.sushi[food]:draw(SushiSprite, plate.position.x, plate.position.y, 0, Config.image.scale * 0.8, Config.image.scale * 0.8, 8, 8)
        end
    end

    -- draw the table collider
    if Config.debug then
        love.graphics.setColor(1, 0, 0)
        love.graphics.circle("line", self.background.collider.x, self.background.collider.y, self.background.collider.radius)
        love.graphics.setColor(1, 1, 1)
    end
end

function Level:resize(w, h)
    for _, player in ipairs(self.players) do
        player:resize(w, h)
    end
    
    -- Update the table collider's position
    self.background.collider.x, self.background.collider.y = w / 2, h / 2 + 60

    -- Update the last size
    self.lastSize = Vector(w, h)
end

return Level