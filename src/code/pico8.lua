local palette = {
	rgb(0, 0, 0),		rgb(29, 43, 83),	rgb(126, 37, 83),	rgb(0, 135, 81),
	rgb(171, 82, 54),	rgb(95, 87, 79),	rgb(194, 195, 199),rgb(255, 241, 232),
	rgb(255, 0, 77),	rgb(255, 163, 0),	rgb(255, 240, 36),	rgb(0, 231, 86),
	rgb(41, 173, 255),	rgb(131, 118, 156),rgb(255, 119, 168),rgb(255, 204, 170)
}
local emptyline_gfx = "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
local emptyline_map = "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
local playtest_snippet = {
	"local __init = _init function _init() __init() load_level(%s) music(-1) end",
	"local __init = _init function _init() __init() load_level(%s) music(-1) max_djump=2 end"
}

-- Font utils
local function togrey(x,y, r,g,b,a)
	return r*194/255, g*195/255, b*199/255, a
end
local function transparent(x,y, r,g,b,a)
	if r == 0 and g == 0 and b == 0 then return 0, 0, 0, 0
	else return r,g,b,a end
end
local function get_font_quad(digit)
	if digit<10 then return 8*digit,24,4,8
	else return 8*(digit-9),48,4,8 end
end

-- Load pico8 file as editor data
function loadpico8(filename)
    love.graphics.setDefaultFilter("nearest", "nearest")

	-- Setup data
	local data = {
		palette = palette,
		quads = {},
		map = {},
		rooms = {},
		roomBounds = {},
		conf = {},
	}

	-- Load file
	local file = io.open(filename, "rb")
	if not file then return false, "Failed to open file" end

	-- Load data sections from file
	local sections,current_section = {}
	for line in cr_file_lines(file) do
        local sec = string.match(line, "^__([%a_:]+)__$")
		if sec then
			current_section = sec
			sections[sec] = {}
			
		elseif current_section then
			table.insert(sections[current_section], line)

		end
	end
	file:close()

	-- Load PICO-8 font
    local font = love.image.newImageData("assets/pico-8_font.png")
    font_grey=love.image.newImageData(font:getWidth(),font:getHeight(),font:getFormat(),font)
    font_grey:mapPixel(togrey)

	-- Load spritesheet data from PICO-8
	local spritesheet = love.image.newImageData(128, 128)
	local spritewidth,spriteheight = spritesheet:getDimensions()

    for y = 0,spriteheight-1 do
        local line = sections.gfx and sections.gfx[y+1] or emptyline_gfx
        for x = 0,spritewidth-1 do
            local str = string.sub(line, x+1, x+1)
			local hex = fromhex(str)
            local rgb = data.palette[hex+1]
            spritesheet:setPixel(x, y, rgb[1], rgb[2], rgb[3], 1)
        end
    end

	-- Garbage tiles spritesheet
	local spritesheet_alt = spritesheet:clone()
    for y = 8,15 do
        for x = 0,15 do
            local id = x+16*(y-8)
            local d1 = math.floor(id/16)
            local d2 = id%16
            spritesheet_alt:paste(font_grey, x*8, y*8, get_font_quad(d1))
            spritesheet_alt:paste(font, x*8+4, y*8, get_font_quad(d2))
        end
    end

	-- Transparent spritesheet
	local spritesheet_transparent = spritesheet:clone()
	spritesheet_transparent:mapPixel(transparent)

	-- Generate spritesheets
	data.spritesheet = love.graphics.newImage(spritesheet)
	data.spritesheet_alt = love.graphics.newImage(spritesheet_alt)
	data.spritesheet_noblack = love.graphics.newImage(spritesheet_transparent)

	-- Generate quads
	for x = 0,15 do
		for y = 0,15 do
			data.quads[x + y*16] = love.graphics.newQuad(x*8, y*8, 8, 8, spritewidth, spriteheight)
		end
	end
	
	-- Load mapdata
	for x = 0, 127 do
		data.map[x] = {}
		for y = 0,31 do
			local line = sections.map and sections.map[y+1] or emptyline_map
			local hex = string.sub(line, x*2+1, x*2+2)
			data.map[x][y] = fromhex(hex)
		end
		for y = 32,63 do
			local _x = x%64
			local _y = x <= 63 and y*2 or y*2+1
			local line = sections.gfx and sections.gfx[_y+1] or emptyline_gfx
			local hex = string.sub(line, _x*2+1, _x*2+2)
			data.map[x][y] = fromhex_swapnibbles(hex)
		end
	end

	-- Look for configuration block
	-- Use EXT format if it exists
	local code = sections.lua and table.concat(sections.lua, "\n") or ""
    local conf = string.match(code, "%-%-@conf([^@]+)%-%-@")
	conf = sections["meta:everhorn"] and table.concat(sections["meta:everhorn"], "\n") or conf
	
	-- Load configuration, run as code snippets in data.conf
	if conf then
        conf = string.match(conf, "%-%-%[%[([^@]+)%]%]")
		if conf then
			local chunk, err = loadstring(conf)
			if not err then
				chunk = setfenv(chunk, data.conf)
				chunk()
			end
		end
	end

	-- Load level data
	local everhorn_chunk = string.match(code, "%-%-@begin(.-)%-%-@end")
	local levels, mapdata, triggers
	if everhorn_chunk then
		-- Use new format or get parameter names from commented string
        local param_string = everhorn_chunk:match("%-%-\"x,y,w,h,exit_dirs,?(.-)\"")
        data.conf.param_names = data.conf.param_names or split(param_string or "")

		-- Load level data using interpreter
		local chunk, err = loadstring(everhorn_chunk)
		if not err then
			local env = {}
			chunk = setfenv(chunk, env)
			chunk()

			levels, mapdata, triggers = env.levels, env.mapdata, env.triggers or env.camera_offsets
		end
	end

	-- Default configs
	if data.conf.include_exits == nil then data.conf.include_exits = true end
	data.conf.param_names = data.conf.param_names or {}

	-- Convert parameters to EXT format
	for i,v in ipairs(data.conf.param_names) do
		if type(v) == "string" then
			data.conf.param_names[i] = {v, TYPE_STRING}
		end
	end

	-- Flatten levels and mapdata
	local levels_sorted = {}
	mapdata = mapdata or {}
	if levels then
		for i,levelstr in pairs(levels) do
			table.insert(levels_sorted, {i, levelstr, mapdata[i]})
		end
	end

	table.sort(levels_sorted, function(a,b) return a[1] < b[1] end)
	levels, mapdata = {}, {}
	for i,level in pairs(levels_sorted) do
		levels[i] = level[2]
		mapdata[i] = level[3]
	end

	-- Parse levels into rooms, or create empty rooms if no levels exist
	if levels[1] then
		for i,str in pairs(levels) do
			local x,y,w,h,params = string.match(str, "^([^,]*),([^,]*),([^,]*),([^,]*),?(.*)$")
			x,y,w,h = tonumber(x), tonumber(y), tonumber(w), tonumber(h)

			-- Load exits
			local params,exits = split(params or ""), { false,false,false,false }
			if data.conf.include_exits then
				exits = params[1] or 0
				exits = {left=bit.band(exits,2^3)~=0, bottom=bit.band(exits,2^2)~=0, right=bit.band(exits,2^1)~=0, top=bit.band(exits,2^0)~=0}
				table.remove(params, 1)
			end

			-- Generate room if the level data is correct
			if x and y and w and h then
				data.rooms[i] = newRoom(x*128, y*128, w*16, h*16)
				data.rooms[i].exits = exits
				data.rooms[i].is_string = false
				data.rooms[i].params = params
			else
				return false, "Level format failed to parse"
			end
		end
	else
		for y = 0,3 do
			for x = 0,7 do
				local room = newRoom(x*128, y*128, 16, 16)
				room.is_string = false
				table.insert(data.rooms, room)
			end
		end
	end

	-- Load encoded mapdata into rooms if it exists
	if mapdata then
		-- Use format from config
		if data.conf.format then
			for i,levelstr in pairs(mapdata) do
				local room = data.rooms[i]
				if room then
					formats[data.conf.format].load(room, levelstr)
					room.is_string = true
				end
			end

		-- Guess format based on string (hex or base256)
		else
			data.conf.format = export_hex.name
			for i,levelstr in pairs(mapdata) do
				local room = data.rooms[i]
				if room then
					if levelstr:match("[%da-f]") and #levelstr == room.w*room.h*2 then
						export_hex.load(room, levelstr)
					else
						export_base256.load(room, levelstr)
						data.conf.format = export_base256.name
					end
					room.is_string = true
				end
			end
		end
	end

	-- Load mapdata from PICO-8
	for i,room in ipairs(data.rooms) do
		if not room.is_string then
			local left,top = div8(room.x), div8(room.y)
			for x = 0,room.w-1 do
				for y = 0,room.h-1 do
					local tx,ty = left+x, top+y
					if tx >= 0 and tx < 128 and ty >= 0 and ty < 64 then
						room.data[x][y] = data.map[tx][ty]
					else
						room.data[x][y] = 0
					end
				end
			end
		end
	end

	-- Load triggers
	if triggers then
		for i,list in pairs(triggers) do
			if type(list) == "string" then
				list = split(list, "|")
			end
			for ii,trigger in pairs(list) do
				local args = {}
				for arg in trigger:gmatch("%s*[^,]+%s*") do
					table.insert(args, arg)
				end
				if data.rooms[i] then
					table.insert(data.rooms[i].camtriggers, {
						x = args[1], y = args[2],
						w = args[3], h = args[4],
						off_x = tonumber(args[5]),
						off_y = tonumber(args[6]),
					})
				end
			end
		end
	end

	-- Return
	return data
