local tool = Tool:extend("Triggers")

-- Methods ======================================
function tool:panel()
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

function tool:draw()
    local tx, ty = mouseOverTile()

    if not self.camtriggerI then
        drawMouseOverTile({1,0.75,0})
    elseif tx then
		local room = activeRoom()
        local i, j, w, h = rectCont2Tiles(tx, ty, self.camtriggerI, self.camtriggerJ)
        drawColoredRect(room.x+i*8, room.y+j*8, w*8, h*8, {1, 0.75, 0}, false)
    end
end

function tool:mousepressed(x, y, button)
    local tx, ty = mouseOverTile()
    if not tx then return end

    local hovered=hoveredTriggerN()
    if button == 1 then
        if love.keyboard.isDown("lctrl") then
            if not selectedTrigger() and hovered then
                app.selectedCamtriggerN = hovered
            end
            if selectedTrigger() then
                self.camtriggerMoveI, self.camtriggerMoveJ = tx, ty
            end
        else
            local hovered = hoveredTriggerN()
            if selectedTrigger() then
                app.selectedCamtriggerN = nil
                --deselect
            elseif hovered then
                app.selectedCamtriggerN = hovered
            else
                self.camtriggerI, self.camtriggerJ = tx, ty
            end
        end
    elseif button == 2 and love.keyboard.isDown("lctrl") then
        if not selectedTrigger() and hovered then
            app.selectedCamtriggerN = hovered
        end
        if selectedTrigger() then
            self.camtriggerSideI = sign(tx - selectedTrigger().x - selectedTrigger().w/2)
            self.camtriggerSideJ = sign(ty - selectedTrigger().y - selectedTrigger().h/2)
        end
        -- app.camtriggerSideI,app.camtriggerSideJ=tx,ty
    end
end

function tool:mousemoved(x,y)
    local tx,ty = mouseOverTile()
    if not tx then return end

    local trigger = selectedTrigger()

    if self.camtriggerMoveI then
        trigger.x=trigger.x+(tx-self.camtriggerMoveI)
        trigger.y=trigger.y+(ty-self.camtriggerMoveJ)
        self.camtriggerMoveI,self.camtriggerMoveJ=tx,ty
    end
    if self.camtriggerSideI then
        if self.camtriggerSideI < 0 then
            local newx = math.min(tx, trigger.x + trigger.w-1)
            trigger.w = trigger.x - newx + trigger.w
            trigger.x = newx
        else
            trigger.w = math.max(tx - trigger.x + 1, 1)
        end
        if self.camtriggerSideJ < 0 then
            local newy = math.min(ty, trigger.y + trigger.h - 1)
            trigger.h = trigger.y - newy + trigger.h
            trigger.y = newy
        else
            trigger.h = math.max(ty - trigger.y + 1, 1)
        end
    end
end

function tool:mousereleased(x, y, button)
    local tx, ty = mouseOverTile()

    if tx and self.camtriggerI then
        local room = activeRoom()
        local i0, j0, w, h = rectCont2Tiles(self.camtriggerI, self.camtriggerJ, tx, ty)
        local trigger={x=i0,y=j0,w=w,h=h,off_x="0",off_y="0"}
        table.insert(room.camtriggers, trigger)
        app.selectedCamtriggerN = #room.camtriggers
    end

    self.camtriggerI,     self.camtriggerJ     = nil, nil
    self.camtriggerMoveI, self.camtriggerMoveJ = nil, nil
    self.camtriggerSideI, self.camtriggerSideJ = nil, nil
end

-- Return =======================================
return tool