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

    //TODAS LAS INTERACCIONES ED BOTONES Y FORMULARIOS
    setupEventListeners() {
        // NAVEGACION ENTRE VISTAS
        document.querySelectorAll('.nav-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                this.switchView(e.target.dataset.view);
            });
        });
    
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
}//FIN DE pizzeriaApp