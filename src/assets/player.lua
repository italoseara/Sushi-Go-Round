local Class = require "libs.classic"
local Vector = require "libs.vector"

local Player = Class:extend()

function Player:new(position, keybinds, animations, id)
    -- Player ID
    self.id               = id

    -- Collision
    self.width            = 16 * Config.image.scale
    self.height           = 16 * Config.image.scale
    self.radius           = 6 * Config.image.scale

    -- Player movement
    self.position         = position - Vector(self.width / 2, self.height / 2)
    self.velocity         = Vector(0, 0)
    self.acceleration     = Vector(0, 0)
    self.speed            = 3000
    self.friction         = 0.85

    self.minVelocity      = 1

    -- Keybinds
    self.keybinds         = keybinds

    -- Animation
    self.animations       = animations
    self.state            = "idle"
    self.direction        = "down"

    self.currentAnimation = self.animations[self.state][self.direction]

    -- Hand
    self.hand             = {
        sprite   = love.graphics.newImage(Config.image.hand),
        width    = 16 * Config.image.scale / 2,
        height   = 16 * Config.image.scale / 2,
        position = Vector(0, 0),
        radius   = 6 * Config.image.scale / 2,
        angle    = 0,
    }

    self.canPickUp        = false
    self.pickingUp        = false
    self.actionTimer      = -2

    -- Joystick
    if self.keybinds.joystick then
        self.joystick = love.joystick.getJoysticks()[self.keybinds.joystickId or 1]
    end

    -- Score
    self.score = 0
    self.plates = 0
end

function Player:update(dt)
    self:animate(dt)
    self:move(dt)
    self:action(dt)
    self:checkCollision()
end

function Player:animate(dt)
    -- Set animation state
    if self.acceleration == Vector(0, 0) then
        self.state = "idle"
    else
        self.state = "walk"
    end

    -- Set animation direction
    if self.acceleration.y > 0 then
        self.direction = "down"
    elseif self.acceleration.y < 0 then
        self.direction = "up"
    elseif self.acceleration.x > 0 then
        self.direction = "right"
    elseif self.acceleration.x < 0 then
        self.direction = "left"
    end

    -- Update animation
    self.currentAnimation = self.animations[self.state][self.direction]
    self.currentAnimation:update(dt)
end

function Player:move(dt)
    if not Manager.canMove then
        return
    end

    -- Fix diagonal movement (Normalize acceleration vector)
    if self.acceleration.x ~= 0 and self.acceleration.y ~= 0 then
        self.acceleration.x = self.acceleration.x * 0.7071
        self.acceleration.y = self.acceleration.y * 0.7071
    end

    -- Apply acceleration
    self.velocity = self.velocity + self.acceleration * dt

    -- Apply friction
    self.velocity = self.velocity * self.friction

    -- Round velocity to 0 if it's less than mininum velocity
    if math.abs(self.velocity.x) < self.minVelocity then
        self.velocity.x = 0
    end

    if math.abs(self.velocity.y) < self.minVelocity then
        self.velocity.y = 0
    end

    -- Move player
    self.position = self.position + self.velocity * dt

    -- Reset acceleration
    self.acceleration = Vector(0, 0)

    -- Check for input
    if self.keybinds.joystick then
        self:joystickInput()
    else
        self:keyboardInput()
    end
end

