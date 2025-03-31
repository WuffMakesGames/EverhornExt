local mixin = {}

local autolookup = {0, 1, 3, 2, 4, 5, 7, 6, 12, 13, 15, 14, 8, 9, 11, 10}
local autolayout = {
	0,  1,  3,  2,  16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27,
    4,  5,  7,  6,  28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39,
    12, 13, 15, 14, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51,
    8,  9,  11, 10, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63
}

-- Methods ======================================
function mixin:tilePanel()
	ui:layoutRow("dynamic", 25*global_scale, 3)
    ui:label("Tiles:")
	app.showExtraTiles = ui:checkbox("Show extra tiles", app.showExtraTiles)
	app.showGarbageTiles = ui:checkbox("Use garbage?", app.showGarbageTiles)

	-- Buttons
	self:tiles()
	self:autotiles()
	self:composite()
end

-- Tileset ======================================
function mixin:tiles()
	ui:layoutRow("static", 8*tms, 8*tms, 16)
	for n = 0, app.showExtraTiles and 255 or 127 do
		local button = tileButton(n, app.currentTile == n and not (app.autotile or app.comptile))

		if button and self.tileEdit then

			-- Autotiles ========================
			if app.autotile then
				if self.tileEdit >= 16 and n == 0 then
					project.conf.autotiles[app.autotile][self.tileEdit] = nil
				else project.conf.autotiles[app.autotile][self.tileEdit] = n end

				-- Updates
				updateAutotiles()
				app.currentTile = project.conf.autotiles[app.autotile][15]

				-- Next autotile
				local pos = table_pos(autolookup, self.tileEdit)
				if pos then self.tileEdit = autolookup[pos+1]
				else self.tileEdit = nil end

			-- Composite shapes =================
			elseif app.comptile then
				project.conf.composite_shapes[app.comptile][self.tileEdit] = n
				app.currentTile = project.conf.composite_shapes[app.comptile]["0,0"]
				self.tileEdit = nil
			end

		elseif button then
			app.currentTile = n
			app.autotile = nil
			app.comptile = nil
		end
    end
end

-- Autotiles ====================================
function mixin:autotiles()
	ui:layoutRow("dynamic", 25*global_scale, 3)
    ui:label("Autotiles:")
    ui:spacing(1)
    if ui:button("New Autotile") then
        local auto = {[0] = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
        table.insert(project.conf.autotiles, auto)
        updateAutotiles()
    end

	-- List of autotiles ========================
	if #project.conf.autotiles > 0 then
		ui:layoutRow("static", 8*tms, 8*tms, 16)
		for k, auto in ipairs(project.conf.autotiles) do
			if tileButton(auto[5], app.autotile == k) then
				app.currentTile = auto[15]
				app.autotile = k
				app.comptile = nil
				self.tileEdit = nil
			end
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

	-- Autotile editing =========================
    if not project.conf.autotiles[app.autotile] then app.autotile = nil end
    if app.autotile then
		ui:layoutRow("static", 8*tms, 8*tms, 16)
        for i = 1, #autolayout do
			local o = autolayout[i]
			if tileButton(project.conf.autotiles[app.autotile][o] or 0, self.tileEdit == o, o) then
				self.tileEdit = o
			end
        end

        ui:layoutRow("dynamic", 50*global_scale, 1)
        ui:label("Autotile draws with the 16 tiles on the left, connecting them to each other and to any of the extra tiles on the right. This allows connecting to other deco tiles and tiles from other tilesets. Also works when erasing.", "wrap")
    end
end

-- Composite ====================================
function mixin:composite()
	ui:layoutRow("dynamic", 25*global_scale, 3)
	ui:label("Composite Shapes:")
	ui:spacing(1)
	if ui:button("New Composite Shape") then
		table.insert(project.conf.composite_shapes, {})
	end

	-- List of shapes ===========================
	if #project.conf.composite_shapes > 0 then
		ui:layoutRow("static", 8*tms, 8*tms, 16)
		for k, shape in ipairs(project.conf.composite_shapes) do
			if tileButton(shape["0,0"] or 0, app.comptile == k) then
				app.currentTile = shape["0,0"] or 0
				app.comptile = k
				app.autotile = nil
				self.tileEdit = nil
			end
		end
	end

	-- Shape selected ===========================
    if app.comptile then
        ui:layoutRow("dynamic", 25*global_scale, 3)
        ui:label("Shape: (click to edit)")
        ui:spacing(1)
        if ui:button("Delete Composite Shape") then
            table.remove(project.conf.composite_shapes, app.comptile)
            app.comptile = math.max(1, app.comptile - 1)
        end
    end

	-- Shape editing ============================
	if not project.conf.composite_shapes[app.comptile] then app.comptile = nil end 
    if app.comptile then
		ui:layoutRow("static", 8*tms, 8*tms, 5)
		for i = 0, 24 do
			local x,y = i%5-2, math.floor(i/5)-2
			local id = x..","..y
			if tileButton(project.conf.composite_shapes[app.comptile][id] or 0, self.tileEdit==id, id=="0,0" and 0) then
				self.tileEdit = id
			end
		end

        -- ui:layoutRow("dynamic", 50*global_scale, 1)
        -- ui:label("Autotile draws with the 16 tiles on the left, connecting them to each other and to any of the extra tiles on the right. This allows connecting to other deco tiles and tiles from other tilesets. Also works when erasing.", "wrap")
    end
end

-- Return =======================================
return mixin