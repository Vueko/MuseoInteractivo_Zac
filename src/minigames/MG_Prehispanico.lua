local Base  = require("src.minigames.MinigameBase")
local C     = require("src.conf.Constants")

local MG = setmetatable({}, { __index = Base })
MG.__index = MG

local CFG = {
    title        = "⚡  Los Zacatecos — Tower Defense",
    subtitle     = "~200 a.C. – 1546 d.C.",
    accentColor  = {0.65, 0.42, 0.15, 1},
    bgColor      = {0.08, 0.05, 0.02, 1},
    instructions =
        "Defiende tu aldea de los intrusos en este Tower Defense\n\n"..
        "• Mueve a tu HÉROE con ← → (o A/D)\n"..
        "• Presiona ESPACIO para lanzar tu lanza\n"..
        "• Usa CLICK IZQUIERDO en el campo para construir TORRES (Costo: 5 oro)\n"..
        "• ¡Sobrevive a las 3 oleadas para ganar!",
}

local WORLD_W, WORLD_H = 1280, 720

local warrior      = {}
local spears       = {}
local enemies      = {}
local particles    = {}
local towers       = {}
local decorations  = {}

local money        = 10
local villageHP    = 5
local MAX_HP       = 5
local TOWER_COST   = 5

local currentWave  = 1
local waveState    = "intermission"
local waveTimer    = 5.0
local enemiesToSpawn = 0
local waveInterval = 2.0
local spawnTimer   = 0

local bgScroll     = 0

local cinematicTexts = {
    "Zacatecas, Siglo XVI.\n\nEl descubrimiento de inmensas vetas de plata ha atraído a cientos de colonizadores a tierras inexploradas.",
    "Sin embargo, este territorio no está vacío. Los valientes pueblos nativos, como los Caxcanes y los Zacatecos, protegerán su hogar.",
    "A la encarnizada defensa de estas tierras se le conoce como la Guerra Chichimeca (1550 - 1590).",
    "¡Eres un guerrero defendiendo tu aldea!\n\nUtiliza tu lanza, recolecta oro y construye torres para repeler el avance de los colonizadores."
}
local cinematicIndex = 1
local cinematicAlpha = 0

local function startWave(w)
    waveState = "playing"
    enemiesToSpawn = 5 + w * 5  -- W1:10, W2:15, W3:20
    waveInterval = math.max(0.6, 2.2 - w * 0.4)
    spawnTimer = 0
end

function MG.new()
    local self = Base.new(CFG)
    return setmetatable(self, MG)
end

function MG:onEnter(data)
    warrior = {
        x = WORLD_W / 2, y = WORLD_H - 110,
        w = 44, h = 70,
        speed = 300,
        anim  = 0,
    }
    spears       = {}
    enemies      = {}
    particles    = {}
    towers       = {}
    decorations  = {}
    
    for i = 1, 40 do
        table.insert(decorations, {
            x = math.random(0, WORLD_W),
            y = math.random(0, WORLD_H),
            type = math.random(1, 3),
            scale = math.random() * 0.5 + 0.8
        })
    end
    
    money        = 10
    villageHP    = 5
    currentWave  = 1
    
    cinematicIndex = 1
    cinematicAlpha = 0
    waveState    = "cinematic"
    
    waveTimer    = 4.0
    bgScroll     = 0
end

local function spawnSpear(wx, wy, tx, ty)
    local dx = tx - wx
    local dy = ty - wy
    local len = math.sqrt(dx*dx + dy*dy)
    if len == 0 then dx, dy = 0, -1 else dx, dy = dx/len, dy/len end
    table.insert(spears, {
        x = wx, y = wy,
        vx = dx * 650, vy = dy * 650,
        alive = true,
        angle = math.atan2(dy, dx),
    })
end

local function spawnEnemy()
    local startX = math.random(60, WORLD_W - 60)
    local speed = 35 + currentWave * 15 + math.random(-5, 15)
    local hp = currentWave == 3 and math.random(1, 2) or 1
    table.insert(enemies, {
        x = startX, y = -40,
        vx = 0, vy = speed,
        w = 36, h = 50,
        hp = hp, maxHp = hp,
        alive = true,
        anim = math.random() * math.pi * 2,
        type = math.random(1, 3),
    })
