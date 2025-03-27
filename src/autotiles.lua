--  8
--2 O 1
--  4

function updateAutotiles()
    -- calculates auxillary tables for autotile manipulation

    project.autotilet, project.autotilet_strict = {}, {}
    -- n => set of autotiles n belongs to
    -- strict excludes extra autotiles (>=16)

    for n = 0, 255 do
        project.autotilet[n] = {}
        project.autotilet_strict[n] = {}
    end

    for k, auto in pairs(project.conf.autotiles) do
        for o, n in pairs(auto) do
            project.autotilet[n][k] = true
            if o >= 0 and o < 16 then
                project.autotilet_strict[n][k] = true
            end
        end
    end
end

-- out of bounds matched all tilesets
local oob = {}
for n = 0, 255 do
    oob[n] = true
end

local function matchAutotile(room, i, j, strict)
    if i >= 0 and i < room.w and j >= 0 and j < room.h then
        local t = strict and project.autotilet_strict or project.autotilet
        return t[room.data[i][j]]
    else
        return oob
    end
end

local function b1(b) -- converts truthy to 1, falsy to 0
    return b and 1 or 0
end

function autotile(room, i, j, k)
    local match = matchAutotile(room, i, j, true)
    if k and match ~= oob and match[k] then
        local nb = b1(matchAutotile(room, i + 1, j)[k])
                 + b1(matchAutotile(room, i - 1, j)[k]) * 2
                 + b1(matchAutotile(room, i, j + 1)[k]) * 4
                 + b1(matchAutotile(room, i, j - 1)[k]) * 8
        room.data[i][j] = project.conf.autotiles[k][nb]
    end
end

function autotileWithNeighbors(room, i, j, k)
    autotile(room, i, j, k)
    autotile(room, i + 1, j, k)
    autotile(room, i - 1, j, k)
    autotile(room, i, j + 1, k)
    autotile(room, i, j - 1, k)
end
