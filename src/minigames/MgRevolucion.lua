-- src/minigames/MgRevolucion.lua
local Base = require("src.minigames.MinigameBase")
local D    = require("src.data.CampaignData")

local MG = setmetatable({}, { __index = Base })
MG.__index = MG

local CFG = {
    id           = "mg_revolucion",
    title        = "División del Norte — Táctico",
    subtitle     = "23 de junio de 1914",
    accentColor  = {0.70, 0.12, 0.12, 1},
    bgColor      = {0.04, 0.03, 0.02, 1},
    instructions = "Asigna tropas a las posiciones y presiona ATACAR.\nEl Cerro de la Bufa es el objetivo final.",
}

local TOTAL_TROOPS = 28

local positions       = {}
local availableTroops = 0
local phase           = "cinematic"
local battleIndex     = 0
local battleTimer     = 0
local BATTLE_DELAY    = 3.2
local results         = {}
local battleCurrentPos    = nil
local battleCurrentResult = nil
local cinematicTexts  = {}
local cinematicIndex  = 1
local cinematicAlpha  = 0

-- Características del terreno (generadas en onEnter, estables)
local terrainRocks   = {}
local terrainPatches = {}

local BTN_W = 44
local BTN_H = 34

local function initPositions()
    positions = {
        { name = "Monte Esmeralda", x = 200, y = 220, defenders = 3, troops = 0, captured = false, last = false },
        { name = "El Loreto",       x = 460, y = 160, defenders = 4, troops = 0, captured = false, last = false },
        { name = "Tierra Negra",    x = 780, y = 200, defenders = 3, troops = 0, captured = false, last = false },
        { name = "El Grillo",       x = 1040,y = 260, defenders = 4, troops = 0, captured = false, last = false },
        { name = "Cerro de la Bufa",x = 600, y = 440, defenders = 8, troops = 0, captured = false, last = true  },
    }
end

-- Genera rasgos del terreno desértico de forma determinista
local function buildTerrain(W, H)
    terrainRocks   = {}
    terrainPatches = {}
    local rng = {seed = 31337}
    local function rand(n)
        rng.seed = (rng.seed * 1664525 + 1013904223) % (2^32)
        return (rng.seed % n) + 1
    end
    local function randf() return rand(1000) / 1000 end

    -- Parches de tierra más oscura
    for _ = 1, 22 do
        table.insert(terrainPatches, {
            x = rand(W), y = rand(H),
            rx = 55 + rand(80), ry = 22 + rand(40),
            a = 0.28 + randf() * 0.20,
        })
    end
    -- Rocas/piedras
    for _ = 1, 14 do
        table.insert(terrainRocks, {
            x = rand(W), y = 80 + rand(H - 120),
            rx = 18 + rand(40), ry = 8 + rand(20),
        })
    end
end

function MG.new()
    local self = Base.new(CFG)
    return setmetatable(self, MG)
end

function MG:onEnter(data)
    cinematicTexts  = D.chapters["mg_revolucion"].opening
    cinematicIndex  = 1
    cinematicAlpha  = 0
    phase               = "cinematic"
    results             = {}
    battleCurrentPos    = nil
    battleCurrentResult = nil
    availableTroops     = TOTAL_TROOPS
    battleIndex         = 0
    battleTimer         = 0
    initPositions()

    local W, H = love.graphics.getDimensions()
    buildTerrain(W, H)
end

local function addTroop(pos)
    if availableTroops > 0 then
        pos.troops = pos.troops + 1; availableTroops = availableTroops - 1
    end
end

local function removeTroop(pos)
    if pos.troops > 0 then
        pos.troops = pos.troops - 1; availableTroops = availableTroops + 1
    end
end

local function allNonLastCaptured()
    for _, p in ipairs(positions) do
        if not p.last and not p.captured then return false end
    end
    return true
end

local function allCaptured()
    for _, p in ipairs(positions) do
        if not p.captured then return false end
    end
    return true
end