end

local function spawnImpact(x, y, col)
    for i = 1, 15 do
        local angle = math.random() * math.pi * 2
        local speed = math.random(40, 160)
        table.insert(particles, {
            x = x, y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed - 50,
            life = 0.8, maxLife = 0.8,
            r = math.random(3, 7),
            col = col or {1, 0.6, 0.2},
        })
    end
end

function MG:onUpdate(dt)
    bgScroll = bgScroll + 10 * dt

    if waveState == "cinematic" then
        cinematicAlpha = math.min(1, cinematicAlpha + dt * 1.5)
        return
    end

    -- Lógica de oleadas
    if waveState == "intermission" then
        waveTimer = waveTimer - dt
        if waveTimer <= 0 then
            startWave(currentWave)
        end
    elseif waveState == "playing" then
        spawnTimer = spawnTimer + dt
        if spawnTimer >= waveInterval and enemiesToSpawn > 0 then
            spawnTimer = 0
            spawnEnemy()
            enemiesToSpawn = enemiesToSpawn - 1
        end
        
        -- ¿Terminó la oleada?
        if enemiesToSpawn <= 0 and #enemies == 0 then
            if currentWave >= 3 then
                self:win()
            else
                currentWave = currentWave + 1
                waveState = "intermission"
                waveTimer = 4.0
            end
        end
    end

    -- Mover héroe
    local dx = 0
    if love.keyboard.isDown("a") or love.keyboard.isDown("left")  then dx = -1 end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then dx =  1 end
    warrior.x = warrior.x + dx * warrior.speed * dt
    warrior.x = math.max(30, math.min(WORLD_W - 30, warrior.x))
    warrior.anim = warrior.anim + dt * (dx ~= 0 and 8 or 2)

    -- Mover torres (animación y disparo auto)
    for _, t in ipairs(towers) do
        t.anim = t.anim + dt * 2
        t.timer = t.timer - dt
        if t.timer <= 0 and #enemies > 0 then
            -- Buscar enemigo más cercano
            local best, bestD = nil, t.range
            for _, e in ipairs(enemies) do
                local dist = math.sqrt((e.x - t.x)^2 + (e.y - t.y)^2)
                if dist < bestD then
                    bestD = dist
                    best = e
                end
            end
            if best then
                spawnSpear(t.x, t.y - 20, best.x, best.y)
                t.timer = 1.2 -- Cooldown de la torre
            end
        end
    end

    -- Mover lanzas
    for i = #spears, 1, -1 do
        local s = spears[i]
        s.x = s.x + s.vx * dt
        s.y = s.y + s.vy * dt
        if s.x < -50 or s.x > WORLD_W + 50 or s.y < -50 or s.y > WORLD_H + 50 then
            table.remove(spears, i)
        end
    end

    -- Mover enemigos y colisiones
    for i = #enemies, 1, -1 do
        local e = enemies[i]
        e.x = e.x + e.vx * dt
        e.y = e.y + e.vy * dt
        e.anim = e.anim + dt * 6

        -- ¿Llegó a la aldea?
        if e.y > WORLD_H - 80 then
            villageHP = villageHP - 1
            spawnImpact(e.x, e.y, {0.9, 0.1, 0.1})
            table.remove(enemies, i)
            if villageHP <= 0 then
                self:lose()
            end
        else
            -- Colisión con lanzas
            for j = #spears, 1, -1 do
                local s = spears[j]
                local dist = math.sqrt((s.x-e.x)^2 + (s.y-e.y)^2)
                if dist < 30 then
                    spawnImpact(e.x, e.y, {1, 0.8, 0.2})
                    table.remove(spears, j)
                    e.hp = e.hp - 1
                    if e.hp <= 0 then
                        money = money + 1
                        table.remove(enemies, i)
                    end
                    break
                end
            end
        end
    end

    -- Partículas
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x    = p.x + p.vx * dt
        p.y    = p.y + p.vy * dt
        p.vy   = p.vy + 200 * dt
        p.life = p.life - dt
        if p.life <= 0 then table.remove(particles, i) end
    end
