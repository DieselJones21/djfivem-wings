fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'djfivem-wings'
author 'DieselJones21'
description 'Network-synced wearable props (wings, shoulder pets) with inventory use and a live placement editor'
version '1.0.0'

shared_scripts {
    'config.lua',
    'shared/utils.lua',
}

client_scripts {
    'client/main.lua',
    'client/editor.lua',
}

server_scripts {
    'server/storage.lua',
    'server/framework.lua',
    'server/main.lua',
    'server/streamcheck.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}

-- REQUIRED for addon props. Add one line per .ytyp in stream/.
-- Example: data_file 'DLC_ITYP_REQUEST' 'stream/your_wings.ytyp'
-- The server console prints the exact lines after a restart if it finds ytyp files.