function MG:onUpdate(dt)
    if phase == "cinematic" then
        cinematicAlpha = math.min(1, cinematicAlpha + dt * 1.5)
        return
    end
    if phase ~= "battle" then return end

    battleTimer = battleTimer - dt
    if battleTimer > 0 then return end

    -- Empujar resultado completado al log
    if battleCurrentResult then
        table.insert(results, battleCurrentResult)
        battleCurrentResult = nil
        battleCurrentPos    = nil
    end

    local order = {}
    for _, p in ipairs(positions) do if not p.last then table.insert(order, p) end end
    for _, p in ipairs(positions) do if p.last     then table.insert(order, p) end end

    battleIndex = battleIndex + 1
    if battleIndex > #order then
        phase = "done"
        if allCaptured() then self:win() else self:lose() end
        return
    end

    -- Resolver y guardar resultado; animar durante BATTLE_DELAY
    local pos = order[battleIndex]
    battleCurrentPos = pos
    if pos.last and not allNonLastCaptured() then
        battleCurrentResult = { name = pos.name, success = false, reason = "Flancos no asegurados" }
    else
        local success = pos.troops > pos.defenders
        pos.captured  = success
        battleCurrentResult = {
            name = pos.name, troops = pos.troops, def = pos.defenders, success = success,
        }
    end
    battleTimer = BATTLE_DELAY
end

function MG:onKeypressed(key)
    if phase == "cinematic" then
        if key == "space" or key == "return" or key == "e" then
            cinematicIndex = cinematicIndex + 1; cinematicAlpha = 0
            if cinematicIndex > #cinematicTexts then phase = "planning" end
        end
        return
    end
    if phase == "planning" and (key == "return" or key == "space") then
        phase = "battle"; battleIndex = 0; battleTimer = BATTLE_DELAY; results = {}
    end
end

function MG:onMousepressed(mx, my, button)
    if phase == "cinematic" and button == 1 then
        cinematicIndex = cinematicIndex + 1; cinematicAlpha = 0
        if cinematicIndex > #cinematicTexts then phase = "planning" end
        return
    end
    if phase ~= "planning" or button ~= 1 then return end

    local W, H = love.graphics.getDimensions()
    local abx  = W / 2 - 100
    local aby  = H - 80
    if mx >= abx and mx <= abx + 200 and my >= aby and my <= aby + 50 then
        phase = "battle"; battleIndex = 0; battleTimer = BATTLE_DELAY; results = {}
        return
    end

    for _, pos in ipairs(positions) do
        local minX  = pos.x - BTN_W - 8
        local plusX = pos.x + 8
        local btnY  = pos.y + 42
        if my >= btnY and my <= btnY + BTN_H then
            if mx >= minX and mx <= minX + BTN_W then
                removeTroop(pos)
            elseif mx >= plusX and mx <= plusX + BTN_W then
                addTroop(pos)
            end
        end
    end
end

-- Silueta de soldado simple para la tira de combate
local function drawSoldierSimple(x, y, isFederal)
    if isFederal then
        -- Federal: kepí oscuro, uniforme verde oscuro, mirando izquierda
        love.graphics.setColor(0.18, 0.25, 0.18, 1)
        love.graphics.circle("fill", x, y + 2, 5)
        love.graphics.setColor(0.14, 0.20, 0.14, 1)
        love.graphics.rectangle("fill", x - 5, y - 8, 10, 7)
        love.graphics.rectangle("fill", x - 6, y - 9, 12, 2)
        love.graphics.setColor(0.28, 0.38, 0.24, 1)
        love.graphics.setLineWidth(1.5)
        love.graphics.line(x - 4, y, x - 10, y - 7)
        love.graphics.setLineWidth(1)
    else
        -- Villista: sombrero ancho, ropa marrón, mirando derecha
        love.graphics.setColor(0.38, 0.26, 0.10, 1)
        love.graphics.circle("fill", x, y + 2, 5)
        love.graphics.setColor(0.22, 0.15, 0.05, 1)
        love.graphics.ellipse("fill", x, y - 5, 8, 2.5)
        love.graphics.circle("fill", x, y - 8, 3.5)
        love.graphics.setColor(0.38, 0.28, 0.14, 1)
        love.graphics.setLineWidth(1.5)
        love.graphics.line(x + 4, y - 1, x + 10, y - 7)
        love.graphics.setLineWidth(1)
    end
