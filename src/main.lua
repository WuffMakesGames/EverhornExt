nuklear = require("nuklear")
filedialog = require("code/filedialog")
serpent = require("libraries/serpent")
class = require("libraries/30log")

require("main/globals")

require("code/util")
require("code/room")
require("code/autotiles")
require("code/tools")
require("code/ui_helpers")
formats = require("code/formats")

-- New Project ==================================
function newProject()
    app = require("main/app")
    project = require("main/project")
    p8data = require("main/p8data")

	-- User interface ===========================
    love.graphics.setNewFont(12*global_scale)
    ui:stylePush({['font']=app.font})
end

function toScreen(x, y)
    return (app.camX + x) * app.camScale + app.left,
           (app.camY + y) * app.camScale + app.top
end

function fromScreen(x, y)
    return (x - app.left)/app.camScale - app.camX,
           (y - app.top)/app.camScale - app.camY
end

function activeRoom()
    return app.room and project.rooms[app.room]
end

function mouseOverTile()
    if activeRoom() then
        local x, y = love.mouse.getPosition()
        local mx, my = fromScreen(x, y)
        local tx, ty = div8(mx - activeRoom().x), div8(my - activeRoom().y)
        if tx >= 0 and tx < activeRoom().w and ty >= 0 and ty < activeRoom().h then
            return tx, ty
        end
    end
end

function drawMouseOverTile(col, tile)
    local col = col or {0, 1, 0.5}

    local tx, ty = mouseOverTile()
    if tx then
        love.graphics.setColor(1, 1, 1)
        if tile then
            local x, y=activeRoom().x + tx*8, activeRoom().y + ty*8
            love.graphics.draw(p8data.spritesheet, p8data.quads[tile], x,y)
            drawCompositeShape(tile,x,y)
        end

        love.graphics.setColor(col)
        love.graphics.setLineWidth(1 / app.camScale)
        love.graphics.rectangle("line", activeRoom().x + tx*8 + 0.5 / app.camScale,
                                        activeRoom().y + ty*8 + 0.5 / app.camScale, 8, 8)
    end
end

function drawColoredRect(x, y, w, h, col, filled)
    love.graphics.setColor(col)
    love.graphics.setLineWidth(1 / app.camScale)
    love.graphics.rectangle("line", x + 0.5 / app.camScale,
                                    y + 0.5 / app.camScale,
                                    w, h)
    if filled then
        love.graphics.setColor(col[1], col[2], col[3], 0.25)
        love.graphics.rectangle("fill", x + 0.5 / app.camScale,
                                        y + 0.5 / app.camScale,
                                        w, h)
    end
end

-- Returns the composite shape data where n is located at 0,0
function getCompositeShape(n)
	for i,shape in ipairs(project.conf.composite_shapes) do
		if shape["0,0"] == n then return shape end
	end
end

function drawCompositeShape(n, x, y)
    if not p8data.quads[n] then print(n) end
    local shape=getCompositeShape(n)
	if not shape then return end
	
    love.graphics.setColor(1, 1, 1, 0.5)
	for id,tile in pairs(shape) do
		if id ~= "0,0" and tile > 0 then
			local ox,oy = unpack(split(id))
			love.graphics.draw(p8data.spritesheet_noblack, p8data.quads[tile], x+ox*8, y+oy*8)
		end
	end
    -- if shape then
    --     for oy=1,#shape do
    --         for ox=1,#shape[oy] do
    --             local m=math.abs(shape[oy][ox]) --negative sprite is drawn, but not used as a source for the shape
    --             if m~= 0 then
    --                 love.graphics.draw(p8data.spritesheet_noblack, p8data.quads[m], x + (ox-dx)*8, y + (oy-dy)*8)
    --             end
    --         end
    --     end
    -- end
end

function showMessage(msg)
    app.message = msg
    app.messageTimeLeft = 4
end

function placeSelection()
    if project.selection and app.room then
        local sel, room = project.selection, activeRoom()
        local i0, j0 = div8(sel.x - room.x), div8(sel.y - room.y)
        for i = 0, sel.w - 1 do
            if i0 + i >= 0 and i0 + i < room.w then
                for j = 0, sel.h - 1 do
                    if j0 + j >= 0 and j0 + j < room.h then
                        room.data[i0 + i][j0 + j] = sel.data[i][j]
                    end
                end
            end
        end
    end
    project.selection = nil
end

function select(i1, j1, i2, j2)
    local i0, j0, w, h = rectCont2Tiles(i1, j1, i2, j2)
    if w > 1 or h > 1 then
        local r = activeRoom()
        local selection = newRoom(r.x + i0*8, r.y + j0*8, w, h)
        for i = 0, w - 1 do
            for j = 0, h - 1 do
                selection.data[i][j] = r.data[i0 + i][j0 + j]
                r.data[i0 + i][j0 + j] = 0
            end
        end
        project.selection = selection
    end
end

function hoveredTriggerN()
    local room=activeRoom()
    if room then
        for n, trigger in ipairs(room.camtriggers) do
            local tx, ty = mouseOverTile()
            if tx and tx>=trigger.x and tx<trigger.x+trigger.w and ty>=trigger.y and ty<trigger.y+trigger.h then
                return n
            end
        end
    end
end

function selectedTrigger()
    return activeRoom() and activeRoom().camtriggers[app.selectedCamtriggerN]
end

function switchTool(toolClass)
    if app.tool and not app.tool:instanceOf(toolClass) then
        app.tool:disabled()
        app.tool = toolClass:new()
    end
end

function pushHistory()
    local s = dumpproject(project)
    if s ~= app.history[app.historyN] then
        app.historyN = app.historyN + 1

        for i = app.historyN, #app.history do
            app.history[i] = nil
        end

        app.history[app.historyN] = s
    end
end

function undo()
    if app.historyN >= 2 then
        app.historyN = app.historyN - 1

        local err
        project, err = loadproject(app.history[app.historyN])
        if err then error(err) end
    end

    if not activeRoom() then app.room = nil end
end

function redo()
    if app.historyN <= #app.history - 1 then
        app.historyN = app.historyN + 1

        local err
        project, err = loadproject(app.history[app.historyN])
        if err then error(err) end
    end

    if not activeRoom() then app.room = nil end
end

require("code/fileio")
require("code/inputs/keyboard")
require("code/inputs/mouse")
require("mainloop")
