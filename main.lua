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
    ENTITIES = 9,
    DIALOGUEEDITOR = 10,
    ENTITYSELECT = 11,
    DIALOGUE = 12,
}

-- ASSETS

local assets = scaler.newImage("roguelike.png")

local cursor = scaler.newImage("cursor.png")
love.mouse.setVisible(false)

local font = love.graphics.newFont(10, "mono")
love.graphics.setFont(font)

-- CLASSES

local Dialogue = Object:extend()

function Dialogue:new(script)
    self.script = script
    self.segments = self:parse(script)

    for _, segment in ipairs(self.segments) do
        if segment.type == "wavy" or segment.type == "shaky" then
            segment.timeOffset = math.random() * 20
        end
    end
end

function Dialogue:parse(script)
    local segments = {}

    local i = 1
    while i <= #script do
        local wvyStart, wvyEnd = script:find("{wvy}", i)
        local shkStart, shkEnd = script:find("{shk}", i)
        local rbwStart, rbwEnd = script:find("{rbw}", i)
        local wvyCloseStart, wvyCloseEnd = script:find("{/wvy}", i)
        local shkCloseStart, shkCloseEnd = script:find("{/shk}", i)
        local rbwCloseStart, rbwCloseEnd = script:find("{/rbw}", i)

        if wvyStart and wvyCloseStart then
            if wvyStart > i then
                table.insert(segments, {type = "normal", content = script:sub(i, wvyStart - 1)})
            end
            table.insert(segments, {type = "wavy", content = script:sub(wvyEnd + 1, wvyCloseStart - 1)})
            i = wvyCloseEnd + 1
        elseif shkStart and shkCloseStart then
            if shkStart > i then
                table.insert(segments, {type = "normal", content = script:sub(i, shkStart - 1)})
            end
            table.insert(segments, {type = "shaky", content = script:sub(shkEnd + 1, shkCloseStart - 1)})
            i = shkCloseEnd + 1
        elseif rbwStart and rbwCloseStart then
            if rbwStart > i then
                table.insert(segments, {type = "normal", content = script:sub(i, rbwStart - 1)})
            end
            table.insert(segments, {type = "rainbow", content = script:sub(rbwEnd + 1, rbwCloseStart - 1)})
            i = rbwCloseEnd + 1
        else
            table.insert(segments, {type = "normal", content = script:sub(i)})
            break
        end
    end

    return segments
end

function Dialogue:drawWavy(text, x, y, timeOffset)
    local freq = 4
    local amp = 4

    for i = 1, #text do
        local char = text:sub(i, i)
        local charX = x + font:getWidth(text:sub(1, i - 1))
        local offsetY = math.sin((love.timer.getTime() * freq) + timeOffset + (i * 0.5)) * amp
        love.graphics.print(char, charX, y + offsetY)
    end
end

function Dialogue:drawShaky(text, x, y)
    for i = 1, #text do
        local char = text:sub(i, i)
        local charX = x + font:getWidth(text:sub(1, i - 1))
        local offsetX = math.random(-1, 1)
        local offsetY = math.random(-1, 1)
        love.graphics.print(char, charX + offsetX, y + offsetY)
    end
end

function Dialogue:drawRainbow(text, x, y)
    for i = 1, #text do
        local char = text:sub(i, i)
        local charX = x + font:getWidth(text:sub(1, i - 1))

        local r = math.sin(i * 0.3 + love.timer.getTime() * 5) * 0.5 + 0.5
        local g = math.sin(i * 0.3 + love.timer.getTime() * 5 + (2 * math.pi / 3)) * 0.5 + 0.5
        local b = math.sin(i * 0.3 + love.timer.getTime() * 5 + (4 * math.pi / 3)) * 0.5 + 0.5

        love.graphics.setColor(r, g, b)
        love.graphics.print(char, charX, y)
    end
    love.graphics.setColor(1, 1, 1)
end

function Dialogue:draw()
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, HEIGHT - 80, WIDTH, 80)
    love.graphics.setColor(1, 1, 1)

    local currentX = 10
    for _, segment in ipairs(self.segments) do
        if segment.type == "normal" then
            love.graphics.print(segment.content, currentX, HEIGHT - 70)
            currentX = currentX + font:getWidth(segment.content)
        elseif segment.type == "wavy" then
            self:drawWavy(segment.content, currentX, HEIGHT - 70, segment.timeOffset)
            currentX = currentX + font:getWidth(segment.content)
        elseif segment.type == "shaky" then
            self:drawShaky(segment.content, currentX, HEIGHT - 70)
            currentX = currentX + font:getWidth(segment.content)
        elseif segment.type == "rainbow" then
            self:drawRainbow(segment.content, currentX, HEIGHT - 70)
            currentX = currentX + font:getWidth(segment.content)
        end
    end
