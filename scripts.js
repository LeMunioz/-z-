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
    
    
}//FIN DE pizzeriaApp