-- src/minigames/MgMineria.lua
-- Vista en primera persona (raycasting DDA) en las minas coloniales de Zacatecas
local Base = require("src.minigames.MinigameBase")
local D    = require("src.data.CampaignData")

local MG = setmetatable({}, { __index = Base })
MG.__index = MG

local CFG = {
    id           = "mg_mineria",
    title        = "Real de Minas — Exploración",
    subtitle     = "Siglos XVI–XVII d.C.",
    accentColor  = {0.78, 0.78, 0.82, 1},
    bgColor      = {0.04, 0.04, 0.06, 1},
    instructions = "Encuentra las tres vetas de plata en la mina.\nWASD: mover y girar.",
}

local MAP_W = 16
local MAP_H = 12
-- 1 = pared de roca, 0 = corredor
local MAP = {
    {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
    {1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1},
    {1,0,1,1,0,0,0,1,0,0,0,0,1,1,0,1},
    {1,0,0,0,0,1,0,1,0,1,0,0,0,0,0,1},
    {1,1,0,1,0,0,0,0,0,1,0,1,0,1,1,1},
    {1,0,0,1,0,1,0,1,0,0,0,1,0,0,0,1},
    {1,0,1,0,0,0,0,0,0,1,0,0,0,1,0,1},
    {1,0,0,0,1,0,1,0,0,0,1,0,0,0,0,1},
    {1,1,0,0,0,0,0,0,1,0,0,1,0,1,1,1},
    {1,0,0,1,0,1,0,0,0,0,1,0,0,0,0,1},
    {1,0,0,0,0,0,0,1,0,0,0,0,1,0,0,1},
    {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
}

-- Vetas de plata: (columna, fila) en coordenadas 1-indexed del mapa
-- Verificados como celdas libres (MAP[fila][col] == 0)
local ORE_CELLS = { {14,2}, {2,10}, {14,10} }

local player    = {}
local ores      = {}
local collected = 0
local gameState = "cinematic"
local cinematicTexts = {}
local cinematicIndex = 1
local cinematicAlpha = 0

local MOVE_SPEED = 2.5
local ROT_SPEED  = 2.0
local COLLECT_DIST = 0.85

-- Z-buffer: distancia perpendicular por columna de pantalla
local zBuffer = {}

local function mapBlocked(wx, wy)
    local col = math.floor(wx) + 1
    local row = math.floor(wy) + 1
    if row < 1 or row > MAP_H or col < 1 or col > MAP_W then return true end
    return MAP[row][col] == 1
end

function MG.new()
    local self = Base.new(CFG)
    return setmetatable(self, MG)
end

function MG:onEnter(data)
    cinematicTexts = D.chapters["mg_mineria"].opening
    cinematicIndex = 1
    cinematicAlpha = 0
    gameState      = "cinematic"
    collected      = 0

    -- Jugador comienza en celda (2,2), mirando al este (+X)
    player = {
        x  = 1.5, y = 1.5,
        dx = 1.0, dy = 0.0,  -- vector dirección
        cx = 0.0, cy = 0.66, -- plano de cámara (FOV ~66°)
    }

    ores = {}
    for _, cell in ipairs(ORE_CELLS) do
        -- Centro de celda en coordenadas mundo (0-indexed float)
        table.insert(ores, {
            wx        = cell[1] - 0.5,
            wy        = cell[2] - 0.5,
            collected = false,
        })
    end
end

local function rotatePlayer(angle)
    local c = math.cos(angle); local s = math.sin(angle)
    local dx, dy = player.dx, player.dy
    player.dx = dx * c - dy * s
    player.dy = dx * s + dy * c
    local cx, cy = player.cx, player.cy
    player.cx = cx * c - cy * s
    player.cy = cx * s + cy * c
end

function MG:onUpdate(dt)
    if gameState == "cinematic" then
        cinematicAlpha = math.min(1, cinematicAlpha + dt * 1.5)
        return
    end

    -- Movimiento (separado por eje para sliding en paredes)
    if love.keyboard.isDown("w", "up") then
        local nx = player.x + player.dx * MOVE_SPEED * dt
        local ny = player.y + player.dy * MOVE_SPEED * dt
        if not mapBlocked(nx, player.y) then player.x = nx end
        if not mapBlocked(player.x, ny) then player.y = ny end
    end
    if love.keyboard.isDown("s", "down") then
        local nx = player.x - player.dx * MOVE_SPEED * dt
        local ny = player.y - player.dy * MOVE_SPEED * dt
        if not mapBlocked(nx, player.y) then player.x = nx end
        if not mapBlocked(player.x, ny) then player.y = ny end
    end
    -- A/izquierda = girar a la izquierda (ángulo negativo en coordenadas pantalla)
    if love.keyboard.isDown("a", "left")  then rotatePlayer(-ROT_SPEED * dt) end
    if love.keyboard.isDown("d", "right") then rotatePlayer( ROT_SPEED * dt) end

    -- Recoger vetas cercanas
    for _, ore in ipairs(ores) do
        if not ore.collected then
            local dist = math.sqrt((player.x - ore.wx)^2 + (player.y - ore.wy)^2)
            if dist < COLLECT_DIST then
                ore.collected = true
                collected     = collected + 1
                if collected >= 3 then self:win() end
            end
        end
    end
end

function MG:onKeypressed(key)
    if gameState == "cinematic" then
        if key == "space" or key == "return" or key == "e" then
            cinematicIndex = cinematicIndex + 1; cinematicAlpha = 0
            if cinematicIndex > #cinematicTexts then gameState = "playing" end
        end
    end
end

function MG:onMousepressed(mx, my, button)
    if gameState == "cinematic" and button == 1 then
        cinematicIndex = cinematicIndex + 1; cinematicAlpha = 0
        if cinematicIndex > #cinematicTexts then gameState = "playing" end
    end
end

-- DDA raycasting: devuelve (distancia perpendicular, lado)
local function castRay(rayDX, rayDY)
    local mapX = math.floor(player.x)
    local mapY = math.floor(player.y)

    local ddX = rayDX == 0 and 1e30 or math.abs(1 / rayDX)
    local ddY = rayDY == 0 and 1e30 or math.abs(1 / rayDY)

    local stepX, stepY, sdX, sdY
    if rayDX < 0 then stepX = -1; sdX = (player.x - mapX) * ddX
    else              stepX =  1; sdX = (mapX + 1.0 - player.x) * ddX end
    if rayDY < 0 then stepY = -1; sdY = (player.y - mapY) * ddY
    else              stepY =  1; sdY = (mapY + 1.0 - player.y) * ddY end

    local side = 0
    for _ = 1, 64 do
        if sdX < sdY then
            sdX = sdX + ddX; mapX = mapX + stepX; side = 0
        else
            sdY = sdY + ddY; mapY = mapY + stepY; side = 1
        end
        local r = mapY + 1; local c = mapX + 1
        if r < 1 or r > MAP_H or c < 1 or c > MAP_W then break end
        if MAP[r][c] == 1 then break end
    end

    local perpDist
    if side == 0 then perpDist = sdX - ddX
    else              perpDist = sdY - ddY end

    return math.max(0.001, perpDist), side
end

function MG:onDraw()
    local W, H = love.graphics.getDimensions()

    -- Cinemática cubre toda la pantalla
    if gameState == "cinematic" then
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("fill", 0, 0, W, H)
        love.graphics.setColor(1, 0.9, 0.8, cinematicAlpha)
        love.graphics.push()
        love.graphics.translate(W/2, H/2 - 40)
        love.graphics.scale(1.6, 1.6)
        love.graphics.printf(cinematicTexts[cinematicIndex] or "", -240, 0, 480, "center")
        love.graphics.pop()
        love.graphics.setColor(0.7, 0.7, 0.7, cinematicAlpha*(0.5+0.5*math.sin(love.timer.getTime()*4)))
        love.graphics.printf("Presiona ESPACIO o CLIC para continuar", 0, H-60, W, "center")
        return
    end

    -- Techo: roca oscura, con gradiente desde el horizonte
    love.graphics.setColor(0.04, 0.03, 0.02, 1)
    love.graphics.rectangle("fill", 0, 0, W, H / 2)
    -- Gradiente de techo (más claro cerca del centro)
    for i = 0, 40 do
        local t = i / 40
        love.graphics.setColor(0.08 * t, 0.06 * t, 0.04 * t, 0.3)
        love.graphics.rectangle("fill", 0, H/2 - i * 4, W, 4)
    end

    -- Suelo: tierra/piedra, más oscuro al fondo
    love.graphics.setColor(0.10, 0.08, 0.05, 1)
    love.graphics.rectangle("fill", 0, H / 2, W, H / 2)
    for i = 0, 40 do
        local t = i / 40
        love.graphics.setColor(0.06 * (1-t), 0.05 * (1-t), 0.03 * (1-t), 0.3)
        love.graphics.rectangle("fill", 0, H/2 + i * 4, W, 4)
    end

    -- Columnas de pared (raycasting)
    for screenX = 0, W - 1 do
        local cameraX = 2 * screenX / W - 1
        local rayDX   = player.dx + player.cx * cameraX
        local rayDY   = player.dy + player.cy * cameraX

        local perpDist, side = castRay(rayDX, rayDY)
        zBuffer[screenX]     = perpDist

        local lineH  = math.floor(H / perpDist)
        local y0     = math.max(0, math.floor((H - lineH) / 2))
        local y1     = math.min(H - 1, math.floor((H + lineH) / 2))

        -- Color de pared: luz tenue de antorcha, rango corto
        local torchT = math.max(0, 1 - perpDist / 7)
        local r = 0.08 + torchT * 0.32
        local g = 0.05 + torchT * 0.18
        local b = 0.02 + torchT * 0.06
        -- Paredes N/S más oscuras (ilusión de sombreado)
        if side == 1 then r = r * 0.68; g = g * 0.68; b = b * 0.68 end

        love.graphics.setColor(r, g, b, 1)
        love.graphics.rectangle("fill", screenX, y0, 1, math.max(1, y1 - y0))
    end

    -- Sprites de vetas de plata (ordenados de más lejos a más cercano)
    local spriteList = {}
    local time = love.timer.getTime()
    for _, ore in ipairs(ores) do
        if not ore.collected then
            local dx = ore.wx - player.x; local dy = ore.wy - player.y
            table.insert(spriteList, { ore = ore, dist2 = dx*dx + dy*dy })
        end
    end
    table.sort(spriteList, function(a, b) return a.dist2 > b.dist2 end)

    for _, entry in ipairs(spriteList) do
        local ore = entry.ore
        local dx  = ore.wx - player.x
        local dy  = ore.wy - player.y

        local invDet = 1.0 / (player.cx * player.dy - player.dx * player.cy)
        local tX = invDet * ( player.dy * dx - player.dx * dy)
        local tY = invDet * (-player.cy * dx + player.cx * dy)

        if tY > 0.15 then
            local spriteScreenX = math.floor(W / 2 * (1 + tX / tY))
            local sprH = math.max(1, math.abs(math.floor(H / tY)))
            local sprW = sprH

            local drawY0 = math.max(0, math.floor(H/2 - sprH/2))
            local drawY1 = math.min(H-1, math.floor(H/2 + sprH/2))
            local x0     = math.floor(spriteScreenX - sprW/2)
            local x1     = math.floor(spriteScreenX + sprW/2)

            local glow = 0.60 + 0.40 * math.sin(time * 2.8)

            for sx = x0, x1 do
                if sx >= 0 and sx < W and tY < (zBuffer[sx] or 1e30) then
                    -- Brillo azul-plateado de la veta
                    local frac = (sx - x0) / math.max(1, x1 - x0) - 0.5
                    local intensity = 1 - frac * frac * 4
                    intensity = math.max(0, intensity)
                    love.graphics.setColor(
                        0.55 + 0.30 * intensity,
                        0.80 + 0.15 * intensity,
                        1.00,
                        glow * intensity * 0.85
                    )
                    love.graphics.rectangle("fill", sx, drawY0, 1, math.max(1, drawY1 - drawY0))
                end
            end
            -- Destello central
            if spriteScreenX >= 0 and spriteScreenX < W and tY < (zBuffer[spriteScreenX] or 1e30) then
                local cw = math.max(3, sprW * 0.22)
                local ch = math.max(3, sprH * 0.22)
                love.graphics.setColor(1, 1, 1, glow * 0.95)
                love.graphics.rectangle("fill",
                    spriteScreenX - cw/2, H/2 - ch/2, cw, ch)
            end
        end
    end

    -- Minimapa (esquina superior izquierda)
    local mmCS = 7
    local mmX  = 12; local mmY = 56
    love.graphics.setColor(0, 0, 0, 0.75)
    love.graphics.rectangle("fill", mmX-2, mmY-2, MAP_W*mmCS+4, MAP_H*mmCS+4, 3, 3)
    for row = 1, MAP_H do
        for col = 1, MAP_W do
            local cx = mmX + (col-1)*mmCS
            local cy = mmY + (row-1)*mmCS
            if MAP[row][col] == 1 then
                love.graphics.setColor(0.40, 0.30, 0.20, 1)
            else
                love.graphics.setColor(0.09, 0.08, 0.06, 1)
            end
            love.graphics.rectangle("fill", cx, cy, mmCS-1, mmCS-1)
        end
    end
    -- Vetas en minimapa
    for _, ore in ipairs(ores) do
        if not ore.collected then
            love.graphics.setColor(0.65, 0.88, 1.0, 1)
            love.graphics.circle("fill",
                mmX + ore.wx * mmCS,
                mmY + ore.wy * mmCS, 3)
        end
    end
    -- Jugador en minimapa
    local ppx = mmX + player.x * mmCS
    local ppy = mmY + player.y * mmCS
    love.graphics.setColor(1, 0.85, 0.30, 1)
    love.graphics.circle("fill", ppx, ppy, 3)
    love.graphics.setColor(1, 0.85, 0.30, 0.85)
    love.graphics.line(ppx, ppy, ppx + player.dx * 10, ppy + player.dy * 10)

    local t = love.timer.getTime()
    local flicker = 0.82 + 0.18 * math.sin(t * 6.8) * math.cos(t * 4.3)

    -- Luz de antorcha tenue: solo el área inmediata alrededor del jugador
    love.graphics.setBlendMode("add")
    love.graphics.setColor(0.18, 0.08, 0.01, 0.20 * flicker)
    love.graphics.circle("fill", W/2, H * 0.62, H * 0.72)
    love.graphics.setColor(0.25, 0.12, 0.02, 0.16 * flicker)
    love.graphics.circle("fill", W/2, H * 0.72, H * 0.52)
    love.graphics.setColor(0.35, 0.16, 0.03, 0.12 * flicker)
    love.graphics.circle("fill", W/2, H * 0.82, H * 0.35)
    -- Núcleo cálido cerca de la llama
    love.graphics.setColor(0.55, 0.28, 0.05, 0.22 * flicker)
    love.graphics.circle("fill", W/2, H * 0.88, H * 0.18)
    love.graphics.setBlendMode("alpha")

    -- Viñeta sutil: solo las esquinas extremas (no tapa el centro)
    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.rectangle("fill", 0,       0, W * 0.06, H)
    love.graphics.rectangle("fill", W * 0.94, 0, W * 0.06, H)
    love.graphics.rectangle("fill", 0, 0,       W, H * 0.05)
    love.graphics.rectangle("fill", 0, H * 0.95, W, H * 0.05)

    -- Partículas de polvo flotante
    love.graphics.setColor(0.70, 0.58, 0.40, 0.22)
    for i = 1, 8 do
        local px2 = W * (0.15 + 0.70 * ((i * 137 % 100) / 100))
            + math.sin(t * 0.4 + i * 1.7) * 18
        local py2 = H * 0.38 + math.sin(t * 0.6 + i * 0.9) * (H * 0.18)
        love.graphics.circle("fill", px2, py2, math.max(0.8, 1.5 + math.sin(t * 1.1 + i) * 0.7))
    end

    -- Mango de antorcha (parte inferior, primera persona)
    local tx = W / 2
    local ty = H + 20
    love.graphics.setColor(0.32, 0.20, 0.08, 1)
    love.graphics.rectangle("fill", tx - 6, ty - 80, 12, 90, 2, 2)
    love.graphics.setColor(0.22, 0.13, 0.05, 1)
    love.graphics.rectangle("fill", tx - 4, ty - 78, 8, 86)
    -- Cabeza (trapo con brasa)
    love.graphics.setColor(0.42, 0.26, 0.10, 1)
    love.graphics.circle("fill", tx, ty - 82, 9)
    -- Llama
    love.graphics.setColor(1.0, 0.70, 0.10, flicker)
    love.graphics.circle("fill", tx, ty - 94, 11)
    love.graphics.setColor(1.0, 0.88, 0.30, flicker * 0.85)
    love.graphics.circle("fill", tx + math.sin(t * 5.2) * 2, ty - 104, 7)
    love.graphics.setColor(1.0, 0.96, 0.70, flicker * 0.65)
    love.graphics.circle("fill", tx + math.sin(t * 7.1) * 1.5, ty - 112, 4)

    -- Mira central
    love.graphics.setColor(1, 1, 1, 0.45)
    love.graphics.line(W/2 - 12, H/2, W/2 + 12, H/2)
    love.graphics.line(W/2, H/2 - 12, W/2, H/2 + 12)
    love.graphics.setColor(1, 1, 1, 0.20)
    love.graphics.circle("line", W/2, H/2, 5)

    -- HUD superior
    love.graphics.setColor(0, 0, 0, 0.80)
    love.graphics.rectangle("fill", 0, 0, W, 50)
    love.graphics.setColor(0.78, 0.78, 0.85, 1)
    love.graphics.printf("Vetas de plata: " .. collected .. " / 3", 0, 14, W, "center")
    love.graphics.setColor(0.40, 0.38, 0.34, 1)
    love.graphics.printf("WASD: avanzar · A/D: girar", W - 240, 14, 230, "left")
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
