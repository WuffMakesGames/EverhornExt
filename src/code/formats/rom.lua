local format = {}
format.name = "Rom"
format.desc = "ROM format will export mapdata as a separate cart alongside your game. This can then be loaded into memory using reload() in PICO-8. This exports all strings as if they were a single map. You may lose data if rooms overlap or are out of bounds."
format.isrom = true

local emptyline_gfx = "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
local emptyline_map = "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"

-- Methods ======================================
-- Loads hex 
function format.load(gfx,map)
	local raw_map = table_2d(128,128,0)

	-- Load mapdata
	for x = 0, 127 do
		raw_map[x] = {}
		for y = 0,63 do
			local _x = x%64
			local _y = x <= 63 and y*2 or y*2+1
			local line = gfx and gfx[_y+1] or emptyline_gfx
			local hex = string.sub(line, _x*2+1, _x*2+2)
			raw_map[x][y] = fromhex_swapnibbles(hex)
		end
		for y = 64,95 do
			local line = map and map[y+1] or emptyline_map
			local hex = string.sub(line, x*2+1, x*2+2)
			raw_map[x][y] = fromhex(hex)
		end
	end

	-- Create rooms

	-- Return
	print("hi")
	return {}
end

-- Converts mapdata to hex data
function format.dump(rooms)
	local output = {
		"pico-8 cartridge // http://www.pico-8.com",
		"version 43",
	}

	-- Flatten roomdata
	local raw_map = table_2d(128,128,0)
	for i,room in ipairs(rooms) do
		print(i, room)
		if room.is_string then
			local left,top = div8(room.x), div8(room.y)
			for x = 0,room.w-1 do
				for y = 0,room.h-1 do
					raw_map[left+x][top+y] = room.data[x][y]
				end
			end
		end
	end

	-- Write map to gfx
	table.insert(output, "__gfx__")
	for y = 0,63 do
		local newline = ""
		for x = 0,127 do
			newline = newline..tohex_swapnibbles(raw_map[x][y])
		end
		table.insert(output, string.sub(newline, 1, 128))
		table.insert(output, string.sub(newline, 129, 256))
	end

	-- Write map to map
	table.insert(output, "__map__")
	for y = 64,95 do
		local newline = ""
		for x = 0,127 do
			newline = newline..tohex(raw_map[x][y])
		end
		table.insert(output, newline)
	end

	-- Return p8 cart
	return table.concat(output,"\n")
end

-- Return =======================================
return format