function Player:action(dt)
    if not Manager.canMove then
        return
    end

    -- Update hand position
    local normal = Vector(self.acceleration.x, self.acceleration.y):norm()

    if normal.x == 0 and normal.y == 0 then
        if self.direction == "up" then
            normal = Vector(0, -1)
        elseif self.direction == "down" then
            normal = Vector(0, 1)
        elseif self.direction == "left" then
            normal = Vector(-1, 0)
        elseif self.direction == "right" then
            normal = Vector(1, 0)
        end
    end

    local offset = normal * Vector(self.width / 3 + 4, self.height / 3 + 4):getmag()
    self.hand.angle = math.atan2(normal.y, normal.x)

    self.hand.position.x = self.position.x + self.width / 2 - self.hand.width / 2 + offset.x
    self.hand.position.y = self.position.y + self.height / 2 - self.hand.height / 2 + offset.y

    -- Update action timer
    local isPressing = false

    if self.keybinds.joystick then
        if not self.joystick then
            return
        end

        isPressing = self.joystick:isGamepadDown(self.keybinds.action)
    else
        isPressing = love.keyboard.isDown(self.keybinds.action)
    end

    if isPressing then
        if self.canPickUp and not self.pickingUp and self.actionTimer < -1 then
            self.actionTimer = 0
            self.pickingUp = true
        end

        self.canPickUp = false
    else
        self.canPickUp = true
    end

    if self.pickingUp and self.actionTimer <= 0 then
        local plate = self:handColliding()

        if plate then
            local sushi = plate.food

            if sushi then
                self.score = self.score + Controller.food.sushi.values[sushi]
                self.plates = self.plates + 1
                plate.food = nil
            end
        end
    end

    if self.pickingUp then
        self.actionTimer = self.actionTimer + dt
    else
        self.actionTimer = self.actionTimer - dt
    end

    if self.actionTimer > 0.2 then
        self.actionTimer = 0;
        self.pickingUp = false
    end
end

function Player:handColliding()
    -- Check if the hand collides with any plate in level
    for _, plate in ipairs(Controller.plates) do
        local plateCollider = {
            x = plate.position.x,
            y = plate.position.y,
            radius = Controller.plates.radius
        }

        local handCollider = {
            x = self.hand.position.x + self.hand.width / 2,
            y = self.hand.position.y + self.hand.height / 2,
            radius = self.hand.radius
        }

        -- if the distance between the center of the hand and the plate is less than the sum of the radius of the hand and the plate
        if Vector(handCollider.x - plateCollider.x, handCollider.y - plateCollider.y):getmag() < handCollider.radius + plateCollider.radius then
            return plate
        end
    end
end

function Player:checkCollision()
    -- Check if the collision of the player is inside the circle
    self:stickToCollider(Controller.background.collider)

    -- Check collisions with other players
    for _, player in ipairs(Controller.players) do
        if player ~= self then
            self:collideWithPlayer(player)
        end
    end
end

function Player:collideWithPlayer(player)
    local player2Collider = {
        x = player.position.x + player.width / 2,
        y = player.position.y + player.height / 2,
        radius = player.radius
    }

    local playerCollider = {
        x = self.position.x + self.width / 2,
        y = self.position.y + self.height / 2,
        radius = self.radius
    }

    -- Make the player 1 stuck to the player 2
    local normal = Vector(playerCollider.x - player2Collider.x, playerCollider.y - player2Collider.y)

    local distance = normal:getmag()
    local penetration = playerCollider.radius + player2Collider.radius - distance

    if penetration > 0 then
        normal:norm()
        self.position = self.position + normal * penetration
    end

    -- Push the player 2 away from the player 1
    local normal = Vector(player2Collider.x - playerCollider.x, player2Collider.y - playerCollider.y)

    if penetration > 0 then
        normal:norm()
        player.position = player.position + normal * penetration
    end
end

function Player:stickToCollider(collider)
    local playerCollider = {
        x = self.position.x + self.width / 2,
        y = self.position.y + self.height / 2,
        radius = self.radius
    }

    if math.sqrt((playerCollider.x - collider.x) ^ 2 + (playerCollider.y - collider.y) ^ 2) < collider.radius - playerCollider.radius then
        return
    end

    -- Make player stuck to the circle using normal vector
    local normal = Vector(playerCollider.x - collider.x, playerCollider.y - collider.y):norm()
    local distance = math.sqrt((playerCollider.x - collider.x) ^ 2 + (playerCollider.y - collider.y) ^ 2) -
        (collider.radius - playerCollider.radius)
    self.position = self.position - normal * distance
end

