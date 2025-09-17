<?php
/*
    API para la pizzería
    Permite gestionar pedidos, inventario, productos y estadísticas.
    Usa PHP y MySQL (PDO).
    QUE HAY Y PARA QUE SIRVE:
        Encabezados iniciales (CORS y JSON): permiten que la API responda en JSON y acepte peticiones desde cualquier origen.
        Conexión a la base de datos: se conecta a MySQL usando PDO. (IMPORTANTE: CAMBIAR USUARIO Y CONTRASEÑA AL IMPLEMENTAR)
        Ruteo (Router): analiza la URL y dirige la petición al controlador correcto (orders, inventory, products, stats).
        Manejo de recursos (endpoints):
            Orders (Pedidos): crear, leer, actualizar y borrar pedidos.
            Inventory (Inventario): consultar y actualizar ingredientes/stock.
            Products (Productos): obtener lista de productos ofrecidos.
            Stats (Estadísticas): obtener métricas del día, pedidos pendientes y bajo stock.
*/

// Configuración de cabeceras HTTP
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type');

/*
    #### CONFIGURACIÓN DE BASE DE DATOS Y CONEXION ####
*/
$host = 'localhost';
$dbname = 'pizzeria_db';
$username = 'root';
$password = '3312'; // Cambiar al implementar

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Error de conexión: ' . $e->getMessage()]);
    exit;
}

// Obtener método HTTP y datos
$method = $_SERVER['REQUEST_METHOD'];
$input = json_decode(file_get_contents('php://input'), true);

// DETERMINAR ACCION
$action = '';
if ($method === 'GET' && isset($_GET['action'])) {
    $action = $_GET['action'];
} elseif ($method === 'POST' && isset($input['action'])) {
    $action = $input['action'];
}

