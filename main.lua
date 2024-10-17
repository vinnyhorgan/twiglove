local Object = require("classic")
local scaler = require("scaler")

-- CONSTANTS

local WIDTH, HEIGHT = 256, 256
local CELL_SIZE = 16

local STATES = {
    AREAS = 1,
}

-- CLASSES

local Tile = Object:extend()

function Tile:new(spritesheet, sheetX, sheetY)
    self.spritesheet = spritesheet
    self.quad = love.graphics.newQuad(sheetX * CELL_SIZE, sheetY * CELL_SIZE, CELL_SIZE, CELL_SIZE, self.spritesheet:getDimensions())
end

local Area = Object:extend()

function Area:new(name)
    self.name = name
    self.grid = {}

    for x = 1, WIDTH / CELL_SIZE do
        self.grid[x] = {}
        for y = 1, HEIGHT / CELL_SIZE do
            self.grid[x][y] = nil
        end
    end
end

function Area:setTile(x, y, tile)
    if x >= 1 and x <= WIDTH / CELL_SIZE and y >= 1 and y <= HEIGHT / CELL_SIZE then
        self.grid[x][y] = tile
    end
end

function Area:draw()
    for x = 1, WIDTH / CELL_SIZE do
        for y = 1, HEIGHT / CELL_SIZE do
            local tile = self.grid[x][y]
            if tile then
                love.graphics.draw(tile.spritesheet, tile.quad, (x - 1) * CELL_SIZE, (y - 1) * CELL_SIZE)
            end
        end
    end
end

-- GLOBALS

local areas = {
    Area("Test Area 1"),
    Area("Test Area 2"),
}

local currentArea = 1
local state = STATES.AREAS

-- ASSETS

local assets = scaler.newImage("roguelike.png")

local cursor = scaler.newImage("cursor.png")
love.mouse.setVisible(false)

local font = love.graphics.newFont(10, "mono")
love.graphics.setFont(font)

-- SETUP

scaler.setup(WIDTH, HEIGHT)

areas[1]:setTile(1, 1, Tile(assets, 5, 5))
areas[1]:setTile(5, 5, Tile(assets, 5, 5))

function love.draw()
    scaler.start()

    love.graphics.clear(145 / 255, 183 / 255, 201 / 255)

    if state == STATES.AREAS then
        areas[currentArea]:draw()

        love.graphics.rectangle("line", 10, 10, WIDTH - 20, 30, 4, 4)
        love.graphics.print(areas[currentArea].name, WIDTH / 2 - math.floor(font:getWidth(areas[currentArea].name) / 2), 20)
    end

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

        local gridX = math.floor(scaler.mouse.getX() / cellSize)
        local gridY = math.floor(scaler.mouse.getY() / cellSize)

        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.draw(assets, selected, gridX * cellSize, gridY * cellSize)
        love.graphics.setColor(1, 1, 1, 1)
    end

    local mouseX = scaler.mouse.getX()
    local mouseY = scaler.mouse.getY()

    if (mouseX > 0 and mouseX < WIDTH - 1) and (mouseY > 0 and mouseY < HEIGHT - 1) then
        love.graphics.draw(cursor, mouseX - 4, mouseY - 1)
    end

    scaler.finish()
end

function love.keypressed(key)
    if state == STATES.AREAS then
        if key == "a" then
            currentArea = currentArea - 1
            if currentArea < 1 then
                currentArea = #areas
            end
        elseif key == "d" then
            currentArea = currentArea + 1
            if currentArea > #areas then
                currentArea = 1
            end
        end
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
        if state == "selecting" then
            local mouseX = scaler.mouse.getX()
            local mouseY = scaler.mouse.getY()

            if mouseX >= 0 and mouseX <= WIDTH and mouseY >= 0 and mouseY <= HEIGHT then
                local sheetX = math.floor((scaler.mouse.getX() - selectingX) / cellSize)
                local sheetY = math.floor((scaler.mouse.getY() - selectingY) / cellSize)

                selected = love.graphics.newQuad(sheetX * cellSize, sheetY * cellSize, cellSize, cellSize, assets:getDimensions())
                state = "drawing"
            end
        elseif state == "drawing" then
            local gridX = math.floor(scaler.mouse.getX() / cellSize) + 1
            local gridY = math.floor(scaler.mouse.getY() / cellSize) + 1

            if gridX >= 1 and gridX <= gridWidth and gridY >= 1 and gridY <= gridHeight then
                grid[gridX][gridY] = selected
            end
        end
    elseif button == 2 then
        local gridX = math.floor(scaler.mouse.getX() / cellSize) + 1
        local gridY = math.floor(scaler.mouse.getY() / cellSize) + 1

        if gridX >= 1 and gridX <= gridWidth and gridY >= 1 and gridY <= gridHeight then
            grid[gridX][gridY] = nil
        end
    end
end

function love.resize(w, h)
    scaler.resize(w, h)
end
