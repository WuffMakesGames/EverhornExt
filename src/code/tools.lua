tools = {}

-- this defines the order of tools on the panel
toolslist = {"Brush", "Rectangle", "Select", "Camtrigger", "Room", "Project"}
Tool = class("Tool")

function Tool:disabled() end
function Tool:panel() end
function Tool:update() end
function Tool:draw() end
function Tool:mousepressed() end
function Tool:mousereleased() end
function Tool:mousemoved() end

-- tile panel mixin
local autolookup = {0, 1, 3, 2, 4, 5, 7, 6, 12, 13, 15, 14, 8, 9, 11, 10}
local autolayout = {0,  1,  3,  2,  16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27,
                    4,  5,  7,  6,  28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39,
                    12, 13, 15, 14, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51,
                    8,  9,  11, 10, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63}
TilePanelMx = {}
function TilePanelMx:tilePanel()
    ui:layoutRow("dynamic", 25*global_scale, 3)
    ui:label("Tiles:")
    
	-- Toggles
	app.showExtraTiles = ui:checkbox("Show extra tiles", app.showExtraTiles)
	app.showGarbageTiles = ui:checkbox("Use garbage?", app.showGarbageTiles)

	-- Buttons
    for j = 0, app.showExtraTiles and 15 or 7 do
        ui:layoutRow("static", 8*tms, 8*tms, 16)
        for i = 0, 15 do
            local n = i + j*16

            if tileButton(n, app.currentTile == n and not app.autotile) then
                if self.autotileEditO then
                    if app.autotile then
                        if self.autotileEditO >= 16 and n == 0 then
                            project.conf.autotiles[app.autotile][self.autotileEditO] = nil
                        else
                            project.conf.autotiles[app.autotile][self.autotileEditO] = n
                        end
                    end

                    updateAutotiles()

					-- Next autotile
					local pos = table_pos(autolookup, self.autotileEditO)
                    if pos then self.autotileEditO = autolookup[pos+1]
                    else self.autotileEditO = nil end

					app.currentTile = project.conf.autotiles[app.autotile][15]
                else
                    app.currentTile = n
                    app.autotile = nil
                end
            end
        end
    end

    -- autotiles
    ui:layoutRow("dynamic", 25*global_scale, 3)
    ui:label("Autotiles:")
    ui:spacing(1)
    if ui:button("New Autotile") then
        local auto = {[0] = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
        table.insert(project.conf.autotiles, auto)
        updateAutotiles()
    end

    ui:layoutRow("static", 8*tms, 8*tms, #project.conf.autotiles)
    for k, auto in ipairs(project.conf.autotiles) do
        if tileButton(auto[5], app.autotile == k) then
            app.currentTile = auto[15]
            app.autotile = k
            self.autotileEditO = nil
        end
    end

	-- Autotile brush selected ==================
    if app.autotile then
        ui:layoutRow("dynamic", 25*global_scale, 3)
        ui:label("Tileset: (click to edit)")
        ui:spacing(1)
        if ui:button("Delete Autotile") then
            table.remove(project.conf.autotiles, app.autotile)
            updateAutotiles()
            app.autotile = math.max(1, app.autotile - 1)
        end
    end

    -- check for missing autotile! can happen on undo/redo
    if not project.conf.autotiles[app.autotile] then
        app.autotile = nil
    end

	-- Autotile brush selected ==================
    if app.autotile then
        for r = 0, 3 do
            ui:layoutRow("static", 8*tms, 8*tms, 16)
            for i = 1,16 do
                local o = autolayout[i + r*16]
                if tileButton(project.conf.autotiles[app.autotile][o] or 0, self.autotileEditO == o, o) then
                    self.autotileEditO = o
                end
            end
        end

        ui:layoutRow("dynamic", 50*global_scale, 1)
        ui:label("Autotile draws with the 16 tiles on the left, connecting them to each other and to any of the extra tiles on the right. This allows connecting to other deco tiles and tiles from other tilesets. Also works when erasing.", "wrap")
    end
end



-- Tools
tools.Brush = require("code/tools/brush")
tools.Rectangle = require("code/tools/rectangle")
tools.Select = require("code/tools/select")
tools.Camtrigger = require("code/tools/camtrigger")
tools.Room = require("code/tools/room")
tools.Project = require("code/tools/project")
