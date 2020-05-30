ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

-- Static variables
RACE_MARKER_DEFAULT_DISTANCE = 10
RACE_MARKER = 23
RACE_START_MARKER = 4
RACE_START_BLIP = 38
RACE_TYPES = {sprint = 'sprint', lap = 'lap'}

FINISH_ACTIONS = { save = 'save', clear = 'clear'}

DEFAULT_INTERVAL = 1000      -- Nothing to do - sleeping for 1 second
CREATING_RACE_INTERVAL = 1   -- When creating a race - we need to the markers
READY_RACE_INTERVAL = 1      -- same with showing, needed for start markers
RUNNING_RACE_INTERVAL = 50   -- When running a race we only need the checkpoint/lap logic

-- Dynamic variables
MAIN_LOGIC_INTERVAL = DEFAULT_INTERVAL
RACE_UNIQUE_ID = nil
PENDING_RACE_INVITE = nil

CREATING_RACE = false

SHOWING_RACE = false
STARTING_RACE = false
RUNNING_RACE = false

RACE_DATA = {
    name = nil,
    type = nil,
    laps = nil,
    start = {
        x = nil,
        y = nil,
        z = nil,
        heading = nil
    }
}

CURRENT_LAP     = nil
TOTAL_LAPS      = nil
NEXT_CHECKPOINT = nil
CHECKPOINTS   = {}
BLIPS         = {}
STARTING_BLIP = nil


RegisterCommand('race_create', function(_, _, _)
    TriggerEvent('racing:client:createRace')
end, false)


RegisterCommand('race_cancel', function()
    TriggerServerEvent('racing:server:cleanupRace', RACE_UNIQUE_ID)
    TriggerEvent('racing:client:clearRace')
end)


RegisterCommand('race_save', function(_, args, _)
    TriggerEvent('racing:client:saveRace', args)
end, false)


RegisterCommand('race_checkpoint_add', function(_, args, _)
    TriggerEvent('racing:client:checkpointAdd', args)
end, false)


RegisterCommand('race_checkpoint_undo', function(_, _, _)
    TriggerEvent('racing:client:checkpointUndo')
end, false)


RegisterCommand('race_invite', function(_, args, _)
    TriggerEvent('racing:client:invite', args)
end)

RegisterCommand('race_invite_deny', function(_, _, _)
    TriggerEvent('racing:client:inviteDeny')
end)


RegisterCommand('race_invite_accept', function(_, _, _)
    TriggerEvent('racing:client:inviteAccept')
end)


RegisterCommand('race_invite_cancel', function(_, args, _)
    TriggerEvent('racing:client:inviteCancel', args)
end)


function updateMultiGps()
    ClearGpsMultiRoute()
    StartGpsMultiRoute(6, true, true)
    for _, checkpoint in pairs(CHECKPOINTS) do
        AddPointToGpsMultiRoute(checkpoint.x, checkpoint.y, checkpoint.z)
    end
    SetGpsMultiRouteRender(true)
end


function reloadBlips()
    for index, _ in pairs(CHECKPOINTS) do
        local blip = BLIPS[index]
        -- scale bigger and color differently if it's next checkpoint
        local scale = (index == NEXT_CHECKPOINT) and 2.0 or 1.0
        local color = (index == NEXT_CHECKPOINT) and 54 or 48
        -- Purple circle with checkpoint counter.
        SetBlipSprite(blip, 1)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, scale)
        SetBlipColour(blip, color)
        SetBlipAsShortRange(blip, (index == NEXT_CHECKPOINT) and false or true)
        ShowNumberOnBlip(blip, index)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString('RACE')
        EndTextCommandSetBlipName(blip)
    end
end


