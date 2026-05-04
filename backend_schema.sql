-- Wardrobe app tables (MySQL/MariaDB)
-- Aligns with Flutter requests for login, images, upload, and important dates.

CREATE TABLE IF NOT EXISTS wardrobe_categories (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(120) NOT NULL,
  type VARCHAR(80) NULL,
  gender VARCHAR(40) NULL,
  colour VARCHAR(40) NULL,
  size VARCHAR(40) NULL,
  season VARCHAR(40) NULL,
  occasion VARCHAR(80) NULL,
  description TEXT NULL,
  created_at TIMESTAMP NULL,
  updated_at TIMESTAMP NULL,
  INDEX idx_wardrobe_categories_user_id (user_id),
  CONSTRAINT fk_wardrobe_categories_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS user_images (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  category_id BIGINT UNSIGNED NULL,
  image_name VARCHAR(180) NOT NULL,
  description TEXT NULL,
  image VARCHAR(255) NOT NULL,
  created_at TIMESTAMP NULL,
  updated_at TIMESTAMP NULL,
  INDEX idx_user_images_user_id (user_id),
  INDEX idx_user_images_category_id (category_id),
  CONSTRAINT fk_user_images_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE,
  CONSTRAINT fk_user_images_category
    FOREIGN KEY (category_id) REFERENCES wardrobe_categories(id)
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS important_dates (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(160) NOT NULL,
  date DATE NOT NULL,
  occasion VARCHAR(120) NULL,
  notes TEXT NULL,
  created_at TIMESTAMP NULL,
  updated_at TIMESTAMP NULL,
  INDEX idx_important_dates_user_id (user_id),
  INDEX idx_important_dates_date (date),
  CONSTRAINT fk_important_dates_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Saved outfits
CREATE TABLE IF NOT EXISTS outfits (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(180) NOT NULL,
  occasion VARCHAR(120) NULL,
  notes TEXT NULL,
  created_at TIMESTAMP NULL,
  updated_at TIMESTAMP NULL,
  INDEX idx_outfits_user_id (user_id),
  CONSTRAINT fk_outfits_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS outfit_items (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  outfit_id BIGINT UNSIGNED NOT NULL,
  user_image_id BIGINT UNSIGNED NOT NULL,
  slot VARCHAR(60) NULL,
  sort_order INT UNSIGNED NOT NULL DEFAULT 0,
  created_at TIMESTAMP NULL,
  updated_at TIMESTAMP NULL,
  INDEX idx_outfit_items_outfit_id (outfit_id),
  INDEX idx_outfit_items_user_image_id (user_image_id),
  UNIQUE KEY uq_outfit_items_outfit_image (outfit_id, user_image_id),
  CONSTRAINT fk_outfit_items_outfit
    FOREIGN KEY (outfit_id) REFERENCES outfits(id)
    ON DELETE CASCADE,
  CONSTRAINT fk_outfit_items_user_image
    FOREIGN KEY (user_image_id) REFERENCES user_images(id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Inner circle (shared outfits + invites)
CREATE TABLE IF NOT EXISTS inner_circle_invites (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  email VARCHAR(190) NULL,
  code VARCHAR(80) NOT NULL,
  status VARCHAR(40) NOT NULL DEFAULT 'pending',
  created_at TIMESTAMP NULL,
  updated_at TIMESTAMP NULL,
  accepted_at TIMESTAMP NULL,
  INDEX idx_inner_circle_invites_user_id (user_id),
  INDEX idx_inner_circle_invites_email (email),
  CONSTRAINT fk_inner_circle_invites_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS inner_circle_members (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  member_user_id BIGINT UNSIGNED NOT NULL,
  status VARCHAR(40) NOT NULL DEFAULT 'active',
  created_at TIMESTAMP NULL,
  updated_at TIMESTAMP NULL,
  INDEX idx_inner_circle_members_user_id (user_id),
  INDEX idx_inner_circle_members_member_id (member_user_id),
  CONSTRAINT fk_inner_circle_members_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE,
  CONSTRAINT fk_inner_circle_members_member
    FOREIGN KEY (member_user_id) REFERENCES users(id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS inner_circle_posts (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  image_id BIGINT UNSIGNED NULL,
  caption TEXT NULL,
  likes_count INT UNSIGNED NOT NULL DEFAULT 0,
  comments_count INT UNSIGNED NOT NULL DEFAULT 0,
  created_at TIMESTAMP NULL,
  updated_at TIMESTAMP NULL,
  INDEX idx_inner_circle_posts_user_id (user_id),
  INDEX idx_inner_circle_posts_image_id (image_id),
  CONSTRAINT fk_inner_circle_posts_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE,
  CONSTRAINT fk_inner_circle_posts_image
    FOREIGN KEY (image_id) REFERENCES user_images(id)
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Optional profile fields
ALTER TABLE users
  ADD COLUMN phone VARCHAR(30) NULL AFTER email,
  ADD COLUMN location VARCHAR(255) NULL AFTER phone;
