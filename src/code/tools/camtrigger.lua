local tool = Tool:extend("Camera Trigger")

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
    local ti, tj = mouseOverTile()

    if not self.camtriggerI then
        drawMouseOverTile({1,0.75,0})
    elseif ti then
        local i, j, w, h = rectCont2Tiles(ti, tj, self.camtriggerI, self.camtriggerJ)
        drawColoredRect(activeRoom(), i*8, j*8, w*8, h*8, {1,0.75,0}, false)
    end
end

function tool:mousepressed(x, y, button)
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

function tool:mousemoved(x,y)
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

function tool:mousereleased(x, y, button)
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

-- Return =======================================
return tool