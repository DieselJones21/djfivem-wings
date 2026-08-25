-- Copy these entries into qb-core/shared/items.lua (or your items file).
-- Put PNG icons in your inventory's images folder using the same names.

QBShared = QBShared or {}
QBShared.Items = QBShared.Items or {}

QBShared.Items['neon_pink_wings'] = {
    name = 'neon_pink_wings',
    label = 'Neon Pink Wings',
    weight = 150,
    type = 'item',
    image = 'neon_pink_wings.png',
    unique = true,
    useable = true,
    shouldClose = true,
    description = 'Wearable neon wings. Use to equip or remove.',
}

QBShared.Items['azure_shoulder_pet'] = {
    name = 'azure_shoulder_pet',
    label = 'Azure Shoulder Companion',
    weight = 50,
    type = 'item',
    image = 'azure_shoulder_pet.png',
    unique = true,
    useable = true,
    shouldClose = true,
    description = 'A small companion that sits on your shoulder. Use to equip or remove.',
}
