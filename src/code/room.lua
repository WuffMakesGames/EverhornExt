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

function drawRoom(room, p8data, highlight)
	local active = room == activeRoom()

	love.graphics.push()
	love.graphics.translate(room.x, room.y)
	local ox,oy = toScreen(room.x,room.y)
	love.graphics.setScissor(ox,oy, room.w*8*app.camScale, room.h*8*app.camScale)

	-- Background ===============================
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

    -- draw shapes bigger than 1x1 (like spinners)
    for i = 0, room.w - 1 do
        for j = 0, room.h - 1 do
            local n = room.data[i][j]
            drawCompositeShape(n, 8*i, 8*j)
        end
    end

	-- Tiles ====================================
	local spritesheet = app.showGarbageTiles and p8data.spritesheet_alt or p8data.spritesheet
    for i = 0, room.w - 1 do
        for j = 0, room.h - 1 do
            local n = room.data[i][j]
            if not p8data.quads[n] then print(n) end
            if not highlight or n~=0 then
                love.graphics.setColor(1, 1, 1)

                if n~= 0 then
                    love.graphics.draw(spritesheet, p8data.quads[n], i*8, j*8)
                end
            end
        end
    end

	-- Draw map grid ============================
	if active then
		love.graphics.setLineWidth(0.5)
		love.graphics.setColor(1,1,1,0.2)
		for i = 16, room.w-1, 16 do
			love.graphics.line(i*8, 0, i*8, room.h*8)
		end
		for i = 16, room.h-1, 16 do
			love.graphics.line(0, i*8, room.w*8, i*8)
		end
	end
	
	-- Draw highlight ===========================
    if highlight then
        drawColoredRect(0, 0, room.w*8, room.h*8, {0, 1, 0.5}, true)
    end

	-- Draw triggers ============================
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

	-- Pop
	love.graphics.pop()
	love.graphics.setScissor()
end
