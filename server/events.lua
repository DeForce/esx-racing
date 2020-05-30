RegisterNetEvent('racing:server:saveRace')
AddEventHandler('racing:server:saveRace', function(name, type, laps, start, checkpoints)
    -- TODO: Get character name
    local owner = GetPlayerIdentifiers(source)[1]

    MySQL.ready(function ()
        MySQL.Async.insert("INSERT INTO racing (name, owner_id, type, default_lap_count, start_x, start_y, start_z, heading) VALUES (@name, @owner, @type, @laps, @start_x, @start_y, @start_z, @heading);", {
            ['@name'] = name, ['@owner'] = owner, ['@type'] = type, ['@laps'] = laps,
            ['@start_x'] = start.x, ['@start_y'] = start.y, ['@start_z'] = start.z, ['@heading'] = start.heading
        }, function(race_pk)

            for index, checkpoint in pairs(checkpoints) do
                MySQL.Async.insert("INSERT INTO racing_checkpoints (race_id, checkpoint_order, x, y, z, radius) VALUES (@race_id, @checkpoint_order, @x, @y, @z, @radius);", {
                    ['@race_id'] = race_pk, ['@checkpoint_order'] = index,
                    ['@x'] = checkpoint.x, ['@y'] = checkpoint.y, ['@z'] = checkpoint.z,
                    ['@radius'] = checkpoint.radius
                }, function(checkpoint_id)
                    print(('Checkpoint: %s'):format(checkpoint_id))
                end)
            end
        end)
    end)
end)


RegisterNetEvent('racing:server:startRace')
AddEventHandler('racing:server:startRace', function(player_id)
    local race_info = RACES[player_id]
    if race_info == nil then
        TriggerClientEvent('racing:client:startFailed', player_id, ('No race prepared, ignoring'))
        do return end
    elseif race_info.started then
        TriggerClientEvent('racing:client:startFailed', player_id, ('Race already started'))
        do return end
    end

    -- count participants and send race info to players.
    local participants_count = 0
    local participants = race_info.participants
    for _ in pairs(participants) do
        participants_count = participants_count + 1
    end
    RACES[player_id].total_count = participants_count

    -- Make sure there are no pending invites
    local pending_invites = race_info.pending_invites
    for id, v in pairs(pending_invites) do
        TriggerClientEvent('racing:client:inviteCancelled', id, race_info)
    end
    RACES[player_id].pending_invites = {}

    -- Start race for every participant
    RACES[player_id].started = true
    for id, v in pairs(participants) do
        TriggerClientEvent('racing:client:startRace', id, race_info)
    end

end)


RegisterNetEvent('racing:server:readyRace')
AddEventHandler('racing:server:readyRace', function(player_id, race_name)
    if RACES[player_id] ~= nil then
        TriggerClientEvent('racing:client:readyFailed', player_id, 'Race preparation is already in progress, ignoring')
        do return end
    end

    getRaceData(race_name, function(race_data, checkpoints)
        if checkpoints == nil then
            systemMessage(player_id, ('Unable to find race with name: %s'):format(race_name))
            do return end
        end

        local race_info = RaceInfo(player_id, race_name, race_data, checkpoints)
        RACES[player_id] = race_info

        local race_unique_id = player_id

        systemMessage(player_id, ('Showing Waypoints for %s'):format(race_name))
        TriggerClientEvent('racing:client:readyRace', player_id, race_unique_id, race_info)
    end)
end)

RegisterNetEvent('racing:server:cleanupRace')
AddEventHandler('racing:server:cleanupRace', function(race_unique_id)
    print(('Cleaning race: Source is %s, id is %s'):format(source, race_unique_id))
    -- empty string source is server side.
    if source == '' then
        RACES[race_unique_id] = nil
    elseif race_unique_id ~= nil then
        local player_id = source
        local race_data = RACES[race_unique_id]

        -- removing source user from participant list
        race_data.participants[player_id] = nil

        if race_unique_id ~= nil and race_unique_id == player_id then
            RACES[race_unique_id] = nil
        end
    end
end)

RegisterNetEvent('racing:server:playerFinished')
AddEventHandler('racing:server:playerFinished', function(race_unique_id)
    local race_data = RACES[race_unique_id]

    table.insert(race_data.finished, source)

    if (#race_data.finished == race_data.total_count) then
        for player_id, _ in pairs(race_data.participants) do
            TriggerClientEvent('racing:client:raceEnded', player_id)
        end
        TriggerEvent('racing:server:cleanupRace', race_unique_id)
    end
end)

RegisterNetEvent('racing:server:inviteAccepted')
AddEventHandler('racing:server:inviteAccepted', function(race_unique_id)
    local race_info = RACES[race_unique_id]

    race_info.participants[source] = true

    TriggerClientEvent('racing:client:invitationAccepted', race_info.owner, source)
    TriggerClientEvent('racing:client:readyRace', source, race_unique_id, race_info)
end)


RegisterNetEvent('racing:server:inviteDenied')
AddEventHandler('racing:server:inviteDenied', function(race_unique_id)
    local owner_id = RACES[race_unique_id].owner
    TriggerClientEvent('racing:client:invitationDenied', owner_id)
end)


RegisterNetEvent('racing:server:invitePlayer')
AddEventHandler('racing:server:invitePlayer', function(player_id, race_unique_id)
    local race_info = RACES[race_unique_id]
    local pending_invites = RACES[race_unique_id].pending_invites
    local participants = RACES[race_unique_id].participants

    if pending_invites[player_id] ~= nil then
        TriggerClientEvent('racing:client:inviteFailed', source, ('PlayerID %s is already being invited'):format(player_id))
        do return end
    end

    if participants[player_id] ~= nil then
        TriggerClientEvent('racing:client:inviteFailed', source, ('PlayerID %s is already in the race'):format(player_id))
        do return end
    end

    TriggerClientEvent('racing:client:receivingInvite', player_id, race_unique_id, race_info)
end)

RegisterNetEvent('racing:server:inviteCancel')
AddEventHandler('racing:server:inviteCancel', function(player_id, race_unique_id)
    local pending_invites = RACES[race_unique_id].pending_invites
    local participants = RACES[race_unique_id].participants

    if pending_invites[player_id] ~= nil then
        TriggerClientEvent('racing:client:inviteCancelled', player_id, ('PlayerID %s invite was cancelled'):format(player_id))
        pending_invites[player_id] = nil
    end

    if participants[player_id] ~= nil then
        TriggerClientEvent('racing:client:inviteCancelled', player_id, ('PlayerID %s was removed from the race'):format(player_id))
        participants[player_id] = nil
    end
end)
