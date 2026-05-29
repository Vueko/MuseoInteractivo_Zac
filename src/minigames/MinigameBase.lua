local SceneManager = require("src.managers.SceneManager")
local C = require("src.conf.Constants")

local Base = {}
Base.__index = Base

-- Helpers --
function Base.setColor(col, alpha)
    love.graphics.setColor(col[1], col[2], col[3], alpha or col[4] or 1)
end

function Base.lerp(a, b, x) return a + (b - a) * x end

function Base.clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

-- Constructor --
function Base.new(cfg)
    local self = setmetatable({}, Base)
    self.cfg        = cfg
    self.state      = "intro"
    self.timer      = 0
    self.introT     = 0
    self.fadeOut    = 0
    self.result     = nil
    self.outroIndex = 1
    self.outroAlpha = 0
    return self
end

-- Ciclo de vida que el hijo sobreescribe --
function Base:onEnter(data)  end   
function Base:onUpdate(dt)   end   
function Base:onDraw()       end   
function Base:onKeypressed(k) end
function Base:onMousepressed(x,y,b) end

-- API publica para los hijos --
function Base:win()
    if self.state ~= "playing" then return end
    self.state   = "success"
    self.timer   = 0
    self.fadeOut = 0
end

function Base:lose()
    if self.state ~= "playing" then return end
    self.state  = "fail"
    self.timer  = 0
end

function Base:startPlaying()
    self.state = "playing"
    self.timer = 0
end

-- enter / update / draw --

function Base:enter(data)
    self.data       = data
    self.state      = "intro"
    self.introT     = 0
    self.timer      = 0
    self.outroIndex = 1
    self.outroAlpha = 0
    self:onEnter(data)
end

function Base:update(dt)
    self.timer = self.timer + dt

    if self.state == "intro" then
        self.introT = self.introT + dt

    elseif self.state == "playing" then
        self:onUpdate(dt)

    elseif self.state == "success" then
        self.fadeOut = Base.clamp(self.fadeOut + dt * 0.5, 0, 1)
        if self.timer > 2.0 then
            self.state      = "outro"
            self.timer      = 0
            self.outroIndex = 1
            self.outroAlpha = 0
        end

    elseif self.state == "outro" then
        self.outroAlpha = math.min(1, self.outroAlpha + dt * 1.5)

    elseif self.state == "fail" then
    end
end

function Base:draw()
    local W, H = love.graphics.getDimensions()

    if self.state == "intro" then
        self:drawIntro(W, H)
    elseif self.state == "playing" then
        self:onDraw()
        self:drawPlayingHUD(W, H)
    elseif self.state == "success" then
        self:onDraw()
        self:drawResult(W, H, true)
    elseif self.state == "outro" then
        self:onDraw()
        self:drawOutro(W, H)
    elseif self.state == "fail" then
        self:onDraw()
        self:drawResult(W, H, false)
    end
end

-- Pantalla de introduccion --

