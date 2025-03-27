-- file picker
local ffi = require("ffi")
local com = ffi.load("Comdlg32")

ffi.cdef [[
	int MultiByteToWideChar(unsigned int codepage, unsigned long flags, const char* str, int strlen, wchar_t* wstr, int wstrlen);
	int WideCharToMultiByte(unsigned int codepage, unsigned long flags, const wchar_t* wstr, int wstrlen, char* str, int strlen, char* defchr, int* udefchr);

	typedef struct {
		unsigned long	lStructSize;
		void*			hwndOwner;
		void*			hInstance;
		const wchar_t*	lpstrFilter;
		wchar_t*		lpstrCustomFilter;
		unsigned long	nMaxCustFilter;
		unsigned long	nFilterIndex;
		wchar_t*		lpstrFile;
		unsigned long	nMaxFile;
		wchar_t*		lpstrFileTitle;
		unsigned long 	nMaxFileTitle;
		const wchar_t*	lpstrInitialDir;
		const wchar_t*	lpstrTitle;
		unsigned long 	flags;
		unsigned short	nFileOffset;
		unsigned short	nFileExtension;
		const wchar_t*	lpstrDefExt;
		unsigned long	lCustData;
		void*			lpfnHook;
		const wchar_t*	lpTemplateName;
		void*			pvReserved;
		unsigned long	dwReserved;
		unsigned long	flagsEx;
	} OPENFILENAMEW;

	int _chdir(const char *path);

	int GetOpenFileNameW(OPENFILENAMEW *lpofn);
]]

local function _T(utf8)
	local ptr = ffi.cast("const char*", utf8.."\0")
	local len = ffi.C.MultiByteToWideChar(65001, 0, ptr, #utf8 + 1, nil, 0)
	local utf16 = ffi.new("wchar_t[?]", len)
	ffi.C.MultiByteToWideChar(65001, 0, ptr, #utf8 + 1, utf16, len)
	return utf16, len
end

local function _TtoLuaStr(utf16, len)
	len = len or -1
	local mblen = ffi.C.WideCharToMultiByte(65001, 0, utf16, len, nil, 0, nil, nil)
	local mb = ffi.new("char[?]", mblen)
	ffi.C.WideCharToMultiByte(65001, 0, utf16, len, mb, mblen, nil, nil)
	return ffi.string(mb, mblen):sub(1, -2)
end

return function(title, directory, filter, filterindex, multiple)
	local wd = love.filesystem.getWorkingDirectory()
	local ofnptr = ffi.new("OPENFILENAMEW[1]")
	local ofn = ofnptr[0]

	ofn.lStructSize = ffi.sizeof("OPENFILENAMEW")
	ofn.hwndOwner = NULL

	ofn.lpstrFile = ffi.new("wchar_t[32768]")
	ofn.nMaxFile = 32767

	ofn.nFilterIndex = filterindex or 1

	if type(filter) == "string" then
		ofn.lpstrFilter = _T(filter.."\0")
	elseif type(filter) == "table" then
		local filterlist = {}
		local name
		for index, value in ipairs(filter) do
			if name then
				filterlist[#filterlist+1] = name.."\0"..value
				name = nil
			else
				name = value
			end
		end
		ofn.lpstrFilter = _T(table.concat(filterlist, "\0").."\0")
	else
		ofn.lpstrFilter = _T("All Files\0*.*\0")
	end

	if title then
		ofn.lpstrTitle = _T(title)
	end

	ofn.lpstrFileTitle = nil
	ofn.nMaxFileTitle = 0

	if directory then
		ofn.lpstrInitialDir = _T(directory:gsub("/", "\\").."\0")
	end

	ofn.flags = 0x02081804 + (multiple and 0x00000200 or 0)

	if com.GetOpenFileNameW(ofnptr) > 0 then
		if multiple then
			local list = {}
			local dir = _TtoLuaStr(ofn.lpstrFile):sub(1, -2):gsub("\\", "/")
			local ptr = ofn.lpstrFile + #dir + 1

			if dir:sub(-1) == "/" then
				dir = dir:sub(1, -2)
			end

			while ptr[0] ~= 0 do
				local name = _TtoLuaStr(ptr)

				list[#list + 1] = dir.."/"..name:sub(1, -2)
				ptr = ptr + #name
			end

			if #list == 0 then
				list[1] = dir
			end

			ffi.C._chdir(wd)
			return unpack(list)
		else
			ffi.C._chdir(wd)
			return _TtoLuaStr(ofn.lpstrFile):gsub("\\", "/")
		end
	end

	return nil
end