-- Main logic loop for racing and editing
Citizen.CreateThread(function()
    while true do
        -- draw every couple frames
        Wait(MAIN_LOGIC_INTERVAL)

        if RUNNING_RACE then
            local position = GetEntityCoords(PlayerPedId())
            local checkpoint = CHECKPOINTS[NEXT_CHECKPOINT]

            local distance = GetDistanceBetweenCoords(
                    checkpoint.x, checkpoint.y, checkpoint.z,
                    position.x, position.y, position.z,
                    true)

            if distance < checkpoint.radius then
                ESX.ShowNotification(('Passed checkpoint %s'):format(NEXT_CHECKPOINT))
                local checkpoint_count = #CHECKPOINTS
                if (NEXT_CHECKPOINT == checkpoint_count) then
                    ESX.ShowNotification(('Lap %s finished'):format(CURRENT_LAP))
                    CURRENT_LAP = CURRENT_LAP + 1
                    ui_setLap(CURRENT_LAP)
                    if CURRENT_LAP > TOTAL_LAPS then
                        TriggerEvent('racing:client:finishedRace')
                    else
                        updateMultiGps()
                    end
                    NEXT_CHECKPOINT = 1
                else
                    NEXT_CHECKPOINT = NEXT_CHECKPOINT + 1
                end
                ui_setCheckpoint(NEXT_CHECKPOINT)
                reloadBlips()
            end
        elseif STARTING_RACE then
            -- Draw start line
            local position = RACE_DATA.start
            local checkpoint_pos = CHECKPOINTS[1]

            local direction = {
                x = position.x  - checkpoint_pos.x,
                y = position.y  - checkpoint_pos.y,
                z = 0
            }
            DrawMarker(
                    RACE_START_MARKER,
                    position.x, position.y, position.z - 1.5,              -- coordinates of marker
                    direction.x, direction.y, direction.z, 0.0, 0.0, 0.0,  -- direction and rotation
                    8.0, 8.0, 8.0,                                         -- scale
                    0, 128, 0, 100,                                        -- color
                    false, false, 2, false, nil, nil, false                -- other stuff
            )
        elseif CREATING_RACE then
            -- draw start
            local position = RACE_DATA.start
            DrawMarker(
                    RACE_MARKER,
                    position.x, position.y, position.z - 0.2,  -- coordinates of marker
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,              -- rotation and direction
                    4.0, 4.0, 4.0,                             -- scale
                    0, 255, 0, 200,                            -- color
                    false, false, 2, false, nil, nil, false    -- other stuff
            )
            for _, coords in pairs(CHECKPOINTS) do
                -- Create marker for checkpoint
                DrawMarker(
                        RACE_MARKER,
                        coords.x, coords.y, coords.z - 0.2,      -- coordinates of marker
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,            -- rotation and direction
                        4.0, 4.0, 4.0,                           -- scale
                        255, 255, 0, 200,                        -- color
                        false, false, 2, false, nil, nil, false  -- other stuff
                )
            end
        end
    end
end)


-- Register all command helpers.
Citizen.CreateThread(function()
    -- Client Commmands
    TriggerEvent('chat:addSuggestion', '/race_create', 'Create the race')
    TriggerEvent('chat:addSuggestion', '/race_save', 'Finish race creation and save', {
        { name="race_name", help="Name of the race"},
        { name="race_type", help=(("Type of the Race: [%s]"):format(concatSet(RACE_TYPES, ', ')))},
        { name="lap_count", help=("Lap count. Do not apply for sprints")}
    })
    TriggerEvent('chat:addSuggestion', '/race_checkpoint_undo', 'Undo last created checkpoint')
    TriggerEvent('chat:addSuggestion', '/race_checkpoint_add', 'Add checkpoint to a race', {
        { name="radius", help="Radius of the checkpoint, defaults to 10 (works okay for two-line road)"},
    })
    TriggerEvent('chat:addSuggestion', '/race_cancel', 'Cancel current running race')
    TriggerEvent('chat:addSuggestion', '/race_invite', 'Invite Players to Race', {
        { name="player_id", help=("ID of the target")}
    })
    TriggerEvent('chat:addSuggestion', '/race_invite_cancel', 'Cancel pending or accepted race invite for player', {
        { name="player_id", help=("ID of the target")}
    })
    TriggerEvent('chat:addSuggestion', '/race_invite_accept', 'Accept pending race invite')
    TriggerEvent('chat:addSuggestion', '/race_invite_deny', 'Deny pending race invite')

    -- Server Commands
    TriggerEvent('chat:addSuggestion', '/race_start', 'Start the currently prepared race')
    TriggerEvent('chat:addSuggestion', '/race_ready', 'Prepare race for running', {{ name="race_name", help="Name of the race"}})
    TriggerEvent('chat:addSuggestion', '/race_preview', 'Preview race', {{ name="race_name", help="Name of the race"}})
    TriggerEvent('chat:addSuggestion', '/race_list', 'List of available races')
end)