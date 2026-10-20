NetSceneLogs = {}

local Webhook = ''

local function SendSceneLog(Message)
    if Webhook == '' then return end

    PerformHttpRequest(Webhook, function() end, 'POST', json.encode({ username = 'Heino-NetScenes', content = Message }), { ['Content-Type'] = 'application/json' })
end

function NetSceneLogs.SceneStarted(Source, Name)
    SendSceneLog(('%s startede scene **%s**'):format(GetPlayerName(Source), Name))
end

function NetSceneLogs.SceneFinished(Source, Name)
    SendSceneLog(('%s afsluttede scene **%s**'):format(GetPlayerName(Source), Name))
end
