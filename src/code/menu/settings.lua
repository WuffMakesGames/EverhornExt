local tool = Tool:extend("Settings")

-- Methods ======================================
function tool:panel()

	-- Executable
    ui:layoutRow("dynamic", 25*global_scale, {0.25, 0.65, 0.1})
	ui:label("Executable path:")

	local path = {value = app.executable_path}
	ui:edit("field", path)
	app.executable_path = path.value

	if ui:button("...") then
		app.executable_path = filedialog.get_path("", "") or app.executable_path
	end

	-- Carts
    ui:layoutRow("dynamic", 25*global_scale, {0.25, 0.65, 0.1})
	ui:label("PICO-8 carts path:")

	local path = {value = app.carts_path}
	ui:edit("field", path)
	app.carts_path = path.value

	if ui:button("...") then
		app.carts_path = filedialog.get_path("", "") or app.carts_path
	end
end

-- Return =======================================
return tool