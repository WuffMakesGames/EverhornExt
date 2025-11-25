function newRoom(x, y, w, h)
    local room = {
        x = x or 0,
        y = y or 0,
        w = w or 16,
        h = h or 16,
        string=true,
        data = {},
        exits={left=false, bottom=false, right=false, top=true},
        params = {},
        title = "",
        camtriggers={},
    }
    room.data = fill2d0s(room.w, room.h)

    return room
end

function roomIsEmpty(room)
	for x = 0, room.w - 1 do
		for y = 0, room.h - 1 do
			local tile = room.data[x][y]
			if tile ~= 0 then return false end
		end
	end
	return true
end

function drawRoom(room, p8data, highlight, tilecolor)
	local active = room == activeRoom()
	tilecolor = tilecolor or rgb(255, 255, 255)

	love.graphics.push()
	love.graphics.translate(room.x, room.y)
	local ox,oy = toScreen(room.x,room.y)
	love.graphics.setScissor(ox,oy, room.w*8*app.camScale, room.h*8*app.camScale)

	-- Draw background
	if active then
		love.graphics.setColor(0.133, 0.133, 0.133)
		love.graphics.rectangle("fill", 0, 0, room.w*8, room.h*8)
		love.graphics.setColor(1, 1, 1)

		if app.background_image then
			for xx = 0, room.w*8, app.background_image:getWidth() do
			for yy = 0, room.h*8, app.background_image:getHeight() do
				love.graphics.draw(app.background_image, xx, yy)
			end end
		end
	end

    -- Draw composite shapes
    for i = 0, room.w - 1 do
        for j = 0, room.h - 1 do
            local n = room.data[i][j]
            drawCompositeShape(n, 8*i, 8*j)
        end
    end

	-- Draw tilemap
	local spritesheet = app.showGarbageTiles and p8data.spritesheet_alt or p8data.spritesheet
	love.graphics.setColor(rgb(255, 255, 255))
	for x = 0, room.w - 1 do
		for y = 0, room.h - 1 do
			local tile = room.data[x][y]
			if tile ~= 0 then
				love.graphics.draw(spritesheet, p8data.quads[tile], x*8, y*8)
			end
		end
	end

	-- Draw map grid
	if active then
		love.graphics.setLineWidth(1)
		love.graphics.setColor(1,1,1,0.2)
		for i = 16, room.w-1, 16 do
			love.graphics.line(i*8, 0, i*8, room.h*8)
		end
		for i = 16, room.h-1, 16 do
			love.graphics.line(0, i*8, room.w*8, i*8)
		end
	end
	
	-- Draw highlight
    if highlight then
        drawColoredRect(0, 0, room.w*8, room.h*8, {0, 1, 0.5}, true)
    end

	-- Draw triggers
    if app.tool:instanceOf(tools.Camtrigger) or app.showCameraTriggers then
        local highlighted = app.tool:instanceOf(tools.Camtrigger) and (app.selectedCamtriggerN or hoveredTriggerN())
        for n, trigger in ipairs(room.camtriggers) do
            local col = {1,0.75,0}
            if active and n == highlighted then
				col = app.selectedCamtriggerN and {0.5, 1, 0} or {1, 0.9, 0}
            end
            drawColoredRect(trigger.x*8, trigger.y*8, trigger.w*8, trigger.h*8, col, true)
        end
    end

	-- Draw outline
	if active then
		love.graphics.setLineWidth(2)
		love.graphics.setColor(rgba(255, 255, 255, 0.38))
		love.graphics.rectangle("line", 0, 0, room.w*8, room.h*8)
	end

	-- Pop
	love.graphics.pop()
	love.graphics.setScissor()
end