end

-- Tira de animación de combate (se muestra durante phase=="battle")
local function drawBattleStrip(W, H)
    if not battleCurrentPos or not battleCurrentResult then return end
    local pos    = battleCurrentPos
    local result = battleCurrentResult
    local prog   = math.min(1, math.max(0, (BATTLE_DELAY - battleTimer) / BATTLE_DELAY))

    -- Slide-in y slide-out
    local stripH = 195
    local slideT
    if    prog < 0.12 then slideT = prog / 0.12
    elseif prog > 0.88 then slideT = 1 - (prog - 0.88) / 0.12
    else                     slideT = 1 end
    local baseY = H - (stripH + 14) * slideT

    -- Fondo
    love.graphics.setColor(0.05, 0.03, 0.01, 0.95)
    love.graphics.rectangle("fill", 16, baseY, W - 32, stripH, 8, 8)
    love.graphics.setColor(0.60, 0.10, 0.10, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", 16, baseY, W - 32, stripH, 8, 8)
    love.graphics.setLineWidth(1)

    -- Título
    love.graphics.setColor(1, 0.85, 0.30, 1)
    love.graphics.printf("⚔  " .. pos.name, 16, baseY + 10, W - 32, "center")

    -- Línea de suelo
    local groundY = baseY + stripH - 58
    love.graphics.setColor(0.38, 0.26, 0.12, 0.65)
    love.graphics.rectangle("fill", 26, groundY, W - 52, 3)

    local midX   = W / 2
    local combatY = groundY - 2

    -- Progreso de la sub-animación: approach 0→1 durante prog 0.12→0.62
    local combatT
    if    prog < 0.12 then combatT = 0
    elseif prog < 0.62 then combatT = (prog - 0.12) / 0.50
    else                     combatT = 1 end

    local atkCount = math.min(pos.troops,    6)
    local defCount = math.min(pos.defenders, 6)

    -- Los atacantes empiezan en la izquierda y avanzan al centro
    local atkBaseX = 55 + (midX - 85 - 55) * combatT
    -- Los defensores empiezan a la derecha y se quedan más quietos (retroceden un poco)
    local defBaseX = W - 55 - (W - 55 - (midX + 85)) * combatT * 0.4

    -- Chispas en el choque
    if prog > 0.55 and prog < 0.80 then
        local sparkA = math.sin((prog - 0.55) / 0.25 * math.pi) * 0.85
        local t      = love.timer.getTime()
        love.graphics.setColor(1.0, 0.78, 0.15, sparkA)
        for si = 1, 7 do
            local sx = midX + math.cos(t * 12 + si * 0.9) * 30
            local sy = combatY - 18 + math.sin(t * 9.5 + si * 1.3) * 14
            love.graphics.circle("fill", sx, sy, 3 + math.sin(t * 16 + si) * 1.5)
        end
        -- Flash central
        love.graphics.setColor(1.0, 0.60, 0.10, sparkA * 0.35)
        love.graphics.circle("fill", midX, combatY - 10, 32)
    end

    -- Soldados atacantes (villistas)
    local t = love.timer.getTime()
    for i = 1, atkCount do
        local sx  = atkBaseX - (i - 1) * 14
        local bob = math.sin(t * 10 + i * 0.9) * 2.5 * math.min(1, combatT * 4)
        drawSoldierSimple(sx, combatY + bob, false)
    end
    -- Soldados defensores (federales)
    for i = 1, defCount do
        local sx  = defBaseX + (i - 1) * 14
        local bob = math.sin(t * 10 + i * 0.9 + 5) * 1.5
        drawSoldierSimple(sx, combatY + bob, true)
    end

    -- Contadores de tropas
    love.graphics.setColor(0.30, 0.82, 0.42, 1)
    love.graphics.printf("Tus tropas: " .. pos.troops, 26, groundY + 7, (W - 52) / 2 - 8, "left")
    love.graphics.setColor(0.85, 0.28, 0.22, 1)
    love.graphics.printf("Defensores: " .. pos.defenders, 26, groundY + 7, W - 52, "right")

    -- Resultado (aparece en el último tercio)
    if prog > 0.68 then
        local ra = math.min(1, (prog - 0.68) / 0.14)
        if result.success then
            love.graphics.setColor(0.28, 0.90, 0.42, ra)
            love.graphics.printf("✓  POSICIÓN TOMADA", 16, groundY + 28, W - 32, "center")
        else
            love.graphics.setColor(0.92, 0.22, 0.18, ra)
            local msg = result.reason and ("✗  " .. result.reason) or "✗  REPELIDOS"
            love.graphics.printf(msg, 16, groundY + 28, W - 32, "center")
        end
    end
end

-- Dibuja terreno árido zacatecano
local function drawTerrain(W, H)
    -- Base: tierra caliza cálida
    love.graphics.setColor(0.50, 0.38, 0.22, 1)
    love.graphics.rectangle("fill", 0, 0, W, H)

    -- Parches de tierra
    for _, p in ipairs(terrainPatches) do
        love.graphics.setColor(0.42, 0.31, 0.17, p.a)
        love.graphics.ellipse("fill", p.x, p.y, p.rx, p.ry)
    end

    -- Rocas oscuras
    for _, r in ipairs(terrainRocks) do
        love.graphics.setColor(0.28, 0.21, 0.13, 0.65)
        love.graphics.ellipse("fill", r.x, r.y, r.rx, r.ry)
        love.graphics.setColor(0.35, 0.27, 0.17, 0.4)
        love.graphics.ellipse("fill", r.x - 4, r.y - 4, r.rx * 0.7, r.ry * 0.7)
    end
end

-- Silueta de cerro debajo del nodo
local function drawHillSilhouette(pos)
    if pos.last then
        -- Cerro de la Bufa: pico dramático, más alto
        love.graphics.setColor(0.22, 0.16, 0.10, 0.80)
        love.graphics.ellipse("fill", pos.x, pos.y + 32, 70, 32)
        love.graphics.setColor(0.30, 0.22, 0.13, 0.85)
        love.graphics.ellipse("fill", pos.x, pos.y + 16, 52, 26)
        love.graphics.setColor(0.38, 0.28, 0.17, 0.90)
        love.graphics.ellipse("fill", pos.x, pos.y + 4, 40, 22)
    else
        -- Cerro regular: loma suave
        love.graphics.setColor(0.24, 0.17, 0.10, 0.70)
        love.graphics.ellipse("fill", pos.x, pos.y + 24, 56, 22)
        love.graphics.setColor(0.30, 0.22, 0.13, 0.78)
        love.graphics.ellipse("fill", pos.x, pos.y + 10, 40, 18)
    end
end

-- Bandera sobre el nodo
local function drawFlag(pos)
    local fy = pos.y - 38 - 34
    local fx = pos.x

    -- Asta
    love.graphics.setColor(0.45, 0.35, 0.20, 1)
    love.graphics.setLineWidth(2)
    love.graphics.line(fx, pos.y - 38, fx, fy)

    if pos.last then
        -- Tricolor mexicano (Bufa = objetivo federal + posterior villista)
        love.graphics.setColor(0.04, 0.48, 0.18, 1)
        love.graphics.rectangle("fill", fx, fy, 6, 12)
        love.graphics.setColor(0.95, 0.95, 0.92, 1)
        love.graphics.rectangle("fill", fx + 6, fy, 6, 12)
        love.graphics.setColor(0.70, 0.08, 0.08, 1)
        love.graphics.rectangle("fill", fx + 12, fy, 6, 12)
    else
        -- Bandera federal (rojo oscuro con letras CF)
        love.graphics.setColor(0.62, 0.08, 0.08, 1)
        love.graphics.rectangle("fill", fx, fy, 18, 11)
        love.graphics.setColor(1, 0.88, 0.60, 0.8)
        love.graphics.printf("CF", fx - 1, fy + 1, 20, "center")
    end
    love.graphics.setLineWidth(1)
end

-- Siluetas de soldados villistas (sombreros anchos)
local function drawSoldiers(pos)
    local count = math.min(pos.troops, 5)
    if count == 0 then return end

    local startX = pos.x - (count - 1) * 9
    for i = 1, count do
        local sx = startX + (i - 1) * 18
        local sy = pos.y + 50
        -- Cuerpo
        love.graphics.setColor(0.38, 0.26, 0.10, 1)
        love.graphics.circle("fill", sx, sy + 2, 5)
        -- Sombrero villista (ala amplia, copa redonda)
        love.graphics.setColor(0.25, 0.18, 0.07, 1)
        love.graphics.ellipse("fill", sx, sy - 5, 7, 2.5)
        love.graphics.circle("fill", sx, sy - 7, 3.5)
        -- Rifle (línea)
        love.graphics.setColor(0.35, 0.26, 0.16, 1)
        love.graphics.setLineWidth(1)
        love.graphics.line(sx + 4, sy - 2, sx + 8, sy - 10)
    end
    if pos.troops > 5 then
        love.graphics.setColor(1, 0.88, 0.40, 1)
        love.graphics.printf("+" .. (pos.troops - 5), pos.x - 20, pos.y + 62, 40, "center")
    end
end

-- Icono de cañón (artillería de Ángeles)
local function drawCannon(pos)
    if pos.troops == 0 or pos.captured then return end
    local cx = pos.x - 14
    local cy = pos.y + 2
    -- Ruedas
    love.graphics.setColor(0.22, 0.16, 0.08, 1)
    love.graphics.circle("fill", cx - 8, cy + 6, 5)
    love.graphics.circle("fill", cx + 4, cy + 6, 5)
    -- Cureña
    love.graphics.setColor(0.32, 0.24, 0.12, 1)
    love.graphics.rectangle("fill", cx - 10, cy + 3, 22, 4, 2, 2)
    -- Tubo del cañón
    love.graphics.setColor(0.20, 0.18, 0.14, 1)
    love.graphics.ellipse("fill", cx + 10, cy, 10, 5)
    love.graphics.rectangle("fill", cx - 2, cy - 4, 16, 8, 3, 3)
    love.graphics.setColor(0.28, 0.24, 0.18, 1)
    love.graphics.circle("fill", cx + 10, cy, 4)
end

-- Nodo de posición completo
local function drawPosition(pos, ph)
    local r = 38

    drawHillSilhouette(pos)

    -- Círculo base del nodo
    if pos.last then
        love.graphics.setColor(0.48, 0.07, 0.05, 0.92)
    else
        love.graphics.setColor(0.22, 0.16, 0.10, 0.90)
    end
    love.graphics.circle("fill", pos.x, pos.y, r)

    -- Textura interior (gradiente simulado)
    if pos.last then
        love.graphics.setColor(0.56, 0.10, 0.08, 0.5)
    else
        love.graphics.setColor(0.30, 0.22, 0.14, 0.5)
    end
    love.graphics.circle("fill", pos.x - 6, pos.y - 6, r * 0.65)

    -- Borde: verde si tomado/planificado suficiente, amarillo si pendiente Bufa, rojo si faltan tropas
    if pos.captured then
        love.graphics.setColor(0.28, 0.82, 0.36, 1)
    elseif ph == "planning" and pos.troops > pos.defenders then
        love.graphics.setColor(0.28, 0.82, 0.36, 1)  -- planificado correctamente
    else
        love.graphics.setColor(0.62, 0.10, 0.10, 1)
    end
    love.graphics.setLineWidth(3)
    love.graphics.circle("line", pos.x, pos.y, r)
    love.graphics.setLineWidth(1)

    -- Bandera y cañón
    drawFlag(pos)
    drawCannon(pos)

    -- Nombre (encima del nodo, sobre la bandera)
    love.graphics.setColor(1, 0.92, 0.78, 1)
    love.graphics.printf(pos.name, pos.x - 90, pos.y - r - 58, 180, "center")

    -- Contenido del nodo
    if pos.captured then
        love.graphics.setColor(0.30, 0.90, 0.42, 1)
        love.graphics.printf("✓ TOMADO", pos.x - 90, pos.y - 8, 180, "center")
    else
        love.graphics.setColor(0.88, 0.30, 0.25, 1)
        love.graphics.printf("Def: " .. pos.defenders, pos.x - 90, pos.y - 10, 180, "center")
        -- Color de tropas: verde si suficientes, naranja si faltan, gris si 0
        if ph == "planning" then
            if pos.troops > pos.defenders then
                love.graphics.setColor(0.30, 0.90, 0.42, 1)
                love.graphics.printf(pos.troops .. " ✓", pos.x - 90, pos.y + 10, 180, "center")
            elseif pos.troops > 0 then
                love.graphics.setColor(0.92, 0.60, 0.15, 1)
                love.graphics.printf(pos.troops .. " (necesitas " .. (pos.defenders+1) .. ")", pos.x - 90, pos.y + 10, 180, "center")
            else
                love.graphics.setColor(0.60, 0.60, 0.60, 1)
                love.graphics.printf("0 tropas", pos.x - 90, pos.y + 10, 180, "center")
            end
        else
            love.graphics.setColor(0.28, 0.72, 0.38, 1)
            love.graphics.printf("Trop: " .. pos.troops, pos.x - 90, pos.y + 10, 180, "center")
        end
    end

    -- Soldados villistas (solo en batalla/done; durante planning los botones ocupan esa área)
    if ph ~= "planning" then
        drawSoldiers(pos)
    end

    -- Botones + / − en fase de planificación
    if ph == "planning" and not pos.captured then
        local minX  = pos.x - BTN_W - 8
        local plusX = pos.x + 8
        local btnY  = pos.y + 42

        love.graphics.setColor(0.52, 0.12, 0.10, 0.95)
        love.graphics.rectangle("fill", minX, btnY, BTN_W, BTN_H, 5, 5)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("−", minX, btnY + 6, BTN_W, "center")

        love.graphics.setColor(0.12, 0.42, 0.18, 0.95)
        love.graphics.rectangle("fill", plusX, btnY, BTN_W, BTN_H, 5, 5)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("+", plusX, btnY + 6, BTN_W, "center")
    end
end

-- Líneas de ataque (desde posiciones externas hacia la Bufa)
local function drawAttackLines(ph)
    local bufa = positions[#positions]
    for i = 1, #positions - 1 do
        local pos = positions[i]
        local r, g, b = 0.62, 0.10, 0.10  -- rojo por defecto (federal)
        local a = 0.35
        if pos.captured then r, g, b, a = 0.28, 0.78, 0.35, 0.55
        elseif ph == "battle" then a = 0.25 end

        love.graphics.setColor(r, g, b, a)
        love.graphics.setLineWidth(ph == "battle" and 2 or 1.5)

        -- Línea punteada simulada (segmentos alternos)
        local dx  = bufa.x - pos.x
        local dy  = bufa.y - pos.y
        local len = math.sqrt(dx*dx + dy*dy)
        local nx  = dx / len; local ny = dy / len
        local seg = 14; local gap = 7
        local total = 0
        local drawing = true
        while total < len - 20 do
            local x1 = pos.x + nx * total
            local y1 = pos.y + ny * total
            local adv = drawing and seg or gap
            total = math.min(total + adv, len - 20)
            if drawing then
                local x2 = pos.x + nx * total
                local y2 = pos.y + ny * total
                love.graphics.line(x1, y1, x2, y2)
            end
            drawing = not drawing
        end
    end
    love.graphics.setLineWidth(1)
end

function MG:onDraw()
    local W, H = love.graphics.getDimensions()

    -- Terreno desértico
    drawTerrain(W, H)

    -- Líneas de ataque
    drawAttackLines(phase)

    -- Nodos de posición
    for _, pos in ipairs(positions) do
        drawPosition(pos, phase)
    end

    -- Log de resultados (columna derecha)
    if #results > 0 then
        love.graphics.setColor(0.04, 0.03, 0.02, 0.82)
        love.graphics.rectangle("fill", W - 318, 58, 308, 420, 8, 8)
        love.graphics.setColor(0.60, 0.10, 0.10, 1)
        love.graphics.rectangle("line", W - 318, 58, 308, 420, 8, 8)
        love.graphics.setColor(1, 0.85, 0.30, 1)
        love.graphics.printf("Reporte de batalla", W - 318, 70, 308, "center")

        for i, r in ipairs(results) do
            if r.success then
                love.graphics.setColor(0.25, 0.80, 0.35, 1)
            else
                love.graphics.setColor(0.85, 0.25, 0.20, 1)
            end
            local txt = r.success
                and string.format("✓ %s\n  (%d vs %d def)", r.name, r.troops, r.def)
                or  string.format("✗ %s\n  (%s)", r.name,
                        r.reason or string.format("%d vs %d def", r.troops or 0, r.def or 0))
            love.graphics.printf(txt, W - 306, 98 + (i-1) * 64, 288, "left")
        end
    end

    -- Panel de reglas (solo en planning)
    if phase == "planning" then
        local px, py, pw = 14, 60, 220
        local ph2 = 148
        love.graphics.setColor(0.04, 0.02, 0.01, 0.88)
        love.graphics.rectangle("fill", px, py, pw, ph2, 6, 6)
        love.graphics.setColor(0.62, 0.48, 0.14, 0.9)
        love.graphics.setLineWidth(1.5)
        love.graphics.rectangle("line", px, py, pw, ph2, 6, 6)
        love.graphics.setLineWidth(1)
        love.graphics.setColor(1, 0.85, 0.30, 1)
        love.graphics.printf("CÓMO GANAR", px, py + 8, pw, "center")
        love.graphics.setColor(0.85, 0.85, 0.80, 1)
        love.graphics.printf(
            "1. Asigna MÁS tropas que\n   defensores en cada posición\n\n" ..
            "2. Captura los 4 cerros\n   exteriores PRIMERO\n\n" ..
            "3. Ataca la Bufa al final\n   (necesita flancos tomados)\n\n" ..
            "Verde = suficientes tropas ✓",
        px + 8, py + 30, pw - 16, "left")
    end

    -- Botón ATACAR
    if phase == "planning" then
        local t   = love.timer.getTime()
        local glo = 0.85 + 0.15 * math.sin(t * 3)
        local abx = W / 2 - 100
        local aby = H - 80
        -- Sombra
        love.graphics.setColor(0, 0, 0, 0.4)
        love.graphics.rectangle("fill", abx + 3, aby + 3, 200, 50, 8, 8)
        -- Fondo rojo
        love.graphics.setColor(0.62 * glo, 0.09, 0.07, 1)
        love.graphics.rectangle("fill", abx, aby, 200, 50, 8, 8)
        -- Borde dorado
        love.graphics.setColor(0.85, 0.68, 0.18, 0.9)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", abx, aby, 200, 50, 8, 8)
        love.graphics.setLineWidth(1)
        -- Texto
        love.graphics.setColor(1, 0.95, 0.80, 1)
        love.graphics.printf("⚔  ATACAR", abx, aby + 14, 200, "center")
    end

    -- HUD superior
    love.graphics.setColor(0, 0, 0, 0.78)
    love.graphics.rectangle("fill", 0, 0, W, 50)
    love.graphics.setColor(1, 0.85, 0.30, 1)
    local label
    if phase == "planning" then
        label = "Tropas disponibles: " .. availableTroops .. " / " .. TOTAL_TROOPS
    elseif phase == "battle" then
        label = "⚔ Batalla en curso..."
    else
        label = ""
    end
    love.graphics.printf(label, 0, 14, W, "center")

    -- Tira de animación de combate
    if phase == "battle" then
        drawBattleStrip(W, H)
    end

    -- Cinemática
    if phase == "cinematic" then
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
