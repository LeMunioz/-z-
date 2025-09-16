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



-- ### INSERTANDO DATOS EN LAS TABLAS ###
-- INSERTANDO EN PRODUTOS
INSERT INTO products (name, type, base_price, description) VALUES
-- Especialidades
('Hawaiana', 'pizza_specialty', 180.00, 'Pizza con jamón y piña'),
('Carnes Frías', 'pizza_specialty', 220.00, 'Pizza con peperoni, salami y jamón'),
('Italiana', 'pizza_specialty', 200.00, 'Pizza con salami, champiñones y parmesano'),
('Mexicana', 'pizza_specialty', 210.00, 'Pizza con chorizo, chile, cebolla y jamon'),
('Vegetariana', 'pizza_specialty', 170.00, 'Pizza con champiñones, pimiento y cebolla'),
('Ranchera', 'pizza_specialty', 190.00, 'Pizza estilo ranchero con pastor, chile y jamon'),
('Margarita', 'pizza_specialty', 160.00, 'Pizza clásica con tomate, mozzarella, parmessano y albahaca'),
-- Bebidas
('Refresco', 'drink', 25.00, 'chescos'),
('Agua', 'drink', 15.00, 'Agua natural'),
('Horchata', 'drink', 30.00, 'Agua fresca de arroz'),
('Jugo', 'drink', 35.00, 'Jugo natural de naranja'),
-- Ingredientes
('Peperoni', 'ingredient', 15.00, 'Peperoni en rebanadas'),
('Salami', 'ingredient', 15.00, 'Salami italiano'),
('Jamón', 'ingredient', 15.00, 'Jamón de pierna'),
('Chorizo', 'ingredient', 15.00, 'Chorizo mexicano'),
('Tocino', 'ingredient', 15.00, 'Tocino crujiente'),
('Pastor', 'ingredient', 15.00, 'Carne al pastor'),
('Champiñón', 'ingredient', 15.00, 'Champiñones frescos'),
('Piña', 'ingredient', 15.00, 'Piña en trozos'),
('Chile', 'ingredient', 15.00, 'Chile jalapeño'),
('Cebolla', 'ingredient', 15.00, 'Cebolla blanca'),
('Queso Parmesano', 'ingredient', 15.00, 'Queso parmesano rallado');

-- INSERTANDO EN INVENTARIO
INSERT INTO inventory (product_id, category, item_name, quantity, min_stock) VALUES
-- Ingredientes
(9, 'ingredients', 'Peperoni', 50, 10),
(10, 'ingredients', 'Salami', 30, 5),
(11, 'ingredients', 'Jamón', 40, 8),
(12, 'ingredients', 'Chorizo', 25, 5),
(13, 'ingredients', 'Tocino', 35, 7),
(14, 'ingredients', 'Pastor', 20, 5),
(15, 'ingredients', 'Champiñón', 45, 10),
(16, 'ingredients', 'Piña', 30, 8),
(17, 'ingredients', 'Chile', 60, 15),
(18, 'ingredients', 'Cebolla', 55, 12),
(19, 'ingredients', 'Queso Parmesano', 25, 5),
-- Bebibdas
(5, 'drinks', 'Refresco', 100, 20),
(6, 'drinks', 'Agua', 150, 30),
(7, 'drinks', 'Horchata', 50, 10),
(8, 'drinks', 'Jugo', 75, 15),
-- Desechables
(NULL, 'disposables', 'Platos', 200, 50),
(NULL, 'disposables', 'Vasos', 150, 30),
(NULL, 'disposables', 'Servilletas', 500, 100),
(NULL, 'disposables', 'Cajas de Pizza', 100, 20),
(NULL, 'disposables', 'Bolsas', 80, 15);
-- INSERTANDO EN TAMAÑOS DE PIZZA
INSERT INTO pizza_sizes (size_name, price_multiplier, base_price) VALUES
('pequeña', 1.00, 150.00),
('mediana', 1.50, 225.00),
('familiar', 2.00, 300.00);



-- ### OPTIMIZACIONES ###
-- Create indexes for better performance
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_type ON orders(order_type);
CREATE INDEX idx_orders_created ON orders(created_at);
CREATE INDEX idx_inventory_category ON inventory(category);
CREATE INDEX idx_products_type ON products(type);

