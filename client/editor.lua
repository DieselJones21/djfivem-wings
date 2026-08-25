local editor = {
    open = false,
    slot = nil,
    attach = nil,
    frozen = false,
}

local function setFocus(enable)
    SetNuiFocus(enable, enable)
    SetNuiFocusKeepInput(false)
end

local function freezeLocal(enable)
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, enable)
    editor.frozen = enable
    if enable then
        ClearPedTasksImmediately(ped)
    end
end

local function currentLocalAttach(slot)
    local sid = GetPlayerServerId(PlayerId())
    local entry = GetSpawnedEntry(sid, slot)
    if entry and entry.attach then
        return {
            id = entry.attach.id,
            slot = slot,
            bone = entry.attach.bone,
            x = entry.attach.x,
            y = entry.attach.y,
            z = entry.attach.z,
            rx = entry.attach.rx,
            ry = entry.attach.ry,
            rz = entry.attach.rz,
        }
    end
    local state = Player(sid).state.djwings
    if type(state) == 'table' and state[slot] then
        return Wearables.SanitizeAttach(state[slot].id, state[slot])
    end
    return nil
end

local function sendOpen(attach)
    local prop = Wearables.GetProp(attach.id)
    SendNUIMessage({
        action = 'open',
        data = {
            command = Config.EditorCommand,
            label = prop and prop.label or attach.id,
            slot = attach.slot,
            attach = attach,
            bones = Config.Bones,
            steps = Config.Editor,
            maxOffset = Config.MaxOffset,
        },
    })
end

local function closeEditor(restore)
    if not editor.open then return end
    local slot = editor.slot
    editor.open = false
    SendNUIMessage({ action = 'close' })
    setFocus(false)
    freezeLocal(false)
    if restore then
        local sid = GetPlayerServerId(PlayerId())
        local state = Player(sid).state.djwings
        if type(state) == 'table' and state[slot] then
            PreviewAttach(slot, Wearables.SanitizeAttach(state[slot].id, state[slot]))
        end
    end
    ClearPreview(slot)
    editor.slot = nil
    editor.attach = nil
end

local function openEditor(slot)
    if editor.open then
        closeEditor(true)
        return
    end

    local sid = GetPlayerServerId(PlayerId())
    local state = Player(sid).state.djwings
    if type(state) ~= 'table' then
        TriggerEvent('djwings:notify', Wearables.Locale('nothing_equipped'), 'error')
        return
    end

    if not slot then
        if state.wings then
            slot = 'wings'
        else
            slot = next(state)
        end
    end

    if not state[slot] then
        TriggerEvent('djwings:notify', Wearables.Locale('nothing_equipped'), 'error')
        return
    end

    local attach = currentLocalAttach(slot) or Wearables.SanitizeAttach(state[slot].id, state[slot])
    if not attach then
        TriggerEvent('djwings:notify', Wearables.Locale('nothing_equipped'), 'error')
        return
    end

    editor.open = true
    editor.slot = slot
    editor.attach = attach
    PreviewAttach(slot, attach)
    freezeLocal(true)
    setFocus(true)
    sendOpen(attach)
    TriggerEvent('djwings:notify', Wearables.Locale('editor_open', Config.EditorCommand), 'inform')
end

RegisterCommand(Config.EditorCommand, function(_, args)
    local slot = args[1]
    if editor.open then
        closeEditor(true)
        return
    end
    openEditor(slot)
end, false)

RegisterKeyMapping(Config.EditorCommand, 'Open wearable placement editor', 'keyboard', Config.EditorKey)

RegisterNUICallback('ready', function(_, cb)
    cb({ ok = true })
end)

RegisterNUICallback('preview', function(data, cb)
    if not editor.open or type(data) ~= 'table' then
        cb({ ok = false })
        return
    end
    local attach = Wearables.SanitizeAttach(editor.attach.id, data)
    if not attach then
        cb({ ok = false })
        return
    end
    editor.attach = attach
    PreviewAttach(editor.slot, attach)
    cb({ ok = true, attach = attach })
end)

RegisterNUICallback('rotatePed', function(data, cb)
    if editor.open then
        local ped = PlayerPedId()
        local delta = tonumber(data and data.delta) or 8.0
        SetEntityHeading(ped, GetEntityHeading(ped) + delta)
    end
    cb({ ok = true })
end)

RegisterNUICallback('save', function(data, cb)
    if not editor.open then
        cb({ ok = false })
        return
    end
    local attach = Wearables.SanitizeAttach(editor.attach.id, data or editor.attach)
    TriggerServerEvent('djwings:saveOffsets', attach)
    closeEditor(false)
    cb({ ok = true })
end)

RegisterNUICallback('reset', function(_, cb)
    if not editor.open then
        cb({ ok = false })
        return
    end
    local attach = Wearables.DefaultAttach(editor.attach.id)
    editor.attach = attach
    PreviewAttach(editor.slot, attach)
    cb({ ok = true, attach = attach })
end)

RegisterNUICallback('cancel', function(_, cb)
    closeEditor(true)
    cb({ ok = true })
end)

CreateThread(function()
    while true do
        if editor.open then
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 68, true)
            DisableControlAction(0, 69, true)
            DisableControlAction(0, 70, true)
            DisableControlAction(0, 91, true)
            DisableControlAction(0, 92, true)
            DisableControlAction(0, 257, true)
            DisableControlAction(0, 263, true)
            DisableControlAction(0, 264, true)
            DisablePlayerFiring(PlayerId(), true)
            Wait(0)
        else
            Wait(250)
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if editor.open then
        setFocus(false)
        freezeLocal(false)
    end
end)
