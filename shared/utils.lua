Wearables = Wearables or {}

local function clamp(n, min, max)
    if n < min then return min end
    if n > max then return max end
    return n
end

function Wearables.ClampNumber(n, min, max)
    n = tonumber(n)
    if not n then return min end
    return clamp(n, min, max)
end

function Wearables.GetProp(id)
    return id and Config.Props[id] or nil
end

function Wearables.ResolveModel(prop)
    if Config.DebugPlaceholder then
        return Config.DebugPlaceholderModel
    end
    return prop.model
end

function Wearables.SanitizeAttach(propId, data)
    local prop = Wearables.GetProp(propId)
    if not prop then return nil end

    data = data or {}
    local max = Config.MaxOffset or 0.85
    local bone = tonumber(data.bone) or prop.bone
    local validBone = false
    for i = 1, #Config.Bones do
        if Config.Bones[i].id == bone then
            validBone = true
            break
        end
    end
    if not validBone then
        bone = prop.bone
    end

    local def = prop.default
    return {
        id = propId,
        slot = prop.slot,
        bone = bone,
        x = clamp(tonumber(data.x) or def.x, -max, max),
        y = clamp(tonumber(data.y) or def.y, -max, max),
        z = clamp(tonumber(data.z) or def.z, -max, max),
        rx = (tonumber(data.rx) or def.rx) % 360,
        ry = (tonumber(data.ry) or def.ry) % 360,
        rz = (tonumber(data.rz) or def.rz) % 360,
    }
end

function Wearables.DefaultAttach(propId)
    return Wearables.SanitizeAttach(propId, nil)
end

function Wearables.AttachEquals(a, b)
    if a == b then return true end
    if type(a) ~= 'table' or type(b) ~= 'table' then return false end
    return a.id == b.id
        and a.bone == b.bone
        and a.x == b.x and a.y == b.y and a.z == b.z
        and a.rx == b.rx and a.ry == b.ry and a.rz == b.rz
end

function Wearables.CopyState(state)
    if type(state) ~= 'table' then return nil end
    local copy = {}
    local count = 0
    for slot, attach in pairs(state) do
        if type(attach) == 'table' and attach.id and Wearables.GetProp(attach.id) then
            copy[slot] = Wearables.SanitizeAttach(attach.id, attach)
            count = count + 1
        end
    end
    if count == 0 then return nil end
    return copy
end

function Wearables.Locale(key, ...)
    local text = Config.Locale[key] or key
    if select('#', ...) > 0 then
        return text:format(...)
    end
    return text
end

function Wearables.ItemNames()
    local names = {}
    for id in pairs(Config.Props) do
        names[#names + 1] = id
    end
    table.sort(names)
    return names
end