-- Create views for easier data access
CREATE VIEW v_pending_orders AS
SELECT 
    o.id,
    o.customer_name,
    o.customer_phone,
    o.customer_address,
    o.order_type,
    o.total_amount,
    o.created_at,
    GROUP_CONCAT(
        CONCAT(oi.product_name, ' (', oi.quantity, ')') 
        SEPARATOR ', '
    ) as items
FROM orders o
LEFT JOIN order_items oi ON o.id = oi.order_id
WHERE o.status = 'pending'
GROUP BY o.id
ORDER BY o.created_at ASC;

CREATE VIEW v_low_stock AS
SELECT 
    item_name,
    quantity,
    min_stock,
    category,
    (quantity - min_stock) as stock_difference
FROM inventory
WHERE quantity <= min_stock
ORDER BY stock_difference ASC;

-- Stored procedures for common operations

-- Add new order
DELIMITER //
CREATE PROCEDURE AddOrder(
    IN p_customer_name VARCHAR(100),
    IN p_customer_phone VARCHAR(20),
    IN p_customer_address TEXT,
    IN p_order_type ENUM('pos', 'delivery'),
    IN p_total_amount DECIMAL(10, 2),
    OUT p_order_id INT
)
BEGIN
    INSERT INTO orders (customer_name, customer_phone, customer_address, order_type, total_amount)
    VALUES (p_customer_name, p_customer_phone, p_customer_address, p_order_type, p_total_amount);
    
    SET p_order_id = LAST_INSERT_ID();
END //
DELIMITER ;

-- Update inventory
DELIMITER //
CREATE PROCEDURE UpdateInventory(
    IN p_item_name VARCHAR(100),
    IN p_quantity_change INT
)
BEGIN
    UPDATE inventory 
    SET quantity = GREATEST(0, quantity + p_quantity_change),
        last_updated = CURRENT_TIMESTAMP
    WHERE item_name = p_item_name;
END //
DELIMITER ;

-- Complete order
DELIMITER //
CREATE PROCEDURE CompleteOrder(
    IN p_order_id INT
)
BEGIN
    UPDATE orders 
    SET status = 'completed', 
        completed_at = CURRENT_TIMESTAMP 
    WHERE id = p_order_id;
END //
DELIMITER ;

-- Triggers for inventory management
DELIMITER //
CREATE TRIGGER after_order_insert
AFTER INSERT ON order_items
FOR EACH ROW
BEGIN
    -- Reduce pizza box inventory for pizza orders
    IF NEW.product_type = 'pizza' THEN
        UPDATE inventory 
        SET quantity = GREATEST(0, quantity - NEW.quantity)
        WHERE item_name = 'Cajas de Pizza';
    END IF;
    
    -- Reduce cup inventory for drink orders
    IF NEW.product_type = 'drink' THEN
        UPDATE inventory 
        SET quantity = GREATEST(0, quantity - NEW.quantity)
        WHERE item_name = 'Vasos';
    END IF;
END //
DELIMITER ;

-- Sample data for testing
INSERT INTO orders (customer_name, customer_phone, customer_address, order_type, total_amount, status) VALUES
('Juan Pérez', '555-1234', 'Av. Principal 123', 'delivery', 245.00, 'pending'),
('María García', NULL, NULL, 'pos', 180.00, 'pending'),
('Carlos López', '555-5678', 'Calle Secundaria 456', 'delivery', 320.00, 'completed');

INSERT INTO order_items (order_id, product_type, product_name, size, specialty, quantity, unit_price, total_price) VALUES
(1, 'pizza', 'Pizza Hawaiana', 'mediana', 'hawaiana', 1, 270.00, 270.00),
(1, 'drink', 'Refresco', NULL, NULL, 1, 25.00, 25.00),
(2, 'pizza', 'Pizza Personalizada', 'pequeña', NULL, 1, 180.00, 180.00),
(3, 'pizza', 'Pizza Carnes Frías', 'familiar', 'carnes-frias', 1, 440.00, 440.00);

-- Grant permissions (adjust username as needed)
-- GRANT ALL PRIVILEGES ON pizzeria_db.* TO 'pizzeria_user'@'localhost' IDENTIFIED BY 'pizzeria_password';
-- FLUSH PRIVILEGES;