YtypParse = {}

local GARBAGE = {
    RSC5 = true, RSC7 = true, RSC8 = true,
    Ysu = true, YTD = true, YDR = true, YTYP = true, YFT = true, YBN = true, YDD = true,
    CBaseArchetypeDef = true, CMapTypes = true, CEntityDef = true,
    drawableDictionary = true, textureDictionary = true, physicsDictionary = true,
    assetType = true, assetName = true, lodDist = true, specialAttribute = true,
    hdTextureDist = true,
    ASSET_TYPE_DRAWABLE = true, ASSET_TYPE_ASSETLESS = true,
    ASSET_TYPE_FRAGMENT = true, ASSET_TYPE_DRAWABLEDICTIONARY = true,
}

local function u32(n)
    return n & 0xFFFFFFFF
end

function YtypParse.joaat(str)
    local hash = 0
    str = string.lower(str)
    for i = 1, #str do
        hash = u32(hash + str:byte(i))
        hash = u32(hash + (hash << 10))
        hash = u32(hash ~ (hash >> 6))
    end
    hash = u32(hash + (hash << 3))
    hash = u32(hash ~ (hash >> 11))
    hash = u32(hash + (hash << 15))
    return hash
end

function YtypParse.u32le(n)
    n = u32(n)
    return string.char(
        n & 0xFF,
        (n >> 8) & 0xFF,
        (n >> 16) & 0xFF,
        (n >> 24) & 0xFF
    )
end

function YtypParse.isGarbageName(name)
    return GARBAGE[name] == true or #name < 6
end

function YtypParse.kind(data)
    if type(data) ~= 'string' or data == '' then
        return 'empty'
    end
    local magic = data:sub(1, 4)
    if magic == 'RSC7' or magic == 'RSC8' or magic == 'RSC5' then
        return 'rsc7'
    end
    local head = data:sub(1, 80)
    if head:find('<?xml', 1, true) or head:find('<CMapTypes', 1, true) or head:find('<archetypes', 1, true) then
        return 'xml'
    end
    return 'binary'
end

function YtypParse.findKnownModels(data, candidates)
    local found = {}
    if type(data) ~= 'string' or type(candidates) ~= 'table' then
        return found
    end
    for i = 1, #candidates do
        local name = candidates[i]
        if type(name) == 'string' and name ~= '' then
            local hit = data:find(name, 1, true)
            if not hit then
                local needle = YtypParse.u32le(YtypParse.joaat(name))
                hit = data:find(needle, 1, true)
            end
            if hit then
                found[#found + 1] = name
            end
        end
    end
    return found
end

function YtypParse.extractXmlNames(data)
    local names, seen = {}, {}
    if type(data) ~= 'string' then
        return names
    end
    local function add(name)
        name = tostring(name or ''):match('^%s*(.-)%s*$')
        if name == '' or YtypParse.isGarbageName(name) or name:find('[^%w_]') then
            return
        end
        if seen[name] then return end
        seen[name] = true
        names[#names + 1] = name
    end
    for name in data:gmatch('<name>%s*([^<]+)%s*</name>') do
        add(name)
    end
    for name in data:gmatch('<assetName>%s*([^<]+)%s*</assetName>') do
        add(name)
    end
    return names
end
