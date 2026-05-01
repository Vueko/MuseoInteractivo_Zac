local SceneManager = require("src.managers.SceneManager")
local C = require("src.conf.Constants")

local IntroScene = {}

local t      = 0
local stars  = {}
local NSTARS = 80
local menuState = "main"

local mx, my = 0, 0

local books = {
    "• 'Breve historia de Zacatecas' - José Enciso Contreras",
    "• 'La Guerra Chichimeca (1550-1600)' - Philip Wayne Powell",
    "• 'Historia general de Zacatecas' - Varios Autores",
    "• 'Zacatecas: una historia compartida' - UAZ"
}

local function lerp(a, b, x) return a + (b - a) * x end
local function setColor(col, alpha)
    love.graphics.setColor(col[1], col[2], col[3], alpha or col[4] or 1)
end

function IntroScene:enter()
    t = 0
    menuState = "main"
    stars = {}
    for i = 1, NSTARS do
        table.insert(stars, {
            x  = math.random(0, C.W),
            y  = math.random(0, C.H),
            r  = math.random(1, 3),
            sp = math.random() * 0.3 + 0.05,
            ph = math.random() * math.pi * 2,
        })
    end
end

function IntroScene:update(dt)
    t = t + dt
    mx, my = love.mouse.getPosition()
end

local function drawCerroDeLaBufa(W, H)
    local cx = W / 2
    local base = H * 0.88
    
    love.graphics.setColor(C.COLOR.CANTERA_GRIS)
    love.graphics.polygon("fill",
        0, base,
        cx - 400, base - 100,
        cx - 200, base - 250,
        cx - 50,  base - 320,
        cx + 80,  base - 300,
        cx + 250, base - 180,
        W, base,
        0, base
    )
    
    love.graphics.setColor(0.5, 0.47, 0.44, 1) 
    love.graphics.polygon("fill",
        cx - 90, base - 320,
        cx - 50, base - 340,
        cx + 10, base - 330,
        cx + 60, base - 300,
        cx,      base - 280
    )
    
    love.graphics.setColor(0.3, 0.28, 0.25, 1) 
    local crossX = cx - 30
    local crossY = base - 370
    love.graphics.rectangle("fill", crossX - 3, crossY, 6, 40)
    love.graphics.rectangle("fill", crossX - 15, crossY + 10, 30, 6)
end

local function drawMuseo(W, H)
    local cx  = W / 2
    local base = H * 0.88
    local col  = C.COLOR.CANTERA_ROSA

    love.graphics.setColor(col)
    love.graphics.rectangle("fill", cx - 250, base - 100, 500, 100)
    
    love.graphics.polygon("fill",
        cx - 270, base - 100,
        cx,       base - 160,
        cx + 270, base - 100
    )
    
    love.graphics.setColor(0.65, 0.40, 0.32, 1) 
    for i = 0, 5 do
        local colX = cx - 210 + i * 84
        love.graphics.rectangle("fill", colX, base - 100, 20, 100)
    end
end

local function drawMenuButton(text, bx, by, bw, bh, hover, alpha)
    love.graphics.setColor(0, 0, 0, 0.4 * alpha)
    love.graphics.rectangle("fill", bx+4, by+4, bw, bh, 10, 10)
    if hover then
        setColor(C.COLOR.ORO_PLATA, alpha)
        love.graphics.rectangle("fill", bx, by, bw, bh, 10, 10)
        setColor(C.COLOR.NEGRO, alpha)
    else
        setColor(C.COLOR.CANTERA_ROSA, alpha)
        love.graphics.rectangle("fill", bx, by, bw, bh, 10, 10)
        setColor(C.COLOR.ORO_PLATA, alpha)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", bx, by, bw, bh, 10, 10)
        setColor(C.COLOR.BLANCO, alpha)
    end
    love.graphics.printf(text, bx, by + 14, bw, "center")
end

