local spawned = {} -- [serverId] = { [slot] = { entity, ped, attach } }
local missingNotified = {}
local modelWarned = {}
local modelFailedAt = {}
local myServerId = nil
local previewSlot = nil
local resourceName = GetCurrentResourceName()

local function dbg(...)
    if Config.DebugPlaceholder then
        print(('[%s]'):format(resourceName), ...)
    end
end

local function notify(msg, ntype)
    if GetResourceState('ox_lib') == 'started' then
        exports.ox_lib:notify({
            title = 'Wings',
            description = msg,
            type = ntype or 'inform',
        })
        return
    end
    if GetResourceState('qb-core') == 'started' then
        TriggerEvent('QBCore:Notify', msg, ntype == 'error' and 'error' or 'success')
        return
    end
    if GetResourceState('es_extended') == 'started' then
        TriggerEvent('esx:showNotification', msg)
        return
    end
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(false, false)
end

RegisterNetEvent('djwings:notify', function(msg, ntype)
    notify(msg, ntype)
end)

local function playerPed(serverId)
    if not serverId then return 0 end
    if myServerId and serverId == myServerId then
        return PlayerPedId()
    end
    local player = GetPlayerFromServerId(serverId)
    if player == -1 then return 0 end
    local ped = GetPlayerPed(player)
    if ped == 0 or not DoesEntityExist(ped) then return 0 end
    return ped
end

local function distToPed(ped)
    if ped == 0 then return 9999.0 end
    return #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(ped))
end

local function shouldHide(ped, isLocal)
    if not DoesEntityExist(ped) then return true end
    if Config.HideInVehicle and IsPedInAnyVehicle(ped, false) then
        return true
    end
    if isLocal and Config.HideInFirstPerson then
        if GetFollowPedCamViewMode() == 4 then
            return true
        end
    end
    return false
end

local function deleteEntity(entity)
    if entity and DoesEntityExist(entity) then
        DetachEntity(entity, true, true)
        SetEntityAsMissionEntity(entity, true, true)
        DeleteObject(entity)
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end
end

local function destroySlot(serverId, slot)
    local pack = spawned[serverId]
    if not pack then return end
    local entry = pack[slot]
    if entry then
        deleteEntity(entry.entity)
        pack[slot] = nil
    end
    if next(pack) == nil then
        spawned[serverId] = nil
    end
end

function DestroyAllFor(serverId)
    local pack = spawned[serverId]
    if not pack then return end
    for slot in pairs(pack) do
        destroySlot(serverId, slot)
    end
end

local function loadModel(name)
    local hash = joaat(name)
    if HasModelLoaded(hash) then
        return hash
    end
    local failedAt = modelFailedAt[name]
    if failedAt and (GetGameTimer() - failedAt) < 15000 then
        return nil
    end
    RequestModel(hash)
    local timeout = GetGameTimer() + 3000
    while not HasModelLoaded(hash) do
        if GetGameTimer() > timeout then
            modelFailedAt[name] = GetGameTimer()
            if not modelWarned[name] then
                modelWarned[name] = true
                print(('[djfivem-wings] Failed to load model "%s". Check stream/ and the ytyp data_file in fxmanifest.lua.'):format(name))
            end
            return nil
        end
        Wait(10)
    end
    modelFailedAt[name] = nil
    return hash
end

local function attachToPed(entity, ped, attach)
    local boneIndex = GetPedBoneIndex(ped, attach.bone)
    AttachEntityToEntity(
        entity,
        ped,
        boneIndex,
        attach.x, attach.y, attach.z,
        attach.rx, attach.ry, attach.rz,
        true, true, false, true, 2, true
    )
end

local function applyHide(entity, hidden)
    if not DoesEntityExist(entity) then return end
    SetEntityVisible(entity, not hidden, false)
    SetEntityCollision(entity, false, false)
end

local function createProp(ped, attach)
    local prop = Wearables.GetProp(attach.id)
    if not prop then return nil end
    local modelName = Wearables.ResolveModel(prop)
    local hash = loadModel(modelName)
    if not hash then return nil end

    local coords = GetEntityCoords(ped)
    local entity = CreateObjectNoOffset(hash, coords.x, coords.y, coords.z, false, false, false)
    SetModelAsNoLongerNeeded(hash)
    if entity == 0 or not DoesEntityExist(entity) then
        return nil
    end

    SetEntityAsMissionEntity(entity, true, true)
    SetEntityCollision(entity, false, false)
    SetCanClimbOnEntity(entity, false)
    SetEntityProofs(entity, true, true, true, true, true, true, true, true)
    SetEntityLodDist(entity, math.floor(Config.RenderDistance + 40.0))
    SetEntityCanBeDamaged(entity, false)

    attachToPed(entity, ped, attach)
    return entity
end

