-- Import QB
local QBCore = exports['qb-core']:GetCoreObject()

-- Filename to store scores
local scoreFileName = "./scores.txt"

-- Save scores to JSON file
function saveScores(scores)
    local file = io.open(scoreFileName, "w+")
    if file then
        local contents = json.encode(scores)
        file:write(contents)
        io.close(file)
        return true
    else
        return false
    end
end

-- Load scores from JSON file
function getScores()
    local contents = ""
    local myTable = {}
    local file = io.open(scoreFileName, "r")
    if file then
        -- read all contents of file into a string
        local contents = file:read("*a")
        myTable = json.decode(contents);
        io.close(file)
        return myTable
    end
    return {}
end

QBCore.Functions.CreateCallback('smeg-timetrials:server:GetScores', function(source, cb)
    cb(getScores())
end)

-- Create thread to send scores to clients every 5s
CreateThread(function()
    while (true) do
        Wait(5000)
        TriggerClientEvent('smeg-timetrials:client:receiveRaceScores', -1, getScores())
    end
end)

RegisterServerEvent('smeg-timetrials:server:raceReward')
AddEventHandler('smeg-timetrials:server:raceReward', function(rewardAmount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    Player.Functions.AddMoney(Config.REWARD_CASH_OR_BANK, rewardAmount, "timetrials")
end)

RegisterServerEvent('smeg-timetrials:server:isVehicleOwner')
AddEventHandler('smeg-timetrials:server:isVehicleOwner', function(plate, index, drawScores)
    local src = source
    local pData = QBCore.Functions.GetPlayer(src)
    MySQL.query('SELECT * FROM player_vehicles WHERE plate = ? AND citizenid = ?', { plate, pData.PlayerData.citizenid },
        function(result)
            if result[1] then
                TriggerClientEvent('timetrials:client:vehicleOwner', src, true, index, drawScores)
            else
                TriggerClientEvent('timetrials:client:vehicleOwner', src, false, index, drawScores)
            end
        end)
end)

-- Save score and send chat message when player finishes
RegisterServerEvent('smeg-timetrials:server:raceFinished')
AddEventHandler('smeg-timetrials:server:raceFinished', function(source, message, title, newScore)
    -- Get top car score for this race
    local allScores = getScores()
    local raceScores = allScores[title]
    if raceScores ~= nil then
        -- Compare top score and update if new one is faster
        local carName = newScore.car
        local topScore = raceScores[carName]
        if topScore == nil or newScore.time < topScore.time then
            -- Set new high score
            topScore = newScore
        end
        raceScores[carName] = topScore
    else
        -- No scores for this race, create struct and set new high score
        raceScores = {}
        raceScores[newScore.car] = newScore
    end

    -- Save and store scores back to file
    allScores[title] = raceScores
    saveScores(allScores)
end)
