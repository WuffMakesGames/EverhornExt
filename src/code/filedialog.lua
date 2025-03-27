local filedialog = {}
local pickfile = require("libraries/pickfile")

function filedialog.get_path()
    local path = pickfile("Select a file", nil, {
		"PICO-8", "*.p8"
	})
	print(path)
    return path
end

return filedialog