local function ensureSlot(serverId, slot, attach)
    if previewSlot and myServerId and serverId == myServerId and slot == previewSlot then
        local entry = spawned[serverId] and spawned[serverId][slot]
        if entry and DoesEntityExist(entry.entity) then
            return
        end
    end

    if not attach then
        destroySlot(serverId, slot)
        return
    end

    local ped = playerPed(serverId)
    if ped == 0 then
        destroySlot(serverId, slot)
        return
    end

    local isLocal = myServerId == serverId
    if not isLocal and distToPed(ped) > Config.RenderDistance then
        destroySlot(serverId, slot)
        return
    end

    spawned[serverId] = spawned[serverId] or {}
    local entry = spawned[serverId][slot]

    if entry and DoesEntityExist(entry.entity) then
        local pedChanged = entry.ped ~= ped
        local dataChanged = not Wearables.AttachEquals(entry.attach, attach)
        local detached = not IsEntityAttachedToEntity(entry.entity, ped)
        if pedChanged or dataChanged or detached then
            if dataChanged and entry.attach and entry.attach.id ~= attach.id then
                deleteEntity(entry.entity)
                local entity = createProp(ped, attach)
                if not entity then
                    spawned[serverId][slot] = nil
                    return
                end
                entry.entity = entity
            else
                attachToPed(entry.entity, ped, attach)
            end
            entry.ped = ped
            entry.attach = attach
        end
        applyHide(entry.entity, shouldHide(ped, isLocal))
        return
    end

    local entity = createProp(ped, attach)
    if not entity then
        if isLocal then
            local key = attach.id
            if not missingNotified[key] then
                missingNotified[key] = true
                local prop = Wearables.GetProp(attach.id)
                notify(('Could not load model "%s". Stream the ydr/ytyp or enable Config.DebugPlaceholder.'):format(prop and prop.model or attach.id), 'error')
            end
        end
        return
    end
    spawned[serverId][slot] = {
        entity = entity,
        ped = ped,
        attach = attach,
    }
    applyHide(entity, shouldHide(ped, isLocal))
end

local function applyState(serverId, state)
    state = Wearables.CopyState(state) or {}
    local existing = spawned[serverId]
    if existing then
        for slot in pairs(existing) do
            if not state[slot] then
                destroySlot(serverId, slot)
            end
        end
    end
    for slot, attach in pairs(state) do
        ensureSlot(serverId, slot, attach)
    end
    if next(state) == nil then
        DestroyAllFor(serverId)
    end
end

function GetSpawnedEntry(serverId, slot)
    return spawned[serverId] and spawned[serverId][slot] or nil
end

function PreviewAttach(slot, attach)
    if not myServerId then return end
    previewSlot = slot
    spawned[myServerId] = spawned[myServerId] or {}
    local ped = PlayerPedId()
    local entry = spawned[myServerId][slot]
    if entry and DoesEntityExist(entry.entity) then
        attachToPed(entry.entity, ped, attach)
        entry.attach = attach
        entry.ped = ped
        applyHide(entry.entity, shouldHide(ped, true))
        return
    end
    ensureSlot(myServerId, slot, attach)
end

function ClearPreview(slot)
    if previewSlot == slot then
        previewSlot = nil
    end
end

function IsPreviewing(slot)
    return previewSlot == slot
end

local function readBag(serverId)
    local ply = Player(serverId)
    if not ply then return nil end
    return ply.state.djwings
end

AddStateBagChangeHandler('djwings', nil, function(bagName, _key, value)
    local serverId = tonumber(bagName:match('player:(%d+)'))
    if not serverId then return end
    if type(value) ~= 'table' then
        DestroyAllFor(serverId)
        return
    end
    applyState(serverId, value)
end)

CreateThread(function()
    while true do
        local wait = Config.SyncMs
        myServerId = GetPlayerServerId(PlayerId())
        local seen = {}

        for _, player in ipairs(GetActivePlayers()) do
            local serverId = GetPlayerServerId(player)
            seen[serverId] = true
            local state = readBag(serverId)
            if type(state) == 'table' then
                applyState(serverId, state)
            else
                DestroyAllFor(serverId)
            end
        end

        for serverId in pairs(spawned) do
            if not seen[serverId] then
                DestroyAllFor(serverId)
            end
        end

        Wait(wait)
    end
end)

local function playEquipAnim()
    if not Config.UseEquipAnim then return end
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) or IsPedRagdoll(ped) then return end
    local dict = 'clothingshirt'
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 1500
    while not HasAnimDictLoaded(dict) do
        if GetGameTimer() > timeout then return end
        Wait(10)
    end
    TaskPlayAnim(ped, dict, 'try_shirt_positive_d', 8.0, 8.0, 800, 48, 0.0, false, false, false)
    RemoveAnimDict(dict)
end

RegisterNetEvent('djwings:playEquipAnim', function()
    playEquipAnim()
end)

AddEventHandler('onClientResourceStart', function(res)
    if res ~= resourceName then return end
    Wait(400)
    TriggerServerEvent('djwings:ready')
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('djwings:ready')
end)

RegisterNetEvent('esx:playerLoaded', function()
    TriggerServerEvent('djwings:ready')
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= resourceName then return end
    SetNuiFocus(false, false)
    for serverId in pairs(spawned) do
        DestroyAllFor(serverId)
    end
end)

exports('getEquipped', function()
    if not myServerId then return nil end
    return readBag(myServerId)
end)

exports('isWearing', function(propId)
    if not myServerId then return false end
    local state = readBag(myServerId)
    if type(state) ~= 'table' then return false end
    for _, attach in pairs(state) do
        if attach.id == propId then return true end
    end
    return false
end)

RegisterCommand('wingsoff', function()
    TriggerServerEvent('djwings:clear')
end, false)

RegisterNetEvent('djwings:use', function(propId)
    TriggerServerEvent('djwings:toggle', propId)
end)

dbg('client started')
