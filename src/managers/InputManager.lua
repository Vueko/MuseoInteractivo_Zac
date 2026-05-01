local InputManager = {}

local keys     = {}
local prevKeys = {}
local mouse    = { x = 0, y = 0, buttons = {}, prevButtons = {} }

function InputManager.init()
    keys     = {}
    prevKeys = {}
end

function InputManager.update(dt)
    prevKeys = {}
    for k, v in pairs(keys) do prevKeys[k] = v end
    mouse.prevButtons = {}
    for k, v in pairs(mouse.buttons) do mouse.prevButtons[k] = v end
    mouse.x, mouse.y = love.mouse.getPosition()
end

function InputManager.keypressed(key)
    keys[key] = true
end

function InputManager.keyreleased(key)
    keys[key] = false
end

-- Consultas
function InputManager.isDown(key)
    return keys[key] == true
end

function InputManager.isPressed(key)
    return keys[key] == true and prevKeys[key] ~= true
end

function InputManager.isReleased(key)
    return keys[key] ~= true and prevKeys[key] == true
end

function InputManager.mouseX() return mouse.x end
function InputManager.mouseY() return mouse.y end

function InputManager.mousePos() return mouse.x, mouse.y end

-- Vector de direccion
function InputManager.getAxis()
    local dx, dy = 0, 0
    if InputManager.isDown("w") or InputManager.isDown("up")    then dy = dy - 1 end
    if InputManager.isDown("s") or InputManager.isDown("down")  then dy = dy + 1 end
    if InputManager.isDown("a") or InputManager.isDown("left")  then dx = dx - 1 end
    if InputManager.isDown("d") or InputManager.isDown("right") then dx = dx + 1 end

    local len = math.sqrt(dx*dx + dy*dy)
    if len > 0 then dx, dy = dx/len, dy/len end
    return dx, dy
end

return InputManager