
-- UI Shapes ====================================
function ui_rect(x1,y1,x2,y2)
	ui:line(x1,y1,x2,y1)
	ui:line(x1,y2,x2,y2)
	ui:line(x1,y1,x1,y2)
	ui:line(x2,y1,x2,y2)
end
