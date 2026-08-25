-- ESX item rows. Icon files still need to be added to your inventory UI.

INSERT INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`) VALUES
    ('neon_pink_wings', 'Neon Pink Wings', 1, 0, 1),
    ('azure_shoulder_pet', 'Azure Shoulder Companion', 1, 0, 1)
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`);
