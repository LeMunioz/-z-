// script principal JavaScript

class PizzeriaApp {
    //INICIALIZACION DE LA APP y DE LAS VARIABLES GLOBALES
    constructor() {
        this.cart = [];
        this.currentSize = 'pequeña';
        this.currentMultiplier = 1;
        this.currentView = 'pos';
        this.orders = [];
        this.inventory = this.initializeInventory();
        
        this.init();
    }

    init() {
        this.setupEventListeners();
        this.loadInventory();
        this.loadOrders();
        this.updateCartDisplay();
    }

    initializeInventory() {
        return {
            ingredients: {
                'peperoni': { name: '🍕 Peperoni', quantity: 50 },
                'salami': { name: '🥩 Salami', quantity: 30 },
                'jamon': { name: '🍖 Jamón', quantity: 40 },
                'chorizo': { name: '🌭 Chorizo', quantity: 25 },
                'tocino': { name: '🥓 Tocino', quantity: 35 },
                'pastor': { name: '🌮 Pastor', quantity: 20 },
                'champiñon': { name: '🍄 Champiñón', quantity: 45 },
                'piña': { name: '🍍 Piña', quantity: 30 },
                'chile': { name: '🌶️ Chile', quantity: 60 },
                'cebolla': { name: '🧅 Cebolla', quantity: 55 },
                'parmesano': { name: '🧀 Queso Parmesano', quantity: 25 }
            },
            drinks: {
                'refresco': { name: '🥤 Refresco', quantity: 100 },
                'agua': { name: '💧 Agua', quantity: 150 },
                'horchata': { name: '🥛 Horchata', quantity: 50 },
                'jugo': { name: '🧃 Jugo', quantity: 75 }
            },
            disposables: {
                'platos': { name: '🍽️ Platos', quantity: 200 },
                'vasos': { name: '🥤 Vasos', quantity: 150 },
                'servilletas': { name: '🧻 Servilletas', quantity: 500 },
                'cajas-pizza': { name: '📦 Cajas de Pizza', quantity: 100 },
                'bolsas': { name: '🛍️ Bolsas', quantity: 80 }
            }
        };
    }//FIN DE initializeInventory

