local Class = require "libs.classic"
local Vector = require "libs.vector"
local Anim8 = require "libs.anim8"

local GameManager = Class:extend()

local scores = { 0, 0, 0, 0 }
local winners = {}

function GameManager:new()
    self.state = "menu"
    self.canMove = false
    self.showFood = false

    self.timer = 3
end

function GameManager:update(dt)
    self.timer = self.timer - dt

    if self.state == "starting" then
        if self.timer <= 0 then
            self.canMove = true
            self.showFood = true
            self.timer = 60

            self.state = "playing"
        end
    elseif self.state == "playing" then
        if self.timer <= 0 then
            self.canMove = false
            self.timer = 3

            self.state = "ending1"
        end
    elseif self.state == "ending1" then
        if self.timer <= 0 then
            self.state = "ending2"
        end
    end
end

function GameManager:draw()
    self[self.state.."State"](self)

    if Config.debug then
        love.graphics.setColor(1, 0, 0)
        love.graphics.print("State: " .. self.state, 10, 25)
        love.graphics.setColor(1, 1, 1)
    end
end

function GameManager:menuState()
    local center = Vector(love.graphics:getWidth() / 2, love.graphics:getHeight() / 2)

    -- draw a transparent black background
    love.graphics.setColor(0, 0, 0, 0.25)
    love.graphics.rectangle("fill", 0, 0, love.graphics:getWidth(), love.graphics:getHeight())
    love.graphics.setColor(1, 1, 1)
    
    -- draw the title
    local title = love.graphics.newText(love.graphics.newFont(Config.font.menu, 64), "Sushi Go Round")
    love.graphics.draw(title, center.x, 100, 0, 1, 1, title:getWidth() / 2, title:getHeight() / 2)

    -- draw the subtitle
    local subtitle = love.graphics.newText(love.graphics.newFont(Config.font.menu, 28), "Press any key to start")
    love.graphics.draw(subtitle, center.x, 140, 0, 1, 1, subtitle:getWidth() / 2, subtitle:getHeight() / 2)

    -- draw 4 sushi on the right side of the screen and 4 on the left
    local sushis = Controller.food.sushi.sprites
    local prices = Controller.food.sushi.values
    local offsetX = 300

    for i = 1, 7 do
        local x
        local y

        if i <= 4 then
            x = center.x - offsetX
            y = center.y - 100 + (i - 1) * 100
        else
            x = center.x + offsetX
            y = center.y - 100 + (i - 5) * 100
        end

        sushis[i]:draw(SushiSprite, x, y, 0, Config.image.scale * 1.5, Config.image.scale * 1.5, 8, 8)

        local price = love.graphics.newText(love.graphics.newFont(Config.font.menu, 32), prices[i])
        love.graphics.draw(price, x + 50, y, 0, 1, 1, 0, price:getHeight() / 2)
    end

    -- draw the instructions
    local instructions = love.graphics.newText(love.graphics.newFont(Config.font.menu, 16), "The goal is to eat as much sushi as possible and each sushi has a price that increases your score")
    love.graphics.draw(instructions, center.x, center.y + 300, 0, 1, 1, instructions:getWidth() / 2, instructions:getHeight() / 2)
end

function GameManager:startingState()
    local center = Vector(love.graphics:getWidth() / 2, love.graphics:getHeight() / 2)

    -- draw a transparent black background
    love.graphics.setColor(0, 0, 0, 0.25)
    love.graphics.rectangle("fill", 0, 0, love.graphics:getWidth(), love.graphics:getHeight())
    love.graphics.setColor(1, 1, 1)

    -- draw the countdown
    local countdown = love.graphics.newText(love.graphics.newFont(Config.font.menu, 64), string.format("%d", self.timer + 1))
    love.graphics.draw(countdown, center.x, center.y, 0, 1, 1, countdown:getWidth() / 2, countdown:getHeight() / 2)
end