function Base:drawIntro(W, H)
    local t   = self.introT
    local cfg = self.cfg
    local ac  = cfg.accentColor or C.COLOR.ORO_PLATA
    local bg  = cfg.bgColor     or {0.06, 0.04, 0.08, 1}

    love.graphics.setColor(bg)
    love.graphics.rectangle("fill", 0, 0, W, H)

    for i = 1, 6 do
        local angle = t * 0.3 + i * math.pi / 3
        local r = 280 + 40 * math.sin(t * 0.7 + i)
        local x = W/2 + math.cos(angle) * r
        local y = H/2 + math.sin(angle) * r * 0.5
        love.graphics.setColor(ac[1], ac[2], ac[3], 0.06)
        love.graphics.circle("fill", x, y, 80 + 20 * math.sin(t + i))
    end

    local pw, ph = 680, 400
    local px, py = W/2 - pw/2, H/2 - ph/2

    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", px+6, py+6, pw, ph, 14, 14)

    love.graphics.setColor(0.10, 0.07, 0.05, 0.97)
    love.graphics.rectangle("fill", px, py, pw, ph, 12, 12)

    love.graphics.setColor(ac[1], ac[2], ac[3], 0.9)
    love.graphics.rectangle("fill", px, py, pw, 8, 12, 12, 0, 0)

    love.graphics.setColor(ac[1], ac[2], ac[3], 0.6)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", px, py, pw, ph, 12, 12)

    local a1 = Base.clamp(t * 1.5, 0, 1)
    love.graphics.setColor(ac[1], ac[2], ac[3], a1)
    love.graphics.printf(cfg.title or "Minijuego", px, py + 32, pw, "center")

    local a2 = Base.clamp((t - 0.3) * 1.5, 0, 1)
    love.graphics.setColor(1, 1, 1, a2 * 0.9)
    love.graphics.printf(cfg.subtitle or "", px, py + 90, pw, "center")

    if a2 > 0 then
        local lw = Base.clamp((t - 0.5) * 500, 0, pw - 80)
        love.graphics.setColor(ac[1], ac[2], ac[3], 0.5 * a2)
        love.graphics.setLineWidth(1.5)
        love.graphics.line(W/2 - lw/2, py + 140, W/2 + lw/2, py + 140)
    end

    local a3 = Base.clamp((t - 0.7) * 1.2, 0, 1)
    love.graphics.setColor(0.85, 0.82, 0.74, a3)
    love.graphics.printf(cfg.instructions or "", px + 40, py + 160, pw - 80, "left")

    local a4 = Base.clamp((t - 1.2) * 1.0, 0, 1)
    if a4 > 0 then
        local pulse = 0.75 + 0.25 * math.sin(t * 3.5)
        local bw, bh = 240, 50
        local bx, by2 = W/2 - bw/2, py + ph - 80
        love.graphics.setColor(0, 0, 0, 0.3 * a4)
        love.graphics.rectangle("fill", bx+4, by2+4, bw, bh, 10, 10)
        love.graphics.setColor(ac[1]*0.8, ac[2]*0.8, ac[3]*0.8, a4)
        love.graphics.rectangle("fill", bx, by2, bw, bh, 10, 10)
        love.graphics.setColor(ac[1], ac[2], ac[3], a4 * pulse)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", bx, by2, bw, bh, 10, 10)
        love.graphics.setColor(1, 1, 1, a4)
        love.graphics.printf("▶  ¡Comenzar!", bx, by2 + 14, bw, "center")
    end

    love.graphics.setColor(0.55, 0.52, 0.48, 0.7)
    love.graphics.printf("[Esc] Regresar al museo", 0, H - 36, W, "center")
end

-- HUD del juego --

function Base:drawPlayingHUD(W, H)
    local ac = self.cfg.accentColor or C.COLOR.ORO_PLATA

    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.rectangle("fill", 0, 0, W, 40)
    love.graphics.setColor(ac)
    love.graphics.printf(self.cfg.title or "", 0, 8, W, "center")

    love.graphics.setColor(0.18, 0.12, 0.08, 0.85)
    love.graphics.rectangle("fill", 8, 8, 110, 28, 5, 5)
    love.graphics.setColor(0.70, 0.65, 0.55, 1)
    love.graphics.printf("← Salir [Esc]", 8, 13, 110, "center")
end

-- Pantalla de resultado --

function Base:drawResult(W, H, isWin)
    local ac  = self.cfg.accentColor or C.COLOR.ORO_PLATA
    local t2  = self.timer

    local overlayAlpha = Base.clamp(t2 * 1.5, 0, 0.75)
    if isWin then
        love.graphics.setColor(0.05, 0.25, 0.08, overlayAlpha)
    else
        love.graphics.setColor(0.30, 0.04, 0.04, overlayAlpha)
    end
    love.graphics.rectangle("fill", 0, 0, W, H)

    local a = Base.clamp((t2 - 0.2) * 2.0, 0, 1)
    if a > 0 then
        local bw, bh = 500, 260
        local bx, by = W/2 - bw/2, H/2 - bh/2

        love.graphics.setColor(0.08, 0.06, 0.04, 0.95 * a)
        love.graphics.rectangle("fill", bx, by, bw, bh, 12, 12)

        local borderColor = isWin and {0.25, 0.75, 0.35, 1} or {0.75, 0.15, 0.12, 1}
        love.graphics.setColor(borderColor[1], borderColor[2], borderColor[3], a)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", bx, by, bw, bh, 12, 12)

        local icon = isWin and "🏆" or "💀"
        love.graphics.setColor(1, 1, 1, a)
        love.graphics.printf(icon, bx, by + 30, bw, "center")

        local msg = isWin and "¡Misión Completada!" or "Misión Fallida"
        if isWin then
            love.graphics.setColor(0.30, 0.90, 0.40, a)
        else
            love.graphics.setColor(0.90, 0.25, 0.20, a)
        end
        love.graphics.printf(msg, bx, by + 90, bw, "center")

        love.graphics.setColor(0.85, 0.82, 0.74, a * 0.9)
        local sub = isWin
            and "Has aprendido sobre este período histórico.\nRegresando al museo..."
            or  "Inténtalo de nuevo."
        love.graphics.printf(sub, bx + 30, by + 148, bw - 60, "center")

        if not isWin then
            local bw2, bh2 = 180, 44
            love.graphics.setColor(0.20, 0.55, 0.25, a)
            love.graphics.rectangle("fill", W/2 - bw2 - 10, by + bh - 60, bw2, bh2, 8, 8)
            love.graphics.setColor(1, 1, 1, a)
            love.graphics.printf("↺  Reintentar", W/2 - bw2 - 10, by + bh - 46, bw2, "center")
            love.graphics.setColor(0.40, 0.15, 0.12, a)
            love.graphics.rectangle("fill", W/2 + 10, by + bh - 60, bw2, bh2, 8, 8)
            love.graphics.setColor(1, 1, 1, a)
            love.graphics.printf("← Salir", W/2 + 10, by + bh - 46, bw2, "center")
        end
    end
