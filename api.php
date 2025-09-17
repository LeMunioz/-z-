<?php

// Configuración de cabeceras HTTP
header('Content-Type: application/json'); // Todas las respuestas serán JSON
header('Access-Control-Allow-Origin: *'); // Permitir acceso desde cualquier origen
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type'); // Encabezados aceptados

// Manejar solicitudes preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

/*  =========================================  //                                               
CONFIGURACION Y CONEXION A LA BASE DE DATOS 
//  =========================================  */
$host = 'localhost';
$dbname = 'pizzeria_db';
$username = 'root'; 
$password = '3312';     
try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, $password); // Crear conexión PDO a MySQL
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);  // Activar errores como excepciones
} catch (PDOException $e) {
    http_response_code(500); //ERROR 500 NO CONECTA A LA BASE DE DATOS
    echo json_encode(['error' => 'Database connection failed: ' . $e->getMessage()]);
    exit;
}


/*  =========================================  //                                               
    ROUTER PRINCIPAL
    analiza la URL y dirige la petición al controlador correcto (orders, inventory, products, stats).
//  =========================================  */
$method = $_SERVER['REQUEST_METHOD']; //detecta el método HTTP (GET, POST, PUT, DELETE)
$request = $_SERVER['REQUEST_URI'];
$path = parse_url($request, PHP_URL_PATH);
$path = str_replace('/api.php', '', $path); // Remueve /api.php de la ruta
$segments = explode('/', trim($path, '/')); // Divide la ruta en segmentos
$endpoint = $segments[0] ?? ''; // El primer segmento es el endpoint (orders, inventory, products, stats)
// Obtener cuerpo de la solicitud para solicitudes POST/PUT
$input = json_decode(file_get_contents('php://input'), true);

switch ($endpoint) {
    case 'orders':
        handleOrders($method, $pdo, $input, $segments);
        break;
    case 'inventory':
        handleInventory($method, $pdo, $input, $segments);
        break;
    case 'products':
        handleProducts($method, $pdo, $input, $segments);
        break;
    case 'stats':
        handleStats($method, $pdo);
        break;
    default:
        http_response_code(404);
        echo json_encode(['error' => 'Endpoint not found']);
        break;
}


