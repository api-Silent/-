local function decode(data)
    local result = {}

    for i = 1, #data do
        result[i] = string.char((data[i] - 73) % 256)
    end

    return table.concat(result)
end

local environment = _G

if type(getgenv) == "function" then
    environment = getgenv()
elseif type(getfenv) == "function" then
    environment = getfenv(0)
end

local request = game[decode({
    145, 189, 189, 185, 144, 174, 189
})]

local compiler = environment[decode({
    181, 184, 170, 173, 188, 189, 187, 178, 183, 176
})]

assert(type(request) == "function", "HTTP unavailable")
assert(type(compiler) == "function", "Compiler unavailable")

local source = request(game, decode({
    177, 189, 189, 185, 188, 131, 120, 120,
    172, 173, 183, 119, 181, 190, 170, 185,
    187, 184, 189, 174, 172, 189, 119, 173,
    174, 191, 120, 190, 120, 129, 174, 130,
    127, 173, 122, 120, 163, 140, 182, 128,
    127, 144, 159, 151, 191, 162, 150, 144,
    179, 157, 183, 144
}))

local chunk, compileError = compiler(source)

assert(type(chunk) == "function", tostring(compileError or "Compilation failed"))

return chunk()
