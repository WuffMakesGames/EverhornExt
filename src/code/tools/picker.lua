local tool = Tool:extend("Brush")

-- Methods ======================================
function tool:update(dt)
    if not ui:windowIsAnyHovered()
    and not love.keyboard.isDown("lalt")
    and not app.suppressMouse
    and (love.mouse.isDown(1) or love.mouse.isDown(2)) then
        local n = app.currentTile
        if love.mouse.isDown(2) then
            n = 0
        end

        local tx, ty = mouseOverTile()
        if not tx then return end

        local room = activeRoom()

        if love.keyboard.isDown("lshift","rshift") and love.mouse.isDown(2) then
            --select tile from map with shift+click
            app.currentTile=activeRoom().data[tx][ty]
        else
            activeRoom().data[tx][ty] = n

            if app.autotile then
                autotileWithNeighbors(activeRoom(), tx, ty, app.autotile)
            end
        end
    end
end

function tool:draw()
    drawMouseOverTile(nil, app.currentTile)
end

-- Return =======================================
return tool