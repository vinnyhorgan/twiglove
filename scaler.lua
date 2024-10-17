local scaler = {mouse = {}}

function scaler.setup(x, y)
    scaler.sizeX = x or 64
    scaler.sizeY = y or scaler.sizeX

    local scaleX = math.floor(love.graphics.getWidth() / scaler.sizeX)
    local scaleY = math.floor(love.graphics.getHeight() / scaler.sizeY)
    scaler.scaler = math.min(scaleX, scaleY)

    scaler.x = (love.graphics.getWidth() - (scaler.scaler * scaler.sizeX)) / 2
    scaler.y = (love.graphics.getHeight() - (scaler.scaler * scaler.sizeY)) / 2

    scaler.canvas = love.graphics.newCanvas(scaler.sizeX, scaler.sizeY)
    scaler.canvas:setFilter("nearest")

    scaler.resize(love.graphics.getDimensions())
end

function scaler.start()
    love.graphics.setCanvas(scaler.canvas)
    love.graphics.clear()
end

function scaler.finish()
    love.graphics.setCanvas()
    love.graphics.draw(scaler.canvas, scaler.x, scaler.y, 0, scaler.scaler)
end

function scaler.resize(w, h)
    local scaleX = math.floor(w / scaler.sizeX)
    local scaleY = math.floor(h / scaler.sizeY)
    scaler.scaler = math.min(scaleX, scaleY)

    scaler.x = (w - (scaler.scaler * scaler.sizeX)) / 2
    scaler.y = (h - (scaler.scaler * scaler.sizeY)) / 2
end

function scaler.mouse.getPosition()
    local mx = math.floor((love.mouse.getX() - scaler.x) / scaler.scaler)
    local my = math.floor((love.mouse.getY() - scaler.y) / scaler.scaler)
    return mx, my
end

function scaler.mouse.getX()
    return math.floor((love.mouse.getX() - scaler.x) / scaler.scaler)
end

function scaler.mouse.getY()
    return math.floor((love.mouse.getY() - scaler.y) / scaler.scaler)
end

function scaler.newImage(source)
    local image = love.graphics.newImage(source)
    image:setFilter("nearest")
    return image
end

return scaler
