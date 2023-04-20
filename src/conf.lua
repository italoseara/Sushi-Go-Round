function love.conf(t)
    t.window.title = "Sushi Go Round"
    t.window.width = 1152
    t.window.height = 720
    t.window.resizable = false
    t.window.fullscreen = false
    t.window.vsync = true

    t.modules.joystick = true

    Config = {
        debug = false,
        image = {
            scale = 3,
            player = "assets/images/player.png",
            background = "assets/images/background.png",
            sushi = "assets/images/sushi.png",
            hand = "assets/images/hand.png",
        },
        font = {
            menu = "assets/fonts/arcadeclassic/ARCADECLASSIC.TTF",
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
                action = "rctrl"
            },
            {
                joystick = "left",
                action = "leftshoulder"
            },
            {
                joystick = "right",
                action = "rightshoulder"
            }
        }
    }
end
