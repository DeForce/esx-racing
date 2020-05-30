ESX = nil

TriggerEvent('esx:getSharedObject', function(obj)
    ESX = obj
end)

function RaceInfo(owner_id, race_id, race_data, checkpoints)
    return {
        owner = owner_id,
        started = false,
        participants = {[owner_id] = true},
        pending_invites = {},
        total_count = nil,
        race_id = race_id,
        race_data = race_data,
        checkpoints = checkpoints,
        finished = {}
    }
end

RACES = {}

---getRaceData
---@param race_name string
---@param cb function
---@return string, table
function getRaceData(race_name, cb)
    MySQL.ready(function ()
        MySQL.Async.fetchAll("SELECT id, name, type, default_lap_count, start_x, start_y, start_z, heading FROM racing where name = @name;", { ['@name'] = race_name }, function(races)
            if not (#races == 1) then
                cb(nil, nil)
            else
                local race = races[1]
                local race_id = race.id

                -- Look at RACE_DATA model @client/main.lua:17
                local race_data = {
                    name = race.name,
                    type = race.type,
                    laps = race.default_lap_count,
                    start = {
                        x = race.start_x,
                        y = race.start_y,
                        z = race.start_z,
                        heading = race.heading
                    }
                }
                MySQL.Async.fetchAll("select race_id, checkpoint_order, x, y, z, radius from racing_checkpoints where race_id = @race_id;", {
                    ['@race_id'] = race_id
                }, function(checkpoint_items)
                    local checkpoints = {}
                    for _, item in pairs(checkpoint_items) do
                        checkpoints[item.checkpoint_order] = {
                            order = item.checkpoint_order,
                            x = item.x,
                            y = item.y,
                            z = item.z,
                            radius = item.radius
                        }
                    end
                    cb(race_data, checkpoints)
                end)
            end
        end)
    end)
end


function systemMessage(source, message)
    TriggerClientEvent('chat:addMessage', source, {
        template = ('<div class="chat-message system"><b>%s</div></div>'):format(message),
        args = {}
    })
end

RegisterCommand('race_start', function(source, args, rawCommand)
    TriggerEvent('racing:server:startRace', source)
end)

-- Shows race on map and shows starting position
RegisterCommand('race_ready', function(source, args, rawCommand)
    local race_name = args[1]

    TriggerEvent('racing:server:readyRace', source, race_name)
end, false)


-- Only shows race on map with blips
RegisterCommand('race_preview', function(source, args, rawCommand)
    local race_name = args[1]
    getRaceData(race_name, function(race_data, checkpoints)
        if checkpoints == nil then
            systemMessage(source, ('Unable to find race with name: %s'):format(race_name))
            do return end
        end

        local race_info = RaceInfo(source, source, race_data, checkpoints)

        systemMessage(source, ('Showing Waypoints for %s'):format(race_name))
        TriggerClientEvent('racing:client:showRace', source, race_info)
    end)
end, false)


RegisterCommand('race_list', function(source, args, rawCommand)
    MySQL.ready(function ()
        MySQL.Async.fetchAll("SELECT id, name FROM racing;", {}, function(returns)
            -- Return delimeted list
            local races = ""
            for row, item in pairs(returns) do
                -- doing string format would be more annoying
                races = races .. item.name .. ', '
            end
            races =  string.sub(races, 0, #races - 2)

            TriggerClientEvent('chat:addMessage', source, {
                template = '<div class="chat-message system"><b>Available races: [{0}]</div></div>',
                args = { races }
            })
        end)
    end)
end, false)
