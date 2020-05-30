function ui_setCheckpoint(checkpoint)
    SendNUIMessage({action = "set_checkpoint", checkpoint = checkpoint})
end

function ui_setLap(lap)
    SendNUIMessage({action = "set_lap", lap = lap})
end

function ui_startRace()
    SendNUIMessage({action = "start"})
    SetNuiFocus(false, false)
end

function ui_show(race_info)
    SendNUIMessage({action = "show_ui", race_info = race_info})
    SetNuiFocus(false, false)
end

function ui_hide()
    SendNUIMessage({action = "hide_ui"})
    SetNuiFocus(false, false)
end

