
function closeToolMenu()
    app.toolMenuX, app.toolMenuY = nil, nil
end

-- UI Shapes ====================================
function ui_rect(x1,y1,x2,y2)
	ui:line(x1,y1,x2,y1)
	ui:line(x1,y2,x2,y2)
	ui:line(x1,y1,x1,y2)
	ui:line(x2,y1,x2,y2)
end

-- Buttons ======================================
function tileButton(n, highlight, autotileOverlayO)
    local x, y, w, h = ui:widgetBounds()

    if n ~= 0 then
		local spritesheet = app.showGarbageTiles and p8data.spritesheet_alt or p8data.spritesheet
        ui:image({spritesheet, p8data.quads[n]})
    else
        ui:image(bgtileIm)
    end

    local hov = ui:inputIsHovered(x, y, w, h)
    if hov or highlight or autotileOverlayO then
        love.graphics.setLineWidth(1)
		love.graphics.setColor(hov and {0, 1, 0.5} or {1, 0, 1})

        if hov or highlight then
            local x, y = x - 0.5, y - 0.5
            local w, h = w + 1, h + 1
			ui_rect(x, y, x+w, y+h)
        end

        if autotileOverlayO and autotileOverlayO < 16 then
            love.graphics.setLineWidth(2)
            love.graphics.setColor(1, 0.5, 0)
            local x, y = x + 1.5, y + 1.5
            local w, h = w - 3, h - 3

            local r = bit.band(autotileOverlayO, 1) == 0
            local l = bit.band(autotileOverlayO, 2) == 0
            local d = bit.band(autotileOverlayO, 4) == 0
            local u = bit.band(autotileOverlayO, 8) == 0

            if r then ui:line(x + w, y, x + w, y + h) end
            if l then ui:line(x, y, x, y + h) end
            if d then ui:line(x, y + h, x + w, y + h) end
            if u then ui:line(x, y, x + w, y) end
        end
    end
	
	return ui:inputIsMousePressed("left", x, y, w, h)
end
