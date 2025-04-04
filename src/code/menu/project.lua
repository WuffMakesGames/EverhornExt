local tool = Tool:extend("Project")

-- Methods ======================================
function tool:panel()
    ui:layoutRow("static", 25*global_scale, 100*global_scale, 3)
    if ui:button("Open") then openFile() end
    if ui:button("Save") then saveFile(false) end
    if ui:button("Save as...") then saveFile(true) end

	-- String format ============================
    ui:layoutRow("dynamic", 25*global_scale, 2)
    ui:label("Encode string levels as:")
	project.conf.format = formats.names[ui:combobox(table_pos(formats.names,project.conf.format), formats.names)]

	-- Background ==============================
	local backgrounds = { "(None)" }
	for i,v in ipairs(project.conf.backgrounds) do table.insert(backgrounds, v) end
	table.insert(backgrounds, "Add background...")

	ui:label("Background:")
	local bg = backgrounds[ui:combobox(table_pos(backgrounds, app.background), backgrounds)]
	if bg ~= app.background then
		if bg == "(None)" then
			app.background = "(None)"

		elseif bg == "Add background..." then
			local path = filedialog.get_path("png", "PNG")
			if not table_pos(backgrounds, path) and path then
				table.insert(project.conf.backgrounds, path)
			end
			app.background = path
		else app.background = bg end

		-- Load background
		if app.background ~= "(None)" then
			local file = io.open(app.background, "rb")
			local filedata, err = love.filesystem.newFileData(file:read("all"), "appbg")
			file:close()

			if not err then
				local image_data = love.image.newImageData(filedata)
				app.background_image = love.graphics.newImage(image_data)
				app.background_image:setFilter("nearest")
			end
		end
	end

	-- Options ==================================
    ui:layoutRow("dynamic", 25*global_scale, 1)
	project.conf.include_exits = ui:checkbox("Include level exits?", project.conf.include_exits)

	-- Room parameters ==========================
    ui:layoutRow("dynamic", 25*global_scale, {0.8, 0.1, 0.1})

    ui:label("Room parameter names:")
    if ui:button("+") then table.insert(project.conf.param_names, "") end
    if ui:button("-") then table.remove(project.conf.param_names, #project.conf.param_names) end

    for i = 1, #project.conf.param_names do
        ui:layoutRow("dynamic", 25*global_scale, 1)

        local t = {value=project.conf.param_names[i]}
        ui:edit("field", t)
        project.conf.param_names[i] = t.value
    end
end


-- Return =======================================
return tool