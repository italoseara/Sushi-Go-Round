function love.conf(t)
    t.window.title = "Sushi Go Round"
    t.window.width = 1152
    t.window.height = 720
    t.window.resizable = true
    t.window.fullscreen = false
    t.window.vsync = true

    t.modules.joystick = true

    Config = {
        window = {
            width = 1152,
            height = 720,
        },
        debug = true,
        image = {
            scale = 3,
            player = "assets/images/player.png",
            background = "assets/images/background.png",
            sushi = "assets/images/sushi.png",
            hand = "assets/images/hand.png",
        },
        keybinds = {
            {
                up = "w",
                down = "s",
                left = "a",
                right = "d",
                action = "space"
            },
            {
                up = "up",
                down = "down",
                left = "left",
                right = "right",
                action = "return"
            },
            {
                joystick = "left",
                action = "leftstick"
            },
            {
                joystick = "right",
                action = "rightstick"
            }
        }
    }
end