function GameManager:playingState()
    local plate = Controller.food.plate
    local margin = {
        top = 60,
        bottom = 60,
        left = 70,
        right = 70
    }
    local stack = 5
    local offset = 7

    -- Draw the player 1 at the top left
    local player1 = love.graphics.newText(love.graphics.newFont(Config.font.menu, 32), "Player 1")
    love.graphics.draw(player1, margin.left, margin.top, 0, 1, 1, 0, 0)

    -- draw the plates on top of each other
    for i = getPlayerById(1).plates, 1, -1 do
        local col = math.floor((i - 1) / stack)

        local x = (margin.left + Controller.plates.width / 2) + col * (Controller.plates.width + 5)
        local y = margin.top + 50 + (i - 1) % stack * offset

        plate:draw(SushiSprite, x, y, 0, Config.image.scale, Config.image.scale, 8, 8)
    end

    -- Draw the player 2 at the top right
    local player2 = love.graphics.newText(love.graphics.newFont(Config.font.menu, 32), "Player 2")
    love.graphics.draw(player2, love.graphics:getWidth() - margin.right, margin.top, 0, 1, 1, player2:getWidth(), 0)

    -- draw the plates on top of each other
    for i = getPlayerById(2).plates, 1, -1 do
        local col = math.floor((i - 1) / stack)

        local x = (love.graphics:getWidth() - margin.right - Controller.plates.width / 2) - col * (Controller.plates.width + 5)
        local y = margin.top + 50 + (i - 1) % stack * offset

        plate:draw(SushiSprite, x, y, 0, Config.image.scale, Config.image.scale, 8, 8)
    end

    -- Draw the player 3 at the bottom left
    local player3 = love.graphics.newText(love.graphics.newFont(Config.font.menu, 32), "Player 3")
    love.graphics.draw(player3, margin.left, love.graphics:getHeight() - margin.bottom, 0, 1, 1, 0, player3:getHeight())

    -- draw the plates on top of each other
    for i = getPlayerById(3).plates, 1, -1 do
        local col = math.floor((i - 1) / stack)

        local x = (margin.left + Controller.plates.width / 2) + col * (Controller.plates.width + 5)
        local y = love.graphics:getHeight() - margin.bottom - 50 - player3:getHeight() + Controller.plates.height / 2- (i - 1) % stack * offset

        plate:draw(SushiSprite, x, y, 0, Config.image.scale, Config.image.scale, 8, 8)
    end

    -- Draw the player 4 at the bottom right
    local player4 = love.graphics.newText(love.graphics.newFont(Config.font.menu, 32), "Player 4")
    love.graphics.draw(player4, love.graphics:getWidth() - margin.right, love.graphics:getHeight() - margin.bottom, 0, 1, 1, player4:getWidth(), player4:getHeight())

    -- draw the plates on top of each other
    for i = getPlayerById(4).plates, 1, -1 do
        local col = math.floor((i - 1) / stack)

        local x = (love.graphics:getWidth() - margin.right - Controller.plates.width / 2) - col * (Controller.plates.width + 5)
        local y = love.graphics:getHeight() - margin.bottom - 50 - player4:getHeight() + Controller.plates.height / 2 - (i - 1) % stack * offset

        plate:draw(SushiSprite, x, y, 0, Config.image.scale, Config.image.scale, 8, 8)
    end

    -- Draw the timer
    local timer = love.graphics.newText(love.graphics.newFont(Config.font.menu, 48), string.format("%d", self.timer + 1))
    love.graphics.draw(timer, love.graphics:getWidth() / 2, margin.top, 0, 1, 1, timer:getWidth() / 2, 0)
end

function GameManager:ending1State()
    local center = Vector(love.graphics:getWidth() / 2, love.graphics:getHeight() / 2)

    -- draw a transparent black background
    love.graphics.setColor(0, 0, 0, 0.25)
    love.graphics.rectangle("fill", 0, 0, love.graphics:getWidth(), love.graphics:getHeight())
    love.graphics.setColor(1, 1, 1)

    -- draw "Game Over"
    local timesUp = love.graphics.newText(love.graphics.newFont(Config.font.menu, 64), "Game Over")
    love.graphics.draw(timesUp, center.x, center.y, 0, 1, 1, timesUp:getWidth() / 2, timesUp:getHeight() / 2)
end

