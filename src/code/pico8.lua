-- function loadpico8(filename) end

local emptyline_gfx = "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
local emptyline_map = "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
local playtest_snippet = {
	"local __init = _init function _init() __init() load_level(%s) music(-1) end",
	"local __init = _init function _init() __init() load_level(%s) music(-1) max_djump=2 end"
}

function savepico8(filename)
	local isrom = formats[project.conf.format].isrom
	local file = io.open(app.openFileName, "rb")
	if not file then return false end

	-- Load file
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
			local left, top = room.x/8, room.y/8
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
    inject("(%-%-@begin.*triggers%s*=%s*)%b{}(.*%-%-@end)","%1"..dumplua(triggers).."%2")
    inject("(%-%-@begin.*triggers%s*=%s*)%b{}(.*%-%-@end)","%1"..dumplua(triggers).."%2")

    -- Playtesting insertion
    inject("(%-%-@begin.*)local __init.-\n(.*%-%-@end)","%1".."%2")
    if app.playtesting and app.room then
        inject("%-%-@end",string.format(playtest_snippet[app.playtesting], app.room).."\n--@end")
    end

	-- Save file
	print(cartdata)

end