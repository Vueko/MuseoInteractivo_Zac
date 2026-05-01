local SceneManager = require("src.managers.SceneManager")
local InputManager = require("src.managers.InputManager")

function love.load()
    love.window.setTitle("Museo Interactivo de Zacatecas")
    love.graphics.setDefaultFilter("nearest", "nearest")
    
    math.randomseed(os.time())

    InputManager.init()
    SceneManager.init()

    SceneManager.push("intro")
end 

function love.update(dt)
    InputManager.update(dt)
    SceneManager.update(dt)
end

function love.draw()
    SceneManager.draw()
end

function love.keypressed(key, scancode, isrepeat)
    if key == "escape" then
        SceneManager.pop()
    end
    InputManager.keypressed(key,scancode,isrepeat)
    SceneManager.keypressed(key,scancode,isrepeat)
end

function love.keyreleased(key, scancode)
    if key == "escape" then
        SceneManager.pop()
    end
    InputManager.keyreleased(key,scancode)
    SceneManager.keyreleased(key,scancode)
end

function love.keyreleased(key)
    InputManager.keyreleased(key)
    SceneManager.keyreleased(key)
end

function love.mousepressed(x,y,button,istouch,presses)
    if InputManager.mousepressed then InputManager.mousepressed(x,y,button) end
    SceneManager.mousepressed(x,y,button)
end

function love.mousereleased(x,y,button,istouch)
    if InputManager.mousereleased then InputManager.mousereleased(x,y,button) end
    SceneManager.mousereleased(x,y,button)
end

function love.mousemoved(x,y,dx,dy)
    if InputManager.mousemoved then InputManager.mousemoved(x,y,dx,dy) end
    SceneManager.mousemoved(x,y,dx,dy)
end

function love.resize(w,h)
    if InputManager.resize then InputManager.resize(w,h) end
    SceneManager.resize(w,h)
end

