local filedialog = {}
local pickfile = require("libraries/pickfile")
local nfd = love.filesystem.isFused() and require("nfd")

function filedialog.get_path()
	local path = nfd and nfd.open("p8")
		or pickfile("Select a file", nil, {"PICO-8", "*.p8"})
	print(path)
    return path
end

return filedialog