function GameManager:ending2State()
    -- draw a transparent black background
    love.graphics.setColor(0, 0, 0, 0.25)
    love.graphics.rectangle("fill", 0, 0, love.graphics:getWidth(), love.graphics:getHeight())
    love.graphics.setColor(1, 1, 1)

    local margin = {
        top = 60,
        bottom = 60,
        left = 70,
        right = 70
    }

    -- Draw the player 1 at the top left
    local player1 = love.graphics.newText(love.graphics.newFont(Config.font.menu, 32), "Player 1")
    love.graphics.draw(player1, margin.left, margin.top, 0, 1, 1, 0, 0)

    -- Draw the score below the player name
    local score1 = love.graphics.newText(love.graphics.newFont(Config.font.menu, 32), string.format("%d", scores[1]))
    love.graphics.draw(score1, margin.left, margin.top + 30, 0, 1, 1, 0, 0)

    -- Draw the player 2 at the top right
    local player2 = love.graphics.newText(love.graphics.newFont(Config.font.menu, 32), "Player 2")
    love.graphics.draw(player2, love.graphics:getWidth() - margin.right, margin.top, 0, 1, 1, player2:getWidth(), 0)

    -- Draw the score below the player name
    local score2 = love.graphics.newText(love.graphics.newFont(Config.font.menu, 32), string.format("%d", scores[2]))
    love.graphics.draw(score2, love.graphics:getWidth() - margin.right, margin.top + 30, 0, 1, 1, score2:getWidth(), 0)

    -- Draw the player 3 at the bottom left
    local player3 = love.graphics.newText(love.graphics.newFont(Config.font.menu, 32), "Player 3")
    love.graphics.draw(player3, margin.left, love.graphics:getHeight() - margin.bottom, 0, 1, 1, 0, player3:getHeight())

    -- Draw the score below the player name
    local score3 = love.graphics.newText(love.graphics.newFont(Config.font.menu, 32), string.format("%d", scores[3]))
    love.graphics.draw(score3, margin.left, love.graphics:getHeight() - margin.bottom - 30, 0, 1, 1, 0, score3:getHeight())

    -- Draw the player 4 at the bottom right
    local player4 = love.graphics.newText(love.graphics.newFont(Config.font.menu, 32), "Player 4")
    love.graphics.draw(player4, love.graphics:getWidth() - margin.right, love.graphics:getHeight() - margin.bottom, 0, 1, 1, player4:getWidth(), player4:getHeight())

    -- Draw the score below the player name
    local score4 = love.graphics.newText(love.graphics.newFont(Config.font.menu, 32), string.format("%d", scores[4]))
    love.graphics.draw(score4, love.graphics:getWidth() - margin.right, love.graphics:getHeight() - margin.bottom - 30, 0, 1, 1, score4:getWidth(), score4:getHeight())

    -- Update the scores
    for i = 1, 4 do
        for _ = 1, 3 do
            if scores[i] < getPlayerById(i).score then
                scores[i] = scores[i] + 1
            end
        end
    end

    -- After all scores are equal
    for i = 1, 4 do
        if scores[i] ~= getPlayerById(i).score then
            return
        end
    end

    -- Get the players with the highest score
    if #winners == 0 then
        -- Get the highest score
        local highest = 0
        for i = 1, 4 do
            if scores[i] > highest then
                highest = scores[i]
            end
        end

        for i = 1, 4 do
            if scores[i] == highest then
                table.insert(winners, i)
            end
        end
    end

    local winner

    -- Draw the winner
    if (#winners > 1) then
        winner = love.graphics.newText(love.graphics.newFont(Config.font.menu, 64), "Draw!")
    else
        winner = love.graphics.newText(love.graphics.newFont(Config.font.menu, 64), "Player " .. winners[1] .. " wins!")
    end

    love.graphics.draw(winner, love.graphics:getWidth() / 2, love.graphics:getHeight() / 2, 0, 1, 1, winner:getWidth() / 2, winner:getHeight() / 2)
end

function love.keypressed(key, scancode, isrepeat)
    if Manager.state == "menu" then
        Manager.state = "starting"
    end
end

function getPlayerById(id)
    for _, player in ipairs(Controller.players) do
        if player.id == id then
            return player
        end
    end
end

return GameManager