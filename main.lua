local utf8 = require("utf8")

local Object = require("classic")
local scaler = require("scaler")

-- CONSTANTS

local WIDTH, HEIGHT = 256, 256
local CELL_SIZE = 16

local STATES = {
    AREAS = 1,
    EDIT = 2,
    EDITCOLL = 3,
    EDITMENU = 4,
    SELECT = 5,
    PLAY = 6,
    COLORPICKER = 7,
    SETTINGS = 8,
}

-- CLASSES

local Tile = Object:extend()

function Tile:new(spritesheet, sheetX, sheetY)
    self.spritesheet = spritesheet
    self.quad = love.graphics.newQuad(sheetX * CELL_SIZE, sheetY * CELL_SIZE, CELL_SIZE, CELL_SIZE, self.spritesheet:getDimensions())
end

local Entity = Tile:extend()

function Entity:new(spritesheet, sheetX, sheetY)
    Entity.super.new(self, spritesheet, sheetX, sheetY)
end

local Area = Object:extend()

function Area:new(name)
    self.name = name
    self.background = {145 / 255, 183 / 255, 201 / 255}

    self.grid = {}

    for x = 1, WIDTH / CELL_SIZE do
        self.grid[x] = {}
        for y = 1, HEIGHT / CELL_SIZE do
            self.grid[x][y] = nil
        end
    end

    self.entities = {}

    for x = 1, WIDTH / CELL_SIZE do
        self.entities[x] = {}
        for y = 1, HEIGHT / CELL_SIZE do
            self.entities[x][y] = nil
        end
    end

    self.collision = {}

    for x = 1, WIDTH / CELL_SIZE do
        self.collision[x] = {}
        for y = 1, HEIGHT / CELL_SIZE do
            self.collision[x][y] = false
        end
    end
end

function Area:setTile(x, y, tile)
    if x >= 1 and x <= WIDTH / CELL_SIZE and y >= 1 and y <= HEIGHT / CELL_SIZE then
        self.grid[x][y] = tile
    end
end

function Area:setEntity(x, y, entity)
    if x >= 1 and x <= WIDTH / CELL_SIZE and y >= 1 and y <= HEIGHT / CELL_SIZE then
        self.entities[x][y] = entity
    end
end

function Area:setCollision(x, y, collision)
    if x >= 1 and x <= WIDTH / CELL_SIZE and y >= 1 and y <= HEIGHT / CELL_SIZE then
        self.collision[x][y] = collision
    end
end

function Area:draw()
    love.graphics.clear(self.background[1], self.background[2], self.background[3])

    for x = 1, WIDTH / CELL_SIZE do
        for y = 1, HEIGHT / CELL_SIZE do
            local tile = self.grid[x][y]
            if tile then
                love.graphics.draw(tile.spritesheet, tile.quad, (x - 1) * CELL_SIZE, (y - 1) * CELL_SIZE)
            end
        end
    end

    for x = 1, WIDTH / CELL_SIZE do
        for y = 1, HEIGHT / CELL_SIZE do
            local entity = self.entities[x][y]
            if entity then
                love.graphics.draw(entity.spritesheet, entity.quad, (x - 1) * CELL_SIZE, (y - 1) * CELL_SIZE)
            end
        end
    end
end

-- GLOBALS

local areas = {
    Area("Test Area"),
}

local currentArea = 1
local state = STATES.AREAS
local newAreaId = 1

local prevMouseState = {false, false, false}

local selectedTile = nil
local selectX = 0
local selectY = 0

local delayT = 0

local selectedColor = {1, 1, 1}

local editing = false
local editbuffer = ""

-- ASSETS

local assets = scaler.newImage("roguelike.png")

local cursor = scaler.newImage("cursor.png")
love.mouse.setVisible(false)

local font = love.graphics.newFont(10, "mono")
love.graphics.setFont(font)

-- SETUP

local spawnArea = 1
local spawnX = 4
local spawnY = 4

local player = {
    area = spawnArea,
    x = spawnX,
    y = spawnY,
    spritesheet = assets,
    quad = love.graphics.newQuad(18 * CELL_SIZE, 32 * CELL_SIZE, CELL_SIZE, CELL_SIZE, assets:getDimensions()),
    flip = false,
}

love.keyboard.setKeyRepeat(true)

scaler.setup(WIDTH, HEIGHT)