end

-- Funciones de dibujado auxiliares
local function drawEnemy(e)
    local bob = math.sin(e.anim) * 4
    love.graphics.setColor(0, 0, 0, 0.20)
    love.graphics.ellipse("fill", e.x, e.y + e.h/2 + 3, 18, 6)

    -- Base shape
    -- Colonizadores (Españoles)
    -- Cuerpo (armadura)
    love.graphics.setColor(0.65, 0.65, 0.70, 1) -- Gris metálico
    love.graphics.rectangle("fill", e.x - 14, e.y - 24 + bob, 28, 30, 4, 4)
    
    -- Detalles de armadura según tipo
    if e.type == 1 then
        love.graphics.setColor(0.8, 0.7, 0.2, 1) -- Detalles dorados
        love.graphics.rectangle("fill", e.x - 8, e.y - 20 + bob, 16, 20)
    elseif e.type == 2 then
        love.graphics.setColor(0.3, 0.3, 0.3, 1) -- Armadura oscura
        love.graphics.rectangle("fill", e.x - 10, e.y - 18 + bob, 20, 16)
    else
        love.graphics.setColor(0.6, 0.1, 0.1, 1) -- Detalles rojos
        love.graphics.rectangle("fill", e.x - 4, e.y - 24 + bob, 8, 30)
    end

    -- Cabeza
    love.graphics.setColor(0.9, 0.8, 0.7, 1) -- Piel
    love.graphics.circle("fill", e.x, e.y - 32 + bob, 12)
    
    -- Casco Morrión (Típico conquistador)
    love.graphics.setColor(0.6, 0.6, 0.65, 1)
    love.graphics.arc("fill", e.x, e.y - 34 + bob, 14, math.pi, math.pi*2)
    -- Ala del casco
    love.graphics.ellipse("fill", e.x, e.y - 34 + bob, 18, 3)
    -- Cresta del casco
    love.graphics.polygon("fill", e.x - 4, e.y - 45 + bob, e.x + 4, e.y - 45 + bob, e.x, e.y - 52 + bob)

    -- Piernas
    love.graphics.setColor(0.50, 0.30, 0.12, 1)
    local leg = math.sin(e.anim * 1.5) * 8
    love.graphics.rectangle("fill", e.x - 12, e.y + 6 + bob, 11, 18 + leg, 3, 3)
    love.graphics.rectangle("fill", e.x + 1,  e.y + 6 + bob, 11, 18 - leg, 3, 3)
    
    -- HP Bar si tiene más de 1 maxHp
    if e.maxHp > 1 then
        love.graphics.setColor(1, 0, 0, 0.8)
        love.graphics.rectangle("fill", e.x - 15, e.y - 50 + bob, 30, 5)
        love.graphics.setColor(0, 1, 0, 0.8)
        love.graphics.rectangle("fill", e.x - 15, e.y - 50 + bob, 30 * (e.hp / e.maxHp), 5)
    end
end

