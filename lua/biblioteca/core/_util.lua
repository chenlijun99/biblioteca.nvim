-- Credits. Copied from fzf.lua

local M = {}

M.ansi_codes = {}
M.ansi_escseq = {
    -- the "\x1b" esc sequence causes issues
    -- with older Lua versions
    -- clear    = "\x1b[0m",
    clear = '[0m',
    bold = '[1m',
    italic = '[3m',
    underline = '[4m',
    black = '[0;30m',
    red = '[0;31m',
    green = '[0;32m',
    yellow = '[0;33m',
    blue = '[0;34m',
    magenta = '[0;35m',
    cyan = '[0;36m',
    white = '[0;37m',
    grey = '[0;90m',
    dark_grey = '[0;97m',
}

M.cache_ansi_escseq = function(name, escseq)
    M.ansi_codes[name] = function(string)
        if string == nil or #string == 0 then
            return ''
        end
        if not escseq or #escseq == 0 then
            return string
        end
        return escseq .. string .. M.ansi_escseq.clear
    end
end

-- Generate a cached ansi sequence function for all basic colors
for color, escseq in pairs(M.ansi_escseq) do
    M.cache_ansi_escseq(color, escseq)
end

return M
