CREATE TABLE IF NOT EXISTS `tax_statistics` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `timestamp` INT UNSIGNED NOT NULL COMMENT 'Unix čas shranitve',
  `player_count` INT UNSIGNED NOT NULL COMMENT 'Število igralcev ob vzorčenju',
  `avg_vehicles` FLOAT NOT NULL COMMENT 'Povprečno število vozil na igralca',
  PRIMARY KEY (`id`),
  INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tax_config` (
  `id` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `base_tax`   INT UNSIGNED NOT NULL,
  `vehicle_tax` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Vstavi privzete vrednosti (če še ni)
INSERT INTO tax_config (id, base_tax, vehicle_tax)
SELECT 1, 50, 100
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM tax_config WHERE id = 1);
