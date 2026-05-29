-- src/minigames/MgIndependencia.lua
local Base = require("src.minigames.MinigameBase")
local D    = require("src.data.CampaignData")

local MG = setmetatable({}, { __index = Base })
MG.__index = MG

local CFG = {
    id           = "mg_independencia",
    title        = "Mensajero Insurgente — Sigilo",
    subtitle     = "1810 – 1821 d.C.",
    accentColor  = {0.15, 0.55, 0.25, 1},
    bgColor      = {0.03, 0.06, 0.03, 1},
    instructions = "Entrega los tres mensajes sin ser detectado.\nEvita el campo de visión de las patrullas.",
}

local CS     = 48
local GCOLS  = 24
local GROWS  = 14

local player      = {}
local guards      = {}
local deliveries  = {}
local delivered   = 0
local caught      = false
local gameState   = "cinematic"
local cinematicTexts = {}
local cinematicIndex = 1
local cinematicAlpha = 0
local guardTimer  = 0

-- 0=calle, 1=edificio
local MAP = {
    {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
    {1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,1},
    {1,0,1,1,0,1,1,0,1,0,1,1,0,1,0,1,0,1,1,0,1,1,0,1},
    {1,0,1,0,0,0,1,0,0,0,1,0,0,1,0,0,0,1,0,0,0,1,0,1},
    {1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,1,0,0,0,1},
    {1,1,1,0,1,0,1,1,1,1,1,0,1,0,1,1,1,0,1,1,0,1,1,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,1,1,0,1,0,1,1,0,1,1,0,1,1,0,1,0,1,0,1,1,0,1},
    {1,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,1,0,0,1,0,1,0,1},
    {1,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,1},
    {1,1,1,0,1,0,1,1,1,0,1,0,1,1,1,0,1,0,1,1,0,1,1,1},
    {1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
}

local function inMap(x, y)
    return x >= 1 and x <= GCOLS and y >= 1 and y <= GROWS
end

local function isFree(x, y)
    return inMap(x, y) and MAP[y] and MAP[y][x] == 0
end

function MG.new()
    local self = Base.new(CFG)
    return setmetatable(self, MG)
end

function MG:onEnter(data)
    cinematicTexts = D.chapters["mg_independencia"].opening
    cinematicIndex = 1
    cinematicAlpha = 0
    gameState      = "cinematic"
    delivered      = 0
    caught         = false
    guardTimer     = 0   -- BUG FIX: reset timer on every entry

    player = { gx = 2, gy = 12 }

    guards = {
        -- Guard 1: patrola corredor abierto row 7, sección oeste
        { gx = 5,  gy = 7, dir =  1, axis = "x", min = 2,  max = 11, visionRange = 4 },
        -- Guard 2: patrola corredor abierto row 7, sección este
        { gx = 18, gy = 7, dir = -1, axis = "x", min = 13, max = 22, visionRange = 4 },
        -- Guard 3: patrola corredor norte row 2 (celdas libres 10-15)
        { gx = 12, gy = 2, dir =  1, axis = "x", min = 10, max = 15, visionRange = 3 },
    }

    deliveries = {
        { gx = 22, gy = 2,  done = false },
        { gx = 4,  gy = 5,  done = false },   -- BUG FIX: was (2,5) which is a wall cell
        { gx = 21, gy = 11, done = false },   -- BUG FIX: (22,11) is a wall cell
    }
end

local GUARD_SPEED = 2.2

function MG:onUpdate(dt)
    if gameState == "cinematic" then
        cinematicAlpha = math.min(1, cinematicAlpha + dt * 1.5)
        return
    end
    if caught then return end

    guardTimer = guardTimer + dt
    if guardTimer >= 1 / GUARD_SPEED then
        guardTimer = 0
        for _, g in ipairs(guards) do
            -- BUG FIX: check isFree before moving, reverse on wall
            if g.axis == "x" then
                local nx = g.gx + g.dir
                if not isFree(nx, g.gy) or nx >= g.max or nx <= g.min then
                    g.dir = -g.dir
                    nx    = g.gx + g.dir
                end
                if isFree(nx, g.gy) then g.gx = nx end
            else
                local ny = g.gy + g.dir
                if not isFree(g.gx, ny) or ny >= g.max or ny <= g.min then
                    g.dir = -g.dir
                    ny    = g.gy + g.dir
                end
                if isFree(g.gx, ny) then g.gy = ny end
            end
        end
    end

    -- Detección: rayo en dirección de movimiento
    for _, g in ipairs(guards) do
        local ddx = g.axis == "x" and g.dir or 0
        local ddy = g.axis == "y" and g.dir or 0
        for dist = 1, g.visionRange do
            local vx = g.gx + ddx * dist
            local vy = g.gy + ddy * dist
            if not inMap(vx, vy) then break end
            if MAP[vy][vx] == 1 then break end
            if vx == player.gx and vy == player.gy then
                caught = true
                self:lose()
                return
            end
        end
    end

    -- Recoger entrega
    for _, del in ipairs(deliveries) do
        if not del.done and del.gx == player.gx and del.gy == player.gy then
            del.done  = true
            delivered = delivered + 1
            if delivered >= 3 then self:win() end
        end
    end
end

function MG:onKeypressed(key)
    if gameState == "cinematic" then
        if key == "space" or key == "return" or key == "e" then
            cinematicIndex = cinematicIndex + 1; cinematicAlpha = 0
            if cinematicIndex > #cinematicTexts then gameState = "playing" end
        end
        return
    end
    if caught then return end

    local moves = {
        a = {-1, 0}, left  = {-1, 0},
        d = { 1, 0}, right = { 1, 0},
        w = { 0,-1}, up    = { 0,-1},
        s = { 0, 1}, down  = { 0, 1},
    }
    local m = moves[key]
    if m then
        local nx = player.gx + m[1]
        local ny = player.gy + m[2]
        if isFree(nx, ny) then player.gx, player.gy = nx, ny end
    end
end

function MG:onMousepressed(x, y, button)
    if gameState == "cinematic" and button == 1 then
        cinematicIndex = cinematicIndex + 1; cinematicAlpha = 0
        if cinematicIndex > #cinematicTexts then gameState = "playing" end
    end
end

-- Dibuja adoquines coloniales en celda libre
local function drawCobblestone(px, py)
    love.graphics.setColor(0.13, 0.11, 0.08, 1)
    love.graphics.rectangle("fill", px, py, CS, CS)
    local half = CS / 2
    for cy2 = 0, 1 do
        for cx2 = 0, 1 do
            local sx = px + cx2 * half + 2
            local sy = py + cy2 * half + 2
            local shade = ((cx2 + cy2) % 2 == 0) and 0.18 or 0.16
            love.graphics.setColor(shade, shade * 0.88, shade * 0.72, 1)
            love.graphics.rectangle("fill", sx, sy, half - 4, half - 4, 2, 2)
        end
    end
end

-- Dibuja edificio colonial (pared)
local function drawWall(px, py)
    love.graphics.setColor(0.20, 0.16, 0.11, 1)
    love.graphics.rectangle("fill", px, py, CS, CS)
    love.graphics.setColor(0.26, 0.21, 0.14, 0.8)
    love.graphics.rectangle("fill", px + 3, py + 3, CS - 6, CS - 6)
    -- grietas decorativas
    love.graphics.setColor(0.14, 0.11, 0.07, 0.5)
    love.graphics.line(px + 8, py + 6, px + 8, py + CS - 6)
    love.graphics.line(px + 6, py + 8, px + CS - 6, py + 8)
end

-- Dibuja farol (punto de entrega)
local function drawLantern(del, offX, offY)
    local dx = (del.gx - 1) * CS + CS / 2
    local dy = (del.gy - 1) * CS + CS / 2
    local t  = love.timer.getTime()

    if del.done then
        love.graphics.setColor(0.20, 0.70, 0.30, 0.7)
        love.graphics.circle("fill", dx, dy, CS / 2 - 6)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("✓", (del.gx-1)*CS, (del.gy-1)*CS + CS/4, CS, "center")
        return
    end

    local flicker = 0.75 + 0.25 * math.sin(t * 5.3 + del.gx) * math.cos(t * 3.1 + del.gy)

    -- halo exterior
    love.graphics.setColor(0.90, 0.62, 0.08, 0.12 * flicker)
    love.graphics.circle("fill", dx, dy, CS * 0.9)
    -- halo medio
    love.graphics.setColor(0.95, 0.72, 0.12, 0.25 * flicker)
    love.graphics.circle("fill", dx, dy, CS / 2)
    -- cuerpo del farol
    love.graphics.setColor(0.40, 0.32, 0.18, 1)
    love.graphics.rectangle("fill", dx - 7, dy - 10, 14, 18, 3, 3)
    love.graphics.setColor(0.20, 0.16, 0.08, 1)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", dx - 7, dy - 10, 14, 18, 3, 3)
    -- llama
    love.graphics.setColor(1.0, 0.85, 0.20, flicker)
    love.graphics.circle("fill", dx, dy - 5, 4)
    love.graphics.setColor(1.0, 0.95, 0.60, flicker * 0.8)
    love.graphics.circle("fill", dx, dy - 6, 2)
    -- ícono mensaje
    love.graphics.setColor(1, 0.92, 0.70, 0.9)
    love.graphics.printf("!", (del.gx-1)*CS, (del.gy-1)*CS + CS * 0.6, CS, "center")
end

-- Dibuja mensajero insurgente
local function drawPlayer(ppx, ppy)
    -- sombra
    love.graphics.setColor(0, 0, 0, 0.28)
    love.graphics.circle("fill", ppx + 2, ppy + 5, CS / 3)
    -- serape (cuerpo)
    love.graphics.setColor(0.22, 0.38, 0.18, 1)
    love.graphics.circle("fill", ppx, ppy + 3, CS / 3)
    -- detalle del serape (franja)
    love.graphics.setColor(0.55, 0.30, 0.12, 1)
    love.graphics.rectangle("fill", ppx - 5, ppy + 1, 10, 4)
    -- cabeza
    love.graphics.setColor(0.78, 0.62, 0.46, 1)
    love.graphics.circle("fill", ppx, ppy - CS / 4 + 2, CS / 6)
    -- ala del sombrero
    love.graphics.setColor(0.22, 0.15, 0.06, 1)
    love.graphics.ellipse("fill", ppx, ppy - CS / 4 - CS / 8, CS / 2.8, CS / 11)
    -- copa del sombrero
    love.graphics.setColor(0.28, 0.19, 0.08, 1)
    love.graphics.ellipse("fill", ppx, ppy - CS / 4 - CS / 5.5, CS / 5, CS / 8)
end

-- Dibuja soldado realista
local function drawGuard(gx, gy)
    -- sombra
    love.graphics.setColor(0, 0, 0, 0.28)
    love.graphics.circle("fill", gx + 2, gy + 5, CS / 3)
    -- casaca azul oscuro
    love.graphics.setColor(0.10, 0.15, 0.42, 1)
    love.graphics.circle("fill", gx, gy + 3, CS / 3)
    -- cuello rojo
    love.graphics.setColor(0.68, 0.12, 0.10, 1)
    love.graphics.circle("fill", gx, gy + 1, CS / 5.5)
    -- cabeza
    love.graphics.setColor(0.80, 0.68, 0.52, 1)
    love.graphics.circle("fill", gx, gy - CS / 4 + 2, CS / 6)
    -- bicornio (sombrero de pico)
    love.graphics.setColor(0.08, 0.08, 0.10, 1)
    love.graphics.ellipse("fill", gx, gy - CS / 4 - CS / 9, CS / 3.5, CS / 12)
    -- mosquete (línea diagonal)
    love.graphics.setColor(0.50, 0.40, 0.28, 1)
    love.graphics.setLineWidth(2)
    love.graphics.line(gx + CS/4.5, gy + CS/3.5, gx + CS/3.2, gy - CS/3.5)
    love.graphics.setLineWidth(1)
end

function MG:onDraw()
    local W, H   = love.graphics.getDimensions()
    local mapW   = GCOLS * CS
    local mapH   = GROWS * CS
    local offX   = (W - mapW) / 2
    local offY   = (H - mapH) / 2 + 26

    -- Fondo noche oscura
    love.graphics.setColor(0.04, 0.05, 0.03, 1)
    love.graphics.rectangle("fill", 0, 0, W, H)

    love.graphics.push()
    love.graphics.translate(offX, offY)

    -- Mapa
    for y = 1, GROWS do
        for x = 1, GCOLS do
            local px = (x-1)*CS; local py = (y-1)*CS
            if MAP[y][x] == 1 then
                drawWall(px, py)
            else
                drawCobblestone(px, py)
            end
        end
    end

    -- Puntos de entrega (faroles)
    for _, del in ipairs(deliveries) do
        drawLantern(del, offX, offY)
    end

    -- Cono de visión de guardias
    love.graphics.setColor(0.95, 0.85, 0.15, 0.04)
    for _, g in ipairs(guards) do
        local ddx = g.axis == "x" and g.dir or 0
        local ddy = g.axis == "y" and g.dir or 0
        for dist = 1, g.visionRange do
            local vx = g.gx + ddx * dist
            local vy = g.gy + ddy * dist
            if not inMap(vx, vy) or MAP[vy][vx] == 1 then break end
            local alpha = 0.22 - dist * 0.04
            love.graphics.setColor(1, 0.80, 0.10, alpha)
            love.graphics.rectangle("fill", (vx-1)*CS, (vy-1)*CS, CS, CS)
        end
    end

    -- Guardias
    for _, g in ipairs(guards) do
        local gx = (g.gx-1)*CS + CS/2
        local gy = (g.gy-1)*CS + CS/2
        drawGuard(gx, gy)
    end

    -- Jugador
    local ppx = (player.gx-1)*CS + CS/2
    local ppy = (player.gy-1)*CS + CS/2
    drawPlayer(ppx, ppy)

    love.graphics.pop()

    -- Overlay capturado
    if caught then
        love.graphics.setColor(0.60, 0.04, 0.04, 0.70)
        love.graphics.rectangle("fill", 0, 0, W, H)
        love.graphics.setColor(1, 0.92, 0.80, 1)
        love.graphics.printf("¡DESCUBIERTO!", 0, H/2 - 30, W, "center")
        love.graphics.setColor(0.80, 0.65, 0.50, 0.8)
        love.graphics.printf("La patrulla te encontró", 0, H/2 + 14, W, "center")
    end

    -- HUD
    love.graphics.setColor(0, 0, 0, 0.80)
    love.graphics.rectangle("fill", 0, 0, W, 48)
    love.graphics.setColor(0.20, 0.80, 0.35, 1)
    love.graphics.printf("Mensajes entregados: " .. delivered .. " / 3", 0, 14, W, "center")

    -- Cinemática
    if gameState == "cinematic" then
        love.graphics.setColor(0, 0, 0, 0.90)
        love.graphics.rectangle("fill", 0, 0, W, H)
        love.graphics.setColor(1, 0.9, 0.8, cinematicAlpha)
        love.graphics.push()
        love.graphics.translate(W/2, H/2 - 40)
        love.graphics.scale(1.6, 1.6)
        love.graphics.printf(cinematicTexts[cinematicIndex] or "", -240, 0, 480, "center")
        love.graphics.pop()
        love.graphics.setColor(0.7, 0.7, 0.7, cinematicAlpha*(0.5+0.5*math.sin(love.timer.getTime()*4)))
        love.graphics.printf("Presiona ESPACIO o CLIC para continuar", 0, H-60, W, "center")
    end
end

function MG:enter(data)     Base.enter(self, data)          end
function MG:update(dt)      Base.update(self, dt)           end
function MG:draw()          Base.draw(self)                 end
function MG:keypressed(k)   Base.keypressed(self, k)        end
function MG:mousepressed(x,y,b) Base.mousepressed(self,x,y,b) end
function MG:leave()  end
function MG:pause()  end
function MG:resume() end

return MG.new()
