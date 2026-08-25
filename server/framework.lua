Framework = {
    name = 'standalone',
}

local function started(name)
    return GetResourceState(name) == 'started'
end

local function detect()
    if Config.Framework ~= 'auto' then
        return Config.Framework
    end
    if started('ox_inventory') then return 'ox' end
    if started('qb-core') then return 'qb' end
    if started('qbx_core') then return 'qb' end
    if started('es_extended') then return 'esx' end
    return 'standalone'
end

function Framework.GetPlayer(src)
    Framework.name = detect()
    if Framework.name == 'qb' then
        if started('qb-core') then
            local QBCore = exports['qb-core']:GetCoreObject()
            return QBCore.Functions.GetPlayer(src)
        end
        if started('qbx_core') then
            return exports.qbx_core:GetPlayer(src)
        end
    elseif Framework.name == 'esx' and started('es_extended') then
        return exports.es_extended:getSharedObject().GetPlayerFromId(src)
    end
    return nil
end

function Framework.Identifier(src)
    if Framework.name == 'qb' then
        local player = Framework.GetPlayer(src)
        if player and player.PlayerData and player.PlayerData.citizenid then
            return player.PlayerData.citizenid
        end
    elseif Framework.name == 'esx' then
        local player = Framework.GetPlayer(src)
        if player and player.identifier then
            return player.identifier
        end
    end
    return GetPlayerIdentifierByType(src, 'license')
        or GetPlayerIdentifierByType(src, 'license2')
        or GetPlayerIdentifier(src, 0)
end

function Framework.HasItem(src, itemName)
    Framework.name = detect()
    if not Config.RequireItem then return true end
    if IsPlayerAceAllowed(src, Config.AdminAce) then return true end
    if Framework.name == 'standalone' then return true end

    if Framework.name == 'ox' and started('ox_inventory') then
        local count = exports.ox_inventory:GetItemCount(src, itemName)
        return type(count) == 'number' and count > 0
    end

    if Framework.name == 'qb' then
        local player = Framework.GetPlayer(src)
        if not player then return false end
        if player.Functions and player.Functions.GetItemByName then
            local item = player.Functions.GetItemByName(itemName)
            return item ~= nil and (item.amount or item.count or 1) > 0
        end
    end

    if Framework.name == 'esx' then
        local player = Framework.GetPlayer(src)
        if not player or not player.getInventoryItem then return false end
        local item = player.getInventoryItem(itemName)
        return item ~= nil and (item.count or item.amount or 0) > 0
    end

    return false
end

function Framework.Notify(src, msg, ntype)
    TriggerClientEvent('djwings:notify', src, msg, ntype)
end

local oxHooked, qbHooked, esxHooked = false, false, false

local function registerOxHook()
    if oxHooked or not started('ox_inventory') then return end
    local filter = {}
    for id in pairs(Config.Props) do
        filter[id] = true
    end
    local ok, err = pcall(function()
        exports.ox_inventory:registerHook('usingItem', function(payload)
            local name = payload.item and payload.item.name
            if not name or not Config.Props[name] then return end
            TriggerEvent('djwings:internalToggle', payload.source, name)
            return false
        end, { itemFilter = filter })
    end)
    if ok then
        oxHooked = true
        print('[djfivem-wings] ox_inventory use hook registered')
    else
        print('[djfivem-wings] ox_inventory hook failed:', err)
    end
end

local function registerQbItems()
    if qbHooked or not started('qb-core') then return end
    local QBCore = exports['qb-core']:GetCoreObject()
    for id in pairs(Config.Props) do
        QBCore.Functions.CreateUseableItem(id, function(source)
            TriggerEvent('djwings:internalToggle', source, id)
        end)
    end
    qbHooked = true
    print('[djfivem-wings] QB useable items registered')
end

local function registerEsxItems()
    if esxHooked or not started('es_extended') then return end
    local ESX = exports.es_extended:getSharedObject()
    for id in pairs(Config.Props) do
        ESX.RegisterUsableItem(id, function(source)
            TriggerEvent('djwings:internalToggle', source, id)
        end)
    end
    esxHooked = true
    print('[djfivem-wings] ESX usable items registered')
end

local function registerAll()
    Framework.name = detect()
    if started('ox_inventory') then
        registerOxHook()
    end
    if Framework.name == 'qb' then
        registerQbItems()
    end
    if Framework.name == 'esx' then
        registerEsxItems()
    end
end

CreateThread(function()
    Wait(500)
    registerAll()
    print(('[djfivem-wings] Framework: %s'):format(Framework.name))
end)

AddEventHandler('onServerResourceStart', function(res)
    if res == 'ox_inventory' or res == 'qb-core' or res == 'qbx_core' or res == 'es_extended' then
        SetTimeout(250, registerAll)
    end
end)

-- ox_inventory can call this from an item server export if you prefer that over the hook.
exports('useWearable', function(event, item, inventory)
    if event ~= 'usingItem' then return end
    local src = inventory and inventory.id
    local name = item and item.name
    if src and name then
        TriggerEvent('djwings:internalToggle', src, name)
    end
    return false
end)
