return function()
	local data = {}
	local imgdata = love.image.newImageData(128, 64)
	imgdata:mapPixel(function() return 0, 0, 0, 1 end)

	data.spritesheet = love.graphics.newImage(imgdata)
	data.spritesheet_alt = love.graphics.newImage(imgdata)
	data.spritesheet_noblack = love.graphics.newImage(imgdata)

	data.quads = {}
	for i = 0, 15 do
		for j = 0, 15 do
			data.quads[i + j*16] = love.graphics.newQuad(i*8, j*8, 8, 8, data.spritesheet:getDimensions())
		end
	end

	return data
end