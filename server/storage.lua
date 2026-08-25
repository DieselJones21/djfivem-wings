local PREFIX = 'djwings:'

function LoadSave(identifier)
    if not identifier or identifier == '' then
        return { equipped = {}, offsets = {} }
    end
    local raw = GetResourceKvpString(PREFIX .. identifier)
    if not raw or raw == '' then
        return { equipped = {}, offsets = {} }
    end
    local ok, data = pcall(json.decode, raw)
    if not ok or type(data) ~= 'table' then
        return { equipped = {}, offsets = {} }
    end
    data.equipped = type(data.equipped) == 'table' and data.equipped or {}
    data.offsets = type(data.offsets) == 'table' and data.offsets or {}
    return data
end

function WriteSave(identifier, data)
    if not identifier or identifier == '' then return end
    SetResourceKvp(PREFIX .. identifier, json.encode({
        equipped = data.equipped or {},
        offsets = data.offsets or {},
    }))
end

function DeleteSave(identifier)
    if not identifier or identifier == '' then return end
    DeleteResourceKvp(PREFIX .. identifier)
end