end

function savepico8(filename)
	local file = io.open(app.openFileName, "rb")
	if not file then return false end

	-- Load file
	local isrom = formats[project.conf.format].isrom
	local output = {}
	for line in cr_file_lines(file) do table.insert(output, line) end
	file:close()

	-- Insert missing sections
	if not table_pos(output, "__gfx__") then table.insert(output, "__gfx__") end
	if not table_pos(output, "__map__") then table.insert(output, "__map__") end

	-- Resize sections
	for i,line in ipairs(output) do
		if line == "__gfx__" or line == "__map__" then
			local emptyline = line == "__gfx__" and emptyline_gfx or emptyline_map

			-- Find end of section
			local endof = i+1
			while endof < #output and not output[endof]:match("__%a+__") do
				endof = endof+1
			end

			-- Resize (128 lines for gfx, 32 lines for map)
			for pos = endof, i+(line == "__gfx__" and 128 or 32) do
				table.insert(output, pos, emptyline)
			end
		end
	end

	-- Get start of resized sections
	local gfx_start, map_start
	for i,line in ipairs(output) do
		if line == "__gfx__" then gfx_start = i
		elseif line == "__map__" then map_start = i end
	end
	
	-- Generate cart mapdata
	local raw_map = table_2d(128, 64, 0)
	local is_room = table_2d(128, 64, false)
	for i,room in ipairs(project.rooms) do
		if not room.is_string then
			local left, top = div8(room.x), div8(room.y)
			for x = 0,room.w-1 do
			for y = 0,room.h-1 do
				if raw_map[left+x] then
					raw_map[left+x][top+y] = room.data[x][y]
					is_room[left+x][top+y] = true
				end
			end end
		end
	end

	-- Mapdata [MAP]
	for y = 0,31 do
		local newline = ""
		for x = 0,127 do
			newline = newline..tohex(raw_map[x][y])
		end
		output[map_start+y+1] = newline
	end

	-- Mapdata [SPRITESHEET]
	for y = 32,63 do
		-- Y relative to start of section, add offset to get lower half of spritesheet
		-- Both lines combined, to fix sprite/map length difference
		local line = output[gfx_start + (y-32)*2 + 65] .. output[gfx_start + (y-32)*2 + 66]
		local newline = ""
		for x = 0,127 do
			-- Overwrite hex with mapdata
			if is_room[x][y] then
				newline = newline..tohex_swapnibbles(raw_map[x][y])
			-- Copy hex instead 
			else
				newline = newline..line:sub(x*2+1, x*2+2)
			end
		end
		output[gfx_start + (y-32)*2 + 65] = string.sub(newline, 1, 128)
		output[gfx_start + (y-32)*2 + 66] = string.sub(newline, 129, 256)
	end

	-- Generate code
    local levels, mapdata, triggers = {}, {}, {}
    for n = 1, #project.rooms do
        local room = project.rooms[n]
        levels[n] = string.format("%g,%g,%g,%g", room.x/128, room.y/128, room.w/16, room.h/16)

		-- Level exits ==========================
		if project.conf.include_exits then
			local exit_string="0b"
			for _,v in pairs({"left","bottom","right","top"}) do
				if room.exits[v] then
					exit_string=exit_string.."1"
				else
					exit_string=exit_string.."0"
				end
			end
			levels[n] = levels[n]..","..exit_string
		end

		-- Level parameters =====================
        for _,v in ipairs(room.params) do
            levels[n]=levels[n]..","..v
        end

		-- Level mapdata ========================
        if room.is_string then
			mapdata[n] = formats[project.conf.format].dump(room)
        end

		-- Level triggers =======================
        if room.camtriggers then
            triggers[n]=""
            for _,t in pairs(room.camtriggers) do
				local trigger_str = string.format("%d,%d,%d,%d,%s,%s|",t.x,t.y,t.w,t.h,t.off_x,t.off_y)
				triggers[n] = triggers[n]..trigger_str
            end
			triggers[n] = triggers[n]:sub(1,#triggers[n]-1)
        end
    end

	-- Combine output into a single string for operations
	local cartdata = table.concat(output, "\n").."\n"

	-- !!! Inject code !!!
	local function inject(...)
		cartdata = cartdata:gsub(...)
	end

	-- Append missing configuration block
	if not cartdata:match("__meta:everhorn__") then
		cartdata = cartdata.."__meta:everhorn__\n--[[ ]]\n"
	end

	-- Rewrite configuration block
    local conf = ""
    for key, value in pairs(project.conf) do
		conf = conf .. key .. "=" .. dumplualine(value) .. "\n"
    end
	inject("__meta:everhorn__.-%-%-%[%[.-%]%]", "__meta:everhorn__\n--[[\n"..conf.."]]")

	-- Levels table
	inject("(%-%-@begin.*levels%s*=%s*){.-}(.*%-%-@end)","%1"..dumplua(levels).."%2")
    
	-- Map data
	if isrom then
		
	else
		-- This is done in a function instead of a string with references, in order to avoid having to escape special chars in the mapdata
		inject("(%-%-@begin.*mapdata%s*=%s*){.-\n}(.*%-%-@end)", function(a,b) return a..dumplua(mapdata)..b end )
	end

	-- Alternative camera offsets and triggers for compatibility 
    inject("(%-%-@begin.*camera_offsets%s*=%s*)%b{}(.*%-%-@end)","%1"..dumplua(triggers).."%2")
    inject("(%-%-@begin.*triggers%s*=%s*)%b{}(.*%-%-@end)","%1"..dumplua(triggers).."%2")

    -- Playtesting insertion
    inject("(%-%-@begin.*)local __init.-\n(.*%-%-@end)","%1".."%2")
    if app.playtesting and app.room then
        inject("%-%-@end",string.format(playtest_snippet[app.playtesting], app.room).."\n--@end")
    end

	-- Save file
    file = io.open(filename, "wb")
    file:write(cartdata)
    file:close()

	return true
end
