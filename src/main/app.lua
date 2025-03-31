-- App ==========================================
return {
	W=love.graphics.getWidth(), H = love.graphics.getHeight(),
	font = love.graphics.getFont(),

	-- Camera ===================================
	left = 0, top = 0, -- top left corner of editing area
	camX = 0, camY = 0,
	camScale = 2, --based on camScaleSetting
	camScaleSetting = 1, -- 0, 1, 2 is 1x, 2x, 3x etc, -1, -2, -3 is 0.5x, 0.25x, 0.125x

	-- Variables ================================
	tool = tools.Brush:new(),
	room = nil,

	currentTile = 0,

	message = nil,
	messageTimeLeft = nil,
	playtesting = false,

	-- Appdata ==================================
	executable_path = love.filesystem.read("executable_path") or "",

	-- Options ==================================
	showToolPanel = true,
	showExtraTiles=false,
	showGarbageTiles=false,
	showCameraTriggers=true,

	-- History (undo stack) =====================
	history = {},
	historyN = 0,

	-- these are used in various hacks to work around nuklear being big dumb (or me idk)
	suppressMouse = false, -- disables mouse-driven editing in love.update() when a click has triggered different action, reset on release
	anyWindowHovered = false,
	enterPressed = false,
	roomAdded = false,
}