function setupRaceOnMap(race_info, follow_player)
    local checkpoints = race_info.checkpoints
    RACE_DATA = race_info.race_data
    ClearGpsMultiRoute()
    StartGpsMultiRoute(6, follow_player, true)

    AddPointToGpsMultiRoute(RACE_DATA.start.x, RACE_DATA.start.y, RACE_DATA.start.z)
    for k, checkpoint in pairs(checkpoints) do
        table.insert(CHECKPOINTS, checkpoint)
        table.insert(BLIPS, AddBlipForCoord(checkpoint.x, checkpoint.y, checkpoint.z))
        AddPointToGpsMultiRoute(checkpoint.x, checkpoint.y, checkpoint.z)
    end

    SetGpsMultiRouteRender(true)
    reloadBlips()
end


RegisterNetEvent('racing:client:createRace')
AddEventHandler('racing:client:createRace', function()
    if CREATING_RACE then
        ESX.ShowNotification('Already creating a race, ignoring!')
        do return end
    end

    ESX.ShowNotification('Creating Race')
    local player_ped = PlayerPedId()
    local heading = GetEntityHeading(player_ped)
    local playerCoords = GetEntityCoords(player_ped)

    RACE_DATA.start.x = playerCoords.x
    RACE_DATA.start.y = playerCoords.y
    RACE_DATA.start.z = playerCoords.z
    RACE_DATA.start.heading = heading

    -- Reset values
    MAIN_LOGIC_INTERVAL = CREATING_RACE_INTERVAL
    CREATING_RACE = true
    CHECKPOINTS = {}
    BLIPS = {}
end)


