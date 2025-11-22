local format = {}
format.name = "Base256"
format.desc = "Stores level data in a base256 character format. You can use ord() to get the value from the character."

-- Methods ======================================
local utf8 = require("utf8")
function format.load(room,levelstr)
    local i,j=0,0
    for pos,codepoint in utf8.codes(levelstr) do
        --p8scii has a couple of chars which are 2 bytes, the 2nd of which is 0xFE0F
        if codepoint~=0xFE0F then
            room.data[i][j]=frombase256(utf8.char(codepoint))
            i=i+1
            if i == room.w then
                i=0
                j=j+1
            end
        end
    end
end

function format.dump(room)
    local s = ""
    for j = 0, room.h - 1 do
        for i = 0, room.w - 1 do
            s = s .. tobase256(room.data[i][j])
        end
    end
    return s
end

-- Return =======================================
return format