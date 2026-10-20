NetSceneLogs = {}

local Webhook = ''

local function SendSceneLog(Source, Message)
    if Webhook == '' then return end
    if GetResourceState('heino_bridge') ~= 'started' then return end

    exports['heino_bridge']:DiscordWebhook(Source, {
        Webhook = Webhook,
        Resource = 'Heino-NetScenes',
        Message = Message,
    })
end

function NetSceneLogs.SceneStarted(Source, Name)
    SendSceneLog(Source, ('Startede scene **%s**'):format(Name))
end

function NetSceneLogs.SceneFinished(Source, Name)
    SendSceneLog(Source, ('Afsluttede scene **%s**'):format(Name))
end
