local format = {}
format.name = "Hex"

-- Methods ======================================
function format.load(room, levelstr)
    for i = 0, room.w - 1 do
        for j = 0, room.h - 1 do
            local k = i + j*room.w
            room.data[i][j] = fromhex(string.sub(levelstr, 1 + 2*k, 2 + 2*k))
        end
    end
end

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