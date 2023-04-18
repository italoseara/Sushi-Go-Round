local Class = require "libs.classic"
local Vector = require "libs.vector"
local Anim8 = require "libs.anim8"

local Level = Class:extend()
local Player = require "assets.player"

function Level:new()
    self.players = {}
    self.lastSize = Vector(love.graphics:getWidth(), love.graphics:getHeight())
    self.background = {
        image    = love.graphics.newImage(Config.image.background),
        collider = {
            x      = love.graphics.getWidth() / 2,
            y      = love.graphics.getHeight() / 2 + 60,
            radius = 150
        }
    }

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
                up    = Anim8.newAnimation(grid(index + 1, 4), 1),
                down  = Anim8.newAnimation(grid(index + 1, 1), 1),
                left  = Anim8.newAnimation(grid(index + 1, 2), 1),
                right = Anim8.newAnimation(grid(index + 1, 3), 1)
            },
            walk = {
                up    = Anim8.newAnimation(grid(index .. "-" .. index + 2, 4), 0.15),
                down  = Anim8.newAnimation(grid(index .. "-" .. index + 2, 1), 0.15),
                left  = Anim8.newAnimation(grid(index .. "-" .. index + 2, 2), 0.15),
                right = Anim8.newAnimation(grid(index .. "-" .. index + 2, 3), 0.15)
            }
        }))
    end
    
    -- Load sushi sprites
    SushiSprite = love.graphics.newImage(Config.image.sushi)
    local grid = Anim8.newGrid(16, 16, SushiSprite:getWidth(), SushiSprite:getHeight())

    self.food = {
        plate = Anim8.newAnimation(grid(1, 1), 1),
        sushi = {
            sprites = {},
            chances = { 0.05, 0.1, 0.1, 0.2, 0.25, 0.2, 0.1 },
            values  = { 1000, 250, 350, 20,  50,   150, 600 }
        },
    }

    for i = 2, 8 do
        table.insert(self.food.sushi.sprites, Anim8.newAnimation(grid(i, 1), 1))
    end

    -- Create the plates
    self.plates = {
        angle    = 0,
        amount   = 10,
        lastFood = 0,
        
        width    = 16 * Config.image.scale,
        height   = 16 * Config.image.scale,
        radius   = 6 * Config.image.scale
    }

    for i = 1, self.plates.amount do
        local angle = math.rad(360 / self.plates.amount * i + self.plates.angle)
        local x = math.cos(angle) * (self.background.collider.radius + 20) + self.background.collider.x
        local y = math.sin(angle) * (self.background.collider.radius + 20) + self.background.collider.y

        -- Calculate the chance
        table.insert(self.plates, {
            position = Vector(x, y),
            food = pickRandomWithChance(self.food.sushi.chances)
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
    self.plates.angle = self.plates.angle + 20 * dt

    for i, plate in ipairs(self.plates) do
        local angle = math.rad(360 / self.plates.amount * i + self.plates.angle)
        local x = math.cos(angle) * (self.background.collider.radius + 20) + self.background.collider.x
        local y = math.sin(angle) * (self.background.collider.radius + 20) + self.background.collider.y

        plate.position.x = x
        plate.position.y = y
    end

    -- Add food to an empty plate every 3 seconds
    if self.plates.lastFood > 3 then
        local emptyPlates = {}

        for _, plate in ipairs(self.plates) do
            if not plate.food then
                table.insert(emptyPlates, plate)
            end
        end

        if #emptyPlates > 0 then
            local plate = emptyPlates[math.random(1, #emptyPlates)]
            plate.food = pickRandomWithChance(self.food.sushi.chances)
        end

        self.plates.lastFood = 0
    else
        self.plates.lastFood = self.plates.lastFood + dt
    end
end

function Level:draw()
    -- draw the background
    love.graphics.draw(self.background.image,
        love.graphics.getWidth() / 2 - self.background.image:getWidth() * Config.image.scale / 2,
        love.graphics.getHeight() / 2 - self.background.image:getHeight() * Config.image.scale / 2,
        0, Config.image.scale, Config.image.scale)

    -- draw the plates
    for _, plate in ipairs(self.plates) do
        self.food.plate:draw(SushiSprite, plate.position.x, plate.position.y, 0, Config.image.scale * 0.8, Config.image.scale * 0.8, 8, 8)

        if plate.food then
            self.food.sushi.sprites[plate.food]:draw(SushiSprite, plate.position.x, plate.position.y, 0, Config.image.scale * 0.8, Config.image.scale * 0.8, 8, 8)
        end
    end

    if Config.debug then
        -- draw the plates circle
        love.graphics.setColor(0, 0, 1)
        love.graphics.circle("line", self.background.collider.x, self.background.collider.y, self.background.collider.radius + 20)
        love.graphics.setColor(1, 1, 1)

        -- draw the plates circle hitbox
        love.graphics.setColor(1, 0, 0)
        for _, plate in ipairs(self.plates) do
            love.graphics.circle("line", plate.position.x, plate.position.y, self.plates.radius)
        end
        
        -- draw the table collider
        love.graphics.circle("line", self.background.collider.x, self.background.collider.y, self.background.collider.radius)
        love.graphics.setColor(1, 1, 1)
    end

    -- draw the players
    for _, player in ipairs(self.players) do
        player:draw()
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

function pickRandomWithChance(chances)
    local chance = 0
    for i, c in ipairs(chances) do
        chance = chance + c

        if math.random() < chance then
            return i
        end
    end
end

return Level