local function mousepressed(button)
    local state = love.mouse.isDown(button)

    if state and not prevMouseState[button] then
        prevMouseState[button] = true
        return true
    else
        prevMouseState[button] = state
    end

    return false
end

local function button(x, y, w, h, text)
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

local function slider(x, y, value, max)
    local mouseX = scaler.mouse.getX()
    local mouseY = scaler.mouse.getY()

    love.graphics.rectangle("fill", x, y, 100, 10)
    love.graphics.setColor(0, 0, 0)
    local sliderPos = (value / max) * 100
    love.graphics.rectangle("fill", x + sliderPos - 5, y - 2, 10, 14)

    if mouseX >= x and mouseX <= x + 100 and mouseY >= y and mouseY <= y + 10 and love.mouse.isDown(1) then
        value = (mouseX - x) / 100 * max
    end

    love.graphics.setColor(1, 1, 1)

    return math.min(math.max(value, 0), max)
end

function love.update(dt)
    delayT = delayT + dt

    if state == STATES.EDIT then
        if love.mouse.isDown(1) and delayT > 0.2 then
            local gridX = math.floor(scaler.mouse.getX() / CELL_SIZE) + 1
            local gridY = math.floor(scaler.mouse.getY() / CELL_SIZE) + 1
            areas[currentArea]:setTile(gridX, gridY, selectedTile)
        elseif love.mouse.isDown(2) then
            local gridX = math.floor(scaler.mouse.getX() / CELL_SIZE) + 1
            local gridY = math.floor(scaler.mouse.getY() / CELL_SIZE) + 1
            areas[currentArea]:setTile(gridX, gridY, nil)
        end
    elseif state == STATES.EDITCOLL then
        if love.mouse.isDown(1) and delayT > 0.2 then
            local gridX = math.floor(scaler.mouse.getX() / CELL_SIZE) + 1
            local gridY = math.floor(scaler.mouse.getY() / CELL_SIZE) + 1
            areas[currentArea]:setCollision(gridX, gridY, true)
        elseif love.mouse.isDown(2) then
            local gridX = math.floor(scaler.mouse.getX() / CELL_SIZE) + 1
            local gridY = math.floor(scaler.mouse.getY() / CELL_SIZE) + 1
            areas[currentArea]:setCollision(gridX, gridY, false)
        end
    elseif state == STATES.SELECT then
        if love.keyboard.isDown("w") then
            selectY = selectY + 2
        elseif love.keyboard.isDown("s") then
            selectY = selectY - 2
        end

        if love.keyboard.isDown("a") then
            selectX = selectX + 2
        elseif love.keyboard.isDown("d") then
            selectX = selectX - 2
        end
    elseif state == STATES.COLORPICKER then
        selectedColor[1] = slider(50, 50, selectedColor[1], 1)
        selectedColor[2] = slider(50, 80, selectedColor[2], 1)
        selectedColor[3] = slider(50, 110, selectedColor[3], 1)
    end
end

