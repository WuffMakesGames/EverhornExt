tools = {}

-- this defines the order of tools on the panel
toolslist = {"Brush", "Rectangle", "Select", "Camtrigger", "Room", "Project", "Settings"}
Tool = class("Tool")

function Tool:disabled() end
function Tool:panel() end
function Tool:update() end
function Tool:draw() end
function Tool:mousepressed() end
function Tool:mousereleased() end
function Tool:mousemoved() end

-- Tools
tools.Brush 		= require("code/tools/brush")
tools.Rectangle 	= require("code/tools/rectangle")
tools.Select 		= require("code/tools/select")
tools.Camtrigger 	= require("code/tools/camtrigger")
tools.Room 			= require("code/tools/room")
tools.Project 		= require("code/tools/project")
tools.Settings 		= require("code/tools/settings")
