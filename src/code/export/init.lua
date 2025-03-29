local formats = {}
formats.names = {}

-- Methods ======================================
function add_format(path)
	local format = require(path)
	table.insert(formats.names, format.name)
	formats[format.name] = format
	return format
end

-- Return =======================================
export_base256 = add_format("code/export/base256")
export_hex = add_format("code/export/hex")
return formats