Utils = {}
Utils.DisabledCollisionVehicles = {}
Utils.CheckpointFlares = {}
local QBCore = exports['qb-core']:GetCoreObject()

---Function to disable collisions of a player to any nearby cars
---@param vehiclePedIsIn string
function Utils.DisableVehicleCollision(vehiclePedIsIn)
    local vehList = QBCore.Functions.GetVehicles()
    for _, v in pairs(vehList) do
        if vehiclePedIsIn ~= v then
            SetEntityNoCollisionEntity(v, vehiclePedIsIn, false)
            Utils.DisabledCollisionVehicles[#Utils.DisabledCollisionVehicles + 1] = v
        end
    end
end

---Function to reset any collisions
---@param vehiclePedIsIn string
function Utils.ResetCollision(vehiclePedIsIn)
    for _, v in pairs(Utils.DisabledCollisionVehicles) do
        SetEntityNoCollisionEntity(v, vehiclePedIsIn, true)
    end
    Utils.DisabledCollisionVehicles = {}
end

---Function to teleport a player to a XYZ coordinate
---@param x number
---@param y number
---@param z number
---@param heading number
function Utils.TeleportToCoord(x, y, z, heading)
    Wait(1)
    local player = PlayerPedId()
    if IsPedInAnyVehicle(player, true) then
        SetEntityCoords(GetVehiclePedIsUsing(player), x, y, z)
        Wait(100)
        SetEntityHeading(GetVehiclePedIsUsing(player), heading)
    else
        SetEntityCoords(player, x, y, z)
        Wait(100)
        SetEntityHeading(player, heading)
    end
end

---Setup flares for checkpoints
---@param coords any
---@param r number
---@param g number
---@param b number
function Utils.SetupCheckpointFlares(coords, r, g, b)
    local dict = 'scr_gr_def'
    local particle = 'scr_gr_def_package_flare'
    RequestNamedPtfxAsset(dict)
    while not HasNamedPtfxAssetLoaded(dict) do
        Wait(100)
    end
    local ptfxHandle
    for _, v in pairs(coords) do
        UseParticleFxAsset(dict)
        ptfxHandle = StartParticleFxLoopedAtCoord(particle, v.x, v.y, v
            .z, 0.0, 0.0,
            0.0, 2.0, false, false, false)
        SetParticleFxLoopedColour(ptfxHandle, r, g, b, 0)
        Utils.CheckpointFlares[#Utils.CheckpointFlares + 1] = ptfxHandle
    end
end

---Clear checkpoint flares
function Utils.ClearCheckpointFlares()
    for _, particle in pairs(Utils.CheckpointFlares) do
        -- Stopping each particle effect.
        StopParticleFxLooped(particle, true)
    end
    Utils.CheckpointFlares = {}
end

--- Calculate race distance
--- @param raceStart vector3
---@param checkpoints any
function Utils.CalculateRaceDistance(raceStart, checkpoints)
    local totalRaceDistance = #(vector3(raceStart.x, raceStart.y, raceStart.z) - vector3(checkpoints[1].x, checkpoints[1].y, checkpoints[1].z))
    local i = 1

    while i < #checkpoints do
        totalRaceDistance = totalRaceDistance +
            #(vector3(checkpoints[i].x, checkpoints[i].y, checkpoints[i].z) - vector3(checkpoints[i + 1].x, checkpoints[i + 1].y, checkpoints[i + 1].z))
        i = i + 1
    end
    return totalRaceDistance
end

--- Create blips for all races
function Utils.createBlips()
    for _, race in pairs(TIMETRIAL_RACES) do
        if race.isEnabled then
            race.blip = AddBlipForCoord(race.start.x, race.start.y, race.start.z)
            SetBlipSprite(race.blip, race.mapBlipId)
            SetBlipDisplay(race.blip, 4)
            SetBlipScale(race.blip, 1.0)
            SetBlipColour(race.blip, race.mapBlipColor)
            SetBlipAsShortRange(race.blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(race.title)
            EndTextCommandSetBlipName(race.blip)
        end
    end
end

--- Compare checkpoint times to fastest racer
--- @param currentTime number
---@param checkpointTime number
function Utils.getCheckpointDifference(currentTime, checkpointTime)
    return currentTime - checkpointTime
end

--- Utility function to display 3D text
---@param x number
---@param y number
---@param z number
---@param textInput string
---@param colour table
---@param fontId string
---@param scaleX number
---@param scaleY number
function Utils.Draw3DText(x, y, z, textInput, colour, fontId, scaleX, scaleY)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local dist = #(vector3(px, py, pz) - vector3(x, y, z))
    local scale = (1 / dist) * 20
    local fov = (1 / GetGameplayCamFov()) * 100
    local scale = scale * fov

    SetTextScale(scaleX * scale, scaleY * scale)
    SetTextFont(fontId)
    SetTextProportional(1)
    local colourr, colourg, colourb, coloura = table.unpack(colour)
    SetTextColour(colourr, colourg, colourb, coloura)
    SetTextDropshadow(2, 1, 1, 1, 255)
    SetTextEdge(3, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(textInput)
    SetDrawOrigin(x, y, z + 2, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

--- Utility function to display HUD text
--- @param text number
--- @param colour table
--- @param coordsx number
--- @param coordsy number
--- @param scalex number
--- @param scaley number
function Utils.DrawHudText(text, colour, coordsx, coordsy, scalex, scaley)
    SetTextFont(4)
    SetTextProportional(7)
    SetTextScale(scalex, scaley)
    local colourr, colourg, colourb, coloura = table.unpack(colour)
    SetTextColour(colourr, colourg, colourb, coloura)
    SetTextDropshadow(0, 0, 0, 0, coloura)
    SetTextEdge(1, 0, 0, 0, coloura)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(coordsx, coordsy)
end

--- Utility function to display help message
--- @param text string
---@param duration number
function Utils.RacePromptMessage(text, duration)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, duration or 5000)
end