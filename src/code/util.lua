local utf8 = require("utf8")

function isempty(t)
    for k, v in pairs(t) do
        return false
    end
    return true
end

function fromhex(s)
    return tonumber(s, 16)
end

function fromhex_swapnibbles(s)
    local x = fromhex(s)
    return math.floor(x/16) + 16*(x%16)
end

local hext = { [0] = 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 'a', 'b', 'c', 'd', 'e', 'f'}

function tohex(b)
    return hext[math.floor(b/16)]..hext[b%16]
end

function tohex_swapnibbles(b)
    return hext[b%16]..hext[math.floor(b/16)]
end


local b256_chars = {
    "¹", "²", "³", "⁴", "⁵", "⁶", "⁷", "⁸", "\t", "\n", "ᵇ",
    "ᶜ", "\r", "ᵉ", "ᶠ", "▮", "■", "□", "⁙", "⁘", "‖", "◀",
    "▶", "「", "」", "¥", "•", "、", "。", "゛", "゜", " ", "!",
    "\"", "#", "$", "%", "&", "'", "(", ")", "*", "+", ",", "-", ".", "/", "0",
    "1", "2", "3", "4", "5", "6", "7", "8", "9", ":", ";", "<", "=", ">", "?",
    "@", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N",
    "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "[", "\\", "]",
    "^", "_", "`", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l",
    "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "{",
    "|", "}", "~", "○", "█", "▒", "🐱", "⬇️", "░", "✽", "●",
    "♥", "☉", "웃", "⌂", "⬅️", "😐", "♪", "🅾️", "◆",
    "…", "➡️", "★", "⧗", "⬆️", "ˇ", "∧", "❎", "▤", "▥",
    "あ", "い", "う", "え", "お", "か", "き", "く", "け", "こ", "さ",
    "し", "す", "せ", "そ", "た", "ち", "つ", "て", "と", "な", "に",
    "ぬ", "ね", "の", "は", "ひ", "ふ", "へ", "ほ", "ま", "み", "む",
    "め", "も", "や", "ゆ", "よ", "ら", "り", "る", "れ", "ろ", "わ",
    "を", "ん", "っ", "ゃ", "ゅ", "ょ", "ア", "イ", "ウ", "エ", "オ",
    "カ", "キ", "ク", "ケ", "コ", "サ", "シ", "ス", "セ", "ソ", "タ",
    "チ", "ツ", "テ", "ト", "ナ", "ニ", "ヌ", "ネ", "ノ", "ハ", "ヒ",
    "フ", "ヘ", "ホ", "マ", "ミ", "ム", "メ", "モ", "ヤ", "ユ", "ヨ",
    "ラ", "リ", "ル", "レ", "ロ", "ワ", "ヲ", "ン", "ッ", "ャ", "ュ",
    "ョ", "◜", "◝", "\0"
}

local b256_to_vals={}
for k,v in pairs(b256_chars) do
    b256_to_vals[v]=k

    --for multi code point chars, allow decoding using only their first char
    if utf8.len(v)>1 then
        b256_to_vals[string.sub(v,1,utf8.offset(v,2)-1)]=k
    end
end

--we use a base256 format that is cyclically shifted by 1 from pico8's ord
function frombase256(x)
    return b256_to_vals[x]-1
end

function tobase256(x)
    return b256_chars[x+1]
end

function roundto8(x)
    return 8*math.floor(x/8 + 1/2)
end

function sign(x)
    return x > 0 and 1 or -1
end

function fill2d0s(w, h)
    local a = {}
    for i = 0, w - 1 do
        a[i] = {}
        for j = 0, h - 1 do
            a[i][j] = 0
        end
    end
    return a
end

function rectCont2Tiles(i, j, i_, j_)
    return math.min(i, i_), math.min(j, j_), math.abs(i - i_) + 1, math.abs(j - j_) + 1
end

function div8(x)
    return math.floor(x/8)
end

function dumplua(t)
    return serpent.block(t, {comment = false})
end

function dumplualine(t)
    return serpent.line(t, {comment = false})
end

function loadlua(s)
    f, err = loadstring("return "..s)
    if err then
        return nil, err
    else
        return f()
    end
end

local alph_ = "abcdefghijklmnopqrstuvwxyz"
local alph = {[0] = " "}
for i = 1, 26 do
    alph[i] = string.sub(alph_, i, i)
end

function b26(n)
    local m, n = math.floor(n / 26), n % 26
    if m > 0 then
        return b26(m - 1) .. alph[n + 1]
    else
        return alph[n + 1]
    end
end



function loadroomdata_hex(room, levelstr)
    for i = 0, room.w - 1 do
        for j = 0, room.h - 1 do
            local k = i + j*room.w
            room.data[i][j] = fromhex(string.sub(levelstr, 1 + 2*k, 2 + 2*k))
        end
    end
end

function dumproomdata_hex(room)
    local s = ""
    for j = 0, room.h - 1 do
        for i = 0, room.w - 1 do
            s = s .. tohex(room.data[i][j])
        end
    end
    return s
end

function loadroomdata_base256(room,levelstr)
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

function dumproomdata_base256(room)
    local s = ""
    for j = 0, room.h - 1 do
        for i = 0, room.w - 1 do
            s = s .. tobase256(room.data[i][j])
        end
    end
    return s
end

function roomMakeStr(room)
    if room then
        room.str = dumproomdata_hex(room)
    end
end

function roomMakeData(room)
    if room then
        room.data = fill2d0s(room.w, room.h)
        loadroomdata_hex(room, room.str)
    end
end

function loadproject(str)
    local proj = loadlua(str)
    for n, room in pairs(proj.rooms) do
        roomMakeData(room)
    end
    roomMakeData(proj.selection)

    return proj
end

function dumpproject(proj)
    for n, room in pairs(proj.rooms) do
        roomMakeStr(room)
    end
    roomMakeStr(proj.selection)

    return serpent.line(proj, {compact = true, comment = false, keyignore = {["data"] = true}})
end

function split(str)
    -- emulate pico8's split
    -- split , sperated list, auto convert numbers to ints
    local tbl={}
    for val in string.gmatch(str, '([^,]+)') do
        if tonumber(val) ~= nil then
            val=tonumber(val)
        end
        table.insert(tbl,val)
    end
    return tbl
end

function printbg(text, x, y, fgcol, bgcol, centerx, centery)
    local font = love.graphics.getFont()
    local w, h = font:getWidth(text), font:getHeight(text)

    if centerx then
        x = x - w/2
    end
    if centery then
        y = y - h/2
    end

    love.graphics.setColor(bgcol)
    love.graphics.rectangle("fill", x - 4, y - 4, w + 8, h + 8)

    love.graphics.setColor(fgcol)
    love.graphics.print(text, x, y)
end
