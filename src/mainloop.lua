-- UI things


-- MAIN LOOP
function love.load(args)
    love.keyboard.setKeyRepeat(true)
    ui = nuklear.newUI()

    global_scale=1 -- global scale, to run nicely on hi dpi displays
    tms = 4 -- tile menu scale

    for _,v in ipairs(args) do
        if v=="--hidpi" then
            global_scale = 2
            tms = 4*global_scale
        end
    end

    newProject()
    pushHistory()

    checkmarkIm=love.graphics.newImage("assets/checkmark.png")
    checkmarkWithBg=love.graphics.newCanvas(checkmarkIm:getWidth()*5/4,checkmarkIm:getHeight()*5/4)
    love.graphics.setCanvas(checkmarkWithBg)
    love.graphics.clear(0x64/0xff,0x64/0xff,0x64/0xff)
    love.graphics.draw(checkmarkIm,checkmarkIm:getWidth()/8,checkmarkIm:getHeight()/8)
    love.graphics.setCanvas()

    bgtileIm = love.graphics.newImage("assets/bgtile.png")
    bgtileIm:setFilter("nearest")
end

function love.update(dt)
    app.W, app.H = love.graphics.getDimensions()
    local rpw = app.W * 0.10 -- room panel width
    app.left, app.top = rpw, 0

    ui:frameBegin()
    --ui:scale(2)

    ui:stylePush {
        window = {
            spacing = {x = 1, y = 1},
            padding = {x = 1, y = 1},
        },
        selectable = {
            padding = {x = 0, y = 0},
            ["normal"] = "#262626",
            ["hover"] = "#262626",
            ["pressed"] = "#262626",
            ["normal active"] = "#000000",
            ["hover active"] = "#000000",
            ["pressed active"] = "#000000",
            ["text normal active"] = "#00ff88",
            ["text hover active"] = "#00ff88",
            ["text pressed active"] = "#00ff88",
        },
        checkbox = {
            ["cursor normal"] = checkmarkIm,
            ["cursor hover"] = checkmarkIm
        }
    }

    -- room panel
    if ui:windowBegin("Room Panel", 0, 0, rpw, app.H, {"scrollbar"}) then
        ui:layoutRow("dynamic", 25*global_scale, 1)
        for n, room in ipairs(project.rooms) do
            local line = "["..n..""
			if project.conf.include_exits then
				line = line .. (room.exits.left and "l" or "")
				line = line .. (room.exits.bottom and "d" or "")
				line = line .. (room.exits.right and "r" or "")
				line = line .. (room.exits.top and "u" or "")
			end
			line = line .. (room.is_string and "s" or "")
            line = line .. "] " .. room.title

			--center camera around room
            local selection={value=n==app.room}
            if ui:selectable(line, selection) then
                if app.room==n then
                    app.camX,app.camY=-room.x-4*room.w+app.W/(3*app.camScale), -room.y-4*room.h+app.H/(2*app.camScale)

                end
                app.room = n
            end
        end

        if app.roomAdded then
            ui:windowSetScroll(0, 100000)
            app.roomAdded = false
        end

        app.roomPanelHovered = ui:windowIsHovered()
    end
    ui:windowEnd()

    -- tool panel
    if app.showToolPanel then
        local tpw = 16*8*tms + 18
        if ui:windowBegin("Tool panel", app.W - tpw, 0, tpw+12, app.H, {"scrollbar"}) then
            -- tools list
            for i = 0, #toolslist - 1 do
                if i%4 == 0 then
                    ui:layoutRow("dynamic", 25*global_scale, 4)
                end

                local toolClass = tools[toolslist[1 + i]]

                if ui:selectable(toolClass.name, app.tool:instanceOf(toolClass)) then
                    switchTool(toolClass)
                end
            end

            -- some spacing
            ui:layoutRow("dynamic", 5*global_scale, 0)

            -- tool panel
            app.tool:panel()
        end
        ui:windowEnd()
    end

    app.enterPressed = false

    app.anyWindowHovered = ui:windowIsAnyHovered()

    ui:stylePop()

    -- tool update
    app.tool:update(dt)

    ui:frameEnd()

    local x, y = love.mouse.getPosition()
    local mx, my = fromScreen(x, y)

    if app.roomResizeSideX and app.room then
        local room = activeRoom()

        if not room.is_string then
            -- if the room is stored in mapdata, it still has to fit when resizing
            mx = math.min(math.max(mx, 0), 1024)
            my = math.min(math.max(my, 0), 512)
        end
        local left, top = room.x, room.y
        local right, bottom = left + room.w*8, top + room.h*8

        local ax = app.roomResizeSideX > 0 and right or left
        local ay = app.roomResizeSideY > 0 and bottom or top

        local dx = div8(math.abs(mx-ax)) * sign(mx-ax) * app.roomResizeSideX
        local dy = div8(math.abs(my-ay)) * sign(my-ay) * app.roomResizeSideY

        dx = math.max(1, room.w + dx) - room.w
        dy = math.max(1, room.h + dy) - room.h

        if dx ~= 0 or dy ~= 0 then
            local newdata, neww, newh = {}, room.w + dx, room.h + dy

            -- copy all tiles (even if outside bounds - so they persist if you cut part of room off and then resize back)
            for i, col in pairs(room.data) do
                for j, n in pairs(col) do
                    local i_, j_ = i + (ax == left and dx or 0), j + (ay == top and dy or 0)

                    if not newdata[i_] then newdata[i_] = {} end
                    newdata[i_][j_] = n
                end
            end
            for _,c in pairs(room.camtriggers) do
                c.x = c.x + (ax == left and dx or 0)
                c.y = c.y + (ay == top and dy or 0)
            end
            -- add 0 when no data is there
            for i = 0, neww - 1 do
                newdata[i] = newdata[i] or {}
                for j = 0, newh - 1 do
                    newdata[i][j] = newdata[i][j] or 0
                end
            end

            room.x = room.x - (ax == left and 8*(neww-room.w) or 0)
            room.y = room.y - (ay == top and 8*(newh-room.h) or 0)
            room.data, room.w, room.h = newdata, neww, newh
        end
    end

    if app.message then
        app.messageTimeLeft = app.messageTimeLeft - dt
        if app.messageTimeLeft < 0 then
            app.message = nil
            app.messageTimeLeft = nil
        end
    end