end

local Tile = Object:extend()

function Tile:new(spritesheet, sheetX, sheetY)
    self.spritesheet = spritesheet
    self.quad = love.graphics.newQuad(sheetX * CELL_SIZE, sheetY * CELL_SIZE, CELL_SIZE, CELL_SIZE, self.spritesheet:getDimensions())
end

local Entity = Tile:extend()

function Entity:new(spritesheet, sheetX, sheetY, dialogue)
    Entity.super.new(self, spritesheet, sheetX, sheetY)
    self.dialogue = dialogue
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

local entities = {
    Entity(assets, 18, 27, Dialogue("{shk}HELLOO{/shk} how are {rbw}YOU{/rbw}??")),
}

local currentArea = 1
local currentEntity = 1

local state = STATES.AREAS
local newAreaId = 1

local prevMouseState = {false, false, false}

local selectedTile = nil
local selectX = 0
local selectY = 0

local selectedEntity = nil

local delayT = 0

local selectedColor = {1, 1, 1}

local editing = false
local editbuffer = ""

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

local interactingEntity = nil

-- SETUP

areas[currentArea]:setEntity(6, 4, entities[1]) -- test

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
            if selectedEntity then
                local gridX = math.floor(scaler.mouse.getX() / CELL_SIZE) + 1
                local gridY = math.floor(scaler.mouse.getY() / CELL_SIZE) + 1
                areas[currentArea]:setEntity(gridX, gridY, selectedEntity)

                delayT = 0
                selectedEntity = nil
            else
                local gridX = math.floor(scaler.mouse.getX() / CELL_SIZE) + 1
                local gridY = math.floor(scaler.mouse.getY() / CELL_SIZE) + 1
                areas[currentArea]:setTile(gridX, gridY, selectedTile)
            end
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

        if button(WIDTH / 2 - 30, HEIGHT - 160, 60, 20, "Play") then
            state = STATES.PLAY
            player.area = spawnArea
            player.x = spawnX
            player.y = spawnY
        end

        if button(WIDTH / 2 - 30, HEIGHT - 130, 60, 20, "Entities") then
            state = STATES.ENTITIES
        end

        if button(WIDTH / 2 - 30, HEIGHT - 100, 60, 20, "Settings") then
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

        if selectedEntity then
            love.graphics.draw(assets, selectedEntity.quad, gridX * CELL_SIZE, gridY * CELL_SIZE)
        else
            love.graphics.draw(assets, selectedTile.quad, gridX * CELL_SIZE, gridY * CELL_SIZE)
        end

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

        if button(WIDTH / 2 - 50, HEIGHT - 80, 100, 30, "Entities") then
            state = STATES.ENTITYSELECT
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
    elseif state == STATES.DIALOGUE then
        areas[player.area]:draw()

        if (player.flip) then
            love.graphics.draw(player.spritesheet, player.quad, (player.x) * CELL_SIZE, (player.y - 1) * CELL_SIZE, 0, -1, 1)
        else
            love.graphics.draw(player.spritesheet, player.quad, (player.x - 1) * CELL_SIZE, (player.y - 1) * CELL_SIZE)
        end

        interactingEntity.dialogue:draw()

        if love.keyboard.isDown("space") then
            state = STATES.PLAY
            interactingEntity = nil
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

        love.graphics.print("Settings", 10, 10)

        -- change title and player sprite
    elseif state == STATES.ENTITIES then
        love.graphics.clear(0.5, 0.5, 0.5)

        love.graphics.print("Entities", 10, 10)

        love.graphics.draw(assets, entities[currentEntity].quad, WIDTH / 2 - CELL_SIZE * 3 / 2, HEIGHT / 2 - CELL_SIZE * 3 / 2, 0, 3, 3)

        if button(WIDTH - 40, 10, 30, 30, "+") then
            table.insert(entities, Entity(assets, 4, 4, Dialogue("Hello!")))
            currentEntity = #entities
        end

        if button(10, HEIGHT / 2 - 15, 30, 30, "<") then
            currentEntity = currentEntity - 1
            if currentEntity < 1 then
                currentEntity = #entities
            end
        end

        if button(WIDTH - 40, HEIGHT / 2 - 15, 30, 30, ">") then
            currentEntity = currentEntity + 1
            if currentEntity > #entities then
                currentEntity = 1
            end
        end

        if button(WIDTH / 2 - 50, HEIGHT - 40, 100, 30, "Dialogue") then
            state = STATES.DIALOGUEEDITOR
        end
    elseif state == STATES.ENTITYSELECT then
        love.graphics.clear(0.5, 0.5, 0.5)

        for i, entity in ipairs(entities) do
            love.graphics.draw(assets, entity.quad, 10 + (i - 1) * 40, 10, 0, 2, 2)

            if button(10 + (i - 1) * 40, 10, 30, 30, "") then
                selectedEntity = entity
                state = STATES.EDIT
                delayT = 0
            end
        end
    elseif state == STATES.DIALOGUEEDITOR then
        love.graphics.clear(0.5, 0.5, 0.5)

        love.graphics.print("Dialogue Editor", 10, 10)

        love.graphics.print("Entity: " .. currentEntity, 10, 40)

        love.graphics.print("Script: ", 10, 70)

        love.graphics.print(entities[currentEntity].dialogue.script, 10, 100)

        if button(WIDTH - 50, 10, 40, 30, "Save") then
            entities[currentEntity].dialogue = Dialogue(entities[currentEntity].dialogue.script)
            state = STATES.ENTITIES
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
            if player.y > 1 and areas[player.area].collision[player.x][player.y - 1] == false and areas[player.area].entities[player.x][player.y - 1] == nil then
                player.y = player.y - 1
            end
        elseif key == "s" then
            if player.y < HEIGHT / CELL_SIZE and areas[player.area].collision[player.x][player.y + 1] == false and areas[player.area].entities[player.x][player.y + 1] == nil then
                player.y = player.y + 1
            end
        elseif key == "a" then
            if player.x > 1 and areas[player.area].collision[player.x - 1][player.y] == false and areas[player.area].entities[player.x - 1][player.y] == nil then
                player.x = player.x - 1
            end
            player.flip = false
        elseif key == "d" then
            if player.x < WIDTH / CELL_SIZE and areas[player.area].collision[player.x + 1][player.y] == false and areas[player.area].entities[player.x + 1][player.y] == nil then
                player.x = player.x + 1
            end
            player.flip = true
        end

        if key == "e" then
            if player.x > 1 and areas[player.area].entities[player.x - 1][player.y] then
                state = STATES.DIALOGUE
                interactingEntity = areas[player.area].entities[player.x - 1][player.y]
            elseif player.x < WIDTH / CELL_SIZE and areas[player.area].entities[player.x + 1][player.y] then
                state = STATES.DIALOGUE
                interactingEntity = areas[player.area].entities[player.x + 1][player.y]
            elseif player.y > 1 and areas[player.area].entities[player.x][player.y - 1] then
                state = STATES.DIALOGUE
                interactingEntity = areas[player.area].entities[player.x][player.y - 1]
            elseif player.y < HEIGHT / CELL_SIZE and areas[player.area].entities[player.x][player.y + 1] then
                state = STATES.DIALOGUE
                interactingEntity = areas[player.area].entities[player.x][player.y + 1]
            end
        end
    elseif state == STATES.COLORPICKER then
        if key == "return" then
            areas[currentArea].background = {selectedColor[1], selectedColor[2], selectedColor[3]}
            state = STATES.EDITMENU
        elseif key == "escape" then
            state = STATES.EDITMENU
        end
    elseif state == STATES.SETTINGS then
        if key == "escape" then
            state = STATES.AREAS
        end
    elseif state == STATES.ENTITIES then
        if key == "escape" then
            state = STATES.AREAS
        end
    elseif state == STATES.DIALOGUEEDITOR then
        if key == "escape" then
            state = STATES.ENTITIES
        elseif key == "backspace" then
            local byteoffset = utf8.offset(entities[currentEntity].dialogue.script, -1)

            if byteoffset then
                entities[currentEntity].dialogue.script = string.sub(entities[currentEntity].dialogue.script, 1, byteoffset - 1)
            end
        end
    elseif state == STATES.ENTITYSELECT then
        if key == "escape" then
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
    elseif state == STATES.DIALOGUEEDITOR then
        entities[currentEntity].dialogue.script = entities[currentEntity].dialogue.script .. text
    end
end

function love.resize(w, h)
    scaler.resize(w, h)
end
