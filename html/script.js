const uiClass = "main_ui";
const classShown = "main_ui_shown";
const classHidden = "main_ui_hidden";

const checkpointClass = "current_checkpoint";
const totalCheckpointClass = "total_checkpoint";

const lapClass = "current_lap";
const totalLapClass = "total_lap";

let totalLapStart = null;
let currentLapStart = null;
let started = null;

let top_lap = null;

function setLap(lap) {
    currentLapStart = new Date();
    document.getElementById(lapClass).innerHTML = `${lap}`;
}

function setCheckpoint(checkpoint) {
    document.getElementById(checkpointClass).innerHTML = `${checkpoint}`;
}

function start() {
    totalLapStart = new Date();
    currentLapStart = new Date();

    started = setInterval(clockRunning, 7);
}

function stop() {
    clearInterval(started);
}

function reset() {
    clearInterval(started);
    totalLapStart = null;
    currentLapStart = null;
    top_lap = null;
    document.getElementById("total_time_counter").innerHTML = "00:00:00.000";
}

function get_delta_string(time) {
    let hour = time.getUTCHours().toString().padStart(2, '0');
    let min = time.getUTCMinutes().toString().padStart(2, '0');
    let sec = time.getUTCSeconds().toString().padStart(2, '0');
    let ms = time.getUTCMilliseconds().toString().padStart(3, '0');

    return `${hour}:${min}:${sec}.${ms}`
}

function clockRunning(){
    let currentTime = new Date();

    document.getElementById("total_time_counter").innerHTML = get_delta_string(new Date(currentTime - totalLapStart));
    document.getElementById("lap_time_counter").innerHTML = get_delta_string(new Date(currentTime - currentLapStart));
}

function hideUI() {
    let main_ui = document.getElementsByClassName(uiClass)[0];

    if (main_ui.classList.contains(classShown)) {
        main_ui.classList.remove(classShown);
        main_ui.classList.add(classHidden);
    }
}

function showUI(raceInfo) {
    let main_ui = document.getElementsByClassName(uiClass)[0];

    if (main_ui.classList.contains(classHidden)) {
        main_ui.classList.remove(classHidden);
        main_ui.classList.add(classShown);
    }

    document.getElementById(checkpointClass).innerHTML = "1";
    document.getElementById(totalCheckpointClass).innerHTML = `${raceInfo.checkpoints.length}`;

    document.getElementById(lapClass).innerHTML = "1";
    document.getElementById(totalLapClass).innerHTML = `${raceInfo.race_data.laps}`;
}

window.addEventListener('message', (event) => {
    let data = event.data;
    let action = data.action;

    switch(action) {
        case 'hide_ui':
            stop();
            reset();
            hideUI();
            break;
        case 'show_ui':
            showUI(data.race_info);
            break;
        case 'start':
            start();
            break;
        case 'set_lap':
            setLap(data.lap);
            break;
        case 'set_checkpoint':
            setCheckpoint(data.checkpoint);
            break;
    }
});
