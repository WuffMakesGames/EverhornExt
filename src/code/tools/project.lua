local tool = Tool:extend("Project")

-- Methods ======================================
function tool:panel()
    ui:layoutRow("static", 25*global_scale, 100*global_scale, 3)
    if ui:button("Open") then openFile() end
    if ui:button("Save") then saveFile(false) end
    if ui:button("Save as...") then saveFile(true) end

	-- String format ============================
    ui:layoutRow("dynamic", 25*global_scale,3)
    ui:label("Encode string levels as:")

    local radio_state = {value=app.store_strings_as_hex and "Hex" or "Base256"}
    ui:radio("Base256", radio_state)
    ui:radio("Hex", radio_state)
    app.store_strings_as_hex = radio_state.value=="Hex"

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