local function drawWarrior(w)
    local bob = math.sin(w.anim) * 3
    love.graphics.setColor(0, 0, 0, 0.25)
    love.graphics.ellipse("fill", w.x, w.y + w.h/2 + 5, 20, 7)

    -- Piernas
    -- Guerrero Zapoteca (Héroe)
    love.graphics.setColor(0.35, 0.22, 0.08, 1)
    local leg = math.sin(w.anim * 1.5) * 10
    love.graphics.rectangle("fill", w.x - 14, w.y + 10 + bob, 12, 22 + leg, 3, 3)
    love.graphics.rectangle("fill", w.x + 2,  w.y + 10 + bob, 12, 22 - leg, 3, 3)

    -- Cuerpo (túnica con patrones vibrantes)
    love.graphics.setColor(0.8, 0.2, 0.2, 1) -- Rojo carmín
    love.graphics.rectangle("fill", w.x - 18, w.y - 22 + bob, 36, 34, 5, 5)
    love.graphics.setColor(0.1, 0.6, 0.4, 1) -- Verde jade (detalles)
    love.graphics.rectangle("fill", w.x - 10, w.y - 18 + bob, 20, 14, 2, 2)
    love.graphics.setColor(0.9, 0.8, 0.2, 1) -- Oro
    love.graphics.rectangle("fill", w.x - 18, w.y + 6 + bob, 36, 6)

    -- Escudo Zapoteca (Greca)
    love.graphics.setColor(0.2, 0.4, 0.8, 1)
    love.graphics.circle("fill", w.x - 22, w.y - 5 + bob, 14)
    love.graphics.setColor(0.9, 0.8, 0.2, 1)
    love.graphics.circle("line", w.x - 22, w.y - 5 + bob, 12)
    love.graphics.rectangle("fill", w.x - 26, w.y - 9 + bob, 8, 8)

    -- Cabeza
    love.graphics.setColor(0.65, 0.45, 0.25, 1) -- Piel morena
    love.graphics.circle("fill", w.x, w.y - 32 + bob, 15)

    -- Gran Penacho (Plumas)
    local plumes = {{-16,-10,0.1,0.6,0.3},{-10,-18,0.9,0.8,0.2},{0,-22,0.8,0.2,0.2},{10,-18,0.9,0.8,0.2},{16,-10,0.1,0.6,0.3}}
    for _, pl in ipairs(plumes) do
        love.graphics.setColor(pl[3], pl[4], pl[5], 1)
        love.graphics.polygon("fill", w.x, w.y - 35 + bob, w.x + pl[1] - 5, w.y - 35 + bob + pl[2], w.x + pl[1] + 5, w.y - 35 + bob + pl[2])
    end
end

local function drawTower(t)
    local bob = math.sin(t.anim) * 2
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.ellipse("fill", t.x, t.y + 15, 25, 8)
    
    -- Base de la torre (piedras)
    love.graphics.setColor(0.4, 0.4, 0.4, 1)
    love.graphics.rectangle("fill", t.x - 20, t.y - 10, 40, 25, 3, 3)
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.rectangle("fill", t.x - 15, t.y - 5, 30, 20, 2, 2)
    
    -- Aliado Zapoteca encima
    love.graphics.setColor(0.1, 0.6, 0.4, 1) -- Verde jade
    love.graphics.rectangle("fill", t.x - 12, t.y - 35 + bob, 24, 25, 4, 4)
    love.graphics.setColor(0.65, 0.45, 0.25, 1) -- Piel
    love.graphics.circle("fill", t.x, t.y - 45 + bob, 12)
    
    -- Penacho pequeño
    love.graphics.setColor(0.8, 0.2, 0.2, 1)
    love.graphics.polygon("fill", t.x, t.y - 50 + bob, t.x - 8, t.y - 60 + bob, t.x + 8, t.y - 60 + bob)
    
    -- Rango visible sutil
    love.graphics.setColor(1, 1, 1, 0.05)
    love.graphics.circle("line", t.x, t.y, t.range)
end

