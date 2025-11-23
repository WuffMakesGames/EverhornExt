local format = {}
format.name = "Rom"
format.desc = "ROM format will export mapdata as a separate cart alongside your game. This can then be loaded into memory using reload() in PICO-8. This exports all strings as if they were a single map. You may lose data if rooms overlap or are out of bounds."
format.isrom = true

-- Methods ======================================
-- Loads string data into a room
function format.load(room, levelstr)
    for i = 0, room.w - 1 do
        for j = 0, room.h - 1 do
            local k = i + j*room.w
            room.data[i][j] = fromhex(string.sub(levelstr, 1 + 2*k, 2 + 2*k))
        end
    end
end

-- Converts roomdata to string data
function format.dump(room)
    local s = ""
    for j = 0, room.h - 1 do
        for i = 0, room.w - 1 do
            s = s .. tohex(room.data[i][j])
        end
    end
    return s
end

-- Return =======================================
return format