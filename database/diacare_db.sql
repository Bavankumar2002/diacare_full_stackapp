-- =============================================================================
-- DiaCare - Diabetes Patient Management Database Schema
-- Database Name: diacare_db
-- Compatibility: MySQL 5.7+ / MySQL 8.0+ / MariaDB 10.3+
-- =============================================================================

CREATE DATABASE IF NOT EXISTS `diacare_db` 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE `diacare_db`;

SET FOREIGN_KEY_CHECKS = 0;

-- Drop existing tables to ensure clean schema migration
DROP TABLE IF EXISTS `meals`;
DROP TABLE IF EXISTS `sugar_readings`;
DROP TABLE IF EXISTS `reminders`;
DROP TABLE IF EXISTS `profiles`;
DROP TABLE IF EXISTS `food_items`;
DROP TABLE IF EXISTS `health_tips`;
DROP TABLE IF EXISTS `users`;

SET FOREIGN_KEY_CHECKS = 1;

-- -----------------------------------------------------------------------------
-- Table: users
-- Account credentials and primary authentication
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `users` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL,
    `email` VARCHAR(150) NOT NULL UNIQUE,
    `phone` VARCHAR(25) NOT NULL UNIQUE,
    `password_hash` VARCHAR(255) NOT NULL,
    `reset_token` VARCHAR(100) NULL DEFAULT NULL,
    `reset_token_expiry` DATETIME NULL DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_users_email` (`email`),
    INDEX `idx_users_phone` (`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- Table: profiles
-- Detailed medical and personal information
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `profiles` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL UNIQUE,
    `full_name` VARCHAR(150) NOT NULL,
    `age` INT NOT NULL,
    `dob` DATE NULL,
    `gender` ENUM('Male', 'Female', 'Other') NOT NULL DEFAULT 'Male',
    `height_cm` DECIMAL(5,2) NOT NULL,
    `weight_kg` DECIMAL(5,2) NOT NULL,
    `bmi` DECIMAL(4,1) NOT NULL,
    `diabetes_type` ENUM('Type 1', 'Type 2', 'Gestational', 'Pre-diabetes') NOT NULL DEFAULT 'Type 2',
    `year_diagnosed` INT NULL,
    `current_medicines` TEXT NULL,
    `allergies` TEXT NULL,
    `emergency_contact_name` VARCHAR(100) NULL,
    `emergency_contact_phone` VARCHAR(25) NULL,
    `doctor_name` VARCHAR(100) NULL,
    `doctor_hospital` VARCHAR(150) NULL,
    `daily_calorie_goal` INT DEFAULT 1800,
    `profile_photo` VARCHAR(255) NULL,
    `is_completed` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_profile_user` FOREIGN KEY (`user_id`) 
        REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- Table: sugar_readings
-- Blood glucose logs with automatic classification
-- Classification: Low (<70 mg/dL), Normal (70-140 mg/dL), High (>140 mg/dL)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sugar_readings` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `reading_value` DECIMAL(5,1) NOT NULL,
    `reading_type` ENUM('fasting', 'before_meal', 'after_meal', 'bedtime', 'random') NOT NULL DEFAULT 'fasting',
    `reading_status` ENUM('Low', 'Normal', 'High') NOT NULL,
    `measured_at` DATETIME NOT NULL,
    `notes` TEXT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_sugar_user` FOREIGN KEY (`user_id`) 
        REFERENCES `users` (`id`) ON DELETE CASCADE,
    INDEX `idx_sugar_user_date` (`user_id`, `measured_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- Table: food_items
