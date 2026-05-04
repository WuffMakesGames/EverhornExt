local filedialog = {}
local nfd = require("nfd")--love.filesystem.isFused() and require("nfd")
-- local pickfile = require("libraries/pickfile")

function filedialog.get_path(extension,name)
	local path = nfd.open(extension)
	if path then path = path:gsub("%\\", "/") end
	-- local path = nfd and nfd.open(extension)
	-- 	or pickfile("Select a file", nil, {name or "PICO-8", "*."..extension})
	-- if nfd then path = path:gsub("%\\", "/") end
	print(path)
    return path
end

return filedialog