try {
    switch ($action) {
        case 'get_inventory':
            getInventory($pdo);
            break;
            
        case 'update_inventory':
            updateInventory($pdo, $input['inventory']);
            break;
            
        case 'save_order':
            saveOrder($pdo, $input['order']);
            break;
            
        case 'get_orders':
            getOrders($pdo);
            break;
            
        case 'update_order_status':
            updateOrderStatus($pdo, $input['order_id'], $input['status']);
            break;
            
        case 'init_database':
            initDatabase($pdo);
            break;
            
        default:
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Acción no válida']);
            break;
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Error del servidor: ' . $e->getMessage()]);
}

/* 
    FUNCIONES DE MANEJO DE INVENTARIO Y PEDIDOS
*/
function getInventory($pdo) {
    $stmt = $pdo->query("SELECT * FROM inventory");
    $items = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Organizar por categorías
    $inventory = [
        'ingredients' => [],
        'drinks' => [],
        'disposables' => []
    ];
    
    foreach ($items as $item) {
        $inventory[$item['category']][$item['item_key']] = [
            'name' => $item['name'],
            'quantity' => (int)$item['quantity']
        ];
    }
    
    echo json_encode(['success' => true, 'inventory' => $inventory]);
}

// Función para actualizar inventario
function updateInventory($pdo, $inventory) {
    $pdo->beginTransaction();
    
    try {
        // Limpiar inventario actual
        $pdo->exec("DELETE FROM inventory");
        
        // Insertar nuevo inventario
        $stmt = $pdo->prepare("INSERT INTO inventory (category, item_key, name, quantity) VALUES (?, ?, ?, ?)");
        
        foreach ($inventory as $category => $items) {
            foreach ($items as $key => $item) {
                $stmt->execute([$category, $key, $item['name'], $item['quantity']]);
            }
        }
        
        $pdo->commit();
        echo json_encode(['success' => true, 'message' => 'Inventario actualizado']);
        
    } catch (Exception $e) {
        $pdo->rollback();
        throw $e;
    }
}

// Función para guardar orden
function saveOrder($pdo, $order) {
    $stmt = $pdo->prepare("
        INSERT INTO orders (order_id, customer_name, order_type, total_amount, order_items, delivery_info, comments, status, created_at) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ");
    
    $deliveryInfo = isset($order['deliveryInfo']) ? json_encode($order['deliveryInfo']) : null;
    $comments = isset($order['comments']) ? $order['comments'] : null;
    
    $stmt->execute([
        $order['id'],
        $order['customer'],
        $order['type'],
        $order['total'],
        json_encode($order['items']),
        $deliveryInfo,
        $comments,
        $order['status'],
        date('Y-m-d H:i:s')
    ]);
    
    echo json_encode(['success' => true, 'message' => 'Orden guardada']);
}

// Función para obtener órdenes
function getOrders($pdo) {
    $stmt = $pdo->query("SELECT * FROM orders WHERE status = 'pending' ORDER BY created_at DESC");
    $orders = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Procesar órdenes para el formato esperado
    $processedOrders = [];
    foreach ($orders as $order) {
        $processedOrder = [
            'id' => $order['order_id'],
            'customer' => $order['customer_name'],
            'type' => $order['order_type'],
            'total' => (float)$order['total_amount'],
            'items' => json_decode($order['order_items'], true),
            'status' => $order['status'],
            'timestamp' => new DateTime($order['created_at']),
            'comments' => $order['comments']
        ];
        
        if ($order['delivery_info']) {
            $processedOrder['deliveryInfo'] = json_decode($order['delivery_info'], true);
        }
        
        $processedOrders[] = $processedOrder;
    }
    
    echo json_encode(['success' => true, 'orders' => $processedOrders]);
}

// Función para actualizar estado de orden
function updateOrderStatus($pdo, $orderId, $status) {
    $stmt = $pdo->prepare("UPDATE orders SET status = ? WHERE order_id = ?");
    $stmt->execute([$status, $orderId]);
    
    echo json_encode(['success' => true, 'message' => 'Estado de orden actualizado']);
}
    //FUNCIONES PARA INICIALIZAR LA BASE DE DATOS
// Función para inicializar base de datos
function initDatabase($pdo) {
    // Crear tabla de inventario si no existe
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS inventory (
            id INT AUTO_INCREMENT PRIMARY KEY,
            category VARCHAR(50) NOT NULL,
            item_key VARCHAR(50) NOT NULL,
            name VARCHAR(100) NOT NULL,
            quantity INT NOT NULL DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            UNIQUE KEY unique_item (category, item_key)
        )
    ");
    
    // Crear tabla de órdenes si no existe
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS orders (
            id INT AUTO_INCREMENT PRIMARY KEY,
            order_id BIGINT NOT NULL UNIQUE,
            customer_name VARCHAR(100) NOT NULL,
            order_type ENUM('pos', 'delivery') NOT NULL,
            total_amount DECIMAL(10,2) NOT NULL,
            order_items JSON NOT NULL,
            delivery_info JSON NULL,
            comments TEXT NULL,
            status ENUM('pending', 'completed', 'cancelled') DEFAULT 'pending',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ");
    
    // Insertar inventario inicial si está vacío
    $stmt = $pdo->query("SELECT COUNT(*) FROM inventory");
    if ($stmt->fetchColumn() == 0) {
        $initialInventory = [
            // Ingredientes
            ['ingredients', 'peperoni', '🍕 Peperoni', 50],
            ['ingredients', 'salami', '🥩 Salami', 30],
            ['ingredients', 'jamon', '🍖 Jamón', 40],
            ['ingredients', 'chorizo', '🌭 Chorizo', 25],
            ['ingredients', 'tocino', '🥓 Tocino', 35],
            ['ingredients', 'pastor', '🌮 Pastor', 20],
            ['ingredients', 'champiñon', '🍄 Champiñón', 45],
            ['ingredients', 'piña', '🍍 Piña', 30],
            ['ingredients', 'chile', '🌶️ Chile', 60],
            ['ingredients', 'cebolla', '🧅 Cebolla', 55],
            ['ingredients', 'parmesano', '🧀 Queso Parmesano', 25],
            
            // Bebidas
            ['drinks', 'coca', '🥤 Coca Cola', 100],
            ['drinks', 'fanta', '🍊 Fanta', 80],
            ['drinks', 'sprite', '🍋 Sprite', 75],
            ['drinks', 'manzanita', '🍎 Manzanita', 60],
            ['drinks', 'fresca', '🥤 Fresca', 50],
            ['drinks', 'agua', '💧 Agua', 150],
            ['drinks', 'horchata', '🥛 Horchata', 40],
            ['drinks', 'jugo', '🧃 Jugo', 65],
            
            // Desechables
            ['disposables', 'platos', '🍽️ Platos', 200],
            ['disposables', 'vasos', '🥤 Vasos', 150],
            ['disposables', 'servilletas', '🧻 Servilletas', 500],
            ['disposables', 'cajas-pizza', '📦 Cajas de Pizza', 100],
            ['disposables', 'bolsas', '🛍️ Bolsas', 80]
        ];
        
        $stmt = $pdo->prepare("INSERT INTO inventory (category, item_key, name, quantity) VALUES (?, ?, ?, ?)");
        foreach ($initialInventory as $item) {
            $stmt->execute($item);
        }
    }
    
    echo json_encode(['success' => true, 'message' => 'Base de datos inicializada']);
}

?>