end

-- Eventos --

function Base:keypressed(key)
    if key == "escape" then
        SceneManager.pop()
        return
    end
    if self.state == "intro" then
        if key == "return" or key == "space" or key == "e" then
            self:startPlaying()
        end
    elseif self.state == "playing" then
        self:onKeypressed(key)
    elseif self.state == "outro" then
        if key == "return" or key == "space" or key == "e" then
            self:advanceOutro()
        end
    elseif self.state == "fail" then
        if key == "return" or key == "r" then
            self:enter(self.data)
        end
    end
end

function Base:mousepressed(x, y, button)
    if button ~= 1 then return end
    local W, H = love.graphics.getDimensions()

    if self.state == "intro" then
        local pw, ph = 680, 400
        local py = H/2 - ph/2
        local bh = 50
        local by2 = py + ph - 80
        if y >= by2 and y <= by2 + bh then
            self:startPlaying()
        end
    elseif self.state == "playing" then
        if x >= 8 and x <= 118 and y >= 8 and y <= 36 then
            SceneManager.pop()
            return
        end
        self:onMousepressed(x, y, button)
    elseif self.state == "outro" then
        self:advanceOutro()
    elseif self.state == "fail" then
        local bw2, bh2 = 180, 44
        local pw, ph = 500, 260
        local bx, by = W/2 - pw/2, H/2 - ph/2
        if x >= W/2 - bw2 - 10 and x <= W/2 - 10
           and y >= by + ph - 60 and y <= by + ph - 16 then
            self:enter(self.data)
        end
        if x >= W/2 + 10 and x <= W/2 + bw2 + 10
           and y >= by + ph - 60 and y <= by + ph - 16 then
            SceneManager.pop()
        end
    end
end

function Base:leave() end
function Base:pause() end
function Base:resume() end

function Base:advanceOutro()
    self.outroIndex = self.outroIndex + 1
    self.outroAlpha = 0
    if self.outroIndex > 2 then
        local GS = require("src.data.GameState")
        if self.cfg.id then
            GS.completed[self.cfg.id] = true
        end
        SceneManager.pop()
    end
end

function Base:drawOutro(W, H)
    local D       = require("src.data.CampaignData")
    local chapter = D.chapters[self.cfg.id]
    if not chapter then SceneManager.pop(); return end

    local screens = {
        { text = chapter.quote.text, footer = "— " .. chapter.quote.speaker },
        { text = chapter.bridge,     footer = nil },
    }
    local screen = screens[self.outroIndex]
    if not screen then SceneManager.pop(); return end

    local a = self.outroAlpha

    love.graphics.setColor(0, 0, 0, 0.88 * a)
    love.graphics.rectangle("fill", 0, 0, W, H)

    love.graphics.setColor(1, 0.92, 0.82, a)
    love.graphics.push()
    love.graphics.translate(W / 2, H / 2 - 60)
    love.graphics.scale(1.35, 1.35)
    love.graphics.printf(screen.text, -240, 0, 480, "center")
    love.graphics.pop()

    if screen.footer then
        love.graphics.setColor(0.65, 0.65, 0.65, a)
        love.graphics.printf(screen.footer, 0, H / 2 + 60, W, "center")
    end

    local pulse = 0.5 + 0.5 * math.sin(love.timer.getTime() * 3.5)
    love.graphics.setColor(0.55, 0.52, 0.48, a * pulse)
    love.graphics.printf("Presiona ESPACIO para continuar", 0, H - 48, W, "center")
end

return Base