local Object = require("classic")
local scaler = require("scaler")

-- CONSTANTS

local WIDTH, HEIGHT = 256, 256
local CELL_SIZE = 16

local STATES = {
    AREAS = 1,
    EDIT = 2,
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
local newAreaId = 1

local prevMouseState = {false, false, false}

local selectedTile = nil

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

function mousepressed(button)
    local state = love.mouse.isDown(button)

    if state and not prevMouseState[button] then
        prevMouseState[button] = true
        return true
    else
        prevMouseState[button] = state
    end

    return false
end

function button(x, y, w, h, text)
    local mouseX = scaler.mouse.getX()
    local mouseY = scaler.mouse.getY()

    if mouseX >= x and mouseX <= x + w and mouseY >= y and mouseY <= y + h then
        love.graphics.setColor(0.8, 0.8, 0.8)
    end

    love.graphics.rectangle("line", x, y, w, h, 4, 4)
    love.graphics.print(text, x + w / 2 - math.floor(font:getWidth(text) / 2), y + h / 2 - math.floor(font:getHeight() / 2))

    love.graphics.setColor(1, 1, 1)

    return mouseX >= x and mouseX <= x + w and mouseY >= y and mouseY <= y + h and mousepressed(1)
end

function love.draw()
    scaler.start()

    love.graphics.clear(145 / 255, 183 / 255, 201 / 255)

    if state == STATES.AREAS then
        areas[currentArea]:draw()

        if button(10, 10, 200, 30, areas[currentArea].name) then
        end

        if button(WIDTH - 40, 10, 30, 30, "+") then
            table.insert(areas, Area("New Area " .. newAreaId))
            newAreaId = newAreaId + 1
            currentArea = #areas
        end

        if button(10, HEIGHT - 40, 30, 30, "<") then
            currentArea = currentArea - 1
            if currentArea < 1 then
                currentArea = #areas
            end
        end

        if button(WIDTH - 40, HEIGHT - 40, 30, 30, ">") then
            currentArea = currentArea + 1
            if currentArea > #areas then
                currentArea = 1
            end
        end

        if button(WIDTH / 2 - 50, HEIGHT - 40, 100, 30, "Edit") then
            state = STATES.EDIT
            selectedTile = Tile(assets, 4, 4)
        end
    elseif state == STATES.EDIT then
        areas[currentArea]:draw()

        local gridX = math.floor(scaler.mouse.getX() / CELL_SIZE)
        local gridY = math.floor(scaler.mouse.getY() / CELL_SIZE)

        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.draw(assets, selectedTile.quad, gridX * CELL_SIZE, gridY * CELL_SIZE)
        love.graphics.setColor(1, 1, 1)

        if love.keyboard.isDown("escape") then
            state = STATES.AREAS
        end
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
    elseif state == STATES.EDIT then
        if key == "escape" then
            state = STATES.AREAS
        end
    end
end

function love.mousepressed(x, y, button)
    if state == STATES.EDIT then
        local gridX = math.floor(scaler.mouse.getX() / CELL_SIZE) + 1
        local gridY = math.floor(scaler.mouse.getY() / CELL_SIZE) + 1
        areas[currentArea]:setTile(gridX, gridY, selectedTile)
    end
end

function love.resize(w, h)
    scaler.resize(w, h)
end
