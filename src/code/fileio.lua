-- Fix /r/n newline format
function cr_lines(str)
    return str:gsub('\r\n?', '\n'):gmatch('(.-)\n')
end

function cr_file_lines(file)
    local str = file:read('*a')
    if str:sub(#str, #str) ~= "\n" then
        str = str.."\n"
    end
    return cr_lines(str)
end

-- file handling
function _loadpico8(filename)
    love.graphics.setDefaultFilter("nearest", "nearest")

    local file, err = io.open(filename, "rb")
    local data = {}
    data.palette = {
        rgb(0, 0, 0),		rgb(29, 43, 83),	rgb(126, 37, 83),	rgb(0, 135, 81),
        rgb(171, 82, 54),	rgb(95, 87, 79),	rgb(194, 195, 199),rgb(255, 241, 232),
        rgb(255, 0, 77),	rgb(255, 163, 0),	rgb(255, 240, 36),	rgb(0, 231, 86),
        rgb(41, 173, 255),	rgb(131, 118, 156),rgb(255, 119, 168),rgb(255, 204, 170)
    }

    local sections = {}
    local cursec = nil
    for line in cr_file_lines(file) do
        local sec = string.match(line, "^__([%a_:]+)__$")
        if sec then
            cursec = sec
            sections[sec] = {}
        elseif cursec then
            table.insert(sections[cursec], line)
        end
    end
    file:close()

	-- Load font
    local p8font=love.image.newImageData("assets/pico-8_font.png")
    local function toGrey(x,y,r,g,b,a)
        return r*194/255,g*195/255,b*199/255,a
    end
    p8fontGrey=love.image.newImageData(p8font:getWidth(),p8font:getHeight(),p8font:getFormat(),p8font)
    p8fontGrey:mapPixel(toGrey)
    local function get_font_quad(digit)
        if digit<10 then
            return 8*digit,24,4,8
        else
            return 8*(digit-9),48,4,8
        end
    end

	-- Load spritesheet
    local spritesheet_data = love.image.newImageData(128, 128)
    for j = 0, spritesheet_data:getHeight() - 1 do
        local line = sections["gfx"] and sections["gfx"][j + 1] or "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
        for i = 0, spritesheet_data:getWidth() - 1 do
            local s = string.sub(line, 1 + i, 1 + i)
            local b = fromhex(s)
            local c = data.palette[b + 1]
            spritesheet_data:setPixel(i, j, c[1], c[2], c[3], 1)
        end
    end

	-- Garbage tiles
	local spritesheet_data_alt = spritesheet_data:clone()
    for j =8,15 do
        for i = 0, 15 do
            local id=i+16*(j-8)
            local d1=math.floor(id/16)
            local d2=id%16
            spritesheet_data_alt:paste(p8fontGrey,8*i,8*j,get_font_quad(d1))
            spritesheet_data_alt:paste(p8font,8*i+4,8*j,get_font_quad(d2))
        end
    end

    data.spritesheet = love.graphics.newImage(spritesheet_data)
    data.spritesheet_alt = love.graphics.newImage(spritesheet_data_alt)

    data.quads = {}
    for i = 0, 15 do
        for j = 0, 15 do
            data.quads[i + j*16] = love.graphics.newQuad(i*8, j*8, 8, 8, data.spritesheet:getDimensions())
        end
    end

    -- extra spritesheet with transparent black
    local spritesheet_data_copy = spritesheet_data:clone()
    spritesheet_data_copy:mapPixel(function(x, y, r, g, b, a) if r == 0 and g == 0 and b == 0 then return 0, 0, 0, 0 else return r, g, b, a end end)
    data.spritesheet_noblack = love.graphics.newImage(spritesheet_data_copy)

	-- Load mapdata
    data.map = {}
    for i = 0, 127  do
        data.map[i] = {}
        for j = 0, 31 do
            local line = sections["map"] and sections["map"][j + 1] or "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
            local s = string.sub(line, 1 + 2*i, 2 + 2*i)
            data.map[i][j] = fromhex(s)
        end
        for j = 32, 63 do
            local i_ = i%64
            local j_ = i <= 63 and j*2 or j*2 + 1
            local line = sections["gfx"][j_ + 1] or "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
            local s = string.sub(line, 1 + 2*i_, 2 + 2*i_)
            data.map[i][j] = fromhex_swapnibbles(s)
        end
    end

    data.rooms = {}
    data.roomBounds = {}

    -- code: look for the magic comment
    local code = table.concat(sections["lua"], "\n")
	data.conf = {}

    -- get configuration code, if exists
    local conf = string.match(code, "%-%-@conf([^@]+)%-%-@")
	if sections["meta:everhorn"] then
		conf = ""
		for i,line in ipairs(sections["meta:everhorn"]) do
			conf = conf..line.."\n"
		end
	end

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

    local evh = string.match(code, "%-%-@begin(.-)%-%-@end")
    local levels, mapdata, camera_offsets
    if evh then
        -- get names of parameters from commented string
        local param_string=evh:match("%-%-\"x,y,w,h,exit_dirs,?(.-)\"")
        data.conf.param_names = data.conf.param_names or split(param_string or "")

		-- Load stuff
        local chunk, err = loadstring(evh)
        if not err then
            local env = {}
            chunk = setfenv(chunk, env)
            chunk()

            levels, mapdata, camera_offsets = env.levels, env.mapdata, env.camera_offsets or env.triggers
        end
    end
    -- parameter names default to none
	if data.conf.include_exits == nil then data.conf.include_exits = true end
    data.conf.param_names = data.conf.param_names or {}

	-- Convert parameter strings to tables (old -> new format)
	for i,v in ipairs(data.conf.param_names) do
		if type(v)=="string" then
			data.conf.param_names[i] = {v, TYPE_STRING}
		end
	end

    -- flatten levels and mapdata
    local lvls = {}
    mapdata = mapdata or {}
    if levels then
        for n, s in pairs(levels) do
            table.insert(lvls, {n, s, mapdata[n]})
        end
    end
    table.sort(lvls, function(p1, p2) return p1[1] < p2[1] end)
    levels, mapdata = {}, {}
    for n, p in pairs(lvls) do
        levels[n] = p[2]
        mapdata[n] = p[3]
    end

    -- load levels
    if levels[1] then
        for n, s in pairs(levels) do
            local x, y, w, h, params = string.match(s, "^([^,]*),([^,]*),([^,]*),([^,]*),?(.*)$")
			x, y, w, h = tonumber(x), tonumber(y), tonumber(w), tonumber(h)

			-- Load exits
			local params,exits = split(params or ""), { false,false,false,false }
			if data.conf.include_exits then
				exits = params[1] or 0
				exits = {left=bit.band(exits,2^3)~=0, bottom=bit.band(exits,2^2)~=0, right=bit.band(exits,2^1)~=0, top=bit.band(exits,2^0)~=0}
				table.remove(params, 1)
			end

			-- Load data
            if x and y and w and h then -- this confirms they're there and they're numbers
                data.rooms[n] = newRoom(x*128, y*128, w*16, h*16)
                data.rooms[n].exits=exits
                data.rooms[n].is_string=false
                data.rooms[n].params=params
            else
                print("wat", s)
            end
        end
    else
        for J = 0, 3 do
            for I = 0, 7 do
                local room=newRoom(I*128, J*128, 16, 16)
                room.is_string = false
                --b.title=""
                table.insert(data.rooms, room)
            end
        end
    end

    -- Load mapdata =============================
	if mapdata then
		if data.conf.format then
			print("Format found:", data.conf.format)
			for n, levelstr in pairs(mapdata) do
				local room = data.rooms[n]
				if room then
					formats[data.conf.format].load(room, levelstr)
					room.is_string=true
				end
			end
		
		-- Assume format (hex or base256)
		else
			data.conf.format = export_hex.name
			for n, levelstr in pairs(mapdata) do
				local room = data.rooms[n]
				if room then
					if levelstr:match("[%da-f]") and #levelstr==room.w*room.h*2 then
						export_hex.load(room, levelstr)
					else
						export_base256.load(room, levelstr)
						data.conf.format = export_base256.name
					end
					room.is_string=true
				end
			end
		end
	end
	
    -- fill rooms with no mapdata from p8 map
    for n, room in ipairs(data.rooms) do
        if not room.is_string then
            for i = 0, room.w - 1 do
                for j = 0, room.h - 1 do
                    local i1, j1 = div8(room.x) + i, div8(room.y) + j
                    if i1 >= 0 and i1 < 128 and j1 >= 0 and j1 < 64 then
                        room.data[i][j] = data.map[i1][j1]
                    else
                        room.data[i][j] = 0
                    end
                end
            end
        end
    end

	-- Parse triggers ===========================
    if camera_offsets then
        for n,val in pairs(camera_offsets) do
			if type(val) == "string" then
				val = split(val, "|")
			end

			for _,tbl in pairs(val) do
				args={}
				-- strip leading and trailing whitespace
				-- off_x and off_y are strings and not numbers
				for d in tbl:gmatch("%s*[^,]+%s*") do
					table.insert(args,#args<4 and tonumber(d) or d)
				end
				if data.rooms[n] then
					table.insert(data.rooms[n].camtriggers,{x=args[1],y=args[2],w=args[3],h=args[4],off_x=args[5],off_y=args[6]})
				end
			end
        end
    end
    return data
end

function openPico8(filename)
	local data = loadpico8(filename)
	if not data then return false end

	-- Data loaded successfuly
    newProject()
	p8data,project.rooms = data,data.rooms

    -- Load config safely
    for k, v in pairs(p8data.conf) do
        project.conf[k] = v
    end
    updateAutotiles()

    app.openFileName = filename
    return true
end

function _savepico8(filename)
    local map = fill2d0s(128, 64)

    --boolean 128x64 table which marks which tiles are part of rooms
    local is_room={}
    for i=0,127 do is_room[i]={} end

    for _, room in ipairs(project.rooms) do
		if not room.is_string then
			local i0, j0 = div8(room.x), div8(room.y)
			for i = 0, room.w - 1 do
			for j = 0, room.h - 1 do
				if map[i0+i] then
					map[i0+i][j0+j] = room.data[i][j]
					is_room[i0+i][j0+j]=true
				end
			end end
		end
	end
	-- DEBUG
	-- print(dumplua(is_room))
	-- if true then return end
	-- /DEBUG

    -- use current cart as base
    file = io.open(app.openFileName, "rb")
    if not file then return false end

    local out = {}
    local ln = 1
    local gfxstart, mapstart
    for line in cr_file_lines(file) do
        table.insert(out, line)
        ln = ln + 1
    end
    file:close()

	-- Generate code
    local levels, mapdata, camera_offsets = {}, {}, {}
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
            camera_offsets[n]=""
            for _,t in pairs(room.camtriggers) do
				local trigger_str = string.format("%d,%d,%d,%d,%s,%s|",t.x,t.y,t.w,t.h,t.off_x,t.off_y)
				camera_offsets[n] = camera_offsets[n]..trigger_str
            end
			camera_offsets[n] = camera_offsets[n]:sub(1,#camera_offsets[n]-1)
        end
    end

    -- map section
    -- start out by making sure both sections exist, and are sized to max size
    local gfxexist, mapexist=false,false

	-- Find sections
    for k = 1, #out do
        if out[k] == "__gfx__" then
            gfxexist=true
        elseif out[k] == "__map__" then
            mapexist=true
        end
    end

	-- Insert sections if not found
    if not gfxexist then table.insert(out,"__gfx__") end
    if not mapexist then table.insert(out,"__map__") end

	-- Resize sections to max
    for k,v in ipairs(out) do
        if out[k]=="__gfx__" or out[k]=="__map__" then
            local j=k+1
            while j<=#out and not out[j]:match("__%a+__") do
                j=j+1
            end
            local emptyline=""
            for i=1,out[k]=="__gfx__" and 128 or 256 do
                emptyline=emptyline.."0"
            end
            for i=j,k+(out[k]=="__gfx__" and 128 or 32) do
                table.insert(out,i,emptyline)
            end
        end
    end

    local gfxstart, mapstart
    for k = 1, #out do
        if out[k] == "__gfx__" then
            gfxstart = k
        elseif out[k] == "__map__" then
            mapstart = k
        end
    end

	-- Neither exist, shouldn't be possible
    if not (mapstart and gfxstart) then error("uuuh") end

	-- MAPDATA [MAP]
    for j = 0, 31 do
        local line = ""
        for i = 0, 127 do
            line = line .. tohex(map[i][j])
        end
        out[mapstart+j+1] = line
    end

	-- MAPDATA [SPRITESHEET]
    for j = 32, 63 do
        local gfxline=out[gfxstart+(j-32)*2+65]..out[gfxstart+(j-32)*2+66]
        local line = ""
        for i = 0, 127 do
            -- Overwrite hex with map
            if is_room[i][j] then
                line = line .. tohex_swapnibbles(map[i][j])
			-- Copy hex from file
            else
                line= line .. gfxline:sub(2*i+1,2*i+2)
            end
        end
        out[gfxstart+(j-32)*2+65] = string.sub(line, 1, 128)
        out[gfxstart+(j-32)*2+66] = string.sub(line, 129, 256)
    end

    -- newline at the end to match vanilla carts
    local cartdata=table.concat(out, "\n") .. "\n"

	-- ! Code injections !

    -- add configuration block if missing
    if not cartdata:match("__meta:everhorn__") then
        cartdata = cartdata.."__meta:everhorn__\n--[[ ]]\n"
    end

    -- rewrite configuration block
    local confcode = ""
    for key, value in pairs(project.conf) do
		confcode = confcode .. key .. "=" .. dumplualine(value) .. "\n"
    end
    cartdata = cartdata:gsub("__meta:everhorn__.-%-%-%[%[.-%]%]", "__meta:everhorn__\n--[[\n"..confcode.."]]")

    -- write to levels table without overwriting the code
    cartdata = cartdata:gsub("(%-%-@begin.*levels%s*=%s*){.-}(.*%-%-@end)","%1"..dumplua(levels).."%2")
    cartdata = cartdata:gsub("(%-%-@begin.*mapdata%s*=%s*){.-\n}(.*%-%-@end)",
        --this is done in a function instead of a string with references, in order to avoid having to escape special chars in the mapdata
        function(a,b)
            return a..dumplua(mapdata)..b
        end
    )

    cartdata = cartdata:gsub("(%-%-@begin.*camera_offsets%s*=%s*)%b{}(.*%-%-@end)","%1"..dumplua(camera_offsets).."%2")
    cartdata = cartdata:gsub("(%-%-@begin.*triggers%s*=%s*)%b{}(.*%-%-@end)","%1"..dumplua(camera_offsets).."%2")

    --remove playtesting inject if one already exists:
    cartdata = cartdata:gsub("(%-%-@begin.*)local __init.-\n(.*%-%-@end)","%1".."%2")
    if app.playtesting and app.room then
        local inject = "local __init = _init function _init() __init() load_level("..app.room..") music(-1)"
        if app.playtesting == 2 then
            inject = inject.." max_djump=2"
        end
        inject = inject.." end"
        cartdata=cartdata:gsub("%-%-@end",inject.."\n--@end")
    end

	-- Save file
    -- file = io.open(filename, "wb")
    -- file:write(cartdata)
    -- file:close()
    return false
end

function openFile()
    local filename = filedialog.get_path("p8", "PICO-8")
    local openOk, err

    if filename then
        local ext = string.match(filename, ".(%w+)$")
        if ext == "p8" then
            openOk, err = openPico8(filename)
        end

        if openOk then
            app.history = {}
            app.historyN = 0
            pushHistory()
        end
    end

	-- Success/Failure
    if openOk then
        showMessage("Opened "..string.match(filename, "/([^/]*)$"))
        app.saveFileName = filename
    else
        showMessage(err or "Failed to open file")
    end
end

function saveFile(as)
    local filename
    if app.saveFileName and not as then
        filename = app.saveFileName
    else
        filename = filedialog.get_path("p8", "PICO-8")
    end

    if filename and savepico8(filename) then
        showMessage("Saved "..string.match(filename, "/([^/]*)$"))

        app.saveFileName = filename
    else
        showMessage("Failed to save cart")
    end
end
