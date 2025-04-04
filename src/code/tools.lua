tools = {}

-- this defines the order of tools on the panel
toolslist = {"Tiles", "Camtrigger", "Room", "Project", "Settings"}
Tool = class("Tool")

function Tool:disabled() end
function Tool:panel() end
function Tool:update() end
function Tool:draw() end
function Tool:mousepressed() end
function Tool:mousereleased() end
function Tool:mousemoved() end

-- Tools
tools.Tiles 		= require("code/menu/tiles")
tools.Camtrigger 	= require("code/menu/camtrigger")
tools.Room 			= require("code/menu/room")
tools.Project 		= require("code/menu/project")
tools.Settings 		= require("code/menu/settings")
