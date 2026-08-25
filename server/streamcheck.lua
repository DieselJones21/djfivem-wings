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

CreateThread(function()
    Wait(250)
    local files, streamPath = listStreamFiles()
    local ytyp, ydr = {}, {}
    for i = 1, #files do
        local rel = toStreamRel(files[i], streamPath)
        local lower = rel:lower()
        if lower:sub(-5) == '.ytyp' then
            ytyp[#ytyp + 1] = rel
        elseif lower:sub(-4) == '.ydr' then
            local base = rel:match('([^/]+)%.ydr$') or rel:sub(1, #rel - 4)
            ydr[#ydr + 1] = base
        end
    end

    print('^3[djfivem-wings] Stream folder^7')
    if #ydr == 0 then
        print('^1[djfivem-wings] No .ydr files found in stream/. Put your props there.^7')
    else
        print(('[djfivem-wings] Found models: %s'):format(table.concat(ydr, ', ')))
        print('[djfivem-wings] Set Config.Props[].model to those names (no .ydr).')
    end

    if #ytyp == 0 then
        print('^1[djfivem-wings] No .ytyp in stream/. Addon props will not spawn without one.^7')
        return
    end

    print('^3[djfivem-wings] Add these lines to fxmanifest.lua, then restart the resource:^7')
    for i = 1, #ytyp do
        print(("    data_file 'DLC_ITYP_REQUEST' 'stream/%s'"):format(ytyp[i]))
    end
end)
