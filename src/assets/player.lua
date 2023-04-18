local Class = require "libs.classic"
local Vector = require "libs.vector"

local Player = Class:extend()

function Player:new(position, keybinds, animations)
    -- Collision
    self.width            = 16 * Config.image.scale
    self.height           = 16 * Config.image.scale
    self.radius           = 6 * Config.image.scale

    -- Player movement
    self.position         = position - Vector(self.width / 2, self.height / 2)
    self.velocity         = Vector(0, 0)
    self.acceleration     = Vector(0, 0)
    self.speed            = 3500
    self.friction         = 0.9

    self.minVelocity      = 1

    -- Keybinds
    self.keybinds         = keybinds

    -- Animation
    self.animations       = animations
    self.state            = "idle"
    self.direction        = "down"

    self.currentAnimation = self.animations[self.state][self.direction]

    -- Hand
    self.hand             = love.graphics.newImage(Config.image.hand)
    self.pickingUp        = false

    -- Joystick
    if self.keybinds.joystick then
        self.joystick = love.joystick.getJoysticks()[self.keybinds.joystickId or 1]
    end
end

function Player:update(dt)
    self:animate(dt)
    self:move(dt)
    self:action()
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

function Player:action()
    if self.keybinds.joystick then
        if not self.joystick then
            return
        end

        if self.joystick:isGamepadDown(self.keybinds.action) then
            self.pickingUp = true
        else
            self.pickingUp = false
        end

        return
    end

    if love.keyboard.isDown(self.keybinds.action) then
        self.pickingUp = true
    else
        self.pickingUp = false
    end
end

function Player:checkCollision()
    -- Check if the collision of the player is inside the circle
    self:stickToCollider(Level.background.collider)

    -- Check collisions with other players
    for _, player in ipairs(Level.players) do
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

function Player:resize(w, h)
    local difference = Vector(w, h) - Level.lastSize

    self.position = self.position + difference / 2
end

function Player:draw()
    self.currentAnimation:draw(PlayerSprite, self.position.x, self.position.y, 0, Config.image.scale, Config.image.scale)

    if self.pickingUp then
        if self.direction == "down" then
            love.graphics.draw(
                self.hand,
                self.position.x + self.width / 2 - self.hand:getWidth(),
                self.position.y + self.height / 2 - self.hand:getHeight(),
                0,
                Config.image.scale / 2,
                Config.image.scale / 2
            )
        end
    end

    if Config.debug then
        love.graphics.setColor(1, 0, 0)

        -- Collision
        love.graphics.circle("line", self.position.x + self.width / 2, self.position.y + self.height / 2, self.radius)

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

        love.graphics.setColor(1, 1, 1)
    end
end

return Player
