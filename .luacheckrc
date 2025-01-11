-- Reference: https://luacheck.readthedocs.io/en/stable/warnings.html
ignore = {
    '631', -- max_line_length
    '122', -- read-only field of global variable
}
read_globals = {
    'vim',
    'describe',
    'it',
    'assert',
}

-- Rerun tests only if their modification time changed.
cache = true

std = luajit

codes = true
self = false
