tools = {}

-- this defines the order of tools on the panel
toolslist = {"Brush", "Rectangle", "Select", "Camtrigger", "Room", "Project"}
Tool = class("Tool")

function Tool:disabled() end
function Tool:panel() end
function Tool:update() end
function Tool:draw() end
function Tool:mousepressed() end
function Tool:mousereleased() end
function Tool:mousemoved() end

-- tile panel mixin
local autolayout = {{0,  1,  3,  2,  16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27},
                    {4,  5,  7,  6,  28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39},
                    {12, 13, 15, 14, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51},
                    {8,  9,  11, 10, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63}}
TilePanelMx = {}
function TilePanelMx:tilePanel()
    ui:layoutRow("dynamic", 25*global_scale, 3)
    ui:label("Tiles:")
    
	-- Toggles
	app.showExtraTiles = ui:checkbox("Show extra tiles", app.showExtraTiles)
	app.showGarbageTiles = ui:checkbox("Use garbage?", app.showGarbageTiles)

	-- Buttons
    for j = 0, app.showExtraTiles and 15 or 7 do
        ui:layoutRow("static", 8*tms, 8*tms, 16)
        for i = 0, 15 do
            local n = i + j*16

            if tileButton(n, app.currentTile == n and not app.autotile) then
                if self.autotileEditO then
                    if app.autotile then
                        if self.autotileEditO >= 16 and n == 0 then
                            project.conf.autotiles[app.autotile][self.autotileEditO] = nil
                        else
                            project.conf.autotiles[app.autotile][self.autotileEditO] = n
                        end
                    end

                    updateAutotiles()

                    self.autotileEditO = nil
                    app.currentTile = project.conf.autotiles[app.autotile][15]
                else
                    app.currentTile = n
                    app.autotile = nil
                end
            end
        end
    end

    -- autotiles
    ui:layoutRow("dynamic", 25*global_scale, 3)
    ui:label("Autotiles:")
    ui:spacing(1)
    if ui:button("New Autotile") then
        local auto = {[0] = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
        table.insert(project.conf.autotiles, auto)

        updateAutotiles()
    end

    ui:layoutRow("static", 8*tms, 8*tms, #project.conf.autotiles)
    for k, auto in ipairs(project.conf.autotiles) do
        if tileButton(auto[5], app.autotile == k) then
            app.currentTile = auto[15]
            app.autotile = k

            self.autotileEditO = nil
        end
    end

    if app.autotile then
        ui:layoutRow("dynamic", 25*global_scale, 3)
        ui:label("Tileset: (click to edit)")
        ui:spacing(1)
        if ui:button("Delete Autotile") then
            table.remove(project.conf.autotiles, app.autotile)

            updateAutotiles()

            app.autotile = math.max(1, app.autotile - 1)
        end
    end

    -- check for missing autotile! can happen on undo/redo
    if not project.conf.autotiles[app.autotile] then
        app.autotile = nil
    end

    if app.autotile then
        for r = 1, 4 do
            ui:layoutRow("static", 8*tms, 8*tms, 16)
            for i = 1, #autolayout[r] do
                local o = autolayout[r][i]
                if tileButton(project.conf.autotiles[app.autotile][o] or 0, self.autotileEditO == o, o) then
                    self.autotileEditO = o
                end
            end
        end

        ui:layoutRow("dynamic", 50*global_scale, 1)
        ui:label("Autotile draws with the 16 tiles on the left, connecting them to each other and to any of the extra tiles on the right. This allows connecting to other deco tiles and tiles from other tilesets. Also works when erasing.", "wrap")
    end
end



-- Brush

tools.Brush = Tool:extend("Brush"):with(TilePanelMx)

function tools.Brush:panel()
    self:tilePanel()
end

function tools.Brush:update(dt)
    if not ui:windowIsAnyHovered()
    and not love.keyboard.isDown("lalt")
    and not app.suppressMouse
    and (love.mouse.isDown(1) or love.mouse.isDown(2)) then
        local n = app.currentTile
        if love.mouse.isDown(2) then
            n = 0
        end

        local ti, tj = mouseOverTile()
        if not ti then return end

        local room = activeRoom()

        if love.keyboard.isDown("lshift","rshift") and love.mouse.isDown(2) then
            --select tile from map with shift+click
            app.currentTile=activeRoom().data[ti][tj]
        else
            activeRoom().data[ti][tj] = n

            if app.autotile then
                autotileWithNeighbors(activeRoom(), ti, tj, app.autotile)
            end
        end
    end
end

function tools.Brush:draw()
    drawMouseOverTile(nil, app.currentTile)
end



-- Rectangle

tools.Rectangle = Tool:extend("Rectangle"):with(TilePanelMx)

function tools.Rectangle:panel()
    self:tilePanel()
end

function tools.Rectangle:draw()
    local ti, tj = mouseOverTile()

    if not self.rectangleI then
        drawMouseOverTile(nil, app.currentTile)
    elseif ti then
        local i, j, w, h = rectCont2Tiles(ti, tj, self.rectangleI, self.rectangleJ)
        drawColoredRect(activeRoom(), i*8, j*8, w*8, h*8, {0, 1, 0.5}, false)
    end
end

function tools.Rectangle:mousepressed(x, y, button)
    local ti, tj = mouseOverTile()

    if not ti then return end
    --select tile from map with shift+right click
    if button == 2 and love.keyboard.isDown("lshift","rshift") then
        app.currentTile=activeRoom().data[ti][tj]
    elseif button == 1 or button == 2 then
        self.rectangleI, self.rectangleJ = ti, tj
    end
end

function tools.Rectangle:mousereleased(x, y, button)
    local ti, tj = mouseOverTile()

    if ti and self.rectangleI then
        local room = activeRoom()

        local n = app.currentTile
        if button == 2 then
            n = 0
        end

        local i0, j0, w, h = rectCont2Tiles(self.rectangleI, self.rectangleJ, ti, tj)
        for i = i0, i0 + w - 1 do
            for j = j0, j0 + h - 1 do
                room.data[i][j] = n
            end
        end

        if app.autotile then
            for i = i0, i0 + w - 1 do
                autotileWithNeighbors(room, i, j0, app.autotile)
                autotileWithNeighbors(room, i, j0 + h - 1, app.autotile)
            end
            for j = j0 + 1, j0 + h - 2 do
                autotileWithNeighbors(room, i0, j, app.autotile)
                autotileWithNeighbors(room, i0 + w - 1, j, app.autotile)
            end
        end
    end

    self.rectangleI, self.rectangleJ = nil, nil
end



-- Selection

tools.Select = Tool:extend("Selection")

function tools.Select:disabled()
    if project.selection then
        placeSelection()
    end
end

function tools.Select:draw()
    local ti, tj = mouseOverTile()

    if not self.selectTileI then
        drawMouseOverTile()
    elseif ti then
        local i, j, w, h = rectCont2Tiles(ti, tj, self.selectTileI, self.selectTileJ)
        drawColoredRect(activeRoom(), i*8, j*8, w*8, h*8, {0, 1, 0.5}, false)
    end
end

function tools.Select:mousepressed(x, y, button)
    local ti, tj = mouseOverTile()
    local mx, my = fromScreen(x, y)

    if button == 1 then
        if not project.selection then
            if ti then
                self.selectTileI, self.selectTileJ = ti, tj
            end
        else
            self.selectionMoveX,  self.selectionMoveY  = mx - project.selection.x, my - project.selection.y
            self.selectionStartX, self.selectionStartY = project.selection.x, project.selection.y
        end
    end
end

function tools.Select:mousereleased(x, y, button)
    local ti, tj = mouseOverTile()

    if ti and self.selectTileI then
        placeSelection()

        select(ti, tj, self.selectTileI, self.selectTileJ)
    end

    if project.selection and self.selectionMoveX then
        if project.selection.x == self.selectionStartX and project.selection.y == self.selectionStartY then
            placeSelection()
        end
    end

    self.selectTileI,    self.selectTileJ    = nil, nil
    self.selectionMoveX, self.selectionMoveY = nil, nil
end

function tools.Select:mousemoved(x, y, dx, dy)
    local mx, my = fromScreen(x, y)

    if self.selectionMoveX and project.selection then
        project.selection.x = roundto8(mx - self.selectionMoveX)
        project.selection.y = roundto8(my - self.selectionMoveY)
    end
end



-- Camera Trigger

tools.Camtrigger = Tool:extend("Camera Trigger")

function tools.Camtrigger:panel()
    ui:layoutRow("dynamic", 25*global_scale, 1)
    app.showCameraTriggers = ui:checkbox("Show camera triggers when not using the tool",app.showCameraTriggers)
    if selectedTrigger() then
        local trigger = selectedTrigger()

        local editX = {value = trigger.off_x}
        local editY = {value = trigger.off_y}

        ui:layoutRow("dynamic",25*global_scale,4)
        ui:label("x offset","centered")
        ui:edit("simple", editX)
        ui:label("y offset","centered")
        ui:edit("simple", editY)

        trigger.off_x = editX.value
        trigger.off_y = editY.value
    end
end

function tools.Camtrigger:draw()
    local ti, tj = mouseOverTile()

    if not self.camtriggerI then
        drawMouseOverTile({1,0.75,0})
    elseif ti then
        local i, j, w, h = rectCont2Tiles(ti, tj, self.camtriggerI, self.camtriggerJ)
        drawColoredRect(activeRoom(), i*8, j*8, w*8, h*8, {1,0.75,0}, false)
    end
end

function tools.Camtrigger:mousepressed(x, y, button)
    local ti, tj = mouseOverTile()
    if not ti then return end

    local hovered=hoveredTriggerN()
    if button == 1 then
        if love.keyboard.isDown("lctrl") then
            if not selectedTrigger() and hovered then
                app.selectedCamtriggerN = hovered
            end
            if selectedTrigger() then
                self.camtriggerMoveI, self.camtriggerMoveJ = ti, tj
            end
        else
            local hovered = hoveredTriggerN()
            if selectedTrigger() then
                app.selectedCamtriggerN = nil
                --deselect
            elseif hovered then
                app.selectedCamtriggerN = hovered
            else
                self.camtriggerI, self.camtriggerJ = ti, tj
            end
        end
    elseif button == 2 and love.keyboard.isDown("lctrl") then
        if not selectedTrigger() and hovered then
            app.selectedCamtriggerN = hovered
        end
        if selectedTrigger() then
            self.camtriggerSideI = sign(ti - selectedTrigger().x - selectedTrigger().w/2)
            self.camtriggerSideJ = sign(tj - selectedTrigger().y - selectedTrigger().h/2)
        end
        -- app.camtriggerSideI,app.camtriggerSideJ=ti,tj
    end
end

function tools.Camtrigger:mousemoved(x,y)
    local ti,tj = mouseOverTile()
    if not ti then return end

    local trigger = selectedTrigger()

    if self.camtriggerMoveI then
        trigger.x=trigger.x+(ti-self.camtriggerMoveI)
        trigger.y=trigger.y+(tj-self.camtriggerMoveJ)
        self.camtriggerMoveI,self.camtriggerMoveJ=ti,tj
    end
    if self.camtriggerSideI then
        if self.camtriggerSideI < 0 then
            local newx = math.min(ti, trigger.x + trigger.w-1)
            trigger.w = trigger.x - newx + trigger.w
            trigger.x = newx
        else
            trigger.w = math.max(ti - trigger.x + 1, 1)
        end
        if self.camtriggerSideJ < 0 then
            local newy = math.min(tj, trigger.y + trigger.h - 1)
            trigger.h = trigger.y - newy + trigger.h
            trigger.y = newy
        else
            trigger.h = math.max(tj - trigger.y + 1, 1)
        end
    end
end

function tools.Camtrigger:mousereleased(x, y, button)
    local ti, tj = mouseOverTile()

    if ti and self.camtriggerI then
        local room = activeRoom()
        local i0, j0, w, h = rectCont2Tiles(self.camtriggerI, self.camtriggerJ, ti, tj)
        local trigger={x=i0,y=j0,w=w,h=h,off_x="0",off_y="0"}
        table.insert(room.camtriggers, trigger)
        app.selectedCamtriggerN = #room.camtriggers
    end

    self.camtriggerI,     self.camtriggerJ     = nil, nil
    self.camtriggerMoveI, self.camtriggerMoveJ = nil, nil
    self.camtriggerSideI, self.camtriggerSideJ = nil, nil
end



-- Room Properties

tools.Room = Tool:extend("Room")

function tools.Room:panel()
    ui:layoutRow("static", 25*global_scale, 100*global_scale, 2)
    if ui:button("New Room") then
        local x, y = fromScreen(app.W/3, app.H/3)
        local room = newRoom(roundto8(x), roundto8(y), 16, 16)

        room.title = ""

        table.insert(project.rooms, room)
        app.room = #project.rooms
        app.roomAdded = true
    end
    if ui:button("Delete Room") then
        if activeRoom() then
            table.remove(project.rooms, app.room)
            if not activeRoom() then
                app.room = #project.rooms
            end
        end
    end

    local room = activeRoom()
    if room then
        local param_n = math.max(#project.conf.param_names,#room.params)

        local x,y=div8(room.x),div8(room.y)
        local fits_on_map=x>=0 and x+room.w<=128 and y>=0 and y+room.h<=64
        ui:layoutRow("dynamic",25*global_scale,1)
        if not fits_on_map then
            local style={}
            for k,v in pairs({"text normal", "text hover", "text active"}) do
                style[v]="#707070"
            end
            for k,v in pairs({"normal", "hover", "active"}) do
                style[v]=checkmarkWithBg -- show both selected and unselected as having a check to avoid nukelear limitations
                -- kinda hacky but it works decently enough
            end
            ui:stylePush({['checkbox']=style})

        else
            ui:stylePush({})
        end
        room.is_string = ui:checkbox("Store as string", room.is_string or not fits_on_map)
        ui:stylePop()

        ui:layoutRow("dynamic", 25*global_scale, 5)
        ui:label("Level Exits:")
        for _,v in pairs({"left","bottom","right","top"}) do
            room.exits[v] = ui:checkbox(v, room.exits[v])
        end

        for i=1, param_n do
            ui:layoutRow("dynamic", 25*global_scale, {0.25,0.75} )
            ui:label(project.conf.param_names[i] or "")

            local t = {value=room.params[i] or 0}
            ui:edit("field", t)
            room.params[i] = t.value
        end
    end
end



tools.Project = Tool:extend("Project")

function tools.Project:panel()
    ui:layoutRow("static", 25*global_scale, 100*global_scale, 3)
    if ui:button("Open") then
        openFile()
    end
    if ui:button("Save") then
        saveFile(false)
    end
    if ui:button("Save as...") then
        saveFile(true)
    end

    ui:layoutRow("dynamic", 25*global_scale,3)
    ui:label("Encode string levels as:")

    -- local radio_state={Base256= not app.store_strings_as_hex, Hex=app.store_strings_as_hex}
    local radio_state= {value=app.store_strings_as_hex and "Hex" or "Base256"}
    ui:radio("Base256", radio_state)
    ui:radio("Hex", radio_state)
    app.store_strings_as_hex = radio_state.value=="Hex"

    ui:layoutRow("dynamic", 25*global_scale, {0.8, 0.1, 0.1})
    ui:label("Room parameter names:")
    if ui:button("+") then
        table.insert(project.conf.param_names, "")
    end
    if ui:button("-") then
        table.remove(project.conf.param_names, #project.param_names)
    end
    for i = 1, #project.conf.param_names do
        ui:layoutRow("dynamic", 25*global_scale, 1)

        local t = {value=project.conf.param_names[i]}
        ui:edit("field", t)
        project.conf.param_names[i] = t.value
    end
end
