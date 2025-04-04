local tool = Tool:extend("Rectangle")

-- Methods ======================================
function tool:draw()
    local ti, tj = mouseOverTile()

    if not self.rectangleI then
        drawMouseOverTile(nil, app.currentTile)
    elseif ti then
		local room = activeRoom()
        local i, j, w, h = rectCont2Tiles(ti, tj, self.rectangleI, self.rectangleJ)
        drawColoredRect(room.x+i*8, room.y+j*8, w*8, h*8, {0, 1, 0.5}, false)
    end
end

function tool:mousepressed(x, y, button)
    local ti, tj = mouseOverTile()

    if not ti then return end
    --select tile from map with shift+right click
    if button == 2 and love.keyboard.isDown("lshift","rshift") then
        app.currentTile=activeRoom().data[ti][tj]
    elseif button == 1 or button == 2 then
        self.rectangleI, self.rectangleJ = ti, tj
    end
end

function tool:mousereleased(x, y, button)
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

-- Return =======================================
return tool