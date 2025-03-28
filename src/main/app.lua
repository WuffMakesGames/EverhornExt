-- App ==========================================
return {
	W=love.graphics.getWidth(), H = love.graphics.getHeight(),
	camX = 0, camY = 0,
	camScale = 2, --based on camScaleSetting
	camScaleSetting = 1, -- 0, 1, 2 is 1x, 2x, 3x etc, -1, -2, -3 is 0.5x, 0.25x, 0.125x
	room = nil,
	suppressMouse = false, -- disables mouse-driven editing in love.update() when a click has triggered different action, reset on release
	tool = tools.Brush:new(),
	currentTile = 0,
	message = nil,
	messageTimeLeft = nil,
	playtesting = false,
	store_strings_as_hex=false,
	font = love.graphics.getFont(),
	left = 0, top = 0, -- top left corner of editing area

	-- Options ==================================
	showToolPanel = true,
	showExtraTiles=false,
	showGarbageTiles=false,
	showCameraTriggers=true,

	-- History (undo stack) =====================
	history = {},
	historyN = 0,

	-- these are used in various hacks to work around nuklear being big dumb (or me idk)
	anyWindowHovered = false,
	enterPressed = false,
	roomAdded = false,
}