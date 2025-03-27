function love.keypressed(key, scancode, isrepeat)
    local x, y = love.mouse.getPosition()
    local mx, my = fromScreen(x, y)

    -- shortcuts that work on with a nuklear window active

    -- room switching / swapping
    if key == "down" or key == "up" then
        if app.room and not project.selection then
            local n1 = app.room
            local n2 = key == "down" and app.room + 1 or app.room - 1

            if project.rooms[n1] and project.rooms[n2] then
                if love.keyboard.isDown("lctrl") then
                    -- swap
                    local tmp = project.rooms[n1]
                    project.rooms[n1] = project.rooms[n2]
                    project.rooms[n2] = tmp
                end

                app.room = n2
            end
        end
    end



    if ui:keypressed(key, scancode, isrepeat) then
        return
    end



    -- shortcuts that nuklear windows swallow

    if key == "return" then
        app.enterPressed = true
    end

    -- first handle actions that are allowed to repeat when holding key

    local dx, dy = 0, 0
    if key == "left" then dx = -1 end
    if key == "right" then dx = 1 end
    if key == "up" then dy = -1 end
    if key == "down" then dy = 1 end
    if project.selection then
        project.selection.x = project.selection.x + dx*8
        project.selection.y = project.selection.y + dy*8
    end

    -- Ctrl+Z, Ctrl+Shift+Z
    if love.keyboard.isDown("lctrl") then
        if key == "z" then
            if love.keyboard.isDown("lshift") then
                redo()
            else
                undo()
            end
        end
    end

    if isrepeat then
        return
    end

    -- non-repeatable global shortcuts

    if love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") then
        -- Ctrl+O
        if key == "o" then
            openFile()
        -- Ctrl+R
        elseif key == "r" then
            if app.openFileName then
                local data = loadpico8(app.openFileName)
                p8data.spritesheet = data.spritesheet
                showMessage("Reloaded")
            end
        -- Ctrl+S
        elseif key == "s" then
            saveFile(love.keyboard.isDown("lshift"))
        -- Ctrl+X
        elseif key == "x" then
            if love.keyboard.isDown("lshift") then
                -- cut entire room
                if activeRoom() then
                    local s = dumplualine {"room", activeRoom()}
                    love.system.setClipboardText(s)
                    table.remove(project.rooms, app.room)
                    app.room = nil

                    showMessage("Cut room")
                end
            else
                -- cut selection
                if project.selection then
                    local s = dumplualine {"selection", project.selection}
                    love.system.setClipboardText(s)
                    project.selection = nil

                    showMessage("Cut")
                end
            end
        -- Ctrl+C
        elseif key == "c" then
            if love.keyboard.isDown("lshift") then
                -- copy entire room
                if activeRoom() then
                    local s = dumplualine {"room", activeRoom()}
                    love.system.setClipboardText(s)

                    showMessage("Copied room")
                end
            else
                -- copy selection
                if project.selection then
                    local s = dumplualine {"selection", project.selection}
                    love.system.setClipboardText(s)
                    placeSelection()

                    showMessage("Copied")
                end
            end
        -- Ctrl+V
        elseif key == "v" then
            placeSelection() -- to clean selection first

            local t, err = loadlua(love.system.getClipboardText())
            if not err then
                if type(t) == "table" then
                    if t[1] == "selection" then
                        local s = t[2]
                        project.selection = s
                        project.selection.x = roundto8(mx - s.w*4)
                        project.selection.y = roundto8(my - s.h*4)
                        switchTool(tools.Select)

                        showMessage("Pasted")
                    elseif t[1] == "room" then
                        local r = t[2]
                        r.x = roundto8(mx - r.w*4)
                        r.y = roundto8(my - r.h*4)
                        table.insert(project.rooms, r)
                        app.room = #project.rooms
                    else
                        err = true
                    end
                else
                    err = true
                end
            end
            if err then
                showMessage("Failed to paste (did you paste something you're not supposed to?)")
            end
        elseif key == "a" then
            if activeRoom() then
                switchTool(tools.Select)
                select(0, 0, activeRoom().w - 1, activeRoom().h - 1)
            end
        elseif key=="h" then
            app.showGarbageTiles=not app.showGarbageTiles
        elseif key=="t" then
            app.showCameraTriggers=not app.showCameraTriggers
        end
    else -- if ctrl is not down
        if key == "delete" and love.keyboard.isDown("lshift") then
            if activeRoom() then
                table.remove(project.rooms, app.room)
                if not activeRoom() then
                    app.room = #project.rooms
                end
            end
        elseif key == "return" then
            placeSelection()
        elseif key == "tab" and not love.keyboard.isDown("lalt") then
            if not app.playtesting then
                app.playtesting = 1
            elseif app.playtesting == 1 then
                app.playtesting = 2
            else
                app.playtesting = false
            end
        elseif key == "delete" then
            local room=activeRoom()
            if app.selectedCamtriggerN and room then
                table.remove(room.camtriggers, app.selectedCamtriggerN)
                app.selectedCamtriggerN=nil
            end
        end
    end
end

function love.keyreleased(key, scancode)
    -- just save history every time a key is released lol
    pushHistory()

    if ui:keyreleased(key, scancode) then
        return
    end
end

function love.textinput(text)
    if ui:textinput(text) then
        return
    end

    -- tool switching with 12...9
    for i = 1, math.min(#toolslist,9) do
        if text==tostring(i) then
            switchTool(tools[toolslist[i]])
        end
    end

    if text == "n" then
        local x, y = love.mouse.getPosition()
        local mx, my = fromScreen(x, y)
        local room = newRoom(roundto8(mx), roundto8(my), 16, 16)

        room.title = ""

        table.insert(project.rooms, room)
        app.room = #project.rooms
        app.roomAdded = true
    elseif text == " " then
        app.showToolPanel = not app.showToolPanel
    end
end