function MG:onDraw()
    local W, H = love.graphics.getDimensions()
    local sx = W / WORLD_W
    local sy = H / WORLD_H
    local scale = math.min(sx, sy)
    local offX = (W - WORLD_W * scale) / 2
    local offY = (H - WORLD_H * scale) / 2

    love.graphics.push()
    love.graphics.translate(offX, offY)
    love.graphics.scale(scale, scale)

    -- Fondo Tierra Semi-Desértica (Zacatecas)
    love.graphics.setColor(0.80, 0.65, 0.45, 1) -- Arena/Tierra clara
    love.graphics.rectangle("fill", 0, 0, WORLD_W, WORLD_H)
    
    -- Textura del suelo (parches de tierra)
    love.graphics.setColor(0.75, 0.58, 0.40, 1)
    for i = 0, WORLD_W, 80 do
        for j = -80, WORLD_H, 80 do
            if (i+j)%160 == 0 then
                love.graphics.rectangle("fill", i, j + (bgScroll%80), 80, 80)
            end
        end
    end

    -- Decoraciones del semidesierto (Maguey, Roca, Nopal)
    for _, d in ipairs(decorations) do
        local ry = (d.y + bgScroll * 0.5) % WORLD_H
        love.graphics.push()
        love.graphics.translate(d.x, ry)
        love.graphics.scale(d.scale, d.scale)
        if d.type == 1 then
            -- Maguey / Agave
            love.graphics.setColor(0.3, 0.45, 0.35, 1)
            love.graphics.polygon("fill", 0,0, -15,-20, -5,-5, 0,-25, 5,-5, 15,-20)
        elseif d.type == 2 then
            -- Roca de cantera/piedra
            love.graphics.setColor(0.65, 0.55, 0.55, 1)
            love.graphics.ellipse("fill", 0,0, 18, 10)
            love.graphics.setColor(0.55, 0.45, 0.45, 1)
            love.graphics.ellipse("fill", -5,2, 8, 5)
        else
            -- Nopal
            love.graphics.setColor(0.4, 0.55, 0.3, 1)
            love.graphics.ellipse("fill", 0,0, 10, 15)
            love.graphics.ellipse("fill", -8,-5, 8, 10)
            love.graphics.ellipse("fill", 8,-10, 8, 10)
        end
        love.graphics.pop()
    end

    -- Línea de la aldea
    love.graphics.setColor(0.6, 0.4, 0.2, 0.5)
    love.graphics.rectangle("fill", 0, WORLD_H - 120, WORLD_W, 120)
    love.graphics.setColor(0.8, 0.5, 0.2, 1)
    love.graphics.setLineWidth(4)
    love.graphics.line(0, WORLD_H - 120, WORLD_W, WORLD_H - 120)
    
    -- Chozas de la aldea
    for cx = 100, WORLD_W, 250 do
        love.graphics.setColor(0.5, 0.3, 0.1, 1)
        love.graphics.rectangle("fill", cx - 40, WORLD_H - 90, 80, 70, 5, 5)
        love.graphics.setColor(0.8, 0.7, 0.2, 1)
        love.graphics.polygon("fill", cx - 50, WORLD_H - 90, cx, WORLD_H - 140, cx + 50, WORLD_H - 90)
    end

    -- Partículas
    for _, p in ipairs(particles) do
        local a = p.life / p.maxLife
        love.graphics.setColor(p.col[1], p.col[2], p.col[3], a)
        love.graphics.circle("fill", p.x, p.y, p.r * a)
    end

    -- Torres
    for _, t in ipairs(towers) do drawTower(t) end
    
    -- Enemigos
    for _, e in ipairs(enemies) do drawEnemy(e) end

    -- Lanzas
    love.graphics.setColor(0.70, 0.48, 0.18, 1)
    love.graphics.setLineWidth(3)
    for _, s in ipairs(spears) do
        local len = 28
        love.graphics.line(s.x - math.cos(s.angle)*len, s.y - math.sin(s.angle)*len,
                           s.x + math.cos(s.angle)*len, s.y + math.sin(s.angle)*len)
        love.graphics.setColor(0.85, 0.25, 0.10, 1)
        love.graphics.circle("fill", s.x + math.cos(s.angle)*len, s.y + math.sin(s.angle)*len, 5)
        love.graphics.setColor(0.70, 0.48, 0.18, 1)
    end

    drawWarrior(warrior)

    -- Interfaz centrada si está en pausa (intermission)
    if waveState == "intermission" then
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle("fill", WORLD_W/2 - 250, WORLD_H/2 - 60, 500, 120, 10, 10)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("PREPÁRATE PARA LA OLEADA " .. currentWave, WORLD_W/2 - 250, WORLD_H/2 - 20, 500, "center")
        love.graphics.setColor(1, 1, 0.5, 1)
        love.graphics.printf("Inicia en: " .. string.format("%.1f", waveTimer) .. "s", WORLD_W/2 - 250, WORLD_H/2 + 20, 500, "center")
    end

    love.graphics.pop()

    -- HUD Principal Superior
    love.graphics.setColor(0.10, 0.07, 0.03, 0.85)
    love.graphics.rectangle("fill", 0, 0, W, 56)

    -- Textos HUD
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Oleada: " .. currentWave .. " / 3", 20, 18, 200, "left")
    
    love.graphics.setColor(1, 0.8, 0.2, 1)
    love.graphics.printf("Oro: " .. money, W/2 - 100, 18, 200, "center")
    
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.printf("Costo Torre: " .. TOWER_COST, W/2 + 100, 18, 200, "left")

    -- Vidas (Aldea)
    local lifeX = W - 200
    for i = 1, MAX_HP do
        if i <= villageHP then
            love.graphics.setColor(0.90, 0.15, 0.15, 1)
        else
            love.graphics.setColor(0.30, 0.20, 0.20, 0.5)
        end
        love.graphics.printf("❤", lifeX + (i-1)*30, 18, 30, "center")
    end

    -- Cinemática (Superposición total)
    if waveState == "cinematic" then
        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle("fill", 0, 0, W, H)
        
        love.graphics.setColor(1, 0.9, 0.8, cinematicAlpha)
        love.graphics.push()
        love.graphics.translate(W/2, H/2 - 40)
        love.graphics.scale(1.8, 1.8)
        love.graphics.printf(cinematicTexts[cinematicIndex], -250, 0, 500, "center")
        love.graphics.pop()
        
        love.graphics.setColor(0.8, 0.8, 0.8, cinematicAlpha * (0.5 + 0.5 * math.sin(love.timer.getTime() * 4)))
        love.graphics.printf("Presiona ESPACIO o haz CLIC para continuar", 0, H - 80, W, "center")
    end
