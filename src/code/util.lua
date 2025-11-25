local utf8 = require("utf8")

function rgb(r,g,b) return rgba(r,g,b,1) end
function rgba(r,g,b,a) return { r/255,g/255,b/255,a } end

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

function tobool(x)
	if x=="true" then return true end
	if x=="false" then return false end
	if type(x)=="number" then return x>0 end
	return x~=false and x~=nil
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

function roomMakeStr(room)
    if room then
        room.str = export_hex.dump(room)
    end
end

function roomMakeData(room)
    if room then
        room.data = fill2d0s(room.w, room.h)
        export_hex.load(room, room.str)
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

-- emulate pico8's split
-- split , sperated list, auto convert numbers to ints
function split(str,delim)
    local tbl={}
    for val in string.gmatch(str, '([^'..(delim or ",")..']+)') do
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

-- TABLES 
function table_pos(table,v)
	for i,item in ipairs(table) do
		if item == v then return i end
	end
end

function table_2d(width, height, value)
	local t = {}
	for x = 0,width-1 do
		t[x] = {}
		for y = 0,height-1 do
			t[x][y] = value
		end
	end
	return t
end