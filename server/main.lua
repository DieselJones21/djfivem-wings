local equipped = {} -- [src] = { [slot] = attach }
local lastToggle = {}

local function pushState(src)
    local state = Wearables.CopyState(equipped[src])
    Player(src).state:set('djwings', state, true)
end

local function persist(src)
    if not Config.Persist then return end
    local id = Framework.Identifier(src)
    if not id then return end
    local data = LoadSave(id)
    data.equipped = {}
    if equipped[src] then
        for slot, attach in pairs(equipped[src]) do
            data.equipped[slot] = attach.id
            data.offsets[attach.id] = {
                bone = attach.bone,
                x = attach.x, y = attach.y, z = attach.z,
                rx = attach.rx, ry = attach.ry, rz = attach.rz,
            }
        end
    end
    WriteSave(id, data)
end

local function resolveAttach(src, propId)
    local base = Wearables.DefaultAttach(propId)
    if not base then return nil end
    if Config.Persist then
        local id = Framework.Identifier(src)
        local data = id and LoadSave(id)
        if data and data.offsets and data.offsets[propId] then
            return Wearables.SanitizeAttach(propId, data.offsets[propId])
        end
    end
    return base
end

local function throttled(src)
    local now = GetGameTimer()
    if lastToggle[src] and (now - lastToggle[src]) < 400 then
        return true
    end
    lastToggle[src] = now
    return false
end

function ToggleWearable(src, propId)
    src = tonumber(src)
    if not src or not GetPlayerName(src) then return end

    local prop = Wearables.GetProp(propId)
    if not prop then
        Framework.Notify(src, Wearables.Locale('unknown_prop', tostring(propId)), 'error')
        return
    end

    if throttled(src) then
        Framework.Notify(src, Wearables.Locale('cooldown'), 'error')
        return
    end

    equipped[src] = equipped[src] or {}
    local current = equipped[src][prop.slot]

    if current and current.id == propId then
        equipped[src][prop.slot] = nil
        if next(equipped[src]) == nil then
            equipped[src] = nil
        end
        pushState(src)
        persist(src)
        Framework.Notify(src, Wearables.Locale('removed', prop.label), 'inform')
        TriggerClientEvent('djwings:playEquipAnim', src)
        return
    end

    if not Framework.HasItem(src, propId) then
        Framework.Notify(src, Wearables.Locale('missing_item', prop.label), 'error')
        return
    end

    local attach = resolveAttach(src, propId)
    equipped[src][prop.slot] = attach
    pushState(src)
    persist(src)

    if current then
        Framework.Notify(src, Wearables.Locale('swapped', prop.label), 'success')
    else
        Framework.Notify(src, Wearables.Locale('equipped', prop.label), 'success')
    end
    TriggerClientEvent('djwings:playEquipAnim', src)
end

local function clearPlayer(src, silent)
    if equipped[src] then
        equipped[src] = nil
        pushState(src)
        persist(src)
    else
        Player(src).state:set('djwings', nil, true)
    end
    if not silent then
        Framework.Notify(src, Wearables.Locale('removed', 'wearables'), 'inform')
    end
end

local function restorePlayer(src)
    if not Config.Persist then
        pushState(src)
        return
    end
    local id = Framework.Identifier(src)
    if not id then return end
    local data = LoadSave(id)
    equipped[src] = {}
    for slot, propId in pairs(data.equipped or {}) do
        local prop = Wearables.GetProp(propId)
        if prop and prop.slot == slot and Framework.HasItem(src, propId) then
            equipped[src][slot] = resolveAttach(src, propId)
        end
    end
    if next(equipped[src]) == nil then
        equipped[src] = nil
    end
    pushState(src)
end

AddEventHandler('djwings:internalToggle', function(src, propId)
    ToggleWearable(src, propId)
end)

RegisterNetEvent('djwings:toggle', function(propId)
    ToggleWearable(source, propId)
end)

RegisterNetEvent('djwings:clear', function()
    clearPlayer(source, false)
end)

RegisterNetEvent('djwings:ready', function()
    local src = source
    restorePlayer(src)
    -- Inventory often isn't ready on the first spawn tick; retry once.
    SetTimeout(2000, function()
        if GetPlayerName(src) then
            restorePlayer(src)
        end
    end)
end)

RegisterNetEvent('djwings:saveOffsets', function(data)
    local src = source
    if type(data) ~= 'table' or type(data.id) ~= 'string' then return end
    local attach = Wearables.SanitizeAttach(data.id, data)
    if not attach then return end
    equipped[src] = equipped[src] or {}
    local wearing = equipped[src][attach.slot]
    if not wearing or wearing.id ~= attach.id then
        Framework.Notify(src, Wearables.Locale('nothing_equipped'), 'error')
        return
    end
    equipped[src][attach.slot] = attach
    pushState(src)
    persist(src)
    Framework.Notify(src, Wearables.Locale('saved'), 'success')
end)

AddEventHandler('playerDropped', function()
    local src = source
    persist(src)
    equipped[src] = nil
    lastToggle[src] = nil
end)

RegisterCommand('wingtest', function(src, args)
    if src == 0 then
        print('Usage from game: /wingtest <propId>')
        return
    end
    local allow = Framework.name == 'standalone' or IsPlayerAceAllowed(src, Config.AdminAce)
    if not allow then
        Framework.Notify(src, Wearables.Locale('not_allowed'), 'error')
        return
    end
    local propId = args[1]
    if not propId then
        Framework.Notify(src, 'Usage: /wingtest ' .. table.concat(Wearables.ItemNames(), ' | '), 'inform')
        return
    end
    ToggleWearable(src, propId)
end, false)

RegisterCommand('wings', function(src)
    if src == 0 then return end
    local names = Wearables.ItemNames()
    Framework.Notify(src, 'Wearables: ' .. table.concat(names, ', '), 'inform')
end, false)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, playerId in ipairs(GetPlayers()) do
        restorePlayer(tonumber(playerId))
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for src in pairs(equipped) do
        Player(src).state:set('djwings', nil, true)
    end
end)

exports('toggle', ToggleWearable)
exports('clear', function(src)
    clearPlayer(src, true)
end)
exports('getEquipped', function(src)
    return equipped[src]
end)