/*  =========================================  //                                               
    FUNCIONES PARA ORDENES (tabla->orders y order_items)
//  =========================================  */
// Maneja las solicitudes relacionadas con pedidos
function handleOrders($method, $pdo, $input, $segments) { 
    switch ($method) {
        case 'GET':
            if (isset($segments[1])) {
                // Obtener una orden específico
                getOrder($pdo, $segments[1]);
            } else {
                // Obtener todos las ordenes
                getAllOrders($pdo);
            }
            break;
        case 'POST':
            createOrder($pdo, $input);
            break;
        case 'PUT':
            if (isset($segments[1])) {
                updateOrder($pdo, $segments[1], $input);
            }
            break;
        case 'DELETE':
            if (isset($segments[1])) {
                deleteOrder($pdo, $segments[1]);
            }
            break;
    }
}
// Devuelve todos los pedidos con sus items (concatennado en string)
function getAllOrders($pdo) {
    try {
        $stmt = $pdo->query("
            SELECT o.*, 
                   GROUP_CONCAT(
                       CONCAT(oi.product_name, ' (', oi.quantity, ') - $', oi.total_price)
                       SEPARATOR '; '
                   ) as items
            FROM orders o
            LEFT JOIN order_items oi ON o.id = oi.order_id
            GROUP BY o.id
            ORDER BY o.created_at DESC
        ");
        $orders = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode($orders);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
}
// Devuelve un pedido específico con sus items
function getOrder($pdo, $id) {
    try {
        $stmt = $pdo->prepare("SELECT * FROM orders WHERE id = ?");
        $stmt->execute([$id]);
        $order = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($order) {
            // Obtener items del pedido
            $stmt = $pdo->prepare("SELECT * FROM order_items WHERE order_id = ?");
            $stmt->execute([$id]);
            $order['items'] = $stmt->fetchAll(PDO::FETCH_ASSOC);
            echo json_encode($order);
        } else {
            http_response_code(404);
            echo json_encode(['error' => 'Order not found']);
        }
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
}
// Crear una nueva orden con sus items
function createOrder($pdo, $data) {
    try {
        $pdo->beginTransaction();
        
        // Insertar en tabla orders
        $stmt = $pdo->prepare("
            INSERT INTO orders (customer_name, customer_phone, customer_address, order_type, total_amount)
            VALUES (?, ?, ?, ?, ?)
        ");
        $stmt->execute([
            $data['customer_name'],
            $data['customer_phone'] ?? null,
            $data['customer_address'] ?? null,
            $data['order_type'],
            $data['total_amount']
        ]);
        
        $orderId = $pdo->lastInsertId();
        
        // Insertar items de la orden
        if (isset($data['items']) && is_array($data['items'])) {
            $stmt = $pdo->prepare("
                INSERT INTO order_items (order_id, product_type, product_name, size, specialty, custom_ingredients, quantity, unit_price, total_price)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ");
            
            foreach ($data['items'] as $item) {
                $stmt->execute([
                    $orderId,
                    $item['type'],
                    $item['name'],
                    $item['size'] ?? null,
                    $item['specialty'] ?? null,
                    isset($item['ingredients']) ? implode(', ', $item['ingredients']) : null,
                    1, // cantidad
                    $item['price'],
                    $item['price']
                ]);
            }
        }
        
        $pdo->commit();
        echo json_encode(['success' => true, 'order_id' => $orderId]);
    } catch (PDOException $e) {
        $pdo->rollBack();
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
}
// Actualizar estado de un pedido
function updateOrder($pdo, $id, $data) {
    try {
        $stmt = $pdo->prepare("UPDATE orders SET status = ? WHERE id = ?");
        $stmt->execute([$data['status'], $id]);
        // Si pasa a "completed", registrar fecha de finalización
        if ($data['status'] === 'completed') {
            $stmt = $pdo->prepare("UPDATE orders SET completed_at = NOW() WHERE id = ?");
            $stmt->execute([$id]);
        }
        
        echo json_encode(['success' => true]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
}


/*  =========================================  //                                               
    FUNCIONES PARA INVENTARIO (tabla->inventory)
//  =========================================  */
function handleInventory($method, $pdo, $input, $segments) {
    switch ($method) {
        case 'GET':
            getAllInventory($pdo);
            break;
        case 'PUT':
            if (isset($segments[1])) {
                updateInventoryItem($pdo, $segments[1], $input);
            }
            break;
    }
}
// Listar todos los ingredientes agrupados por categoría
function getAllInventory($pdo) {
    try {
        $stmt = $pdo->query("
            SELECT * FROM inventory 
            ORDER BY category, item_name
        ");
        $inventory = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // agrupar por categoría
        $grouped = [];
        foreach ($inventory as $item) {
            $grouped[$item['category']][] = $item;
        }
        
        echo json_encode($grouped);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
}
// Actualizar cantidad de un ingrediente
function updateInventoryItem($pdo, $id, $data) {
    try {
        $stmt = $pdo->prepare("UPDATE inventory SET quantity = ? WHERE id = ?");
        $stmt->execute([$data['quantity'], $id]);
        echo json_encode(['success' => true]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
}

/*  =========================================  //                                               
    FUNCIONES PARA PRODURCTOS Y ESTADISTICAS
//  =========================================  */
function handleProducts($method, $pdo, $input, $segments) {
    switch ($method) {
        case 'GET':
            getAllProducts($pdo);
            break;
    }
}
// Devuelve la lista del menú
function getAllProducts($pdo) {
    try {
        $stmt = $pdo->query("SELECT * FROM products ORDER BY type, name");
        $products = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode($products);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
}

// Maneja las solicitudes relacionadas con estadísticas
function handleStats($method, $pdo) {
    if ($method === 'GET') {
        try {
            // Get daily stats
            $stmt = $pdo->query("
                SELECT 
                    COUNT(*) as total_orders,
                    SUM(total_amount) as total_sales,
                    AVG(total_amount) as avg_order_value
                FROM orders 
                WHERE DATE(created_at) = CURDATE()
            ");
            $dailyStats = $stmt->fetch(PDO::FETCH_ASSOC);
            
            // Obtener pedidos pendientes
            $stmt = $pdo->query("SELECT COUNT(*) as pending_orders FROM orders WHERE status = 'pending'");
            $pendingStats = $stmt->fetch(PDO::FETCH_ASSOC);
            
            // Sacar ingredientes con bajo stock
            $stmt = $pdo->query("SELECT * FROM v_low_stock LIMIT 5");
            $lowStock = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            echo json_encode([
                'daily' => $dailyStats,
                'pending' => $pendingStats,
                'low_stock' => $lowStock
            ]);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }
}

?>
