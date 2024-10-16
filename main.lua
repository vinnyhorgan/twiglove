local maid64 = require("maid64")

local width, height = 256, 256

local assets = maid64.newImage("roguelike.png")

maid64.setup(width, height)

local selected

local state = "selecting"

local selectingX = 0
local selectingY = 0

local gridWidth = 16
local gridHeight = 16
local cellSize = 16
local grid = {}

local font = love.graphics.newFont(10, "mono")
love.graphics.setFont(font)

for x = 1, gridWidth do
    grid[x] = {}
    for y = 1, gridHeight do
        grid[x][y] = nil
    end
end

love.mouse.setVisible(false)

local cursor = maid64.newImage("cursor.png")

function love.update(dt)
    if state == "selecting" then
        if love.keyboard.isDown("w") then
            selectingY = selectingY + 1
        end
        if love.keyboard.isDown("s") then
            selectingY = selectingY - 1
        end
        if love.keyboard.isDown("d") then
            selectingX = selectingX - 1
        end
        if love.keyboard.isDown("a") then
            selectingX = selectingX + 1
        end
    end
end

function love.draw()
    maid64.start()

    love.graphics.clear(145/255, 183/255, 201/255)

    if state == "selecting" then
        love.graphics.draw(assets, selectingX, selectingY)
    elseif state == "drawing" then
        for x = 1, gridWidth do
            for y = 1, gridHeight do
                if grid[x][y] then
                    love.graphics.draw(assets, grid[x][y], (x - 1) * cellSize, (y - 1) * cellSize)
                end
            end
        end

        local gridX = math.floor(maid64.mouse.getX() / cellSize)
        local gridY = math.floor(maid64.mouse.getY() / cellSize)

        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.draw(assets, selected, gridX * cellSize, gridY * cellSize)
        love.graphics.setColor(1, 1, 1, 1)
    end

    love.graphics.print("Porcodio!", 10, 10)

    love.graphics.draw(cursor, maid64.mouse.getX() - cursor:getWidth() / 2, maid64.mouse.getY() - cursor:getHeight() / 2)

    maid64.finish()
end

function love.keypressed(key)
    if key == "space" then
        state = "selecting"
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
        if state == "selecting" then
            local mouseX = maid64.mouse.getX()
            local mouseY = maid64.mouse.getY()

            if mouseX >= 0 and mouseX <= width and mouseY >= 0 and mouseY <= height then
                local sheetX = math.floor((maid64.mouse.getX() - selectingX) / cellSize)
                local sheetY = math.floor((maid64.mouse.getY() - selectingY) / cellSize)

                selected = love.graphics.newQuad(sheetX * cellSize, sheetY * cellSize, cellSize, cellSize, assets:getDimensions())
                state = "drawing"
            end
        elseif state == "drawing" then
            local gridX = math.floor(maid64.mouse.getX() / cellSize) + 1
            local gridY = math.floor(maid64.mouse.getY() / cellSize) + 1

            if gridX >= 1 and gridX <= gridWidth and gridY >= 1 and gridY <= gridHeight then
                grid[gridX][gridY] = selected
            end
        end
    elseif button == 2 then
        local gridX = math.floor(maid64.mouse.getX() / cellSize) + 1
        local gridY = math.floor(maid64.mouse.getY() / cellSize) + 1

        if gridX >= 1 and gridX <= gridWidth and gridY >= 1 and gridY <= gridHeight then
            grid[gridX][gridY] = nil
        end
    end
end

function love.resize(w, h)
    maid64.resize(w, h)
end