function Player:joystickInput()
    -- Get joystick if it was not connected in the beginning
    if not self.joystick then
        self.joystick = love.joystick.getJoysticks()[self.keybinds.joystickId or 1]
        return
    end

    -- Check if joystick is connected or it gets disconnected
    if not self.joystick:isConnected() then
        return
    end

    -- Get joystick axes
    local x, y = self.joystick:getGamepadAxis(self.keybinds.joystick .. "x"),
        self.joystick:getGamepadAxis(self.keybinds.joystick .. "y")

    -- Vertical Movement
    if y < -0.5 then
        self.acceleration.y = -self.speed
    elseif y > 0.5 then
        self.acceleration.y = self.speed
    end

    -- Horizontal Movement
    if x < -0.5 then
        self.acceleration.x = -self.speed
    elseif x > 0.5 then
        self.acceleration.x = self.speed
    end
end

function Player:keyboardInput()
    -- Vertical Movement
    if love.keyboard.isDown(self.keybinds.up) then
        self.acceleration.y = -self.speed
    elseif love.keyboard.isDown(self.keybinds.down) then
        self.acceleration.y = self.speed
    end

    -- Horizontal Movement
    if love.keyboard.isDown(self.keybinds.left) then
        self.acceleration.x = -self.speed
    elseif love.keyboard.isDown(self.keybinds.right) then
        self.acceleration.x = self.speed
    end
end

function Player:draw()
    self.currentAnimation:draw(PlayerSprite, self.position.x, self.position.y, 0, Config.image.scale, Config.image.scale)

    if self.pickingUp then
        self:drawHand()
    end

    -- Draw player id above the player
    local text = love.graphics.newText(love.graphics.newFont(Config.font.menu, 20), "P" .. self.id)
    love.graphics.draw(text, self.position.x + self.width / 2 - text:getWidth() / 2 + 1, self.position.y - 20 + 1)

    if Config.debug then
        love.graphics.setColor(1, 0, 0)

        -- Collision
        love.graphics.circle("line",
            self.position.x + self.width / 2,
            self.position.y + self.height / 2,
            self.radius
        )

        -- Position
        love.graphics.print(
            "Pos: (" .. string.format("%.2f", self.position.x) .. ", " .. string.format("%.2f", self.position.y) .. ")",
            self.position.x, self.position.y - 15
        )

        -- Velocity
        love.graphics.print(
            "Vel: (" .. string.format("%.2f", self.velocity.x) .. ", " .. string.format("%.2f", self.velocity.y) .. ")",
            self.position.x, self.position.y - 30
        )

        -- Acceleration
        love.graphics.print(
            "Acc: (" ..
            string.format("%.2f", self.acceleration.x) .. ", " .. string.format("%.2f", self.acceleration.y) .. ")",
            self.position.x, self.position.y - 45
        )

        -- State
        love.graphics.print(
            "State: " .. self.state,
            self.position.x, self.position.y - 60
        )

        -- Direction
        love.graphics.print(
            "Direction: " .. self.direction,
            self.position.x, self.position.y - 75
        )

        -- Picking up
        love.graphics.print(
            "PickingUp: " .. tostring(self.pickingUp),
            self.position.x, self.position.y - 90
        )

        -- Score
        love.graphics.print(
            "Score: " .. self.score,
            self.position.x, self.position.y - 105
        )

        love.graphics.setColor(1, 1, 1)
    end
end

function Player:drawHand()
    love.graphics.draw(
        self.hand.sprite,
        self.hand.position.x + self.hand.width / 2,
        self.hand.position.y + self.hand.height / 2,
        self.hand.angle,
        Config.image.scale / 2,
        Config.image.scale / 2,
        self.hand.width / 3,
        self.hand.height / 3
    )

    if Config.debug then
        love.graphics.setColor(1, 0, 0)

        -- Collision
        love.graphics.circle("line",
            self.hand.position.x + self.hand.width / 2,
            self.hand.position.y + self.hand.height / 2,
            self.hand.radius
        )

        love.graphics.setColor(1, 1, 1)
    end
end

return Player
