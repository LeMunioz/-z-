-- Para XAMPP/MySQL
-- Ejevutar este codigo en phpMyAdmin o en la consola de MySQL

CREATE DATABASE IF NOT EXISTS pizzeria_db;
USE pizzeria_db;


-- ### TABLAS ###
-- TABLA DE PRODUCTOS
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    type ENUM('pizza_specialty', 'drink', 'ingredient') NOT NULL,
    base_price DECIMAL(10, 2) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- TABLA DE INVENTARIO
CREATE TABLE IF NOT EXISTS inventory (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT,
    category ENUM('ingredients', 'drinks', 'disposables') NOT NULL,
    item_name VARCHAR(100) NOT NULL,
    quantity INT NOT NULL DEFAULT 0,
    min_stock INT DEFAULT 5,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL
);

-- TABLA DE ORDENES
CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    customer_phone VARCHAR(20),
    customer_address TEXT,
    order_type ENUM('pos', 'delivery') NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    status ENUM('pending', 'preparing', 'ready', 'completed', 'cancelled') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL
);

-- LO QUE SE ORDENA (PIZZA Y BEBIDAS)
CREATE TABLE IF NOT EXISTS order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_type ENUM('pizza', 'drink') NOT NULL,
    product_name VARCHAR(200) NOT NULL,
    size ENUM('pequeña', 'mediana', 'familiar'),
    specialty VARCHAR(100),
    custom_ingredients TEXT,
    quantity INT DEFAULT 1,
    unit_price DECIMAL(10, 2) NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
);

-- TAMAÑOS DE PIZZA
CREATE TABLE IF NOT EXISTS pizza_sizes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    size_name ENUM('pequeña', 'mediana', 'familiar') NOT NULL,
    price_multiplier DECIMAL(3, 2) NOT NULL,
    base_price DECIMAL(10, 2) NOT NULL
);