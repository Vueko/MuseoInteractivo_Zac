local SceneManager = {}
local stack = {}
local scenes = {}

local sceneModules = {
    intro = "src.scenes.IntroScene",
    museum = "src.scenes.MuseumScene",
    ending = "src.scenes.EndingScene",

    mg_prehispanico = "src.minigames.MG_Prehispanico",
    mg_conquista = "src.minigames.MgConquista",
    mg_mineria = "src.minigames.MgMineria",
    mg_independencia = "src.minigames.MgIndependencia",
    mg_revolucion = "src.minigames.MgRevolucion"
}

local function loadScene(name)
    if not scenes[name] then
        local ok, mod = pcall(require, sceneModules[name])
        if ok then
            scenes[name] = mod
        else
            error("No se pudo cargar la escena" .. name .. "\n" .. tostring(mod))
        end
    end
    return scenes[name]
end

function SceneManager.init()
    stack = {}
end

-- Remplaza la escena actual
function SceneManager.switch(name,data)
    local scene = loadScene(name)
    if #stack > 0 then
        local current = stack[#stack]
        if current.scene.leave then current.scene:leave() end
    end
    stack[#stack] = { name = name, scene = scene, data = data}
    if scene.enter then scene:enter(data) end
end

-- Aplica una nueva escena
function SceneManager.push(name, data)
    local scene = loadScene(name)
    if #stack > 0 then
        local current = stack[#stack]
        if current.scene.pause then current.scene:pause() end
    end
    table.insert(stack, { name = name, scene = scene, data = data})
    if scene.enter then scene:enter(data) end
end

-- Quita la escena actual
function SceneManager.pop()
    if #stack <= 1 then return end
    local current = stack[#stack]
    if current.scene.leave then current.scene:leave() end
    table.remove(stack)
    local prev = stack[#stack]
    if prev.scene.resume then prev.scene:resume() end
end

-- Nombre de la escena activa
function SceneManager.current()
    if #stack > 0 then return stack[#stack].name end
end

-- Delegacion de eventos --

local function top()
    if #stack > 0 then return stack[#stack].scene end
end

function SceneManager.update(dt)     local s = top(); if s and s.update     then s:update(dt) end end
function SceneManager.draw()         local s = top(); if s and s.draw       then s:draw()     end end
function SceneManager.keypressed(k)  local s = top(); if s and s.keypressed then s:keypressed(k) end end
function SceneManager.keyreleased(k) local s = top(); if s and s.keyreleased then s:keyreleased(k) end end
function SceneManager.mousepressed(x,y,b)  local s = top(); if s and s.mousepressed  then s:mousepressed(x,y,b)  end end
function SceneManager.mousereleased(x,y,b) local s = top(); if s and s.mousereleased then s:mousereleased(x,y,b) end end
function SceneManager.mousemoved(x,y,dx,dy) local s = top(); if s and s.mousemoved then s:mousemoved(x,y,dx,dy) end end
function SceneManager.resize(w,h)    local s = top(); if s and s.resize     then s:resize(w,h) end end
 
return SceneManager