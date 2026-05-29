-- src/minigames/MgConquista.lua
local Base = require("src.minigames.MinigameBase")
local D    = require("src.data.CampaignData")

local MG = setmetatable({}, { __index = Base })
MG.__index = MG

local CFG = {
    id           = "mg_conquista",
    title        = "La Expedición de Tolosa — Norte",
    subtitle     = "1546 d.C.",
    accentColor  = {0.75, 0.55, 0.20, 1},
    bgColor      = {0.10, 0.07, 0.04, 1},
    instructions = "Cruza el norte de la Nueva España.\nWASD / flechas para moverte, W o ↑ para saltar.",
}

-- ─── Constantes de física ────────────────────────────────────────────────────
local GRAVITY      = 900    -- px/s²
local JUMP_VY      = -420   -- impulso inicial del salto
local MOVE_VX      = 180    -- velocidad horizontal
local SLOW_VX      = 60     -- velocidad en charco de agua
local PW, PH       = 24, 36 -- hitbox del jugador
local INVTIME      = 1.5    -- segundos de invencibilidad tras daño
local BOULDER_R    = 20     -- radio de boulders
local ARROW_SPD    = 320    -- velocidad de flechas
local WARRIOR_SPD  = 80
local GUARDIAN_SPD_BASE  = 80
local GUARDIAN_SPD_CHASE = 150
local GUARDIAN_RANGE     = 200  -- px para activar persecución

-- ─── Estado global ───────────────────────────────────────────────────────────
local player       = {}
local currentStage = 1
local gameState    = "cinematic"
local cinematicTexts = {}
local cinematicIndex = 1
local cinematicAlpha = 0
local cameraX      = 0

local platforms   = {}
local enemies     = {}
local arrows      = {}
local boulders    = {}
local stalactites = {}
local hazards     = {}
local boulderTimer = 0

