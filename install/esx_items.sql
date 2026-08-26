INSERT INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`) VALUES
    ('ate_wings_a', 'Wings A', 1, 0, 1),
    ('ate_wings_b', 'Wings B', 1, 0, 1),
    ('ate_wings_c', 'Wings C', 1, 0, 1),
    ('ate_wings_d', 'Wings D', 1, 0, 1)
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`);
