local tool = Tool:extend("Room")

-- Methods ======================================
function tool:panel()
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
        local fits_on_map = x>=0 and x+room.w<=128 and y>=0 and y+room.h<=64
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

		-- Level exits ==========================
		if project.conf.include_exits then
			ui:layoutRow("dynamic", 25*global_scale, 5)
			ui:label("Level Exits:")
			for _,v in pairs({"left","bottom","right","top"}) do
				room.exits[v] = ui:checkbox(v, room.exits[v] or false)
			end
		end

		-- Level parameters =====================
        for i=1, param_n do
            ui:layoutRow("dynamic", 25*global_scale, {0.25,0.75} )
            ui:label(project.conf.param_names[i] or "")

            local t = {value=room.params[i] or 0}
            ui:edit("field", t)
            room.params[i] = t.value
        end
    end
end

-- Return =======================================
return tool