-- ─── Datos de etapas ─────────────────────────────────────────────────────────
-- (completados en Tasks 2-4)
local STAGE_DATA = {
  -- ─── ETAPA 1: TERRENO NORTE (desierto árido, 3200px) ────────────────────
  [1] = {
    width   = 3200,
    startX  = 80,
    startY  = 484,   -- Y=520(suelo) - 36(PH) = 484
    portalX = 3140,
    platforms = {
      -- ZONA 1: intro segura (X 0-700)
      {x=0,    y=520, w=700,  h=30, type="solid"},
      -- ZONA 2: primer hoyo (X 700-900) + puente crumble
      {x=900,  y=460, w=100,  h=20, type="crumble"},
      {x=1060, y=480, w=80,   h=20, type="crumble"},
      -- suelo tras crumble
      {x=1190, y=520, w=560,  h=30, type="solid"},
      -- ZONA 3: cacti sobre suelo (ver hazards)
      -- ZONA 4: plataformas elevadas (X 1800-2360)
      {x=1820, y=460, w=130,  h=20, type="solid"},
      {x=2000, y=420, w=110,  h=20, type="solid"},   -- arquero 1 aquí
      {x=2170, y=460, w=130,  h=20, type="solid"},
      -- suelo intermedio
      {x=2340, y=520, w=240,  h=30, type="solid"},
      -- ZONA 5: zigzag + arquero 2 (X 2600-3000)
      {x=2640, y=440, w=90,   h=20, type="crumble"},
      {x=2790, y=410, w=150,  h=20, type="solid"},   -- arquero 2 aquí
      {x=2990, y=460, w=180,  h=20, type="solid"},
      -- suelo final
      {x=3000, y=520, w=200,  h=30, type="solid"},
    },
    enemies = {
      -- Arquero 1: sobre plataforma Y=420 (su hitbox 20x32, así y = 420-32 = 388)
      { type="archer", x=2040, y=388, dir=-1,
        shootTimer=0.5, shootInterval=2.5 },
      -- Arquero 2: sobre plataforma Y=410 (y = 410-32 = 378)
      { type="archer", x=2830, y=378, dir=-1,
        shootTimer=1.5, shootInterval=2.5 },
    },
    hazards = {
      {type="cactus", x=1290, y=484, w=22, h=36},
      {type="cactus", x=1460, y=484, w=22, h=36},
      {type="cactus", x=1630, y=484, w=22, h=36},
    },
    stalactites = {},
  },
  -- ─── ETAPA 2: ENTRADA DE CUEVA (2800px) ─────────────────────────────────
  [2] = {
    width   = 2800,
    startX  = 80,
    startY  = 484,
    portalX = 2740,
    platforms = {
      -- suelo inicial cueva
      {x=0,    y=520, w=400,  h=30, type="solid"},
      -- plataforma media para saltar sobre guerrero 1
      {x=450,  y=440, w=200,  h=20, type="solid"},
      -- suelo amplio (zona guerrero 1)
      {x=400,  y=520, w=600,  h=30, type="solid"},
      -- pasaje estrecho: techo bajo en X=1050-1250 (a Y=420, deja 100px de paso)
      {x=1050, y=420, w=200,  h=20, type="ceiling"},
      -- suelo continúa
      {x=1000, y=520, w=600,  h=30, type="solid"},
      -- plataformas sobre el charco para evitarlo desde arriba
      {x=1200, y=450, w=100,  h=20, type="solid"},
      -- más suelo
      {x=1600, y=520, w=500,  h=30, type="solid"},
      -- zona guerrero 2: plataformas escalonadas
      {x=2160, y=480, w=160,  h=20, type="solid"},
      {x=2380, y=440, w=160,  h=20, type="solid"},
      {x=2560, y=520, w=250,  h=30, type="solid"},
    },
    enemies = {
      -- Guerrero 1: patrulla suelo X 430-700
      { type="warrior", x=560, y=486, vx=WARRIOR_SPD, minX=430, maxX=700 },
      -- Guerrero 2: patrulla plataforma elevada X 2160-2320
      { type="warrior", x=2200, y=446, vx=-WARRIOR_SPD, minX=2160, maxX=2320 },
    },
    hazards = {
      -- charco de agua (ralentiza)
      { type="charco", x=1200, y=510, w=160, h=12 },
    },
    stalactites = {
      -- estalactitas: triggered al pasar debajo
      { x=680,  y=60, w=24, h=60 },
      { x=1440, y=60, w=20, h=50 },
      { x=1820, y=60, w=26, h=70 },
      { x=2280, y=60, w=22, h=55 },
    },
  },
  -- ─── ETAPA 3: INTERIOR DE MINA (2600px) ──────────────────────────────────
  [3] = {
    width   = 2600,
    startX  = 80,
    startY  = 484,
    portalX = 9999,  -- no hay portal: la veta de plata es la victoria
    platforms = {
      -- suelo inicial mina
      {x=0,    y=520, w=300,  h=30, type="solid"},
      -- andamios de madera (caen al pisarlos)
      {x=360,  y=480, w=100,  h=16, type="wood"},
      {x=510,  y=450, w=100,  h=16, type="wood"},
      {x=660,  y=480, w=100,  h=16, type="wood"},
      {x=810,  y=450, w=100,  h=16, type="wood"},
      {x=960,  y=480, w=100,  h=16, type="wood"},
      -- suelo sólido tras andamios
      {x=1100, y=520, w=500,  h=30, type="solid"},
      -- zona de boulders: suelo continuo (boulders vienen de la derecha)
      {x=1600, y=520, w=800,  h=30, type="solid"},
      -- plataforma elevada frente al guardián
      {x=1800, y=440, w=200,  h=20, type="solid"},
      -- área final con veta
      {x=2400, y=520, w=200,  h=30, type="solid"},
    },
    enemies = {
      -- Guardián: patrulla X 2100-2400, persigue si Tolosa está cerca
      { type="guardian", x=2150, y=474,
        vx=GUARDIAN_SPD_BASE, minX=2100, maxX=2380,
        baseSpeed=GUARDIAN_SPD_BASE, chaseSpeed=GUARDIAN_SPD_CHASE },
    },
    hazards = {},
    stalactites = {},
  },
}

local SILVER = { x = 2490, y = 440, w = 32, h = 40 }

