local tool = Tool:extend("Tiles"):with(require("code/mixins/tileset"))
local toolslist = { "Brush", "Rectangle", "Selection" }
tool.Brush 		= require("code/tools/brush")
tool.Rectangle 	= require("code/tools/rectangle")
tool.Selection 	= require("code/tools/select")

-- Methods ======================================
function tool:panel()
	ui:layoutRow("dynamic", 25*global_scale, #toolslist+1)

	-- Radio menu with tools ====================
	ui:label("Tools:")
	local radio_state = {value = app.currentTool or "Brush"}
	for i,v in ipairs(toolslist) do
		ui:radio(v, radio_state)
	end
	app.currentTool = radio_state.value

	-- Basic tile panel =========================
	self:tilePanel()
end

-- Extend tools =================================
function tool:mousepressed(...) self[app.currentTool]:mousepressed(...) end
function tool:mousereleased(...) self[app.currentTool]:mousereleased(...) end
function tool:mousemoved(...) self[app.currentTool]:mousemoved(...) end
function tool:disabled(...) self[app.currentTool]:disabled(...) end
function tool:update(...) self[app.currentTool]:update(...) end
function tool:draw(...) self[app.currentTool]:draw(...) end

-- Return =======================================
return tool