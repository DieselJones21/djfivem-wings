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

    return files, streamPath, resPath
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

local function pythonNames(resPath, ytypPath)
    local script = resPath .. '/server/inflate_rsc.py'
    local cmds = {
        ('python3 "%s" "%s"'):format(script, ytypPath),
        ('python "%s" "%s"'):format(script, ytypPath),
        ('py "%s" "%s"'):format(script, ytypPath),
    }
    for i = 1, #cmds do
        local ok, handle = pcall(io.popen, cmds[i] .. ' 2>/dev/null')
        if ok and handle then
            local names = {}
            for line in handle:lines() do
                if line and line ~= '' and not YtypParse.isGarbageName(line) then
                    names[#names + 1] = line
                end
            end
            handle:close()
            if #names > 0 then
                return names
            end
        end
    end
    return {}
end

CreateThread(function()
    Wait(250)
    local files, streamPath, resPath = listStreamFiles()
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

    local confirmed = {}
    local seen = {}
    local function remember(name)
        if type(name) ~= 'string' or seen[name] or YtypParse.isGarbageName(name) then
            return
        end
        seen[name] = true
        confirmed[#confirmed + 1] = name
    end

    if #ytyp == 0 then
        print('^1[djfivem-wings] No .ytyp in stream/. Addon props will not spawn without one.^7')
    else
        for i = 1, #ytyp do
            local full = streamPath .. '/' .. ytyp[i]
            local data = readFile(full) or ''
            local kind = YtypParse.kind(data)
            print(('[djfivem-wings] %s (%s)'):format(ytyp[i], kind))

            if kind == 'xml' then
                print('^1[djfivem-wings] That ytyp looks like XML. FiveM needs a compiled .ytyp from CodeWalker.^7')
                local xmlNames = YtypParse.extractXmlNames(data)
                for n = 1, #xmlNames do
                    remember(xmlNames[n])
                end
            elseif kind == 'rsc7' then
                print('[djfivem-wings] RSC7 is the file header, not a spawn name. Keep using the .ydr names (ate_wings_a, ...).')
                local hits = YtypParse.findKnownModels(data, ydr)
                for n = 1, #hits do
                    remember(hits[n])
                end
                local unpacked = pythonNames(resPath, full)
                for n = 1, #unpacked do
                    remember(unpacked[n])
                end
                if #hits == 0 then
                    print('[djfivem-wings] Archetype strings are compressed inside the ytyp. That is normal. Spawn with the .ydr filenames.')
                end
            else
                local hits = YtypParse.findKnownModels(data, ydr)
                for n = 1, #hits do
                    remember(hits[n])
                end
            end
        end
    end

    if #confirmed > 0 then
        print(('[djfivem-wings] Confirmed spawn names: %s'):format(table.concat(confirmed, ', ')))
        GlobalState.djwingsArchetypes = confirmed
    else
        GlobalState.djwingsArchetypes = ydr
        if #ydr > 0 then
            print(('[djfivem-wings] Use these model names in config: %s'):format(table.concat(ydr, ', ')))
        end
    end
    GlobalState.djwingsYdrs = ydr

    for _, prop in pairs(Config.Props) do
        local model = Wearables.ResolveModel(prop)
        if #confirmed > 0 and not seen[model] then
            print(('^1[djfivem-wings] Config model "%s" was not one of the confirmed ytyp names: %s^7'):format(
                model,
                table.concat(confirmed, ', ')
            ))
        end
    end
end)
