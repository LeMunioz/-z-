-- Base de datos para Pizzería πz²α
-- HECHA PARA CORRER USANDO Xampp. Para usarse favor de correr este script en mysql o phpmyadmin

CREATE DATABASE IF NOT EXISTS pizzeria_db;
USE pizzeria_db;

-- Tabla de inventario
CREATE TABLE IF NOT EXISTS inventory (
    id INT AUTO_INCREMENT PRIMARY KEY,
    category VARCHAR(50) NOT NULL COMMENT 'ingredients, drinks, disposables',
    item_key VARCHAR(50) NOT NULL COMMENT 'Clave única del item',
    name VARCHAR(100) NOT NULL COMMENT 'Nombre mostrado del item',
    quantity INT NOT NULL DEFAULT 0 COMMENT 'Cantidad disponible',
    min_stock INT DEFAULT 5 COMMENT 'Stock mínimo para alertas',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_item (category, item_key),
    INDEX idx_category (category),
    INDEX idx_quantity (quantity)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de órdenes
CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL UNIQUE COMMENT 'ID único de la orden (timestamp)',
    customer_name VARCHAR(100) NOT NULL COMMENT 'Nombre del cliente',
    order_type ENUM('pos', 'delivery') NOT NULL COMMENT 'Tipo de orden: punto de venta o domicilio',
    total_amount DECIMAL(10,2) NOT NULL COMMENT 'Monto total de la orden',
    order_items JSON NOT NULL COMMENT 'Items de la orden en formato JSON',
    delivery_info JSON NULL COMMENT 'Información de entrega (solo para delivery)',
    comments TEXT NULL COMMENT 'Comentarios adicionales',
    status ENUM('pending', 'completed', 'cancelled') DEFAULT 'pending' COMMENT 'Estado de la orden',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_order_id (order_id),
    INDEX idx_status (status),
    INDEX idx_type (order_type),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de historial de inventario (para auditoría)
CREATE TABLE IF NOT EXISTS inventory_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    item_category VARCHAR(50) NOT NULL,
    item_key VARCHAR(50) NOT NULL,
    old_quantity INT NOT NULL,
    new_quantity INT NOT NULL,
    change_reason VARCHAR(100) DEFAULT 'manual_update',
    order_id BIGINT NULL COMMENT 'ID de orden si el cambio fue por una venta',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_item (item_category, item_key),
    INDEX idx_order (order_id),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insertar inventario inicial
INSERT INTO inventory (category, item_key, name, quantity, min_stock) VALUES
-- Ingredientes para pizzas
('ingredients', 'peperoni', '🍕 Peperoni', 50, 10),
('ingredients', 'salami', '🥩 Salami', 30, 8),
('ingredients', 'jamon', '🍖 Jamón', 40, 10),
('ingredients', 'chorizo', '🌭 Chorizo', 25, 8),
('ingredients', 'tocino', '🥓 Tocino', 35, 10),
('ingredients', 'pastor', '🌮 Pastor', 20, 5),
('ingredients', 'champiñon', '🍄 Champiñón', 45, 15),
('ingredients', 'piña', '🍍 Piña', 30, 10),
('ingredients', 'chile', '🌶️ Chile', 60, 20),
('ingredients', 'cebolla', '🧅 Cebolla', 55, 15),
('ingredients', 'parmesano', '🧀 Queso Parmesano', 25, 8),

-- Bebidas
('drinks', 'coca', '🥤 Coca Cola', 100, 20),
('drinks', 'fanta', '🍊 Fanta', 80, 15),
('drinks', 'sprite', '🍋 Sprite', 75, 15),
('drinks', 'manzanita', '🍎 Manzanita', 60, 12),
('drinks', 'fresca', '🥤 Fresca', 50, 10),
('drinks', 'agua', '💧 Agua', 150, 30),
('drinks', 'horchata', '🥛 Horchata', 40, 8),
('drinks', 'jugo', '🧃 Jugo', 65, 12),

-- Desechables
('disposables', 'platos', '🍽️ Platos', 200, 50),
('disposables', 'vasos', '🥤 Vasos', 150, 30),
('disposables', 'servilletas', '🧻 Servilletas', 500, 100),
('disposables', 'cajas-pizza', '📦 Cajas de Pizza', 100, 20),
('disposables', 'bolsas', '🛍️ Bolsas', 80, 15)

ON DUPLICATE KEY UPDATE 
    quantity = VALUES(quantity),
    min_stock = VALUES(min_stock);

-- Trigger para registrar cambios en el inventario
DELIMITER //
CREATE TRIGGER IF NOT EXISTS inventory_change_log 
AFTER UPDATE ON inventory
FOR EACH ROW
BEGIN
    IF OLD.quantity != NEW.quantity THEN
        INSERT INTO inventory_history (item_category, item_key, old_quantity, new_quantity, change_reason)
        VALUES (NEW.category, NEW.item_key, OLD.quantity, NEW.quantity, 'system_update');
    END IF;
END//
DELIMITER ;

-- Vista para órdenes pendientes
CREATE OR REPLACE VIEW pending_orders AS
SELECT 
    order_id,
    customer_name,
    order_type,
    total_amount,
    order_items,
    delivery_info,
    comments,
    created_at
FROM orders 
WHERE status = 'pending' 
ORDER BY created_at ASC;

-- Vista para inventario bajo
CREATE OR REPLACE VIEW low_stock_items AS
SELECT 
    category,
    item_key,
    name,
    quantity,
    min_stock,
    (min_stock - quantity) as deficit
FROM inventory 
WHERE quantity <= min_stock
ORDER BY deficit DESC, category, name;

-- Procedimiento para procesar una orden y actualizar inventario
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS ProcessOrder(
    IN p_order_id BIGINT,
    IN p_customer_name VARCHAR(100),
    IN p_order_type VARCHAR(20),
    IN p_total_amount DECIMAL(10,2),
    IN p_order_items JSON,
    IN p_delivery_info JSON,
    IN p_comments TEXT
)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE item_type VARCHAR(50);
    DECLARE item_key VARCHAR(50);
    DECLARE item_quantity INT DEFAULT 1;
    DECLARE specialty VARCHAR(50);
    DECLARE ingredients JSON;
    DECLARE i INT DEFAULT 0;
    DECLARE items_count INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Insertar la orden
    INSERT INTO orders (order_id, customer_name, order_type, total_amount, order_items, delivery_info, comments, status)
    VALUES (p_order_id, p_customer_name, p_order_type, p_total_amount, p_order_items, p_delivery_info, p_comments, 'pending');
    
    -- Procesar items y actualizar inventario
    SET items_count = JSON_LENGTH(p_order_items);
    
    WHILE i < items_count DO
        SET item_type = JSON_UNQUOTE(JSON_EXTRACT(p_order_items, CONCAT('$[', i, '].type')));
        
        IF item_type = 'pizza' THEN
            -- Reducir cajas de pizza
            UPDATE inventory 
            SET quantity = GREATEST(0, quantity - 1)
            WHERE category = 'disposables' AND item_key = 'cajas-pizza';
            
            -- Si es pizza personalizada, reducir ingredientes
            SET ingredients = JSON_EXTRACT(p_order_items, CONCAT('$[', i, '].ingredients'));
            IF ingredients IS NOT NULL THEN
                -- Procesar ingredientes personalizados
                SET @j = 0;
                WHILE @j < JSON_LENGTH(ingredients) DO
                    SET item_key = JSON_UNQUOTE(JSON_EXTRACT(ingredients, CONCAT('$[', @j, '].key')));
                    UPDATE inventory 
                    SET quantity = GREATEST(0, quantity - 1)
                    WHERE category = 'ingredients' AND item_key = item_key;
                    SET @j = @j + 1;
                END WHILE;
            ELSE
                -- Procesar especialidades
                SET specialty = JSON_UNQUOTE(JSON_EXTRACT(p_order_items, CONCAT('$[', i, '].specialty')));
                CASE specialty
                    WHEN 'margarita' THEN
                        UPDATE inventory SET quantity = GREATEST(0, quantity - 1) WHERE category = 'ingredients' AND item_key = 'parmesano';
                    WHEN 'vegetariana' THEN
                        UPDATE inventory SET quantity = GREATEST(0, quantity - 1) WHERE category = 'ingredients' AND item_key IN ('champiñon', 'cebolla', 'chile');
                    WHEN 'hawaiana' THEN
                        UPDATE inventory SET quantity = GREATEST(0, quantity - 1) WHERE category = 'ingredients' AND item_key IN ('jamon', 'piña');
                    WHEN 'carnes-frias' THEN
                        UPDATE inventory SET quantity = GREATEST(0, quantity - 1) WHERE category = 'ingredients' AND item_key IN ('jamon', 'salami', 'tocino');
                    WHEN 'mexicana' THEN
                        UPDATE inventory SET quantity = GREATEST(0, quantity - 1) WHERE category = 'ingredients' AND item_key IN ('chorizo', 'chile', 'cebolla');
                    WHEN 'italiana' THEN
                        UPDATE inventory SET quantity = GREATEST(0, quantity - 1) WHERE category = 'ingredients' AND item_key IN ('salami', 'parmesano');
                    WHEN 'ranchera' THEN
                        UPDATE inventory SET quantity = GREATEST(0, quantity - 1) WHERE category = 'ingredients' AND item_key IN ('tocino', 'cebolla', 'chile');
                END CASE;
            END IF;
            
        ELSEIF item_type = 'drink' THEN
            -- Reducir bebida específica
            SET item_key = JSON_UNQUOTE(JSON_EXTRACT(p_order_items, CONCAT('$[', i, '].drink')));
            UPDATE inventory 
            SET quantity = GREATEST(0, quantity - 1)
            WHERE category = 'drinks' AND item_key = item_key;
            
            -- Reducir vasos
            UPDATE inventory 
            SET quantity = GREATEST(0, quantity - 1)
            WHERE category = 'disposables' AND item_key = 'vasos';
        END IF;
        
        SET i = i + 1;
    END WHILE;
    
    COMMIT;
END//
DELIMITER ;

-- Función para obtener el estado del inventario
DELIMITER //
CREATE FUNCTION IF NOT EXISTS GetInventoryStatus()
RETURNS JSON
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE result JSON;
    
    SELECT JSON_OBJECT(
        'total_items', COUNT(*),
        'low_stock_items', SUM(CASE WHEN quantity <= min_stock THEN 1 ELSE 0 END),
        'out_of_stock_items', SUM(CASE WHEN quantity = 0 THEN 1 ELSE 0 END),
        'categories', JSON_OBJECT(
            'ingredients', (SELECT COUNT(*) FROM inventory WHERE category = 'ingredients'),
            'drinks', (SELECT COUNT(*) FROM inventory WHERE category = 'drinks'),
            'disposables', (SELECT COUNT(*) FROM inventory WHERE category = 'disposables')
        )
    ) INTO result
    FROM inventory;
    
    RETURN result;
END//
DELIMITER ;

-- Insertar algunos datos de ejemplo para testing
INSERT INTO orders (order_id, customer_name, order_type, total_amount, order_items, comments, status) VALUES
(1631234567890, 'Juan Pérez', 'pos', 285.00, '[{"id":1631234567890,"type":"pizza","name":"Pizza Hawaiana (mediana)","price":255,"size":"mediana","specialty":"hawaiana"},{"id":1631234567891,"type":"drink","name":"🥤 Coca Cola","price":30,"drink":"coca"}]', 'Sin cebolla por favor', 'pending'),
(1631234567891, 'María García', 'delivery', 420.00, '[{"id":1631234567892,"type":"pizza","name":"Pizza Personalizada (familiar)","price":374,"size":"familiar","ingredients":[{"name":"🍕 Peperoni (+$20)","key":"peperoni","price":20},{"name":"🥓 Tocino (+$24)","key":"tocino","price":24}],"custom":true},{"id":1631234567893,"type":"drink","name":"🍊 Fanta","price":28,"drink":"fanta"},{"id":1631234567894,"type":"drink","name":"💧 Agua","price":15,"drink":"agua"}]', '{"phone":"555-1234","colonia":"Centro","calle":"Av. Principal 123"}', 'Tocar el timbre dos veces', 'pending');

-- Índices adicionales para optimización
CREATE INDEX idx_inventory_low_stock ON inventory (quantity, min_stock);
CREATE INDEX idx_orders_customer ON orders (customer_name);
CREATE INDEX idx_orders_total ON orders (total_amount);

-- Comentarios en las tablas
ALTER TABLE inventory COMMENT = 'Inventario de ingredientes, bebidas y desechables';
ALTER TABLE orders COMMENT = 'Órdenes de punto de venta y domicilio';
ALTER TABLE inventory_history COMMENT = 'Historial de cambios en el inventario para auditoría';

COMMIT;