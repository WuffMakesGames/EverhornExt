local format = {}
format.name = "Hex"
format.desc = "Stores level data in a hexadecimal format. You can use tonum(hex, 0x1) to get the value from hex."

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