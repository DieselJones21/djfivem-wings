local SKIP = {
    CBaseArchetypeDef = true,
    CMapTypes = true,
    CEntityDef = true,
    drawableDictionary = true,
    textureDictionary = true,
    physicsDictionary = true,
    assetType = true,
    assetName = true,
    lodDist = true,
    specialAttribute = true,
    hdTextureDist = true,
    ASSET_TYPE_DRAWABLE = true,
    ASSET_TYPE_ASSETLESS = true,
    ASSET_TYPE_FRAGMENT = true,
    ASSET_TYPE_DRAWABLEDICTIONARY = true,
}

local function listStreamFiles()
    local resPath = GetResourcePath(GetCurrentResourceName()):gsub('\\', '/')
    local streamPath = resPath .. '/stream'
    local files = {}
    local commands = {
        ('find "%s" -type f 2>/dev/null'):format(streamPath),
        ('ls -1 "%s" 2>/dev/null'):format(streamPath),
    }

    for c = 1, #commands do
        local ok, handle = pcall(io.popen, commands[c])
        if ok and handle then
            for line in handle:lines() do
                if line and line ~= '' then
                    files[#files + 1] = line
                end
            end
            handle:close()
            if #files > 0 then
                break
            end
        end
    end

    return files, streamPath
end

local function toStreamRel(full, streamPath)
    full = full:gsub('\\', '/')
    local prefix = streamPath:gsub('\\', '/')
    if full:sub(1, #prefix) == prefix then
        local rel = full:sub(#prefix + 2)
        if rel ~= '' then
            return rel
        end
    end
    return full:match('([^/]+)$') or full
end

local function readFile(path)
    local ok, handle = pcall(io.open, path, 'rb')
    if not ok or not handle then return nil end
    local data = handle:read('*a')
    handle:close()
    return data
end

local function addName(list, seen, name)
    if type(name) ~= 'string' then return end
    name = name:match('^%s*(.-)%s*$')
    if name == '' or #name < 3 or #name > 48 then return end
    if SKIP[name] or name:find('[^%w_]') then return end
    if seen[name] then return end
    seen[name] = true
    list[#list + 1] = name
end

local function parseYtyp(data)
    if type(data) ~= 'string' or data == '' then
        return {}, 'empty'
    end

    local names, seen = {}, {}
    local head = data:sub(1, 64)
    local kind = 'binary'
    if head:find('<%?xml', 1, false) or head:find('<CMapTypes', 1, true) or head:find('<archetypes', 1, true) then
        kind = 'xml'
        for name in data:gmatch('<name>%s*([^<]+)%s*</name>') do
            addName(names, seen, name)
        end
        for name in data:gmatch('<assetName>%s*([^<]+)%s*</assetName>') do
            addName(names, seen, name)
        end
        return names, kind
    end

    for name in data:gmatch('%z([%a_][%w_]+)%z') do
        addName(names, seen, name)
    end
    if #names == 0 then
        for name in data:gmatch('[%a_][%w_][%w_]+') do
            addName(names, seen, name)
        end
    end
    return names, kind
end

CreateThread(function()
    Wait(250)
    local files, streamPath = listStreamFiles()
    local ytyp, ydr, ytd = {}, {}, {}
    for i = 1, #files do
        local rel = toStreamRel(files[i], streamPath)
        local lower = rel:lower()
        if lower:sub(-5) == '.ytyp' then
            ytyp[#ytyp + 1] = rel
        elseif lower:sub(-4) == '.ydr' then
            ydr[#ydr + 1] = rel:match('([^/]+)%.ydr$') or rel:sub(1, #rel - 4)
        elseif lower:sub(-4) == '.ytd' then
            ytd[#ytd + 1] = rel:match('([^/]+)%.ytd$') or rel:sub(1, #rel - 4)
        end
    end

    print('^3[djfivem-wings] Stream folder^7')
    if #ydr == 0 then
        print('^1[djfivem-wings] No .ydr files found in stream/.^7')
    else
        print(('[djfivem-wings] .ydr files: %s'):format(table.concat(ydr, ', ')))
    end

    if #ytd == 0 and #ydr > 0 then
        print('^3[djfivem-wings] No .ytd textures in stream/. If the wings are invisible after they spawn, copy the pack\'s .ytd here too.^7')
    end

    local archetypes = {}
    local seen = {}
    if #ytyp == 0 then
        print('^1[djfivem-wings] No .ytyp in stream/. Addon props will not spawn without one.^7')
    else
        for i = 1, #ytyp do
            local full = streamPath .. '/' .. ytyp[i]
            local data = readFile(full)
            local names, kind = parseYtyp(data)
            print(('[djfivem-wings] %s (%s)'):format(ytyp[i], kind))
            if kind == 'xml' then
                print('^1[djfivem-wings] That ytyp looks like XML. FiveM needs a compiled .ytyp from CodeWalker, not the XML export.^7')
            end
            if #names == 0 then
                print('^1[djfivem-wings] Could not read archetype names from this ytyp.^7')
            else
                print(('[djfivem-wings] Names inside ytyp: %s'):format(table.concat(names, ', ')))
                for n = 1, #names do
                    addName(archetypes, seen, names[n])
                end
            end
        end
    end

    GlobalState.djwingsArchetypes = archetypes
    GlobalState.djwingsYdrs = ydr

    for _, prop in pairs(Config.Props) do
        local model = Wearables.ResolveModel(prop)
        local inYtyp = seen[model]
        if not inYtyp and #archetypes > 0 then
            print(('^1[djfivem-wings] Config model "%s" was not found in the ytyp. Change model= to one of: %s^7'):format(
                model,
                table.concat(archetypes, ', ')
            ))
        end
    end
end)
