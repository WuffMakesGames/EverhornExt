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
export_base256 = add_format("code/formats/base256")
export_hex = add_format("code/formats/hex")
export_rom = add_format("code/formats/rom")
return formats