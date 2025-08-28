-- ===================================================================
-- SCRIPT LUA FINAL PARA INTEGRAÇÃO COM CHILLI HUB
-- ===================================================================

-- Configuracoes
local PORT = 51948
local HOST = "127.0.0.1"
local RETRY_DELAY = 5

-- Servicos
local HttpService = game:GetService("HttpService")

-- Variaveis
local isConnected = false
local isPaused = false

local function log(message)
    print("[AutoJoiner] " .. tostring(message))
end

local function onMessageReceived(message)
    local success, data = pcall(HttpService.JSONDecode, HttpService, message)
    if not success then
        log("Erro ao decodificar JSON: " .. tostring(data))
        return
    end

    if data.type == "status" then
        isPaused = data.paused
        log(isPaused and "<<<<< SCRIPT PAUSADO >>>>>" or ">>>>> SCRIPT REATIVADO <<<<<")
        return
    end

    -- Verifica se a mensagem e um comando de join e se o script nao esta pausado
    if data.type == "server_info" and data.job_id and not isPaused then
        log("Comando de join para Chilli Hub recebido com JobID: " .. data.job_id)

        -- ============================================================
        -- A MUDANÇA CRÍTICA ESTÁ AQUI
        -- Em vez de loadstring, chamamos a funcao do Chilli Hub.
        -- Se o nome da funcao nao for exatamente "ChilliHub:Join", voce
        -- precisa alterar APENAS a linha abaixo.
        -- ============================================================
        local success, err = pcall(function()
            -- Verifique se 'ChilliHub' e a variavel global correta
            if ChilliHub and ChilliHub.Join then
                log("Chamando a funcao de join do Chilli Hub...")
                ChilliHub:Join(data.job_id)
                log("Comando de join enviado para o Chilli Hub com sucesso!")
            else
                log("ERRO: Funcao de join do Chilli Hub ('ChilliHub:Join') nao encontrada!")
            end
        end)

        if not success then
            log("FALHA AO CHAMAR A FUNCAO DO CHILLI HUB: " .. tostring(err))
        end
    end
end

-- Funcao de conexao (esta versao ja esta correta e robusta)
local function connect()
    if isConnected then return end
    if not WebSocket or not WebSocket.new then return end

    local success, WebSocketClient = pcall(WebSocket.new, "ws://" .. HOST .. ":" .. PORT)

    if not success or not WebSocketClient then
        log("Falha ao conectar. Verifique se o script Python esta rodando.")
        return
    end

    isConnected = true
    log("✅ Conexao com o Python estabelecida!")

    WebSocketClient.OnMessage:Connect(onMessageReceived)
    WebSocketClient.OnClose:Connect(function()
        isConnected = false
        log("Conexao perdida. Tentando reconectar...")
    end)
end

-- Loop principal
task.spawn(function()
    while true do
        if not isConnected then
            pcall(connect)
        end
        task.wait(RETRY_DELAY)
    end
end)