    setupEventListeners() {
        // NAVEGACION ENTRE VISTAS
        document.querySelectorAll('.nav-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                this.switchView(e.target.dataset.view);
            });
        });

    //PARA CAMBIAR DE VISTA 
    switchView(viewName) {
        // actualizar navegacion
        document.querySelectorAll('.nav-btn').forEach(btn => {
            btn.classList.remove('active');
        });
        document.querySelector(`[data-view="${viewName}"]`).classList.add('active');

        // Mover a nueva vista
        document.querySelectorAll('.view').forEach(view => {
            view.classList.remove('active');
        });
        document.getElementById(`${viewName}-view`).classList.add('active');

        this.currentView = viewName;

        // Jalar datos si es necesario en lo del almacen
        if (viewName === 'inventory') {
            this.loadInventory();
        } else if (viewName === 'orders') {
            this.loadOrders();
        }
    }
    
    //================================
    //FUNCIONES DE PARA ORDENAR
    //================================    
        // Tamano de pizza
        document.querySelectorAll('.size-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                this.selectSize(e.target);
            });
        });
        // Especialidades de pizza
        document.querySelectorAll('.pizza-card').forEach(card => {
            card.addEventListener('click', (e) => {
                this.addSpecialtyPizza(e.currentTarget);
            });
        });
        // Bebidas
        document.querySelectorAll('.drink-card').forEach(card => {
            card.addEventListener('click', (e) => {
                this.addDrink(e.currentTarget);
            });
        });
        // Construye pizza
        document.querySelector('.build-pizza-btn').addEventListener('click', () => {
            this.toggleCustomPizzaPanel();
        });
        // Checkboxes de ingredientes
        document.querySelectorAll('.ingredient-item input').forEach(checkbox => {
            checkbox.addEventListener('change', () => {
                this.updateCustomPizzaPrice();
            });
        });
        // Anadir la pizza construida al carrito
        document.querySelector('.add-custom-pizza').addEventListener('click', () => {
            this.addCustomPizza();
        });
        // Poner la orden
        document.getElementById('place-order').addEventListener('click', () => {
            this.placeOrder();
        });
        // Entregar orden (utilizado en la vista de ordenes)
        this.setupDeliveryView();
    }  

    selectSize(sizeBtn) {
        document.querySelectorAll('.size-btn').forEach(btn => {
            btn.classList.remove('active');
        });
        sizeBtn.classList.add('active');
        
        this.currentSize = sizeBtn.dataset.size;
        this.currentMultiplier = parseFloat(sizeBtn.dataset.multiplier);
        
        this.updateCustomPizzaPrice();
    }

    addSpecialtyPizza(pizzaCard) {
        const specialty = pizzaCard.dataset.specialty;
        const basePrice = parseInt(pizzaCard.dataset.price);
        const finalPrice = Math.round(basePrice * this.currentMultiplier);
        
        const item = {
            id: Date.now(),
            type: 'pizza',
            name: `Pizza ${specialty.charAt(0).toUpperCase() + specialty.slice(1)} (${this.currentSize})`,
            price: finalPrice,
            size: this.currentSize,
            specialty: specialty
        };
        
        this.cart.push(item);
        this.updateCartDisplay();
        this.showSuccessMessage(`Pizza ${specialty} agregada al carrito`);
    }

    addDrink(drinkCard) {
        const drink = drinkCard.dataset.drink;
        const price = parseInt(drinkCard.dataset.price);
        
        const item = {
            id: Date.now(),
            type: 'drink',
            name: drinkCard.querySelector('span').textContent,
            price: price,
            drink: drink
        };
        
        this.cart.push(item);
        this.updateCartDisplay();
        this.showSuccessMessage(`${item.name} agregada al carrito`);
    }

    toggleCustomPizzaPanel() {
        const panel = document.querySelector('.ingredients-panel');
        const isVisible = panel.style.display !== 'none';
        panel.style.display = isVisible ? 'none' : 'block';
        
        if (!isVisible) {
            this.updateCustomPizzaPrice();
        }
    }

    updateCustomPizzaPrice() {
        const basePrice = 150; // PRECIO DE LA BASE DE LA PIZZA
        const checkedIngredients = document.querySelectorAll('.ingredient-item input:checked');
        const ingredientsPrice = checkedIngredients.length * 15;
        const totalPrice = Math.round((basePrice + ingredientsPrice) * this.currentMultiplier);
        
        document.getElementById('custom-price').textContent = totalPrice;
    }

    addCustomPizza() {
        const checkedIngredients = document.querySelectorAll('.ingredient-item input:checked');
        const ingredients = Array.from(checkedIngredients).map(input => 
            input.parentElement.querySelector('span').textContent
        );
        
        if (ingredients.length === 0) {
            this.showErrorMessage('Selecciona al menos un ingrediente');
            return;
        }
        
        const basePrice = 150;
        const ingredientsPrice = ingredients.length * 15;
        const totalPrice = Math.round((basePrice + ingredientsPrice) * this.currentMultiplier);
        
        const item = {
            id: Date.now(),
            type: 'pizza',
            name: `Pizza Personalizada (${this.currentSize})`,
            price: totalPrice,
            size: this.currentSize,
            ingredients: ingredients,
            custom: true
        };
        
        this.cart.push(item);
        this.updateCartDisplay();
        
        // REsetear panel
        checkedIngredients.forEach(input => input.checked = false);
        this.toggleCustomPizzaPanel();
        
        this.showSuccessMessage('Pizza personalizada agregada al carrito');
    }

    // ### FUNCIONES DEL CARRITO ### 
    updateCartDisplay() {
        const cartItems = document.getElementById('cart-items');
        const cartTotal = document.getElementById('cart-total');
        
        if (this.cart.length === 0) {
            cartItems.innerHTML = '<p class="empty-cart">El carrito está vacío</p>';
            cartTotal.textContent = '0';
            return;
        }
        
        cartItems.innerHTML = this.cart.map(item => `
            <div class="cart-item">
                <div class="cart-item-info">
                    <div class="cart-item-name">${item.name}</div>
                    ${item.ingredients ? `<div class="cart-item-details">Ingredientes: ${item.ingredients.join(', ')}</div>` : ''}
                </div>
                <div class="cart-item-price">$${item.price}</div>
                <button class="remove-item" onclick="app.removeFromCart(${item.id})">✕</button>
            </div>
        `).join('');
        
        const total = this.cart.reduce((sum, item) => sum + item.price, 0);
        cartTotal.textContent = total;
    }

    removeFromCart(itemId) {
        this.cart = this.cart.filter(item => item.id !== itemId);
        this.updateCartDisplay();
    }

    placeOrder() {
        const customerName = document.getElementById('customer-name').value.trim();
        
        if (!customerName) {
            this.showErrorMessage('Por favor ingresa el nombre del cliente');
            return;
        }
        
        if (this.cart.length === 0) {
            this.showErrorMessage('El carrito está vacío');
            return;
        }
        
        const order = {
            id: Date.now(),
            customer: customerName,
            items: [...this.cart],
            total: this.cart.reduce((sum, item) => sum + item.price, 0),
            timestamp: new Date(),
            type: this.currentView === 'delivery' ? 'delivery' : 'pos',
            status: 'pending'
        };
        
        // agregar info de entrega si es necesario
        if (this.currentView === 'delivery') {
            const phone = document.getElementById('delivery-phone').value.trim();
            const address = document.getElementById('delivery-address').value.trim();
            
            if (!phone || !address) {
                this.showErrorMessage('Por favor completa todos los datos de entrega');
                return;
            }
            
            order.deliveryInfo = {
                phone: phone,
                address: address
            };
        }
        
        this.orders.push(order);
        this.saveOrders();
        
        // limpiar carrito y formulario
        this.cart = [];
        this.updateCartDisplay();
        document.getElementById('customer-name').value = '';
        
        if (this.currentView === 'delivery') {
            document.getElementById('delivery-name').value = '';
            document.getElementById('delivery-phone').value = '';
            document.getElementById('delivery-address').value = '';
        }
        
        this.showSuccessMessage(`Pedido #${order.id} realizado exitosamente`);
        
        // actualizar vista de ordenes si es visible (falta implementar)
        this.updateInventoryAfterOrder(order);
    }

     setupDeliveryView() {
        // copiar nombre automaticamente cuando se escribe en el input de nombre del cliente
        const customerNameInput = document.getElementById('customer-name');
        const deliveryNameInput = document.getElementById('delivery-name');
        
        if (customerNameInput && deliveryNameInput) {
            customerNameInput.addEventListener('input', () => {
                if (this.currentView === 'delivery') {
                    deliveryNameInput.value = customerNameInput.value;
                }
            });
        }
    }

    //================================
    //FUNCIONES DE INVENTARIO
    //================================
    loadInventory() {
        this.displayInventorySection('ingredients', 'ingredients-inventory');
        this.displayInventorySection('drinks', 'drinks-inventory');
        this.displayInventorySection('disposables', 'disposables-inventory');
    }

    displayInventorySection(section, containerId) {
        const container = document.getElementById(containerId);
        if (!container) return;
        
        const items = this.inventory[section];
        container.innerHTML = Object.keys(items).map(key => {
            const item = items[key];
            return `
                <div class="inventory-item">
                    <div class="inventory-item-name">${item.name}</div>
                    <div class="inventory-quantity">${item.quantity}</div>
                    <div class="quantity-controls">
                        <button class="quantity-btn" onclick="app.updateInventory('${section}', '${key}', -1)">-</button>
                        <button class="quantity-btn" onclick="app.updateInventory('${section}', '${key}', 1)">+</button>
                    </div>
                </div>
            `;
        }).join('');
    }

    updateInventory(section, item, change) {
        const currentQuantity = this.inventory[section][item].quantity;
        const newQuantity = Math.max(0, currentQuantity + change);
        
        this.inventory[section][item].quantity = newQuantity;
        this.saveInventory();
        this.loadInventory();
        
        if (newQuantity <= 5) {
            this.showErrorMessage(`⚠️ Stock bajo: ${this.inventory[section][item].name} (${newQuantity} restantes)`);
        }
    }
    // Actualizar inventario despues de hacer una orden para que no se pueda pedir si no hay ingredientes
    updateInventoryAfterOrder(order) {
        order.items.forEach(item => {
            if (item.type === 'pizza') {
                // Reduce pizza ingredients en inventario
                if (item.ingredients) {
                    item.ingredients.forEach(ingredient => {
                        const ingredientKey = this.findIngredientKey(ingredient);
                        if (ingredientKey && this.inventory.ingredients[ingredientKey]) {
                            this.inventory.ingredients[ingredientKey].quantity = Math.max(0, 
                                this.inventory.ingredients[ingredientKey].quantity - 1);
                        }
                    });
                }
                // Reduce cajas de pizza en inventario
                this.inventory.disposables['cajas-pizza'].quantity = Math.max(0, 
                    this.inventory.disposables['cajas-pizza'].quantity - 1);
            } else if (item.type === 'drink') {
                // Reduce bebidas en inventario
                const drinkKey = item.drink;
                if (this.inventory.drinks[drinkKey]) {
                    this.inventory.drinks[drinkKey].quantity = Math.max(0, 
                        this.inventory.drinks[drinkKey].quantity - 1);
                }
                // Reducir vasos en inventario
                this.inventory.disposables['vasos'].quantity = Math.max(0, 
                    this.inventory.disposables['vasos'].quantity - 1);
            }
        });
        
        this.saveInventory();
    }

    findIngredientKey(ingredientName) {
        for (const [key, value] of Object.entries(this.inventory.ingredients)) {
            if (value.name.includes(ingredientName.replace(/[🍕🥩🍖🌭🥓🌮🍄🍍🌶️🧅🧀]/g, '').trim())) {
                return key;
            }
        }
        return null;
    }

    loadOrders() {
        const posOrders = document.getElementById('pos-orders');
        const deliveryOrders = document.getElementById('delivery-orders');
        
        if (!posOrders || !deliveryOrders) return;
        
        const pendingOrders = this.orders.filter(order => order.status === 'pending');
        const posOrdersList = pendingOrders.filter(order => order.type === 'pos');
        const deliveryOrdersList = pendingOrders.filter(order => order.type === 'delivery');
        
        posOrders.innerHTML = posOrdersList.length ? posOrdersList.map(order => this.createOrderCard(order)).join('') : 
            '<p class="empty-cart">No hay pedidos en local pendientes</p>';
        
        deliveryOrders.innerHTML = deliveryOrdersList.length ? deliveryOrdersList.map(order => this.createOrderCard(order)).join('') : 
            '<p class="empty-cart">No hay pedidos a domicilio pendientes</p>';
    }
    // Crear la tarjeta de cada orden
    createOrderCard(order) {
        return `
            <div class="order-card">
                <div class="order-header">
                    <span class="order-id">Pedido #${order.id}</span>
                    <span class="order-time">${order.timestamp.toLocaleTimeString()}</span>
                </div>
                <div class="order-customer">👤 ${order.customer}</div>
                ${order.deliveryInfo ? `
                    <div class="order-delivery">
                        <div>📞 ${order.deliveryInfo.phone}</div>
                        <div>📍 ${order.deliveryInfo.address}</div>
                    </div>
                ` : ''}
                <div class="order-items">
                    ${order.items.map(item => `
                        <div class="order-item">
                            <span>${item.name}</span>
                            <span>$${item.price}</span>
                        </div>
                    `).join('')}
                </div>
                <div class="order-total">Total: $${order.total}</div>
                <button class="complete-order-btn" onclick="app.completeOrder(${order.id})">
                    ✅ Marcar como Completado
                </button>
            </div>
        `;
    }

    completeOrder(orderId) {
        const orderIndex = this.orders.findIndex(order => order.id === orderId);
        if (orderIndex !== -1) {
            this.orders[orderIndex].status = 'completed';
            this.saveOrders();
            this.loadOrders();
            this.showSuccessMessage(`Pedido #${orderId} completado`);
        }
    }

    //================================
    // FUNCIONES DE MANEJO DE MENSAJES Y LOCALSTORAGE
    //================================
    // MENSAJES DE EXITO Y ERROR
    showSuccessMessage(message) {
        this.showMessage(message, 'success');
    }
    showErrorMessage(message) {
        this.showMessage(message, 'error');
    }
    showMessage(message, type) {
        const messageDiv = document.createElement('div');
        messageDiv.className = `${type}-message`;
        messageDiv.textContent = message;
  
        document.body.appendChild(messageDiv);
        
        setTimeout(() => {
            messageDiv.remove();
        }, 3000);
    }

    // PARA GUARDAR EN EL LOCALSTORAGE -> api.php
    saveOrders() {
        localStorage.setItem('pizzeria_orders', JSON.stringify(this.orders));
    }
    loadOrdersFromStorage() {
        const saved = localStorage.getItem('pizzeria_orders');
        if (saved) {
            this.orders = JSON.parse(saved).map(order => ({
                ...order,
                timestamp: new Date(order.timestamp)
            }));
        }
    }
    saveInventory() {
        localStorage.setItem('pizzeria_inventory', JSON.stringify(this.inventory));
    }
    loadInventoryFromStorage() {
        const saved = localStorage.getItem('pizzeria_inventory');
        if (saved) {
            this.inventory = JSON.parse(saved);
        }
    }
}//FIN DE pizzeriaApp ##################################################################

// Inciar la app
const app = new PizzeriaApp();

// cargar datos guardados al iniciar
document.addEventListener('DOMContentLoaded', () => {
    app.loadOrdersFromStorage();
    app.loadInventoryFromStorage();
    app.loadInventory();
    app.loadOrders();
});