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

local wings = Wearables.DefaultAttach('neon_pink_wings')
assertTrue(wings ~= nil, 'default attach exists for neon_pink_wings')
assertTrue(wings.slot == 'wings', 'wings use the wings slot')
assertTrue(wings.bone == 24818, 'wings default bone is Spine3')
assertTrue(wings.y < 0, 'wings sit behind the back (negative Y)')

local pet = Wearables.DefaultAttach('azure_shoulder_pet')
assertTrue(pet ~= nil, 'default attach exists for azure_shoulder_pet')
assertTrue(pet.slot == 'shoulder', 'pet uses the shoulder slot')
assertTrue(pet.bone == 64729, 'pet default bone is left clavicle')

local clamped = Wearables.SanitizeAttach('neon_pink_wings', {
    bone = 24818,
    x = 50, y = -50, z = 0,
    rx = 400, ry = 90, rz = 180,
})
assertTrue(clamped.x == Config.MaxOffset, 'X offset is clamped to MaxOffset')
assertTrue(clamped.y == -Config.MaxOffset, 'Y offset is clamped to -MaxOffset')
assertTrue(clamped.rx == 40, 'rotation wraps with modulo 360')

local invalid = Wearables.SanitizeAttach('neon_pink_wings', { bone = 1, x = 0, y = 0, z = 0, rx = 0, ry = 0, rz = 0 })
assertTrue(invalid.bone == 24818, 'unknown bones fall back to the prop default')

assertTrue(Wearables.GetProp('nope') == nil, 'unknown prop ids are rejected')
assertTrue(Wearables.CopyState({ wings = wings, junk = 1 }).wings.id == 'neon_pink_wings', 'state copy keeps valid slots')
assertTrue(Wearables.CopyState({}) == nil, 'empty state copies to nil')
assertTrue(Wearables.AttachEquals(wings, wings), 'attach equality matches identical tables')
assertTrue(not Wearables.AttachEquals(wings, pet), 'attach equality rejects different props')

local names = Wearables.ItemNames()
assertTrue(#names == 2, 'item name list includes both starter props')

if failed > 0 then
    print(('FAILED %d check(s)'):format(failed))
    os.exit(1)
end

print('All wearable helper checks passed')