function IntroScene:draw()
    local W, H = love.graphics.getDimensions()

    -- Cielo estilo museo (día)
    love.graphics.setColor(C.COLOR.BEIGE_PERGAMINO)
    love.graphics.rectangle("fill", 0, 0, W, H)

    -- Sutil degradado cálido
    for i = 0, 20 do
        local frac = i / 20
        love.graphics.setColor(1, 0.9, 0.8, 0.05 * frac)
        love.graphics.rectangle("fill", 0, H * frac, W, H / 20 + 2)
    end

    drawCerroDeLaBufa(W, H)
    drawMuseo(W, H)

    local cx = W / 2
    local a1 = math.min(1, t * 0.5)
    setColor(C.COLOR.CAFE_OSCURO, a1)
    love.graphics.printf("MUSEO INTERACTIVO", 0, H * 0.15, W, "center")

    local scale = 1 + 0.012 * math.sin(t * 0.8)
    local a2    = math.min(1, math.max(0, (t - 0.4) * 0.7))
    setColor(C.COLOR.ORO_PLATA, a2)
    love.graphics.push()
    love.graphics.translate(cx, H * 0.23)
    love.graphics.scale(scale, scale)
    love.graphics.printf("ZACATECAS", -W/2, 0, W, "center")
    love.graphics.pop()

    local a3 = math.min(1, math.max(0, (t - 0.8) * 0.7))
    setColor(C.COLOR.CAFE_OSCURO, a3)
    love.graphics.printf("Historia · Cultura · Identidad", 0, H * 0.33, W, "center")

    local a5 = math.min(1, math.max(0, (t - 1.2) * 1.0))
    if a5 > 0 then
        if menuState == "main" then
            local bw, bh = 280, 50
            local startY = H * 0.45
            local buttons = {
                { id = "start", text = "▶  Iniciar (Entrar)" },
                { id = "books", text = "📖 Aprender Más" },
                { id = "quit",  text = "✖  Salir" }
            }
            for i, btn in ipairs(buttons) do
                local bx, by = cx - bw/2, startY + (i-1) * 70
                local hover = (mx >= bx and mx <= bx+bw and my >= by and my <= by+bh)
                drawMenuButton(btn.text, bx, by, bw, bh, hover, a5)
            end
        elseif menuState == "books" then
            -- Panel de libros
            love.graphics.setColor(0, 0, 0, 0.7 * a5)
            love.graphics.rectangle("fill", cx - 350, H * 0.42, 700, 300, 10, 10)
            
            setColor(C.COLOR.ORO_PLATA, a5)
            love.graphics.printf("LIBROS RECOMENDADOS", cx - 350, H * 0.45, 700, "center")
            
            setColor(C.COLOR.BLANCO, a5)
            for i, bText in ipairs(books) do
                love.graphics.printf(bText, cx - 320, H * 0.50 + i * 35, 640, "left")
            end
            
            -- Botón volver
            local bw, bh = 240, 45
            local bx, by = cx - bw/2, H * 0.42 + 300 - 65
            local hover = (mx >= bx and mx <= bx+bw and my >= by and my <= by+bh)
            drawMenuButton("← Volver", bx, by, bw, bh, hover, a5)
        end
    end
end

function IntroScene:mousepressed(x, y, button)
    if button ~= 1 then return end
    local W, H = love.graphics.getDimensions()
    local cx = W / 2
    local a5 = math.min(1, math.max(0, (t - 1.2) * 1.0))
    if a5 < 1 then return end

    if menuState == "main" then
        local bw, bh = 280, 50
        local startY = H * 0.45
        for i, id in ipairs({"start", "books", "quit"}) do
            local bx, by = cx - bw/2, startY + (i-1) * 70
            if x >= bx and x <= bx+bw and y >= by and y <= by+bh then
                if id == "start" then
                    SceneManager.switch("museum")
                elseif id == "books" then
                    menuState = "books"
                elseif id == "quit" then
                    love.event.quit()
                end
                return
            end
        end
    elseif menuState == "books" then
        local bw, bh = 240, 45
        local bx, by = cx - bw/2, H * 0.42 + 300 - 65
        if x >= bx and x <= bx+bw and y >= by and y <= by+bh then
            menuState = "main"
        end
    end
end

function IntroScene:keypressed(key)
    if menuState == "books" and key == "escape" then
        menuState = "main"
    end
end

return IntroScene
