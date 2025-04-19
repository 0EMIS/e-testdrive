local masina = nil
local testDriveEndTime = 0
local isTestDriving = false

CreateThread(function()
    local blip = AddBlipForCoord(Config.ZoneCenter)
    SetBlipSprite(blip, 326)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, 2)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(" ")
    EndTextCommandSetBlipName(blip)

    if lib and lib.zones then
        lib.zones.sphere({
            coords = Config.ZoneCenter,
            radius = Config.ZoneRadius,
            debug = false,
            inside = function()
                if not isTestDriving then
                    lib.showTextUI('Panaudojus /importai galėsite atidaryti mašinų sąrašą', { position = 'top-center', icon = 'car' })
                end
            end,
            onExit = function()
                lib.hideTextUI()
            end
        })
    end
end)

local function isInZone(coords)
    return #(coords - Config.ZoneCenter) <= Config.ZoneRadius
end

CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        local inZone = isInZone(playerCoords)
        TriggerServerEvent('e-testdrive:checkZone', inZone)

        if not masina then
            Wait(inZone and 500 or 1000)
        else
            Wait(1000)
        end
    end
end)

RegisterCommand('importai', function()
    if not isInZone(GetEntityCoords(PlayerPedId())) then return end

    local options = {}
    for _, vehicle in ipairs(Config.CarList) do
        if vehicle.model and vehicle.name then
            table.insert(options, {
                title = vehicle.name,
                icon = 'car',
                description = 'Išbandyti ' .. vehicle.name,
                event = 'e-testdrive:selectVehicle',
                args = vehicle.model
            })
        end
    end

    lib.registerContext({
        id = 'testdrive_1',
        title = 'Pasirinkite mašiną',
        options = options
    })

    lib.showContext('testdrive_1')
end)


RegisterNetEvent('e-testdrive:selectVehicle', function(model)
    if masina then return end

    local ped = PlayerPedId()
    local gyvybes = GetEntityHealth(ped)
    lib.requestModel(model)

    if Config.EnableBlackScreenTeleport then
        DoScreenFadeOut(500)
        Wait(700)
    end

    SetEntityCoords(ped, Config.SpawnPoint.x, Config.SpawnPoint.y, Config.SpawnPoint.z)
    SetEntityHeading(ped, Config.SpawnPoint.w)

    masina = CreateVehicle(model, Config.SpawnPoint.x, Config.SpawnPoint.y, Config.SpawnPoint.z, Config.SpawnPoint.w, true, false)
    SetPedIntoVehicle(ped, masina, -1)
    SetVehicleNumberPlateText(masina, Config.NumberPlate)
    SetVehicleEngineOn(masina, Config.VehicleEngineOn, true, false)

    if Config.GhostMode then
        SetEntityAlpha(masina, 200, false)
        SetEntityAlpha(ped, 200, false)
        SetEntityCollision(masina, false, true)
        SetEntityInvincible(ped, true)
        SetEntityInvincible(masina, true)
    end

    if Config.EnableBlackScreenTeleport then
        DoScreenFadeIn(800)
    end

    testDriveEndTime = GetGameTimer() + Config.TestDriveDuration
    isTestDriving = true

    CreateThread(function()
        while GetGameTimer() < testDriveEndTime do
            if not DoesEntityExist(masina) then break end

            local ped = PlayerPedId()
            if GetVehiclePedIsIn(ped, false) ~= masina then
                isTestDriving = false
                break 
            end

            lib.showTextUI(('Likęs laikas: %d sekundės | Mašinos modelis: %s'):format(
                math.ceil((testDriveEndTime - GetGameTimer()) / 1000), model
            ), { position = 'bottom-center' })

            if IsControlJustPressed(0, 49) then break end 
            Wait(1)
        end

        if DoesEntityExist(masina) then
            DeleteEntity(masina)
            masina = nil
            lib.hideTextUI()

            SetEntityCoords(ped, Config.ZoneCenter.x, Config.ZoneCenter.y, Config.ZoneCenter.z)
            SetEntityHealth(ped, gyvybes)
        end
        isTestDriving = false  
    end)
end)
