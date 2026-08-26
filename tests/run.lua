-- Pure Lua checks for shared wearable helpers (no FiveM natives).
-- Run: lua tests/run.lua

dofile('config.lua')
dofile('shared/utils.lua')

local failed = 0

local function assertTrue(cond, msg)
    if not cond then
        failed = failed + 1
        print('FAIL: ' .. msg)
    else
        print('OK   ' .. msg)
    end
end

local wings = Wearables.DefaultAttach('ate_wings_a')
assertTrue(wings ~= nil, 'default attach exists for ate_wings_a')
assertTrue(wings.slot == 'wings', 'wings use the wings slot')
assertTrue(wings.bone == 24818, 'wings default bone is Spine3')
assertTrue(wings.y < 0, 'wings sit behind the back (negative Y)')

local other = Wearables.DefaultAttach('ate_wings_b')
assertTrue(other ~= nil, 'default attach exists for ate_wings_b')
assertTrue(other.model == nil, 'attach payload does not need raw model field')
assertTrue(other.id == 'ate_wings_b', 'second style keeps its own id')

local clamped = Wearables.SanitizeAttach('ate_wings_a', {
    bone = 24818,
    x = 50, y = -50, z = 0,
    rx = 400, ry = 90, rz = 180,
})
assertTrue(clamped.x == Config.MaxOffset, 'X offset is clamped to MaxOffset')
assertTrue(clamped.y == -Config.MaxOffset, 'Y offset is clamped to -MaxOffset')
assertTrue(clamped.rx == 40, 'rotation wraps with modulo 360')

local invalid = Wearables.SanitizeAttach('ate_wings_a', { bone = 1, x = 0, y = 0, z = 0, rx = 0, ry = 0, rz = 0 })
assertTrue(invalid.bone == 24818, 'unknown bones fall back to the prop default')

assertTrue(Wearables.GetProp('nope') == nil, 'unknown prop ids are rejected')
assertTrue(Wearables.CopyState({ wings = wings, junk = 1 }).wings.id == 'ate_wings_a', 'state copy keeps valid slots')
assertTrue(Wearables.CopyState({}) == nil, 'empty state copies to nil')
assertTrue(Wearables.AttachEquals(wings, wings), 'attach equality matches identical tables')
assertTrue(not Wearables.AttachEquals(wings, other), 'attach equality rejects different props')

local names = Wearables.ItemNames()
assertTrue(#names == 4, 'item name list includes all four wing styles')

dofile('shared/ytyp.lua')
assertTrue(YtypParse.kind('RSC7' .. string.rep('\0', 16)) == 'rsc7', 'RSC7 header is classified as rsc7')
assertTrue(YtypParse.isGarbageName('RSC7'), 'RSC7 is not a spawn name')
assertTrue(YtypParse.isGarbageName('Ysu'), 'Ysu is not a spawn name')
assertTrue(not YtypParse.isGarbageName('ate_wings_a'), 'ate_wings_a is a real spawn name')
local found = YtypParse.findKnownModels('RSC7xxxxate_wings_a\0more', { 'ate_wings_a', 'ate_wings_b' })
assertTrue(found[1] == 'ate_wings_a', 'plaintext ydr name is detected in a ytyp blob')
local hashed = 'RSC7' .. YtypParse.u32le(YtypParse.joaat('ate_wings_b'))
local foundHash = YtypParse.findKnownModels(hashed, { 'ate_wings_b' })
assertTrue(foundHash[1] == 'ate_wings_b', 'joaat hash of a ydr name is detected in a ytyp blob')
local ignored = YtypParse.findKnownModels('RSC7 Ysu junk', { 'ate_wings_a' })
assertTrue(#ignored == 0, 'RSC7/Ysu header bytes do not confirm ate_wings_a')

if failed > 0 then
    print(('FAILED %d check(s)'):format(failed))
    os.exit(1)
end

print('All wearable helper checks passed')
