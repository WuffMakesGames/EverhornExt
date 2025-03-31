local tool = Tool:extend("Project")

-- Methods ======================================
function tool:panel()
    ui:layoutRow("static", 25*global_scale, 100*global_scale, 3)
    if ui:button("Open") then openFile() end
    if ui:button("Save") then saveFile(false) end
    if ui:button("Save as...") then saveFile(true) end

	-- Executable ===============================
    -- ui:layoutRow("dynamic", 25*global_scale, {0.25, 0.65, 0.1})
	-- ui:label("Executable path:")

	-- local path = {value = app.executable_path}
	-- ui:edit("field", path)
	-- app.executable_path = path.value

	-- if ui:button("...") then
	-- 	app.executable_path = filedialog.get_path("", "") or app.executable_path
	-- end

	-- String format ============================
    ui:layoutRow("dynamic", 25*global_scale, 2)
    ui:label("Encode string levels as:")
	project.conf.format = formats.names[ui:combobox(table_pos(formats.names,project.conf.format), formats.names)]

	-- Options ==================================
	project.conf.include_exits = ui:checkbox("Include level exits?", project.conf.include_exits)

	-- Room parameters ==========================
    ui:layoutRow("dynamic", 25*global_scale, {0.8, 0.1, 0.1})
    ui:label("Room parameter names:")
    if ui:button("+") then
        table.insert(project.conf.param_names, "")
    end
    if ui:button("-") then
        table.remove(project.conf.param_names, #project.conf.param_names)
    end
    for i = 1, #project.conf.param_names do
        ui:layoutRow("dynamic", 25*global_scale, 1)

        local t = {value=project.conf.param_names[i]}
        ui:edit("field", t)
        project.conf.param_names[i] = t.value
    end
end


-- Return =======================================
return tool