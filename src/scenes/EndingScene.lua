-- src/scenes/EndingScene.lua
local SceneManager = require("src.managers.SceneManager")
local D = require("src.data.CampaignData")

local EndingScene = {}

local t           = 0
local screenIndex = 1
local alpha       = 0
local stars       = {}

local function initStars(W, H)
    stars = {}
    for i = 1, 60 do
        table.insert(stars, {
            x  = math.random(0, W),
            y  = math.random(0, H),
            r  = math.random(1, 3),
            ph = math.random() * math.pi * 2,
        })
    end
end

function EndingScene:enter()
    t           = 0
    screenIndex = 1
    alpha       = 0
    local W, H  = love.graphics.getDimensions()
    initStars(W, H)
end

function EndingScene:update(dt)
    t     = t + dt
    alpha = math.min(1, alpha + dt * 1.2)
end

function EndingScene:draw()
    local W, H   = love.graphics.getDimensions()
    local ending = D.ending

    -- Fondo oscuro
    love.graphics.setColor(0.04, 0.03, 0.08, 1)
    love.graphics.rectangle("fill", 0, 0, W, H)

    -- Estrellas
    for _, s in ipairs(stars) do
        local sa = 0.4 + 0.4 * math.sin(t * 0.5 + s.ph)
        love.graphics.setColor(1, 1, 1, sa * alpha)
        love.graphics.circle("fill", s.x, s.y, s.r)
    end

    -- Título
    love.graphics.setColor(0.85, 0.75, 0.30, alpha)
    love.graphics.printf(ending.title, 0, H * 0.10, W, "center")

    -- Línea decorativa
    local lw = math.min(400, 400 * alpha)
    love.graphics.setColor(0.85, 0.75, 0.30, 0.5 * alpha)
    love.graphics.setLineWidth(1.5)
    love.graphics.line(W/2 - lw/2, H * 0.18, W/2 + lw/2, H * 0.18)

    -- Párrafo actual
    love.graphics.setColor(1, 0.95, 0.88, alpha * 0.92)
    love.graphics.push()
    love.graphics.translate(W / 2, H * 0.30)
    love.graphics.scale(1.25, 1.25)
    love.graphics.printf(ending.paragraphs[screenIndex], -280, 0, 560, "center")
    love.graphics.pop()

    -- Puntos de progreso
    local n = #ending.paragraphs
    for i = 1, n do
        local cx = W/2 + (i - (n + 1)/2) * 22
        if i == screenIndex then
            love.graphics.setColor(0.85, 0.75, 0.30, alpha)
            love.graphics.circle("fill", cx, H - 70, 6)
        else
            love.graphics.setColor(0.40, 0.38, 0.35, alpha)
            love.graphics.circle("fill", cx, H - 70, 4)
        end
    end

    -- Prompt
    local pulse = 0.5 + 0.5 * math.sin(t * 3.2)
    local hint  = screenIndex < n
        and "Presiona ESPACIO para continuar"
        or  "Presiona ESPACIO para volver al inicio"
    love.graphics.setColor(0.55, 0.52, 0.48, alpha * pulse)
    love.graphics.printf(hint, 0, H - 44, W, "center")
end

local function advance()
    local n = #D.ending.paragraphs
    if screenIndex < n then
        screenIndex = screenIndex + 1
        alpha       = 0
    else
        SceneManager.switch("intro")
    end
end

function EndingScene:keypressed(key)
    if key == "space" or key == "return" or key == "e" then
        advance()
    end
end

function EndingScene:mousepressed(x, y, button)
    if button == 1 then advance() end
end

function EndingScene:leave() end
function EndingScene:pause() end
function EndingScene:resume() end

return EndingScene
