local tool = Tool:extend("Selection")

-- Methods ======================================
function tool:disabled()
    if project.selection then
        placeSelection()
    end
end

function tool:draw()
    local tx, ty = mouseOverTile()

    if not self.selectTileI then
        drawMouseOverTile()
    elseif tx then
		local room = activeRoom()
        local i, j, w, h = rectCont2Tiles(tx, ty, self.selectTileI, self.selectTileJ)
        drawColoredRect(room.x+i*8, room.y+j*8, w*8, h*8, {0, 1, 0.5}, false)
    end
end

function tool:mousepressed(x, y, button)
    local tx, ty = mouseOverTile()
    local mx, my = fromScreen(x, y)

    if button == 1 then
        if not project.selection then
            if tx then
                self.selectTileI, self.selectTileJ = tx, ty
            end
        else
            self.selectionMoveX,  self.selectionMoveY  = mx - project.selection.x, my - project.selection.y
            self.selectionStartX, self.selectionStartY = project.selection.x, project.selection.y
        end
    end
end

function tool:mousereleased(x, y, button)
    local tx, ty = mouseOverTile()

    if tx and self.selectTileI then
        placeSelection()

        select(tx, ty, self.selectTileI, self.selectTileJ)
    end

    if project.selection and self.selectionMoveX then
        if project.selection.x == self.selectionStartX and project.selection.y == self.selectionStartY then
            placeSelection()
        end
    end

    self.selectTileI,    self.selectTileJ    = nil, nil
    self.selectionMoveX, self.selectionMoveY = nil, nil
end

function tool:mousemoved(x, y, dx, dy)
    local mx, my = fromScreen(x, y)

    if self.selectionMoveX and project.selection then
        project.selection.x = roundto8(mx - self.selectionMoveX)
        project.selection.y = roundto8(my - self.selectionMoveY)
    end
end


-- Return =======================================
return tool