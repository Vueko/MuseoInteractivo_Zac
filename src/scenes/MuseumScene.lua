local SceneManager = require("src.managers.SceneManager")
local InputManager = require("src.managers.InputManager")
local C = require("src.conf.Constants")
local GS = require("src.data.GameState")

local MuseumScene = {}

local player = {
    x = 200,
    y = 500,
    w = 60,
    h = 120,
    speed = 450,
    anim = 0,
    facing = 1
}

local cameraX = 0
local ROOM_WIDTH = 3400
local paintings = {}

function MuseumScene:enter(data)
    paintings = {}
    local spacing = 600
    local startX = 600
    for i, p in ipairs(C.PERIODS) do
        table.insert(paintings, {
            x = startX + (i-1) * spacing,
            y = 150,
            w = 260,
            h = 360,
            period = p
        })
    end
    if not data or not data.returning then
        player.x = 200
    end
end

function MuseumScene:update(dt)
    local dx = 0
    if InputManager.isDown("a") or InputManager.isDown("left") then dx = -1 end
    if InputManager.isDown("d") or InputManager.isDown("right") then dx = 1 end

    if dx ~= 0 then
        player.facing = dx
        player.anim = player.anim + dt * 12
    else
        player.anim = 0
    end

    player.x = player.x + dx * player.speed * dt
    player.x = math.max(player.w/2, math.min(ROOM_WIDTH - player.w/2, player.x))

    local W = love.graphics.getWidth()
    local targetCameraX = player.x - W/2
    targetCameraX = math.max(0, math.min(ROOM_WIDTH - W, targetCameraX))
    cameraX = cameraX + (targetCameraX - cameraX) * 5 * dt
end

function MuseumScene:draw()
    local W, H = love.graphics.getDimensions()

    love.graphics.push()
    love.graphics.translate(-cameraX, 0)

    love.graphics.setColor(C.COLOR.BEIGE_PERGAMINO)
    love.graphics.rectangle("fill", 0, 0, ROOM_WIDTH, H)
    
    local floorY = H - 180
    love.graphics.setColor(C.COLOR.CAFE_OSCURO)
    love.graphics.rectangle("fill", 0, floorY, ROOM_WIDTH, 180)
    love.graphics.setColor(0.15, 0.08, 0.05, 1)
    love.graphics.rectangle("fill", 0, floorY, ROOM_WIDTH, 20)
    
    love.graphics.setColor(C.COLOR.CANTERA_ROSA)
    for i = 0, ROOM_WIDTH, 400 do
        love.graphics.rectangle("fill", i, 0, 80, floorY)
        love.graphics.setColor(C.COLOR.CANTERA_GRIS)
        love.graphics.rectangle("fill", i - 10, floorY - 30, 100, 30)
        love.graphics.rectangle("fill", i - 10, 0, 100, 30)
        love.graphics.setColor(C.COLOR.CANTERA_ROSA)
    end

    local activePainting = nil

    for _, p in ipairs(paintings) do
        love.graphics.setColor(0, 0, 0, 0.3)
        love.graphics.rectangle("fill", p.x + 10, p.y + 10, p.w + 20, p.h + 20, 5, 5)
        
        if GS.completed[p.period.id] then
            love.graphics.setColor(C.COLOR.PLATA)
        else
            love.graphics.setColor(C.COLOR.ORO_PLATA)
        end
        love.graphics.rectangle("fill", p.x - 15, p.y - 15, p.w + 30, p.h + 30, 5, 5)
        
        love.graphics.setColor(0.1, 0.1, 0.1, 1)
        love.graphics.rectangle("fill", p.x, p.y, p.w, p.h)
        
        love.graphics.setColor(p.period.color)
        love.graphics.rectangle("fill", p.x + 10, p.y + 10, p.w - 20, p.h - 20)
        
        local plaqueW, plaqueH = 180, 40
        local plaqueX = p.x + p.w/2 - plaqueW/2
        local plaqueY = p.y + p.h + 35
        
        love.graphics.setColor(0, 0, 0, 0.4)
        love.graphics.rectangle("fill", plaqueX + 3, plaqueY + 3, plaqueW, plaqueH, 4, 4)
        love.graphics.setColor(C.COLOR.PLATA)
        love.graphics.rectangle("fill", plaqueX, plaqueY, plaqueW, plaqueH, 4, 4)
        
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.printf(p.period.label, plaqueX, plaqueY + 12, plaqueW, "center")

        if GS.completed[p.period.id] then
            love.graphics.setColor(0.25, 0.80, 0.35, 1)
            love.graphics.printf("✓", p.x, p.y + p.h + 42, p.w, "center")
        end

        local dist = math.abs(player.x - (p.x + p.w/2))
        if dist < 180 then
            activePainting = p
            love.graphics.setColor(1, 1, 1, 0.2 + 0.15*math.sin(love.timer.getTime()*6))
            love.graphics.rectangle("fill", p.x + 10, p.y + 10, p.w - 20, p.h - 20)
        end
    end

    local px = player.x
    local py = floorY - player.h/2
    local bob = math.abs(math.sin(player.anim)) * 8
    
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.ellipse("fill", px, floorY + 10, 35, 10)
    
    love.graphics.setColor(0.15, 0.15, 0.2, 1)
    local leg1 = math.sin(player.anim) * 15
    local leg2 = math.sin(player.anim + math.pi) * 15
    local isMoving = player.anim ~= 0
    love.graphics.rectangle("fill", px - 15 + leg1, floorY - 30, 12, 30 + (isMoving and math.min(0, leg1) or 0))
    love.graphics.rectangle("fill", px + 5 + leg2, floorY - 30, 12, 30 + (isMoving and math.min(0, leg2) or 0))
    
    love.graphics.setColor(0.2, 0.4, 0.6, 1)
    love.graphics.rectangle("fill", px - player.w/2, py - player.h/2 - bob, player.w, player.h - 10, 12, 12)
    
    love.graphics.setColor(0.9, 0.7, 0.6, 1)
    love.graphics.circle("fill", px, py - player.h/2 - 25 - bob, 22)

    love.graphics.setColor(0.5, 0.2, 0.2, 1)
    love.graphics.rectangle("fill", px - 35 * player.facing, py - 30 - bob, 20, 45, 5, 5)

    love.graphics.pop()

    if activePainting then
        love.graphics.setColor(C.COLOR.NEGRO_UI)
        love.graphics.rectangle("fill", W/2 - 220, H - 70, 440, 50, 8, 8)
        
        love.graphics.setColor(C.COLOR.AMARILLO_HUD)
        love.graphics.printf("[E] Entrar al minijuego: " .. activePainting.period.label, W/2 - 220, H - 54, 440, "center")
    end
    
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 10, 10, 220, 40, 5, 5)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("← A / D → Moverse", 10, 22, 220, "center")
end

function MuseumScene:keypressed(key)
    if key == "e" or key == "return" then
        for _, p in ipairs(paintings) do
            local dist = math.abs(player.x - (p.x + p.w/2))
            if dist < 180 then
                SceneManager.push(p.period.id, { returning = true })
                return
            end
        end
    end
end

function MuseumScene:resume()
    if GS.endingShown then return end
    for _, p in ipairs(C.PERIODS) do
        if not GS.completed[p.id] then return end
    end
    GS.endingShown = true
    SceneManager.switch("ending")
end

return MuseumScene
