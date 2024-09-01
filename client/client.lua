local QBCore = exports['qb-core']:GetCoreObject()
local vehiclePedIsIn
local playerRaceStatus = {}
local racerName = string.format(string.sub(QBCore.Functions.GetPlayerData().charinfo.firstname, 1, 1) ..
    '. ' .. QBCore.Functions.GetPlayerData().charinfo.lastname)
local currentRaceState = {
    checkpoint = 1,
    index = 0,
    startTime = 0,
    scores = nil,
    blip = nil,
}

-- Array of colors to display scores, top to bottom and scores out of range will be white
local raceScoreColors = {
    { 214, 175, 54,  255 },
    { 167, 167, 173, 255 },
    { 167, 112, 68,  255 }
}

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Utils.createBlips()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Utils.createBlips()
    end
end)

CreateThread(function()
    preRace()
end)

function preRace()
    currentRaceState.index = 0
    currentRaceState.checkpoint = 1
    currentRaceState.startTime = 0
    currentRaceState.blip = nil
    -- While player is not racing
    while currentRaceState.index == 0 do
        Wait(1)
        local player = PlayerPedId()
        local inrange = false
        local playerCoords = GetEntityCoords(player)

        for index, race in pairs(TIMETRIAL_RACES) do
            if race.isEnabled then
                if #(vector3(race.start.x, race.start.y, race.start.z) - playerCoords) < Config.DRAW_MARKER_DISTANCE then
                    DrawMarker(1, race.start.x, race.start.y, race.start.z - 1, 0, 0, 0, 0, 0, 0, 3.0001, 3.0001, 1.5001,
                        255, 165, 0, 165, 0, 0, 0, 0)
                    inrange = true
                end
                if #(vector3(race.start.x, race.start.y, race.start.z) - playerCoords) < Config.DRAW_TEXT_DISTANCE then
                    local x, y, z = race.start.x, race.start.y, race.start.z - 0.600
                    Utils.Draw3DText(x, y, z, race.title, Config.RACING_HUD_COLOR, 4, 0.3, 0.3)
                end

                if #(vector3(race.start.x, race.start.y, race.start.z) - playerCoords) < Config.DRAW_SCORES_DISTANCE then
                    if currentRaceState.scores ~= nil then
                        -- Get scores for this race and sort them
                        local raceScores = currentRaceState.scores[race.title]
                        if raceScores ~= nil then
                            local sortedScores = {}
                            for k, v in pairs(raceScores) do
                                table.insert(sortedScores, { key = k, value = v })
                            end
                            table.sort(sortedScores, function(a, b) return a.value.time < b.value.time end)

                            local count = 0
                            drawScores = {}
                            for _, v in pairs(sortedScores) do
                                if count < Config.DRAW_SCORES_COUNT_MAX then
                                    count = count + 1
                                    table.insert(drawScores, v.value)
                                end
                            end

                            local zOffset = 0
                            if (#drawScores > #raceScoreColors) then
                                zOffset = 0.450 * (#raceScoreColors) + 0.300 * (#drawScores - #raceScoreColors - 1)
                            else
                                zOffset = 0.450 * (#drawScores - 1)
                            end

                            for k, score in pairs(drawScores) do
                                if (k > #raceScoreColors) then
                                    Utils.Draw3DText(race.start.x, race.start.y, race.start.z + zOffset,
                                        string.format("%s %.2fs (%s)", score.car, (score.time / 1000.0), score.player),
                                        { 255, 255, 255, 255 }, 4, 0.13, 0.13)
                                    zOffset = zOffset - 0.300
                                else
                                    Utils.Draw3DText(race.start.x, race.start.y, race.start.z + zOffset,
                                        string.format("%s %.2fs (%s)", score.car, (score.time / 1000.0), score.player),
                                        raceScoreColors[k], 4, 0.22, 0.22)
                                    zOffset = zOffset - 0.450
                                end
                            end
                        else
                            drawScores = nil
                        end
                    else
                        drawScores = nil
                    end
                end

                -- When close enough, prompt player
                if #(vector3(race.start.x, race.start.y, race.start.z) - playerCoords) < Config.START_PROMPT_DISTANCE then
                    Utils.RacePromptMessage("Press ~INPUT_CONTEXT~ to Race!", 5000)
                    if (IsControlJustReleased(1, 51)) then
                        local canRace = true
                        local currTime = GetGameTimer()
                        -- Set race index, clear scores and trigger event to start the race
                        for k, v in pairs(playerRaceStatus) do
                            if v.player == PlayerId() and v.race == index then
                                tableIndex = k
                                if (v.time + Config.COOLDOWN > currTime) then
                                    canRace = false
                                    QBCore.Functions.Notify("You can only do this race again in " ..
                                        ((v.time + Config.COOLDOWN) - currTime) / 1000 .. 's', "error")
                                    break
                                else
                                    table.remove(playerRaceStatus, k)
                                end
                            end
                        end
                        if canRace then
                            if not IsPedInAnyVehicle(player) then
                                QBCore.Functions.Notify("You have to be in a vehicle to race, duh.", "error", 5000)
                                break
                            end
                            vehiclePedIsIn = GetVehiclePedIsIn(player)
                            local plate = QBCore.Functions.GetPlate(vehiclePedIsIn)
                            if Config.ALLOW_PLAYER_OWNED_VEHICLES_ONLY then
                                TriggerServerEvent('smeg-timetrials:server:isVehicleOwner', plate, index, drawScores)
                            else
                                currentRaceState.index = index
                                TriggerEvent('smeg-timetrials:client:startRace', drawScores)
                            end
                        end
                        break
                    end
                end
            end
        end
        if not inrange then
            Wait(2500)
        end
    end
end

RegisterNetEvent('smeg-timetrials:client:vehicleOwner')
AddEventHandler('smeg-timetrials:client:vehicleOwner', function(result, index, drawScores)
    if not result then
        QBCore.Functions.Notify("You cannot use a stolen car!", "error", 2500)
        return
    end
    currentRaceState.index = index
    currentRaceState.scores = nil
    TriggerEvent("smeg-timetrials:client:startRace", drawScores)
end)

-- Receive race scores from server and print
RegisterNetEvent("smeg-timetrials:client:receiveRaceScores")
AddEventHandler("smeg-timetrials:client:receiveRaceScores", function(scores)
    -- Save scores to state
    currentRaceState.scores = scores
end)


-- Countdown race start with controls disabled
RegisterNetEvent("smeg-timetrials:client:startRace")
AddEventHandler("smeg-timetrials:client:startRace", function(drawScores)
    -- Get race from index
    local race = TIMETRIAL_RACES[currentRaceState.index]
    -- Teleport player to start and set heading
    Utils.TeleportToCoord(race.start.x, race.start.y, race.start.z + 4.0, race.start.heading)
    CreateThread(function()
        -- Countdown timer
        local time = 0
        function setcountdown(x) time = GetGameTimer() + x * 1000 end

        function getcountdown() return math.floor((time - GetGameTimer()) / 1000) end

        -- Count down to race start
        setcountdown(5)
        PlaySoundFrontend(-1, '5S', 'MP_MISSION_COUNTDOWN_SOUNDSET', true)
        while getcountdown() > 0 do
            -- Update HUD
            Wait(1)
            SetEntityAlpha(vehiclePedIsIn, 204, false)
            Utils.DisableVehicleCollision(vehiclePedIsIn)
            Utils.DrawHudText(getcountdown(), { 255, 191, 0, 255 }, 0.5, 0.4, 4.0, 4.0)
            SendNUIMessage({
                action = "DrawPosition",
                type = "race",
                data = {
                    CurrentCheckpoint = currentRaceState.checkpoint,
                    TotalCheckpoints = #race.Checkpoints,
                    TotalLaps = 1,
                    Player = racerName,
                    CurrentLap = 1,
                    CurrentTime = 0,
                    Delta = "0.000"
                },
                active = true,
            })
            -- Disable acceleration/reverse until race starts
            DisableControlAction(2, 71, true)
            DisableControlAction(2, 72, true)
        end

        -- Enable acceleration/reverse once race starts
        EnableControlAction(2, 71, true)
        EnableControlAction(2, 72, true)

        -- Start race
        TriggerEvent("smeg-timetrials:client:ActiveRace", drawScores)
    end)
end)

-- Main race function
RegisterNetEvent("smeg-timetrials:client:ActiveRace")
AddEventHandler("smeg-timetrials:client:ActiveRace", function(drawScores)
    local race = TIMETRIAL_RACES[currentRaceState.index]
    currentRaceState.startTime = GetGameTimer()
    local totalRaceDistance = Utils.CalculateRaceDistance(race.start, race.Checkpoints)
    local fastestCheckpointTimes
    if drawScores ~= nil then
        fastestCheckpointTimes = drawScores[1].checkpointTimes
    else
        fastestCheckpointTimes = nil
    end
    local checkpointDifference = 0
    local collisionsEnabled = false
    CreateThread(function()
        -- Create first checkpoint
        local checkpointTimes = {}
        Utils.SetupCheckpointFlares(race.Checkpoints, 0.9, 0.6, 0.1)
        currentRaceState.blip = AddBlipForCoord(race.Checkpoints[currentRaceState.checkpoint].x,
            race.Checkpoints[currentRaceState.checkpoint].y,
            race.Checkpoints[currentRaceState.checkpoint].z)

        -- Set waypoints if enabled
        if race.showWaypoints == true then
            SetNewWaypoint(race.Checkpoints[currentRaceState.checkpoint + 1].x,
                race.Checkpoints[currentRaceState.checkpoint + 1].y)
        end

        while currentRaceState.index ~= 0 do
            Wait(1)
            if not collisionsEnabled then
                if (GetGameTimer() - currentRaceState.startTime) > 5000 then
                    SetEntityAlpha(vehiclePedIsIn, 255, false)
                    collisionsEnabled = true
                    Utils.ResetCollision(vehiclePedIsIn)
                end
            end

            if Config.ALLOW_PLAYER_TO_CANCEL_RACE and IsControlJustReleased(0, Config.PLAYER_RACE_RESTART_KEY) then
                RemoveBlip(currentRaceState.blip)
                Utils.TeleportToCoord(race.start.x, race.start.y, race.start.z + 4.0, race.start.heading)
                SetEntityAlpha(vehiclePedIsIn, 255, false)
                Utils.ResetCollision(vehiclePedIsIn)
                Utils.ClearCheckpointFlares()
                DeleteWaypoint()
                currentRaceState.index = 0
                SetTimeout(5000, function()
                    SendNUIMessage({
                        action = "DrawPosition",
                        type = "race",
                        data = {},
                        active = false,
                    })
                end)
                break
            end


            local currentTime = (GetGameTimer() - currentRaceState.startTime) / 1000
            SendNUIMessage({
                action = "DrawPosition",
                type = "race",
                data = {
                    CurrentCheckpoint = currentRaceState.checkpoint,
                    TotalCheckpoints = #race.Checkpoints,
                    TotalLaps = 1,
                    Player = racerName,
                    CurrentLap = 1,
                    CurrentTime = currentTime,
                    Delta = checkpointDifference / 1000
                },
                active = true,
            })
            if #(vector3(race.Checkpoints[currentRaceState.checkpoint].x, race.Checkpoints[currentRaceState.checkpoint].y, race.Checkpoints[currentRaceState.checkpoint].z) - GetEntityCoords(PlayerPedId())) < race.checkpointRadius then
                RemoveBlip(currentRaceState.blip)
                PlaySoundFrontend(-1, "RACE_PLACED", "HUD_AWARDS")
                if currentRaceState.checkpoint == #(race.Checkpoints) then
                    -- Save time and play sound for finish line
                    local finishTime = (GetGameTimer() - currentRaceState.startTime)
                    PlaySoundFrontend(-1, "ScreenFlash", "WastedSounds")
                    Utils.ClearCheckpointFlares()
                    local rewardAmount = math.floor((totalRaceDistance / (finishTime / 1000)) *
                    (totalRaceDistance * 0.02))
                    TriggerServerEvent('smeg-timetrials:server:raceReward', rewardAmount)
                    SetTimeout(5000, function()
                        SendNUIMessage({
                            action = "DrawPosition",
                            type = "race",
                            data = {
                                CurrentCheckpoint = currentRaceState.checkpoint,
                                TotalCheckpoints = #race.Checkpoints,
                                TotalLaps = 1,
                                Player = racerName,
                                CurrentLap = 1,
                                CurrentTime = currentTime,
                            },
                            active = false,
                        })
                    end)
                    -- Get vehicle name and create score
                    local aheadVehHash = GetEntityModel(GetVehiclePedIsUsing(PlayerPedId()))
                    local aheadVehNameText = GetLabelText(GetDisplayNameFromVehicleModel(aheadVehHash))
                    local score = {}
                    score.time = finishTime
                    score.car = aheadVehNameText
                    score.player = '' ..
                        QBCore.Functions.GetPlayerData().charinfo.firstname ..
                        ' ' .. QBCore.Functions.GetPlayerData().charinfo.lastname
                    score.checkpointTimes = checkpointTimes
                    message = string.format("You finished " ..
                        race.title ..
                        " using " ..
                        aheadVehNameText ..
                        " in " ..
                        (finishTime / 1000) .. " s, earning you $" .. rewardAmount .. ".")
                    TriggerServerEvent('smeg-timetrials:server:raceFinished', score.player, message, race.title, score)
                    QBCore.Functions.Notify(message, 'primary', 3000)
                    playerRaceStatus[#playerRaceStatus + 1] = {
                        player = PlayerId(),
                        time = GetGameTimer(),
                        race =
                            currentRaceState.index
                    }
                    break
                end

                -- Increment checkpoint counter and create next checkpoint
                currentRaceState.checkpoint = currentRaceState.checkpoint + 1
                if currentRaceState.checkpoint + 1 ~= #race.Checkpoints + 1 then
                    -- Create normal checkpoint
                    currentRaceState.blip = AddBlipForCoord(race.Checkpoints[currentRaceState.checkpoint].x,
                        race.Checkpoints[currentRaceState.checkpoint].y,
                        race.Checkpoints[currentRaceState.checkpoint].z)
                    SetNewWaypoint(race.Checkpoints[currentRaceState.checkpoint + 1].x,
                        race.Checkpoints[currentRaceState.checkpoint + 1].y)
                    checkpointTimes[currentRaceState.checkpoint] = GetGameTimer() - currentRaceState.startTime

                    if fastestCheckpointTimes ~= nil then
                        checkpointDifference = Utils.getCheckpointDifference(GetGameTimer() - currentRaceState.startTime,
                            fastestCheckpointTimes[currentRaceState.checkpoint])
                    end
                else
                    currentRaceState.blip = AddBlipForCoord(race.Checkpoints[currentRaceState.checkpoint].x,
                        race.Checkpoints[currentRaceState.checkpoint].y,
                        race.Checkpoints[currentRaceState.checkpoint].z)
                    SetNewWaypoint(race.Checkpoints[currentRaceState.checkpoint].x,
                        race.Checkpoints[currentRaceState.checkpoint].y)

                    checkpointTimes[currentRaceState.checkpoint] = GetGameTimer() - currentRaceState.startTime
                    if fastestCheckpointTimes ~= nil then
                        checkpointDifference = Utils.getCheckpointDifference(GetGameTimer() - currentRaceState.startTime,
                            fastestCheckpointTimes[currentRaceState.checkpoint])
                    end
                end
            end
        end

        -- Reset race
        preRace()
    end)
end)