RegisterNetEvent('racing:client:checkpointAdd')
AddEventHandler('racing:client:checkpointAdd', function(args)
    if not CREATING_RACE then
        ESX.ShowNotification('Not creating a race, ignoring command')
        do return end
    end

    local radius = args[1]
    if radius == nil then
        radius = RACE_MARKER_DEFAULT_DISTANCE
    end

    local playerCoords = GetEntityCoords(PlayerPedId())
    local checkpoint = {
        x = playerCoords.x,
        y = playerCoords.y,
        z = playerCoords.z,
        radius = radius
    }
    table.insert(CHECKPOINTS, checkpoint)
    table.insert(BLIPS, AddBlipForCoord(playerCoords.x, playerCoords.y, playerCoords.z))
    ESX.ShowNotification(('Adding checkpoint %s'):format(#CHECKPOINTS))

    reloadBlips()
end)


RegisterNetEvent('racing:client:checkpointUndo')
AddEventHandler('racing:client:checkpointUndo', function()
    if not CREATING_RACE then
        ESX.ShowNotification('Not creating a race, ignoring command')
        do return end
    end

    local checkpoints_length = #CHECKPOINTS
    if not checkpoints_length then
        ESX.ShowNotification('No checkpoints available, nothing to undo')
        do return end
    end

    table.remove(CHECKPOINTS, checkpoints_length)
    RemoveBlip(BLIPS[checkpoints_length])
    table.remove(BLIPS, checkpoints_length)
    ESX.ShowNotification((('Removed checkpoint %s'):format(checkpoints_length)))

    reloadBlips()
end)

RegisterNetEvent('racing:client:showRace')
AddEventHandler('racing:client:showRace', function(race_info)
    local race_data = race_info.race_data

    print(("Name: %s, Type: %s, Checkpoint Count: %s"):format(race_data.name, race_data.type, #race_info.checkpoints))

    SHOWING_RACE = true
    setupRaceOnMap(race_info, false)
end)


RegisterNetEvent('racing:client:readyRace')
AddEventHandler('racing:client:readyRace', function(race_unique_id, race_info)
    TriggerEvent('racing:client:clearRace', race_info)

    STARTING_RACE = true
    RACE_UNIQUE_ID = race_unique_id
    MAIN_LOGIC_INTERVAL = READY_RACE_INTERVAL

    local race_data = race_info.race_data
    STARTING_BLIP = AddBlipForCoord(race_data.start.x, race_data.start.y, race_data.start.z)
    local blip = STARTING_BLIP
    -- Race Flag
    SetBlipSprite(blip, RACE_START_BLIP)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 1.0)
    SetBlipColour(blip, 2)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('RACE_START')
    EndTextCommandSetBlipName(blip)

    TriggerEvent('racing:client:showRace', race_info)
end)


RegisterNetEvent('racing:client:readyFailed')
AddEventHandler('racing:client:readyFailed', function(reason)
    ESX.ShowNotification(reason)
end)


RegisterNetEvent('racing:client:startRace')
AddEventHandler('racing:client:startRace', function(race_info)
    local race_data = race_info.race_data
    print(("Name: %s, Type: %s, Checkpoint Count: %s"):format(race_data.name, race_data.type, #race_info.checkpoints))

    MAIN_LOGIC_INTERVAL = RUNNING_RACE_INTERVAL
    STARTING_RACE = false
    RUNNING_RACE = true
    CURRENT_LAP = 1
    TOTAL_LAPS = race_data.laps
    NEXT_CHECKPOINT = 1

    -- Remove old blips as we are recreating them.
    for _, v in pairs(BLIPS) do
        RemoveBlip(v)
    end

    RemoveBlip(STARTING_BLIP)
    STARTING_BLIP = nil

    BLIPS = {}
    CHECKPOINTS = {}

    setupRaceOnMap(race_info, true)
    ui_show(race_info)

    for i=5, 1, -1 do
        PlaySound(-1, 'RACE_PLACED', 'HUD_AWARDS', 0, 0, 1)
        ESX.ShowNotification(('Starting in %s'):format(i))
        ESX.Scaleform.ShowFreemodeMessage(i, "Get Ready!", 1)
        Wait(400)
    end

    PlaySound(-1, 'RACE_PLACED', 'HUD_AWARDS', 0, 0, 1)
    ESX.ShowNotification(('~g~%s~s~'):format('RACE STARTED, GOGOGO'))
    ui_startRace()
    ESX.Scaleform.ShowFreemodeMessage("~g~Go Go Go~s~", "", 0.9)
end)


RegisterNetEvent('racing:client:saveRace')
AddEventHandler('racing:client:saveRace', function(args)
    if not CREATING_RACE then
        ESX.ShowNotification('Not in process of creating a race, nothing to do')
        do return end
    end

    local race_name = args[1]
    local race_type = args[2]
    local laps = (race_type == RACE_TYPES.sprint) and 1 or args[3]

    RACE_DATA.name = race_name
    RACE_DATA.type = race_type
    RACE_DATA.laps = laps

    if not (RACE_TYPES[race_type] ~= nil) then
        ESX.ShowNotification(('Invalid race type! Use: [%s]'):format(concatSet(RACE_TYPES, ', ')))
        do return end
    end

    if #CHECKPOINTS == 0 then
        ESX.ShowNotification('No checkpoints available, cleaning up')
    else
        TriggerServerEvent('racing:server:saveRace', RACE_DATA.name, RACE_DATA.type, RACE_DATA.laps, RACE_DATA.start, CHECKPOINTS)
        ESX.ShowNotification(('Race %s saved'):format(RACE_DATA.name))
    end

    for index, _ in pairs(CHECKPOINTS) do
        RemoveBlip(BLIPS[index])
    end

    CREATING_RACE = false
    CHECKPOINTS = {}
    BLIPS = {}
end)


RegisterNetEvent('racing:client:startFailed')
AddEventHandler('racing:client:startFailed', function(reason)
    ESX.ShowNotification(reason)
end)


RegisterNetEvent('racing:client:finishedRace')
AddEventHandler('racing:client:finishedRace', function()
    ESX.ShowNotification(('You have finished!'))
    TriggerServerEvent('racing:server:playerFinished', RACE_UNIQUE_ID)
    TriggerEvent('racing:client:clearRace')
end)


RegisterNetEvent('racing:client:raceEnded')
AddEventHandler('racing:client:raceEnded', function()
    ESX.ShowNotification(('Race is done. Thank you for participating!'))
    TriggerEvent('racing:client:clearRace')
end)


RegisterNetEvent('racing:client:clearRace')
AddEventHandler('racing:client:clearRace', function()
    CREATING_RACE = false
    STARTING_RACE = false
    RUNNING_RACE = false
    SHOWING_RACE = false
    MAIN_LOGIC_INTERVAL = DEFAULT_INTERVAL

    PENDING_RACE_INVITE = nil
    RACE_UNIQUE_ID = nil

    for _, v in pairs(BLIPS) do
        RemoveBlip(v)
    end

    RemoveBlip(STARTING_BLIP)
    STARTING_BLIP = nil

    NEXT_CHECKPOINT = nil
    CURRENT_LAP = nil
    TOTAL_LAPS = nil

    CHECKPOINTS = {}
    BLIPS = {}

    ui_hide()
    ClearGpsMultiRoute()
    reloadBlips()
end)


RegisterNetEvent('racing:client:invite')
AddEventHandler('racing:client:invite', function()
    if not STARTING_RACE then
        ESX.ShowNotification('Race has not been started, ignoring command')
        do return end
    end

    local invited_id = tonumber(args[1])
    local players = GetActivePlayers()

    for _, id in pairs(players) do
        local player_server_id = GetPlayerServerId(id)
        if invited_id == player_server_id then
            ESX.ShowNotification((('Invited %s for race %s'):format(invited_id, RACE_UNIQUE_ID)))
            TriggerServerEvent('racing:server:invitePlayer', invited_id, RACE_UNIQUE_ID)
            do return end
        end
    end

    ESX.ShowNotification(('Unable to find player with ID %s'):format(invited_id))
end)


RegisterNetEvent('racing:client:inviteDeny')
AddEventHandler('racing:client:inviteDeny', function()
    if PENDING_RACE_INVITE == nil then
        ESX.ShowNotification('No pending invites')
        do return end
    end

    TriggerServerEvent('racing:server:inviteDenied', PENDING_RACE_INVITE)
    PENDING_RACE_INVITE = nil
    ESX.ShowNotification('Invitation was denied')
end)


RegisterNetEvent('racing:client:inviteAccept')
AddEventHandler('racing:client:inviteAccept', function()
    if PENDING_RACE_INVITE == nil then
        ESX.ShowNotification('No pending invites')
        do return end
    end

    local unique_id = PENDING_RACE_INVITE

    PENDING_RACE_INVITE = nil
    ESX.ShowNotification(('Registered for race %s'):format(unique_id))

    TriggerEvent('racing:client:clearRace', race_info)
    TriggerServerEvent('racing:server:inviteAccepted', unique_id)
end)


RegisterNetEvent('racing:client:inviteAccept')
AddEventHandler('racing:client:inviteAccept', function(args)
    if RACE_UNIQUE_ID == nil then
        ESX.ShowNotification('No race preparation in progress, skipping')
        do return end
    end

    local player_id = tonumber(args[1])
    ESX.ShowNotification(('Cancelling invitation for %s'):format(player_id))
    TriggerServerEvent('racing:server:inviteCancel', player_id, RACE_UNIQUE_ID)
end)


RegisterNetEvent('racing:client:inviteCancelled')
AddEventHandler('racing:client:inviteCancelled', function(race_info)
    PENDING_RACE_INVITE = nil
    TriggerEvent('racing:client:clearRace')
    ESX.ShowNotification(('Invitation for race %s was cancelled.'):format(race_info.race_id))
end)


RegisterNetEvent('racing:client:inviteFailed')
AddEventHandler('racing:client:inviteFailed', function(reason)
    ESX.ShowNotification(reason)
end)


RegisterNetEvent('racing:client:receivingInvite')
AddEventHandler('racing:client:receivingInvite', function(race_unique_id, race_info)
    PENDING_RACE_INVITE = race_unique_id
    ESX.ShowNotification(('Name: %s, Type: %s, Laps: %s'):format(
            race_info.race_data.name, race_info.race_data.type, race_info.race_data.laps))
    ESX.ShowNotification(('Pending notification for the race %s! /race_invite_accept to accept.'):format(race_unique_id))
end)


RegisterNetEvent('racing:client:invitationDenied')
AddEventHandler('racing:client:invitationDenied', function(player_id)
    ESX.ShowNotification(('Invitation sent to %s was denied.'):format(player_id))
end)


RegisterNetEvent('racing:client:invitationAccepted')
AddEventHandler('racing:client:invitationAccepted', function(player_id)
    ESX.ShowNotification(('Invitation sent to %s was accepted.'):format(player_id))
end)