function love.draw()
    scaler.start()

    if state == STATES.AREAS then
        areas[currentArea]:draw()

        for x = 1, WIDTH / CELL_SIZE do
            for y = 1, HEIGHT / CELL_SIZE do
                if x == spawnX and y == spawnY and currentArea == spawnArea then
                    love.graphics.setColor(0, 0, 1, 0.5)
                    love.graphics.rectangle("fill", (x - 1) * CELL_SIZE, (y - 1) * CELL_SIZE, CELL_SIZE, CELL_SIZE)
                    love.graphics.setColor(1, 1, 1)
                end
            end
        end

        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", 0, 0, WIDTH, HEIGHT)
        love.graphics.setColor(1, 1, 1)

        if editing then
            if math.floor(delayT * 2) % 2 == 0 then
                love.graphics.rectangle("line", 10, 10, 200, 30, 4, 4)
            end
            love.graphics.print(editbuffer, 10 + 200 / 2 - math.floor(font:getWidth(editbuffer) / 2), 10 + 30 / 2 - math.floor(font:getHeight() / 2))
        else
            if button(10, 10, 200, 30, areas[currentArea].name) then
                editing = true
            end
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
            state = STATES.EDITMENU
            delayT = 0
            selectedTile = Tile(assets, 4, 4)
        end

        if button(WIDTH / 2 - 30, HEIGHT - 140, 60, 20, "Play") then
            state = STATES.PLAY
            player.area = spawnArea
            player.x = spawnX
            player.y = spawnY
        end

        if button(WIDTH / 2 - 30, HEIGHT - 110, 60, 20, "Settings") then
            state = STATES.SETTINGS
        end
    elseif state == STATES.EDIT then
        areas[currentArea]:draw()

        for x = 1, WIDTH / CELL_SIZE do
            for y = 1, HEIGHT / CELL_SIZE do
                if x == spawnX and y == spawnY and currentArea == spawnArea then
                    love.graphics.setColor(0, 0, 1, 0.5)
                    love.graphics.rectangle("fill", (x - 1) * CELL_SIZE, (y - 1) * CELL_SIZE, CELL_SIZE, CELL_SIZE)
                    love.graphics.setColor(1, 1, 1)
                end
            end
        end

        local gridX = math.floor(scaler.mouse.getX() / CELL_SIZE)
        local gridY = math.floor(scaler.mouse.getY() / CELL_SIZE)

        if love.mouse.isDown(2) then
            love.graphics.setColor(1, 0, 0, 0.5)
        else
            love.graphics.setColor(1, 1, 1, 0.5)
        end

        love.graphics.draw(assets, selectedTile.quad, gridX * CELL_SIZE, gridY * CELL_SIZE)
        love.graphics.setColor(1, 1, 1)
    elseif state == STATES.EDITCOLL then
        areas[currentArea]:draw()

        for x = 1, WIDTH / CELL_SIZE do
            for y = 1, HEIGHT / CELL_SIZE do
                local coll = areas[currentArea].collision[x][y]
                if coll then
                    love.graphics.setColor(1, 0, 0, 0.5)
                    love.graphics.rectangle("fill", (x - 1) * CELL_SIZE, (y - 1) * CELL_SIZE, CELL_SIZE, CELL_SIZE)
                    love.graphics.setColor(1, 1, 1)
                end
            end
        end

        local gridX = math.floor(scaler.mouse.getX() / CELL_SIZE)
        local gridY = math.floor(scaler.mouse.getY() / CELL_SIZE)

        love.graphics.setColor(1, 0, 0, 0.5)
        love.graphics.rectangle("fill", gridX * CELL_SIZE, gridY * CELL_SIZE, CELL_SIZE, CELL_SIZE)
        love.graphics.setColor(1, 1, 1)
    elseif state == STATES.EDITMENU then
        areas[currentArea]:draw()

        for x = 1, WIDTH / CELL_SIZE do
            for y = 1, HEIGHT / CELL_SIZE do
                if x == spawnX and y == spawnY and currentArea == spawnArea then
                    love.graphics.setColor(0, 0, 1, 0.5)
                    love.graphics.rectangle("fill", (x - 1) * CELL_SIZE, (y - 1) * CELL_SIZE, CELL_SIZE, CELL_SIZE)
                    love.graphics.setColor(1, 1, 1)
                end
            end
        end

        love.graphics.print("Press SPACE to start editing", 10, 10)

        if button(10, HEIGHT - 40, 60, 30, "Sprites") then
            state = STATES.SELECT
        end

        if button(WIDTH - 70, HEIGHT - 40, 60, 30, "Collision") then
            state = STATES.EDITCOLL
            delayT = 0
        end

        if button(WIDTH / 2 - 50, HEIGHT - 40, 100, 30, "Background") then
            state = STATES.COLORPICKER
        end
    elseif state == STATES.SELECT then
        love.graphics.clear(areas[currentArea].background[1], areas[currentArea].background[2], areas[currentArea].background[3])

        love.graphics.draw(assets, selectX, selectY)

        local sheetX = math.floor((scaler.mouse.getX() - selectX) / CELL_SIZE)
        local sheetY = math.floor((scaler.mouse.getY() - selectY) / CELL_SIZE)

        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.rectangle("line", selectX + sheetX * CELL_SIZE, selectY + sheetY * CELL_SIZE, CELL_SIZE, CELL_SIZE)
        love.graphics.setColor(1, 1, 1)
    elseif state == STATES.PLAY then
        areas[player.area]:draw()

        if (player.flip) then
            love.graphics.draw(player.spritesheet, player.quad, (player.x) * CELL_SIZE, (player.y - 1) * CELL_SIZE, 0, -1, 1)
        else
            love.graphics.draw(player.spritesheet, player.quad, (player.x - 1) * CELL_SIZE, (player.y - 1) * CELL_SIZE)
        end
    elseif state == STATES.COLORPICKER then
        love.graphics.clear(0.5, 0.5, 0.5)

        love.graphics.print("Color Picker: Use sliders to adjust RGB", 10, 10)
        love.graphics.print("Red: " .. math.floor(selectedColor[1] * 255), 10, 50)
        love.graphics.print("Green: " .. math.floor(selectedColor[2] * 255), 10, 80)
        love.graphics.print("Blue: " .. math.floor(selectedColor[3] * 255), 10, 110)

        -- Draw RGB sliders
        selectedColor[1] = slider(150, 50, selectedColor[1], 1)
        selectedColor[2] = slider(150, 80, selectedColor[2], 1)
        selectedColor[3] = slider(150, 110, selectedColor[3], 1)

        -- Show preview of the selected color
        love.graphics.setColor(selectedColor[1], selectedColor[2], selectedColor[3])
        love.graphics.rectangle("fill", 50, 150, 100, 50)
        love.graphics.setColor(1, 1, 1)

        love.graphics.print("Press Enter to apply color, Esc to cancel", 10, 200)
    elseif state == STATES.SETTINGS then
        love.graphics.clear(0.5, 0.5, 0.5)

        if button(10, 10, 100, 30, "Back") then
            state = STATES.AREAS
        end

        -- change title and player sprite
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
        if editing then
            if key == "return" then
                areas[currentArea].name = editbuffer
                editing = false
                editbuffer = ""
            elseif key == "escape" then
                editing = false
                editbuffer = ""
            elseif key == "backspace" then
                local byteoffset = utf8.offset(editbuffer, -1)

                if byteoffset then
                    editbuffer = string.sub(editbuffer, 1, byteoffset - 1)
                end
            end
        end
    elseif state == STATES.EDIT then
        if key == "e" then
            state = STATES.SELECT
        elseif key == "space" then
            state = STATES.EDITMENU
        end
    elseif state == STATES.EDITCOLL then
        if key == "escape" then
            state = STATES.EDITMENU
        end
    elseif state == STATES.EDITMENU then
        if key == "space" then
            state = STATES.EDIT
        elseif key == "escape" then
            state = STATES.AREAS
        end
    elseif state == STATES.SELECT then
        if key == "escape" then
            state = STATES.EDITMENU
        end
    elseif state == STATES.PLAY then
        if key == "escape" then
            state = STATES.AREAS
            editing = false
        end

        if key == "w" then
            if player.y > 1 and areas[player.area].collision[player.x][player.y - 1] == false then
                player.y = player.y - 1
            end
        elseif key == "s" then
            if player.y < HEIGHT / CELL_SIZE and areas[player.area].collision[player.x][player.y + 1] == false then
                player.y = player.y + 1
            end
        elseif key == "a" then
            if player.x > 1 and areas[player.area].collision[player.x - 1][player.y] == false then
                player.x = player.x - 1
            end
            player.flip = false
        elseif key == "d" then
            if player.x < WIDTH / CELL_SIZE and areas[player.area].collision[player.x + 1][player.y] == false then
                player.x = player.x + 1
            end
            player.flip = true
        end
    elseif state == STATES.COLORPICKER then
        if key == "return" then
            areas[currentArea].background = {selectedColor[1], selectedColor[2], selectedColor[3]}
            state = STATES.EDITMENU
        elseif key == "escape" then
            state = STATES.EDITMENU
        end
    end
end

function love.mousepressed(x, y, button)
    if state == STATES.SELECT then
        if button == 1 then
            local sheetX = math.floor((scaler.mouse.getX() - selectX) / CELL_SIZE)
            local sheetY = math.floor((scaler.mouse.getY() - selectY) / CELL_SIZE)
            selectedTile = Tile(assets, sheetX, sheetY)
            state = STATES.EDIT
            delayT = 0

            print(sheetX, sheetY)
        end
    elseif state == STATES.EDIT then
        if button == 3 then
            local gridX = math.floor(scaler.mouse.getX() / CELL_SIZE) + 1
            local gridY = math.floor(scaler.mouse.getY() / CELL_SIZE) + 1
            spawnArea = currentArea
            spawnX = gridX
            spawnY = gridY
        end
    end
end

function love.textinput(text)
    if state == STATES.AREAS then
        if editing and font:getWidth(editbuffer .. text) < 180 then
            editbuffer = editbuffer .. text
        end
    end
end

function love.resize(w, h)
    scaler.resize(w, h)
end