end

function love.draw()
    love.graphics.clear(0.25, 0.25, 0.25)
    love.graphics.reset()
    love.graphics.setLineStyle("rough")

    local x, y = love.mouse.getPosition()
    local mx, my = fromScreen(x, y)

    local ox, oy = toScreen(0, 0)
    love.graphics.translate(math.floor(ox), math.floor(oy))
    love.graphics.scale(app.camScale)

    love.graphics.setColor(0.28, 0.28, 0.28)
    love.graphics.setLineWidth(2)
    for i = 0, 7 do
        for j = 0, 3 do
            love.graphics.rectangle("line", i*128, j*128, 128, 128)
        end
    end

    for n, room in ipairs(project.rooms) do
        if room ~= activeRoom() then
            drawRoom(room, p8data)
            love.graphics.setColor(0.5, 0.5, 0.5, 0.4)
            love.graphics.rectangle("fill", room.x, room.y, room.w*8, room.h*8)

            if app.roomPanelHovered then
                love.graphics.push()
                love.graphics.translate(room.x + room.w*4, room.y + room.h*4)
                love.graphics.scale(1 / app.camScale)

                printbg(n, 0, 0, {1, 1, 1}, {0, 0, 0}, true, true)

                love.graphics.pop()
            end
        end
    end
    if activeRoom() then
        local room = activeRoom()
        drawRoom(room, p8data)

        if app.roomPanelHovered then
            love.graphics.push()
            love.graphics.translate(room.x + room.w*4, room.y + room.h*4)
            love.graphics.scale(1 / app.camScale)

            printbg(app.room, 0, 0, {0, 1, 0.5}, {0, 0, 0}, true, true)

            love.graphics.pop()
        end
    end
    if project.selection then
        drawRoom(project.selection, p8data, true)
        love.graphics.setColor(0, 1, 0.5)
        love.graphics.setLineWidth(1 / app.camScale)
        love.graphics.rectangle("line", project.selection.x + 0.5 / app.camScale, project.selection.y + 0.5 / app.camScale, project.selection.w*8, project.selection.h*8)
    end

    -- tool draw
    app.tool:draw()

    love.graphics.reset()
    love.graphics.setColor(1, 1, 1)
    love.graphics.translate(app.left, app.top)
    love.graphics.setFont(app.font)

    if app.message then
        printbg(app.message, 4, app.H - app.font:getHeight() - 4, {0, 1, 0.5}, {0, 0, 0})
    end

    if app.playtesting then
        local s = app.playtesting == 1 and "[playtesting]" or "[playtesting, 2 dashes]"
        printbg(s, 4, 4, {0, 1, 0.5}, {0, 0, 0})
    end
    ui:draw()
end
