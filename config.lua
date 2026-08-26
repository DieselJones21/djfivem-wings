Config = {}

-- auto | ox | qb | esx | standalone
-- auto detects ox_inventory, qb-core, then es_extended. standalone uses commands only.
Config.Framework = 'auto'

-- Players must have the matching inventory item to equip (ignored in standalone).
Config.RequireItem = true

-- Remember equipped props + saved placements across reconnects (resource KVP).
Config.Persist = true

-- Hide attached props while the ped is in a vehicle (prevents clipping).
Config.HideInVehicle = true

-- Hide local player's props in first-person so they don't fill the camera.
Config.HideInFirstPerson = true

-- Only spawn local copies of other players' props within this range (meters).
Config.RenderDistance = 48.0

-- How often the client reconciles streamed players / distance / ped swaps.
Config.SyncMs = 500

-- Max |x,y,z| offset from the bone so placement cannot be used to troll.
Config.MaxOffset = 0.85

-- Ace for /wingtest and bypassing item checks while testing.
Config.AdminAce = 'djwings.admin'

-- Command to open the live placement editor (also registered as a key mapping).
Config.EditorCommand = 'wingeditor'
Config.EditorKey = 'F7'

-- Play a short clothing anim when you equip or remove a prop.
Config.UseEquipAnim = true

-- Until your custom ytyp is streamed, set this true to test with a vanilla bag model.
-- Turn it OFF once your wing models are in stream/ and named in Config.Props.
Config.DebugPlaceholder = false
Config.DebugPlaceholderModel = 'prop_cs_heist_bag_s'

Config.Locale = {
    equipped = 'Equipped %s',
    removed = 'Removed %s',
    swapped = 'Swapped to %s',
    missing_item = 'You need %s in your inventory',
    unknown_prop = 'Unknown wearable: %s',
    nothing_equipped = 'You are not wearing anything to edit',
    saved = 'Placement saved',
    cancelled = 'Placement cancelled',
    reset = 'Placement reset to default',
    not_allowed = 'You cannot do that',
    cooldown = 'Wait a moment',
    editor_open = 'Placement editor — F7 or /%s to close',
}

--[[
    Each entry is one inventory item AND one wearable.

    id (table key)  = item name in ox_inventory / qb / esx
    model           = spawn name from the ytyp (usually the .ydr name without extension)
    slot            = only one prop per slot (using another wings item swaps it)
    bone            = GTA bone id (see Config.Bones)
    default         = AttachEntityToEntity offset / rotation
]]
Config.Props = {
    ate_wings_a = {
        label = 'Wings A',
        model = 'ate_wings_a',
        slot = 'wings',
        bone = 24818,
        default = { x = 0.00, y = -0.18, z = 0.02, rx = 0.00, ry = 90.00, rz = 180.00 },
    },
    ate_wings_b = {
        label = 'Wings B',
        model = 'ate_wings_b',
        slot = 'wings',
        bone = 24818,
        default = { x = 0.00, y = -0.18, z = 0.02, rx = 0.00, ry = 90.00, rz = 180.00 },
    },
    ate_wings_c = {
        label = 'Wings C',
        model = 'ate_wings_c',
        slot = 'wings',
        bone = 24818,
        default = { x = 0.00, y = -0.18, z = 0.02, rx = 0.00, ry = 90.00, rz = 180.00 },
    },
    ate_wings_d = {
        label = 'Wings D',
        model = 'ate_wings_d',
        slot = 'wings',
        bone = 24818,
        default = { x = 0.00, y = -0.18, z = 0.02, rx = 0.00, ry = 90.00, rz = 180.00 },
    },
}

-- Bones shown in the placement editor dropdown.
Config.Bones = {
    { id = 24818, name = 'Spine3 (upper back)' },
    { id = 24817, name = 'Spine2 (mid back)' },
    { id = 24816, name = 'Spine1 (lower back)' },
    { id = 11816, name = 'Pelvis' },
    { id = 39317, name = 'Neck' },
    { id = 31086, name = 'Head' },
    { id = 64729, name = 'Left clavicle' },
    { id = 10706, name = 'Right clavicle' },
    { id = 45509, name = 'Left upper arm' },
    { id = 40269, name = 'Right upper arm' },
    { id = 61163, name = 'Left forearm' },
    { id = 28252, name = 'Right forearm' },
    { id = 18905, name = 'Left hand' },
    { id = 57005, name = 'Right hand' },
}

Config.Editor = {
    fine = { pos = 0.001, rot = 0.10 },
    normal = { pos = 0.010, rot = 1.00 },
    coarse = { pos = 0.050, rot = 5.00 },
}