-- ─── Utilidades de colisión ──────────────────────────────────────────────────
local function rectOverlap(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and ax + aw > bx
       and ay < by + bh and ay + ah > by
end

local function circleRectOverlap(cx, cy, cr, rx, ry, rw, rh)
    local nearX = math.max(rx, math.min(cx, rx + rw))
    local nearY = math.max(ry, math.min(cy, ry + rh))
    local dx, dy = cx - nearX, cy - nearY
    return dx*dx + dy*dy < cr*cr
end

-- ─── Física del jugador ──────────────────────────────────────────────────────
local function resolvePlatforms(dt)
    player.onGround = false
    for _, p in ipairs(platforms) do
        if p.fallen then goto continue end
        if p.type == "ceiling" then
            -- colisión desde abajo: cancela salto al golpear techo
            if player.vy < 0 and rectOverlap(player.x, player.y, PW, PH, p.x, p.y, p.w, p.h) then
                local prevTop = player.y - player.vy * dt
                if prevTop >= p.y + p.h - 4 then
                    player.y  = p.y + p.h
                    player.vy = 0
                end
            end
        else
            -- plataformas one-way: solo aterrizaje desde arriba
            if player.vy >= 0 and rectOverlap(player.x, player.y, PW, PH, p.x, p.y, p.w, p.h) then
                local prevBottom = (player.y - player.vy * dt) + PH
                if prevBottom <= p.y + 6 then
                    player.y        = p.y - PH
                    player.vy       = 0
                    player.onGround = true
                    player.airJumps = 1
                    -- activar temporizador de derrumbe
                    if (p.type == "crumble" or p.type == "wood") and not p.crumbleTimer then
                        p.crumbleTimer = (p.type == "crumble") and 1.0 or 1.5
                    end
                end
            end
        end
        ::continue::
    end
end

-- ─── Funciones de daño y respawn ─────────────────────────────────────────────
local function loadStageData(n)
    local sd = STAGE_DATA[n]
    if not sd then return end

    -- Copiar profundo las plataformas (para resetear crumbleTimer)
    platforms = {}
    for _, p in ipairs(sd.platforms) do
        table.insert(platforms, {
            x=p.x, y=p.y, w=p.w, h=p.h, type=p.type,
            crumbleTimer=nil, fallen=false
        })
    end
    -- Copiar enemigos
    enemies = {}
    for _, e in ipairs(sd.enemies) do
        local copy = {}
        for k, v in pairs(e) do copy[k] = v end
        table.insert(enemies, copy)
    end
    -- Copiar hazards
    hazards = {}
    for _, h in ipairs(sd.hazards or {}) do
        local copy = {}
        for k, v in pairs(h) do copy[k] = v end
        table.insert(hazards, copy)
    end
    -- Copiar estalactitas
    stalactites = {}
    for _, s in ipairs(sd.stalactites or {}) do
        table.insert(stalactites, {x=s.x, y=s.y, w=s.w, h=s.h, vy=0, fallen=false, triggered=false})
    end

    arrows    = {}
    boulders  = {}
    boulderTimer = 4
    cameraX   = 0
end

local mgRef  -- referencia a self para funciones locales

local function takeDamage()
    if player.invTimer > 0 then return end
    player.lives   = player.lives - 1
    player.invTimer = INVTIME
    if player.lives <= 0 then
        mgRef:lose()
    else
        loadStageData(currentStage)
        local sd = STAGE_DATA[currentStage] or {startX=80, startY=484}
        player.x = sd.startX; player.y = sd.startY
        player.vx = 0; player.vy = 0; player.onGround = false; player.airJumps = 1
    end
end

-- ─── MinigameBase ────────────────────────────────────────────────────────────
function MG.new()
    local self = Base.new(CFG)
    local inst = setmetatable(self, MG)
    mgRef = inst
    return inst
end

function MG:onEnter(data)
    cinematicTexts = D.chapters["mg_conquista"].opening
    cinematicIndex = 1
    cinematicAlpha = 0
    gameState      = "cinematic"
    currentStage   = 1
    player.lives   = 3
    loadStageData(1)
    local sd = STAGE_DATA[1] or {startX=80, startY=484}
    player.x = sd.startX; player.y = sd.startY
    player.vx = 0; player.vy = 0; player.onGround = false; player.invTimer = 0; player.airJumps = 1
end

function MG:onUpdate(dt)
    if gameState == "cinematic" then
        cinematicAlpha = math.min(1, cinematicAlpha + dt * 1.5)
        return
    end

    local W = love.graphics.getWidth()
    local sd = STAGE_DATA[currentStage] or {width=3200, portalX=3150}

    -- Invencibilidad
    if player.invTimer > 0 then player.invTimer = math.max(0, player.invTimer - dt) end

    -- Crumble timers
    for _, p in ipairs(platforms) do
        if p.crumbleTimer then
            p.crumbleTimer = p.crumbleTimer - dt
            if p.crumbleTimer <= 0 then
                p.fallen = true
                p.crumbleTimer = nil
            end
        end
    end

    -- Movimiento horizontal
    player.vx = 0
    if love.keyboard.isDown("a", "left")  then player.vx = -MOVE_VX end
    if love.keyboard.isDown("d", "right") then player.vx =  MOVE_VX end

    -- Zona de charco (reducir velocidad)
    for _, h in ipairs(hazards) do
        if h.type == "charco" and rectOverlap(player.x, player.y, PW, PH, h.x, h.y, h.w, h.h) then
            if player.vx > 0 then player.vx = math.min(player.vx, SLOW_VX) end
            if player.vx < 0 then player.vx = math.max(player.vx, -SLOW_VX) end
        end
    end

    -- Física
    player.vy = player.vy + GRAVITY * dt
    player.x  = player.x  + player.vx * dt
    player.y  = player.y  + player.vy * dt

    -- Límite izquierdo del nivel
    if player.x < 0 then player.x = 0 end

    resolvePlatforms(dt)

    -- Actualizar enemigos
    for _, e in ipairs(enemies) do
        if e.type == "archer" then
            e.shootTimer = e.shootTimer - dt
            if e.shootTimer <= 0 then
                e.shootTimer = e.shootInterval
                table.insert(arrows, {
                    x = e.x - 14, y = e.y + 12,
                    w = 14, h = 4, vx = -ARROW_SPD
                })
            end
        elseif e.type == "warrior" then
            e.x = e.x + e.vx * dt
            if e.x <= e.minX then e.vx =  math.abs(e.vx); e.x = e.minX end
            if e.x >= e.maxX then e.vx = -math.abs(e.vx); e.x = e.maxX end
        elseif e.type == "guardian" then
            local dist = math.abs(player.x - e.x)
            local spd  = dist < GUARDIAN_RANGE and GUARDIAN_SPD_CHASE or GUARDIAN_SPD_BASE
            e.vx = player.x < e.x and -spd or spd
            e.x  = e.x + e.vx * dt
            e.x  = math.max(e.minX, math.min(e.maxX, e.x))
        end
    end

    -- Actualizar flechas
    for i = #arrows, 1, -1 do
        local a = arrows[i]
        a.x = a.x + a.vx * dt
        if a.x < cameraX - 60 then
            table.remove(arrows, i)
        elseif player.invTimer <= 0 and rectOverlap(player.x, player.y, PW, PH, a.x, a.y, a.w, a.h) then
            table.remove(arrows, i)
            takeDamage()
        end
    end

    -- Actualizar estalactitas
    for _, s in ipairs(stalactites) do
        if not s.fallen then
            -- trigger si jugador pasa debajo
            if not s.triggered then
                local underX = player.x + PW/2
                local underY = player.y
                if math.abs(underX - (s.x + s.w/2)) < 80 and underY > s.y then
                    s.triggered = true
                end
            end
            if s.triggered then
                s.vy = s.vy + GRAVITY * dt
                s.y  = s.y  + s.vy * dt
                -- colisión con jugador
                if player.invTimer <= 0 and rectOverlap(player.x, player.y, PW, PH, s.x, s.y, s.w, s.h) then
                    takeDamage()
                end
                -- toca suelo
                if s.y > 600 then s.fallen = true end
            end
        end
    end

    -- Actualizar boulders (etapa 3)
    if currentStage == 3 then
        boulderTimer = boulderTimer - dt
        if boulderTimer <= 0 then
            boulderTimer = 3.0
            table.insert(boulders, {
                x  = cameraX + W + BOULDER_R + 10,
                y  = 500,
                vx = -200
            })
        end
        for i = #boulders, 1, -1 do
            local b = boulders[i]
            b.x = b.x + b.vx * dt
            -- Colisión jugador
            if player.invTimer <= 0 and circleRectOverlap(b.x, b.y, BOULDER_R, player.x, player.y, PW, PH) then
                takeDamage()
            end
            -- Remover si sale por la izquierda
            if b.x < cameraX - BOULDER_R - 20 then
                table.remove(boulders, i)
            end
        end
    end

    -- Colisión con cuerpo de enemigos y cacti
    if player.invTimer <= 0 then
        for _, e in ipairs(enemies) do
            local ew = e.type == "guardian" and 30 or e.type == "warrior" and 22 or 20
            local eh = e.type == "guardian" and 46 or e.type == "warrior" and 34 or 32
            if rectOverlap(player.x, player.y, PW, PH, e.x, e.y, ew, eh) then
                takeDamage(); break
            end
        end
        for _, h in ipairs(hazards) do
            if h.type == "cactus" and rectOverlap(player.x, player.y, PW, PH, h.x, h.y, h.w, h.h) then
                takeDamage(); break
            end
        end
    end

    -- Caída al vacío
    if player.y > 700 then takeDamage() end

    -- Cámara
    cameraX = math.max(0, math.min(player.x - W/2, sd.width - W))

    -- Avance de etapa
    if currentStage < 3 and player.x + PW > sd.portalX then
        currentStage = currentStage + 1
        loadStageData(currentStage)
        local nsd = STAGE_DATA[currentStage]
        if not nsd then return end
        player.x = nsd.startX; player.y = nsd.startY
        player.vx = 0; player.vy = 0; player.onGround = false; player.airJumps = 1
        cameraX = 0
    end

    -- Victoria: tocar veta de plata
    if currentStage == 3 and rectOverlap(player.x, player.y, PW, PH, SILVER.x, SILVER.y, SILVER.w, SILVER.h) then
        self:win()
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
    if key == "w" or key == "up" or key == "space" then
        if player.onGround then
            player.vy       = JUMP_VY
            player.onGround = false
        elseif player.airJumps > 0 then
            player.vy       = JUMP_VY
            player.airJumps = player.airJumps - 1
        end
    end
end

function MG:onMousepressed(mx, my, button)
    if gameState == "cinematic" and button == 1 then
        cinematicIndex = cinematicIndex + 1; cinematicAlpha = 0
        if cinematicIndex > #cinematicTexts then gameState = "playing" end
    end
end

-- ─── Funciones de dibujo de personajes ───────────────────────────────────────

local function drawTolosa(x, y, blink)
    if blink then return end
    love.graphics.setColor(0, 0, 0, 0.28)
    love.graphics.circle("fill", x + PW/2 + 2, y + PH + 2, PW/2)
    love.graphics.setColor(0.52, 0.10, 0.08, 1)
    love.graphics.ellipse("fill", x + PW/2 - 1, y + PH*0.6, PW/1.8, PH/2.8)
    love.graphics.setColor(0.48, 0.32, 0.14, 1)
    love.graphics.circle("fill", x + PW/2, y + PH*0.55, PW/2)
    love.graphics.setColor(0.68, 0.10, 0.10, 0.9)
    love.graphics.rectangle("fill", x + PW/2 - 1, y + PH*0.35, 3, 10)
    love.graphics.rectangle("fill", x + PW/2 - 5, y + PH*0.45, 10, 3)
    love.graphics.setColor(0.80, 0.66, 0.48, 1)
    love.graphics.circle("fill", x + PW/2, y + PH*0.22, PW/2.6)
    love.graphics.setColor(0.56, 0.54, 0.52, 1)
    love.graphics.ellipse("fill", x + PW/2, y + PH*0.12, PW/2.3, PH/10)
    love.graphics.ellipse("fill", x + PW/2, y + PH*0.08, PW/3.5, PH/9)
    love.graphics.setColor(0.72, 0.72, 0.76, 1)
    love.graphics.setLineWidth(2)
    love.graphics.line(x + PW - 2, y + PH*0.7, x + PW + 6, y + PH*0.35)
    love.graphics.setLineWidth(1)
end

local function drawArcher(e)
    local cx = e.x + 10
    local cy = e.y + 16
    love.graphics.setColor(0.45, 0.25, 0.10, 1)
    love.graphics.circle("fill", cx, cy + 6, 9)
    love.graphics.setColor(0.70, 0.20, 0.08, 1)
    for i = -1, 1 do
        love.graphics.rectangle("fill", cx + i*3 - 1, cy - 16 + math.abs(i)*2, 3, 10)
    end
    love.graphics.setColor(0.68, 0.50, 0.32, 1)
    love.graphics.circle("fill", cx, cy - 8, 7)
    love.graphics.setColor(0.40, 0.28, 0.10, 1)
    love.graphics.setLineWidth(2)
    love.graphics.arc("line", "open", cx - 10, cy - 4, 10, -0.6, 0.6)
    love.graphics.setColor(0.75, 0.65, 0.45, 1)
    love.graphics.setLineWidth(1)
    love.graphics.line(cx - 10, cy - 9, cx - 10, cy + 1)
end

local function drawWarrior(e)
    local cx = e.x + 11
    local cy = e.y + 17
    love.graphics.setColor(0.42, 0.22, 0.08, 1)
    love.graphics.circle("fill", cx, cy + 4, 11)
    love.graphics.setColor(0.65, 0.48, 0.30, 1)
    love.graphics.circle("fill", cx, cy - 10, 9)
    love.graphics.setColor(0.72, 0.18, 0.08, 1)
    love.graphics.ellipse("fill", cx, cy - 20, 8, 4)
    love.graphics.rectangle("fill", cx - 2, cy - 26, 4, 8)
    love.graphics.setColor(0.38, 0.26, 0.10, 1)
    love.graphics.setLineWidth(3)
    love.graphics.line(cx + 10, cy + 4, cx + 20, cy - 10)
    love.graphics.setColor(0.28, 0.18, 0.06, 1)
    love.graphics.circle("fill", cx + 20, cy - 12, 5)
    love.graphics.setLineWidth(1)
end

local function drawGuardian(e)
    local cx = e.x + 15
    local cy = e.y + 23
    love.graphics.setColor(0.38, 0.18, 0.06, 1)
    love.graphics.circle("fill", cx, cy + 4, 15)
    love.graphics.setColor(0.62, 0.45, 0.28, 1)
    love.graphics.circle("fill", cx, cy - 14, 12)
    love.graphics.setColor(0.65, 0.15, 0.05, 1)
    for i = -2, 2 do
        love.graphics.rectangle("fill", cx + i*5 - 2, cy - 30 + math.abs(i)*3, 4, 14)
    end
    love.graphics.setColor(0.85, 0.62, 0.08, 1)
    for i = -1, 1 do
        love.graphics.rectangle("fill", cx + i*5 - 1, cy - 34 + math.abs(i)*3, 3, 10)
    end
    love.graphics.setColor(0.35, 0.22, 0.08, 1)
    love.graphics.setLineWidth(4)
    love.graphics.line(cx + 14, cy + 4, cx + 28, cy - 14)
    love.graphics.setColor(0.25, 0.14, 0.04, 1)
    love.graphics.circle("fill", cx + 28, cy - 16, 7)
    love.graphics.setLineWidth(1)
end

local function drawBgDesert(W, H, camX)
    love.graphics.setColor(0.72, 0.48, 0.22, 1)
    love.graphics.rectangle("fill", 0, 0, W, H * 0.55)
    love.graphics.setColor(0.55, 0.38, 0.18, 1)
    love.graphics.rectangle("fill", 0, H * 0.4, W, H * 0.15)
    love.graphics.setColor(0.95, 0.75, 0.20, 0.9)
    love.graphics.circle("fill", W * 0.75, H * 0.38, 38)
    local px = camX * 0.15
    love.graphics.setColor(0.40, 0.28, 0.15, 0.8)
    for i = 0, 4 do
        local bx = (i * 340 - px) % (W + 200) - 100
        love.graphics.ellipse("fill", bx, H * 0.52, 180, 70)
    end
    love.graphics.setColor(0.50, 0.38, 0.22, 1)
    love.graphics.rectangle("fill", 0, H * 0.52, W, H * 0.48)
end

local function drawBgCave(W, H, camX)
    love.graphics.setColor(0.06, 0.04, 0.02, 1)
    love.graphics.rectangle("fill", 0, 0, W, H)
    local t = love.timer.getTime()
    local torchSpacing = 280
    local firstTorch = math.floor(camX / torchSpacing) * torchSpacing
    for i = 0, math.ceil(W / torchSpacing) + 1 do
        local wx = firstTorch + i * torchSpacing
        local sx = wx - camX
        local flicker = 0.7 + 0.3 * math.sin(t * 5.1 + i * 2.3)
        love.graphics.setColor(0.80, 0.50, 0.08, 0.08 * flicker)
        love.graphics.circle("fill", sx, 300, 100)
        love.graphics.setColor(0.35, 0.22, 0.08, 1)
        love.graphics.rectangle("fill", sx - 3, 290, 6, 14)
        love.graphics.setColor(0.95, 0.65, 0.10, flicker)
        love.graphics.circle("fill", sx, 286, 6)
        love.graphics.setColor(1, 0.90, 0.50, flicker * 0.8)
        love.graphics.circle("fill", sx, 284, 3)
    end
    love.graphics.setColor(0.14, 0.10, 0.06, 1)
    love.graphics.rectangle("fill", 0, 0, W, 60)
end

local function drawBgMine(W, H, camX)
    love.graphics.setColor(0.04, 0.03, 0.02, 1)
    love.graphics.rectangle("fill", 0, 0, W, H)
    local t = love.timer.getTime()
    local torchSpacing = 350
    local firstTorch = math.floor(camX / torchSpacing) * torchSpacing
    for i = 0, math.ceil(W / torchSpacing) + 1 do
        local wx = firstTorch + i * torchSpacing
        local sx = wx - camX
        local flicker = 0.65 + 0.35 * math.sin(t * 4.8 + i * 3.1)
        love.graphics.setColor(0.85, 0.42, 0.05, 0.10 * flicker)
        love.graphics.circle("fill", sx, 310, 120)
        love.graphics.setColor(0.35, 0.22, 0.08, 1)
        love.graphics.rectangle("fill", sx - 3, 298, 6, 14)
        love.graphics.setColor(0.90, 0.55, 0.08, flicker)
        love.graphics.circle("fill", sx, 294, 6)
    end
    local beamSpacing = 180
    local firstBeam = math.floor(camX / beamSpacing) * beamSpacing
    for i = 0, math.ceil(W / beamSpacing) + 1 do
        local wx = firstBeam + i * beamSpacing
        local sx = wx - camX
        love.graphics.setColor(0.28, 0.18, 0.08, 0.8)
        love.graphics.rectangle("fill", sx - 6, 0, 12, 70)
        love.graphics.rectangle("fill", sx - 6, H - 70, 12, 70)
        love.graphics.rectangle("fill", sx - 60, 68, 120, 10)
    end
    love.graphics.setColor(0.65, 0.68, 0.75, 0.12)
    for i = 0, 5 do
        local wx = (i * 420 + 200) - (camX * 0.9)
        love.graphics.ellipse("fill", wx % W, 80 + i * 30, 60, 8)
    end
    love.graphics.setColor(0.08, 0.06, 0.04, 1)
    love.graphics.rectangle("fill", 0, 0, W, 55)
end

function MG:onDraw()
    local W, H = love.graphics.getDimensions()

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
        return
    end

    if currentStage == 1 then
        drawBgDesert(W, H, cameraX)
    elseif currentStage == 2 then
        drawBgCave(W, H, cameraX)
    else
        drawBgMine(W, H, cameraX)
    end

    love.graphics.push()
    love.graphics.translate(-cameraX, 0)

    for _, p in ipairs(platforms) do
        if not p.fallen then
            local shake = (p.crumbleTimer and math.sin(love.timer.getTime() * 40) * 2) or 0
            if p.type == "solid" then
                -- colores claramente distintos del fondo de cada etapa
                if currentStage == 1 then
                    -- piedra oscura arenisca — contrasta con el suelo dorado (0.50,0.38,0.22)
                    love.graphics.setColor(0.28, 0.18, 0.08, 1)
                elseif currentStage == 2 then
                    -- roca cálida iluminada — contrasta con cueva casi negra
                    love.graphics.setColor(0.52, 0.38, 0.22, 1)
                else
                    -- roca de mina gris-café — contrasta con fondo negro
                    love.graphics.setColor(0.40, 0.30, 0.18, 1)
                end
                love.graphics.rectangle("fill", p.x + shake, p.y, p.w, p.h)
                -- borde oscuro para separar del entorno
                love.graphics.setColor(0, 0, 0, 0.60)
                love.graphics.rectangle("line", p.x + shake, p.y, p.w, p.h)
                -- borde superior brillante (5px, muy visible)
                if currentStage == 1 then
                    love.graphics.setColor(0.90, 0.72, 0.42, 0.92)
                elseif currentStage == 2 then
                    love.graphics.setColor(0.85, 0.68, 0.38, 0.92)
                else
                    love.graphics.setColor(0.78, 0.62, 0.34, 0.92)
                end
                love.graphics.rectangle("fill", p.x + shake, p.y, p.w, 5)
            elseif p.type == "crumble" then
                -- naranja-arena con grietas, bien diferente del fondo
                love.graphics.setColor(0.65, 0.46, 0.22, 1)
                love.graphics.rectangle("fill", p.x + shake, p.y, p.w, p.h)
                love.graphics.setColor(0.45, 0.30, 0.12, 0.7)
                love.graphics.rectangle("fill", p.x + 5 + shake, p.y + 5, p.w - 10, p.h - 7)
                love.graphics.setColor(0, 0, 0, 0.55)
                love.graphics.rectangle("line", p.x + shake, p.y, p.w, p.h)
                -- borde superior amarillo-naranja
                love.graphics.setColor(1.0, 0.85, 0.45, 0.90)
                love.graphics.rectangle("fill", p.x + shake, p.y, p.w, 5)
            elseif p.type == "wood" then
                -- madera clara, visible sobre fondo negro de mina
                love.graphics.setColor(0.60, 0.40, 0.16, 1)
                love.graphics.rectangle("fill", p.x + shake, p.y, p.w, p.h)
                love.graphics.setColor(0.40, 0.26, 0.08, 0.65)
                for li = 0, 2 do
                    love.graphics.line(p.x + li*35 + shake, p.y, p.x + li*35 + shake, p.y + p.h)
                end
                love.graphics.setColor(0, 0, 0, 0.55)
                love.graphics.rectangle("line", p.x + shake, p.y, p.w, p.h)
                -- borde superior crema-madera
                love.graphics.setColor(0.95, 0.80, 0.50, 0.92)
                love.graphics.rectangle("fill", p.x + shake, p.y, p.w, 5)
            elseif p.type == "ceiling" then
                love.graphics.setColor(0.20, 0.14, 0.08, 1)
                love.graphics.rectangle("fill", p.x, p.y, p.w, p.h)
            end
        end
    end

    for _, h in ipairs(hazards) do
        if h.type == "cactus" then
            love.graphics.setColor(0.18, 0.48, 0.16, 1)
            love.graphics.rectangle("fill", h.x + h.w/2 - 3, h.y, 6, h.h)
            love.graphics.rectangle("fill", h.x, h.y + h.h * 0.4, h.w, 5)
            love.graphics.rectangle("fill", h.x, h.y + h.h * 0.3, 5, h.h * 0.2)
            love.graphics.rectangle("fill", h.x + h.w - 5, h.y + h.h * 0.35, 5, h.h * 0.2)
            love.graphics.setColor(0.80, 0.80, 0.70, 0.7)
            for si = 0, 2 do
                love.graphics.line(h.x + h.w/2 - 3, h.y + si*12 + 4, h.x + h.w/2 - 10, h.y + si*12)
                love.graphics.line(h.x + h.w/2 + 3, h.y + si*12 + 4, h.x + h.w/2 + 10, h.y + si*12)
            end
        elseif h.type == "charco" then
            local t = love.timer.getTime()
            love.graphics.setColor(0.18, 0.42, 0.62, 0.65)
            love.graphics.rectangle("fill", h.x, h.y, h.w, h.h, 4, 4)
            love.graphics.setColor(0.55, 0.78, 0.92, 0.3 + 0.15*math.sin(t*2))
            love.graphics.rectangle("fill", h.x + 4, h.y + 2, h.w - 8, 4, 2, 2)
        end
    end

    for _, s in ipairs(stalactites) do
        if not s.fallen then
            love.graphics.setColor(0.32, 0.24, 0.16, 1)
            love.graphics.polygon("fill",
                s.x, s.y,
                s.x + s.w, s.y,
                s.x + s.w/2, s.y + s.h)
            love.graphics.setColor(0.42, 0.32, 0.20, 0.5)
            love.graphics.polygon("fill",
                s.x + 4, s.y,
                s.x + s.w - 4, s.y,
                s.x + s.w/2, s.y + s.h * 0.6)
        end
    end

    for _, b in ipairs(boulders) do
        love.graphics.setColor(0.35, 0.28, 0.18, 1)
        love.graphics.circle("fill", b.x, b.y, BOULDER_R)
        love.graphics.setColor(0.25, 0.18, 0.10, 0.7)
        local t = love.timer.getTime()
        love.graphics.line(
            b.x + math.cos(t * 5) * BOULDER_R * 0.6,
            b.y + math.sin(t * 5) * BOULDER_R * 0.6,
            b.x + math.cos(t * 5 + math.pi) * BOULDER_R * 0.6,
            b.y + math.sin(t * 5 + math.pi) * BOULDER_R * 0.6)
    end

    for _, a in ipairs(arrows) do
        love.graphics.setColor(0.55, 0.40, 0.18, 1)
        love.graphics.rectangle("fill", a.x, a.y, a.w, a.h)
        love.graphics.setColor(0.72, 0.20, 0.10, 1)
        love.graphics.rectangle("fill", a.x + a.w - 6, a.y - 2, 6, a.h + 4)
    end

    for _, e in ipairs(enemies) do
        if e.type == "archer" then
            drawArcher(e)
        elseif e.type == "warrior" then
            drawWarrior(e)
        elseif e.type == "guardian" then
            drawGuardian(e)
        end
    end

    if currentStage == 3 then
        local t = love.timer.getTime()
        local pulse = 0.55 + 0.45 * math.sin(t * 3.2)
        love.graphics.setColor(0.68, 0.72, 0.82, 0.15 * pulse)
        love.graphics.circle("fill", SILVER.x + SILVER.w/2, SILVER.y + SILVER.h/2, 40)
        love.graphics.setColor(0.75, 0.78, 0.86, 1)
        love.graphics.rectangle("fill", SILVER.x, SILVER.y, SILVER.w, SILVER.h, 4, 4)
        love.graphics.setColor(0.92, 0.94, 0.98, 1)
        love.graphics.rectangle("fill", SILVER.x + 6, SILVER.y + 6, SILVER.w - 12, SILVER.h - 12, 2, 2)
        love.graphics.setColor(1, 1, 1, pulse)
        love.graphics.circle("fill", SILVER.x + SILVER.w/2, SILVER.y + SILVER.h/2, 6)
        love.graphics.setColor(0.88, 0.90, 0.96, pulse * 0.6)
        love.graphics.setLineWidth(1.5)
        for i = 1, 5 do
            local angle = t * 0.8 + i * math.pi * 0.4
            love.graphics.line(
                SILVER.x + SILVER.w/2, SILVER.y + SILVER.h/2,
                SILVER.x + SILVER.w/2 + math.cos(angle) * 22,
                SILVER.y + SILVER.h/2 + math.sin(angle) * 22)
        end
        love.graphics.setLineWidth(1)
        love.graphics.setColor(0.85, 0.88, 0.94, 0.85)
        love.graphics.printf("PLATA", SILVER.x - 20, SILVER.y + SILVER.h + 4, SILVER.w + 40, "center")
    end

    local blink = player.invTimer > 0 and math.floor(player.invTimer * 10) % 2 == 0
    drawTolosa(player.x, player.y, blink)

    local sd = STAGE_DATA[currentStage]
    if sd and currentStage < 3 then
        local t = love.timer.getTime()
        love.graphics.setColor(0.85, 0.68, 0.18, 0.4 + 0.3*math.sin(t*3))
        love.graphics.rectangle("fill", sd.portalX, 440, 18, 80, 4, 4)
        love.graphics.setColor(1, 0.92, 0.60, 0.9)
        love.graphics.printf("→", sd.portalX - 10, 490, 38, "center")
    end

    love.graphics.pop()

    love.graphics.setColor(0, 0, 0, 0.80)
    love.graphics.rectangle("fill", 0, 0, W, 48)
    for i = 1, 3 do
        local filled = i <= player.lives
        love.graphics.setColor(filled and 0.90 or 0.28, filled and 0.18 or 0.16, filled and 0.18 or 0.16, 1)
        love.graphics.printf(filled and "♥" or "♡", 8 + (i-1)*34, 12, 30, "center")
    end
    love.graphics.setColor(1, 0.85, 0.30, 1)
    love.graphics.printf("Etapa " .. currentStage .. " / 3", 0, 14, W, "center")
    local stageNames = {"Terreno Norte", "Entrada de Cueva", "Interior de Mina"}
    love.graphics.setColor(0.65, 0.52, 0.28, 0.85)
    love.graphics.printf(stageNames[currentStage] or "", W - 230, 14, 220, "right")
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
