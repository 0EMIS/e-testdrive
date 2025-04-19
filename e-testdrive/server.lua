RegisterNetEvent('e-testdrive:checkZone', function(isInZone)
    local src = source
    TriggerClientEvent('e-testdrive:notifyZone', src, isInZone)
end)