-- Seed database of common Indian and general foods for quick calorie lookup
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `food_items` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(120) NOT NULL,
    `category` VARCHAR(50) NOT NULL,
    `serving_size` VARCHAR(80) NOT NULL,
    `calories` INT NOT NULL,
    `carbs_g` DECIMAL(5,1) NOT NULL,
    `protein_g` DECIMAL(5,1) NOT NULL,
    `fat_g` DECIMAL(5,1) NOT NULL,
    `is_custom` TINYINT(1) DEFAULT 0,
    `created_by` INT NULL,
    INDEX `idx_food_name` (`name`),
    INDEX `idx_food_category` (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- Table: meals
-- Logged daily meals (breakfast, lunch, dinner, snack)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `meals` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `meal_type` ENUM('breakfast', 'lunch', 'dinner', 'snack') NOT NULL,
    `food_name` VARCHAR(150) NOT NULL,
    `calories` INT NOT NULL,
    `carbs_g` DECIMAL(5,1) NOT NULL DEFAULT 0.0,
    `serving_quantity` DECIMAL(4,1) NOT NULL DEFAULT 1.0,
    `meal_date` DATE NOT NULL,
    `meal_time` TIME NOT NULL,
    `notes` TEXT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_meals_user` FOREIGN KEY (`user_id`) 
        REFERENCES `users` (`id`) ON DELETE CASCADE,
    INDEX `idx_meals_user_date` (`user_id`, `meal_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- Table: reminders
-- Scheduled patient alerts (medicine, sugar check, water, exercise, appointments)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `reminders` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `title` VARCHAR(150) NOT NULL,
    `type` ENUM('medicine', 'sugar_check', 'water', 'meal', 'exercise', 'doctor') NOT NULL DEFAULT 'medicine',
    `dosage` VARCHAR(100) NULL,
    `time` TIME NOT NULL,
    `repeat_type` ENUM('daily', 'weekdays', 'weekends', 'custom', 'once') NOT NULL DEFAULT 'daily',
    `repeat_days` VARCHAR(50) NOT NULL DEFAULT '1,2,3,4,5,6,7',
    `is_enabled` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_reminders_user` FOREIGN KEY (`user_id`) 
        REFERENCES `users` (`id`) ON DELETE CASCADE,
    INDEX `idx_reminders_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- Table: health_tips
-- Daily curated diabetes lifestyle & care recommendations
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `health_tips` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `title` VARCHAR(150) NOT NULL,
    `tip` TEXT NOT NULL,
    `category` VARCHAR(50) NOT NULL,
    `language` VARCHAR(10) NOT NULL DEFAULT 'en'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================================
-- SEED DATA: Common Indian Foods (Ideal for diabetic patients & Indian diet)
-- =============================================================================
INSERT INTO `food_items` (`name`, `category`, `serving_size`, `calories`, `carbs_g`, `protein_g`, `fat_g`) VALUES
-- Breakfast
('Idli (Steamed)', 'Breakfast', '2 pieces (100g)', 130, 26.0, 4.0, 0.4),
('Plain Dosa', 'Breakfast', '1 medium (80g)', 168, 28.5, 3.8, 4.2),
('Rava Upma', 'Breakfast', '1 cup (150g)', 210, 36.0, 5.2, 5.0),
('Ragi Dosa', 'Breakfast', '1 piece (80g)', 135, 23.0, 3.2, 2.5),
('Oats Porridge with Milk', 'Breakfast', '1 bowl (200g)', 175, 27.0, 6.5, 3.8),
('Vegetable Poha', 'Breakfast', '1 cup (150g)', 220, 38.0, 4.0, 5.5),
('Egg Omelette (2 eggs + veggies)', 'Breakfast', '1 plate', 180, 2.0, 13.0, 12.0),
('Boiled Egg', 'Breakfast', '1 large egg', 78, 0.6, 6.3, 5.3),
('Methi Thepla', 'Breakfast', '2 pieces', 160, 24.0, 4.5, 4.8),
('Sprouted Moong Salad', 'Breakfast', '1 cup (150g)', 138, 22.0, 9.2, 0.9),

-- Lunch & Dinner Staples
('White Rice (Cooked)', 'Lunch/Dinner', '1 cup (150g)', 195, 43.0, 4.2, 0.4),
('Brown Rice (Cooked)', 'Lunch/Dinner', '1 cup (150g)', 168, 35.0, 3.8, 1.4),
('Phulka / Whole Wheat Chapati', 'Lunch/Dinner', '1 piece (35g)', 85, 17.5, 3.0, 0.5),
('Ragi Mudde / Ragi Ball', 'Lunch/Dinner', '1 medium (150g)', 200, 42.0, 5.0, 1.0),
('Sambar (Vegetable)', 'Lunch/Dinner', '1 bowl (150g)', 120, 18.0, 5.5, 2.5),
('Dal Tadka / Yellow Dal', 'Lunch/Dinner', '1 bowl (150g)', 150, 19.0, 7.5, 4.0),
('Rasam (Tomato/Pepper)', 'Lunch/Dinner', '1 cup (150g)', 60, 8.0, 1.8, 1.5),
('Palak Paneer', 'Lunch/Dinner', '1 bowl (150g)', 230, 8.0, 11.0, 16.0),
('Grilled Chicken Breast', 'Lunch/Dinner', '100g', 165, 0.0, 31.0, 3.6),
('Fish Curry (South Indian Style)', 'Lunch/Dinner', '1 bowl (150g)', 190, 5.0, 18.0, 10.0),
('Bhindi Masala (Okra)', 'Lunch/Dinner', '1 bowl (150g)', 110, 12.0, 3.0, 5.0),
('Bitter Gourd / Karela Fry', 'Lunch/Dinner', '1 small bowl (100g)', 95, 9.0, 2.5, 5.0),
('Curd / Homemade Plain Dahi', 'Lunch/Dinner', '1 small cup (100g)', 65, 4.5, 3.5, 3.2),
('Cucumber & Tomato Salad', 'Lunch/Dinner', '1 plate (150g)', 35, 6.0, 1.5, 0.2),

-- Snacks & Beverages
('Roasted Makhana (Foxnuts)', 'Snacks', '1 cup (30g)', 106, 20.0, 3.0, 0.2),
('Chana Sundal (Boiled Chickpeas)', 'Snacks', '1 cup (120g)', 180, 28.0, 8.5, 3.0),
('Roasted Peanuts', 'Snacks', 'handful (30g)', 170, 6.0, 7.5, 14.0),
('Almonds & Walnuts mix', 'Snacks', 'handful (25g)', 160, 4.0, 5.0, 14.5),
('Green Tea (Unsweetened)', 'Beverages', '1 cup (200ml)', 2, 0.2, 0.2, 0.0),
('Buttermilk (Chaas / Moru)', 'Beverages', '1 glass (200ml)', 40, 4.0, 2.2, 1.2),
('Black Coffee (No Sugar)', 'Beverages', '1 cup (150ml)', 4, 0.5, 0.3, 0.0),
('Tender Coconut Water', 'Beverages', '1 glass (200ml)', 45, 9.0, 1.0, 0.5),
('Apple (Medium with skin)', 'Snacks', '1 medium (150g)', 85, 21.0, 0.4, 0.3),
('Guava (Glycemic Friendly)', 'Snacks', '1 medium (100g)', 68, 14.0, 2.5, 1.0);

-- =============================================================================
-- SEED DATA: Diabetes Health Tips
-- =============================================================================
INSERT INTO `health_tips` (`title`, `tip`, `category`, `language`) VALUES
('Walk After Meals', 'A brisk 10 to 15-minute walk after meals helps insulin work more efficiently and significantly reduces post-meal glucose spikes.', 'Exercise', 'en'),
('Hydration Keeps Sugar Stable', 'Drinking sufficient water (2.5 - 3 liters daily) helps your kidneys flush out excess glucose through urine.', 'Diet', 'en'),
('Prioritize Fiber-Rich Foods', 'Incorporate high-fiber items like oats, methi, chia seeds, and raw greens. Soluble fiber slows carbohydrate absorption and prevents sudden sugar surges.', 'Diet', 'en'),
('Check Your Feet Daily', 'Diabetes can cause reduced sensation in the feet. Inspect feet daily for cuts, blisters, swelling, or redness, and dry thoroughly between toes.', 'Foot Care', 'en'),
('Consistency with Medicine Times', 'Take diabetes medications or insulin at the same time every day with reference to your meals to prevent hypoglycemia.', 'Monitoring', 'en'),
('Sleep Impacts Glucose Levels', 'Aim for 7-8 hours of sound sleep. Chronic sleep deprivation elevates stress hormone cortisol, which can raise blood sugar levels.', 'Mental Well-being', 'en'),
('Pair Carbs with Protein', 'When having carbs (like dosa or chapati), pair them with protein (dal, boiled egg, or paneer) to slow down glucose release.', 'Diet', 'en'),
('Manage Stress Mindfully', 'Stress triggers the liver to release extra glucose. Practice 5 minutes of deep breathing or pranayama when feeling overwhelmed.', 'Mental Well-being', 'en');