end

-- Controles
function MG:onKeypressed(key)
    if waveState == "cinematic" then
        if key == "space" or key == "return" then
            cinematicIndex = cinematicIndex + 1
            cinematicAlpha = 0
            if cinematicIndex > #cinematicTexts then
                waveState = "intermission"
                waveTimer = 4.0
            end
        end
        return
    end

    if key == "space" then
        local W, H = love.graphics.getDimensions()
        local tx, ty = warrior.x, warrior.y - WORLD_H
        if #enemies > 0 then
            local best, bestDist = enemies[1], math.huge
            for _, e in ipairs(enemies) do
                local d = math.sqrt((e.x - warrior.x)^2 + (e.y - warrior.y)^2)
                if d < bestDist then bestDist = d; best = e end
            end
            tx, ty = best.x, best.y
        end
        spawnSpear(warrior.x, warrior.y - 30, tx, ty)
    end
end

function MG:onMousepressed(x, y, button)
    if button == 1 then
        if waveState == "cinematic" then
            cinematicIndex = cinematicIndex + 1
            cinematicAlpha = 0
            if cinematicIndex > #cinematicTexts then
                waveState = "intermission"
                waveTimer = 4.0
            end
            return
        end

        local W, H = love.graphics.getDimensions()
        local sx = W / WORLD_W
        local sy = H / WORLD_H
        local scale = math.min(sx, sy)
        local offX = (W - WORLD_W * scale) / 2
        local offY = (H - WORLD_H * scale) / 2
        local wx = (x - offX) / scale
        local wy = (y - offY) / scale
        
        -- Construir torre si haces click en la pantalla
        if wy < WORLD_H - 120 and wy > 60 then
            if money >= TOWER_COST then
                money = money - TOWER_COST
                table.insert(towers, {x = wx, y = wy, range = 280, timer = 1.0, anim = 0})
                spawnImpact(wx, wy, {0.6, 0.6, 0.6})
            end
        end
    end
end

function MG:enter(data)     Base.enter(self, data)     end
function MG:update(dt)      Base.update(self, dt)      end
function MG:draw()          Base.draw(self)          end
function MG:keypressed(k)   Base.keypressed(self, k)   end
function MG:mousepressed(x,y,b) Base.mousepressed(self,x,y,b) end
function MG:leave()         end
function MG:pause()         end
function MG:resume()        end

return MG.new()