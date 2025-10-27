// Admin Panel JavaScript
class AdminPanel {
    constructor() {
        this.apiBaseUrl = 'http://localhost:3000/api';
        this.socket = null;
        this.currentUser = null;
        this.charts = {};
        this.init();
    }

    init() {
        this.setupSocket();
        this.loadDashboard();
        this.setupEventListeners();
    }

    setupSocket() {
        this.socket = io('http://localhost:3000');
        
        this.socket.on('connect', () => {
            console.log('Connected to server');
            this.showNotification('Kết nối thành công với server', 'success');
        });

        this.socket.on('disconnect', () => {
            console.log('Disconnected from server');
            this.showNotification('Mất kết nối với server', 'warning');
        });

        this.socket.on('location-update', (data) => {
            this.handleLocationUpdate(data);
        });

        this.socket.on('order-status-update', (data) => {
            this.handleOrderStatusUpdate(data);
        });
    }

    setupEventListeners() {
        // Auto refresh every 30 seconds
        setInterval(() => {
            if (document.getElementById('dashboard-section').style.display !== 'none') {
                this.loadDashboard();
            }
        }, 30000);
    }

    async loadDashboard() {
        this.showLoading();
        
        try {
            // Load statistics with timeout
            const statsPromise = this.loadStatistics();
            const statsTimeout = new Promise(resolve => setTimeout(resolve, 2000));
            await Promise.race([statsPromise, statsTimeout]);
            
            // Load recent orders with timeout
            const ordersPromise = this.loadRecentOrders();
            const ordersTimeout = new Promise(resolve => setTimeout(resolve, 2000));
            await Promise.race([ordersPromise, ordersTimeout]);
            
            // Load charts
            this.loadCharts();
            
        } catch (error) {
            console.error('Error loading dashboard:', error);
            this.showNotification('Lỗi khi tải dashboard', 'error');
        }
        
        // Always hide loading after 3 seconds maximum
        setTimeout(() => {
            this.hideLoading();
        }, 3000);
    }

    async loadStatistics() {
        // Always use mock data for now to avoid loading issues
        const stats = {
            totalOrders: 1247,
            deliveredOrders: 892,
            processingOrders: 156,
            totalRevenue: 45678900
        };

        document.getElementById('total-orders').textContent = stats.totalOrders.toLocaleString();
        document.getElementById('delivered-orders').textContent = stats.deliveredOrders.toLocaleString();
        document.getElementById('processing-orders').textContent = stats.processingOrders.toLocaleString();
        document.getElementById('total-revenue').textContent = this.formatCurrency(stats.totalRevenue);
    }

    async loadRecentOrders() {
        // Always use mock data for now to avoid loading issues
        const orders = [
            {
                id: 1,
                order_number: 'ORD-001',
                restaurant_name: 'Nhà hàng ABC',
                customer_name: 'Nguyễn Văn A',
                total_amount: 150000,
                status: 'processing',
                created_at: new Date().toISOString()
            },
            {
                id: 2,
                order_number: 'ORD-002',
                restaurant_name: 'Quán ăn XYZ',
                customer_name: 'Trần Thị B',
                total_amount: 200000,
                status: 'shipped',
                created_at: new Date(Date.now() - 3600000).toISOString()
            },
            {
                id: 3,
                order_number: 'ORD-003',
                restaurant_name: 'Cafe DEF',
                customer_name: 'Lê Văn C',
                total_amount: 80000,
                status: 'delivered',
                created_at: new Date(Date.now() - 7200000).toISOString()
            }
        ];

        const tbody = document.getElementById('recent-orders-table');
        tbody.innerHTML = orders.map(order => `
            <tr onclick="adminPanel.showOrderDetails(${order.id})" style="cursor: pointer;">
                <td>${order.order_number}</td>
                <td>${order.restaurant_name}</td>
                <td>${order.customer_name}</td>
                <td>${this.formatCurrency(order.total_amount)}</td>
                <td><span class="badge status-${order.status}">${this.getStatusText(order.status)}</span></td>
                <td>${this.formatDateTime(order.created_at)}</td>
            </tr>
        `).join('');
    }

    loadCharts() {
        this.loadOrdersChart();
        this.loadStatusChart();
    }

    loadOrdersChart() {
        const ctx = document.getElementById('ordersChart').getContext('2d');
        
        if (this.charts.orders) {
            this.charts.orders.destroy();
        }

        this.charts.orders = new Chart(ctx, {
            type: 'line',
            data: {
                labels: ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'],
                datasets: [{
                    label: 'Đơn hàng',
                    data: [65, 78, 90, 81, 95, 105, 88],
                    borderColor: '#6366f1',
                    backgroundColor: 'rgba(99, 102, 241, 0.1)',
                    tension: 0.4,
                    fill: true
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        display: false
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });
    }

    loadStatusChart() {
        const ctx = document.getElementById('statusChart').getContext('2d');
        
        if (this.charts.status) {
            this.charts.status.destroy();
        }

        this.charts.status = new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: ['Đã giao', 'Đang xử lý', 'Đang giao', 'Chờ xử lý'],
                datasets: [{
                    data: [45, 25, 20, 10],
                    backgroundColor: [
                        '#10b981',
                        '#6366f1',
                        '#8b5cf6',
                        '#f59e0b'
                    ]
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'bottom'
                    }
                }
            }
        });
    }

    async showOrders() {
        this.hideAllSections();
        document.getElementById('orders-section').style.display = 'block';
        
        try {
            await this.loadOrders();
        } catch (error) {
            console.error('Error loading orders:', error);
            this.showNotification('Lỗi khi tải danh sách đơn hàng', 'error');
        }
    }

    async loadOrders() {
        try {
            // Mock data for demonstration
            const orders = [
                {
                    id: 1,
                    order_number: 'ORD-001',
                    restaurant_name: 'Nhà hàng ABC',
                    customer_name: 'Nguyễn Văn A',
                    items: [
                        { name: 'Phở bò', quantity: 2, price: 75000 },
                        { name: 'Nước ngọt', quantity: 1, price: 15000 }
                    ],
                    total_amount: 165000,
                    status: 'processing',
                    created_at: new Date().toISOString()
                },
                {
                    id: 2,
                    order_number: 'ORD-002',
                    restaurant_name: 'Quán ăn XYZ',
                    customer_name: 'Trần Thị B',
                    items: [
                        { name: 'Cơm tấm', quantity: 1, price: 45000 },
                        { name: 'Canh chua', quantity: 1, price: 25000 }
                    ],
                    total_amount: 70000,
                    status: 'shipped',
                    created_at: new Date(Date.now() - 3600000).toISOString()
                }
            ];

            const tbody = document.getElementById('orders-table');
            tbody.innerHTML = orders.map(order => `
                <tr>
                    <td>${order.order_number}</td>
                    <td>${order.restaurant_name}</td>
                    <td>${order.customer_name}</td>
                    <td>
                        ${order.items.map(item => `${item.name} (x${item.quantity})`).join('<br>')}
                    </td>
                    <td>${this.formatCurrency(order.total_amount)}</td>
                    <td><span class="badge status-${order.status}">${this.getStatusText(order.status)}</span></td>
                    <td>${this.formatDateTime(order.created_at)}</td>
                    <td>
                        <button class="btn btn-sm btn-outline-primary" onclick="adminPanel.showOrderDetails(${order.id})">
                            <i class="fas fa-eye"></i>
                        </button>
                        <button class="btn btn-sm btn-outline-success" onclick="adminPanel.updateOrderStatus(${order.id})">
                            <i class="fas fa-edit"></i>
                        </button>
                    </td>
                </tr>
            `).join('');

        } catch (error) {
            console.error('Error loading orders:', error);
        }
    }

    async showTracking() {
        this.hideAllSections();
        document.getElementById('tracking-section').style.display = 'block';
        
        try {
            await this.loadActiveDeliveries();
        } catch (error) {
            console.error('Error loading tracking:', error);
            this.showNotification('Lỗi khi tải theo dõi giao hàng', 'error');
        }
    }

    async loadActiveDeliveries() {
        try {
            // Mock data for demonstration
            const deliveries = [
                {
                    order_id: 1,
                    order_number: 'ORD-001',
                    customer_name: 'Nguyễn Văn A',
                    restaurant_name: 'Nhà hàng ABC',
                    status: 'on_the_way',
                    latitude: 10.762622,
                    longitude: 106.660172,
                    address: '123 Nguyễn Huệ, Q1, TP.HCM',
                    estimated_time: '15 phút'
                },
                {
                    order_id: 2,
                    order_number: 'ORD-002',
                    customer_name: 'Trần Thị B',
                    restaurant_name: 'Quán ăn XYZ',
                    status: 'picked_up',
                    latitude: 10.775658,
                    longitude: 106.700420,
                    address: '456 Lê Lợi, Q1, TP.HCM',
                    estimated_time: '25 phút'
                }
            ];

            const container = document.getElementById('active-deliveries');
            container.innerHTML = deliveries.map(delivery => `
                <div class="order-item">
                    <div class="d-flex justify-content-between align-items-start mb-2">
                        <h6 class="mb-0">${delivery.order_number}</h6>
                        <span class="badge status-${delivery.status}">${this.getStatusText(delivery.status)}</span>
                    </div>
                    <p class="mb-1"><strong>Khách hàng:</strong> ${delivery.customer_name}</p>
                    <p class="mb-1"><strong>Nhà hàng:</strong> ${delivery.restaurant_name}</p>
                    <p class="mb-1"><strong>Địa chỉ:</strong> ${delivery.address}</p>
                    <p class="mb-0"><strong>Thời gian dự kiến:</strong> ${delivery.estimated_time}</p>
                    <div class="mt-2">
                        <button class="btn btn-sm btn-primary" onclick="adminPanel.trackOrder(${delivery.order_id})">
                            <i class="fas fa-map-marker-alt me-1"></i>Theo dõi
                        </button>
                    </div>
                </div>
            `).join('');

        } catch (error) {
            console.error('Error loading active deliveries:', error);
        }
    }

    async showUsers() {
        this.hideAllSections();
        document.getElementById('users-section').style.display = 'block';
        
        try {
            await this.loadUsers();
        } catch (error) {
            console.error('Error loading users:', error);
            this.showNotification('Lỗi khi tải danh sách người dùng', 'error');
        }
    }

    async loadUsers() {
        try {
            // Mock data for demonstration
            const users = [
                {
                    id: 1,
                    full_name: 'Nguyễn Văn A',
                    email: 'nguyenvana@email.com',
                    phone: '0123456789',
                    address: '123 Nguyễn Huệ, Q1, TP.HCM',
                    created_at: new Date().toISOString()
                },
                {
                    id: 2,
                    full_name: 'Trần Thị B',
                    email: 'tranthib@email.com',
                    phone: '0987654321',
                    address: '456 Lê Lợi, Q1, TP.HCM',
                    created_at: new Date(Date.now() - 86400000).toISOString()
                }
            ];

            const tbody = document.getElementById('users-table');
            tbody.innerHTML = users.map(user => `
                <tr>
                    <td>${user.id}</td>
                    <td>${user.full_name}</td>
                    <td>${user.email}</td>
                    <td>${user.phone}</td>
                    <td>${user.address}</td>
                    <td>${this.formatDateTime(user.created_at)}</td>
                    <td>
                        <button class="btn btn-sm btn-outline-primary">
                            <i class="fas fa-eye"></i>
                        </button>
                        <button class="btn btn-sm btn-outline-warning">
                            <i class="fas fa-edit"></i>
                        </button>
                    </td>
                </tr>
            `).join('');

        } catch (error) {
            console.error('Error loading users:', error);
        }
    }

    async showAnalytics() {
        this.hideAllSections();
        document.getElementById('analytics-section').style.display = 'block';
        
        try {
            await this.loadAnalytics();
        } catch (error) {
            console.error('Error loading analytics:', error);
            this.showNotification('Lỗi khi tải thống kê', 'error');
        }
    }

    async loadAnalytics() {
        try {
            this.loadRevenueChart();
            this.loadRestaurantsChart();
        } catch (error) {
            console.error('Error loading analytics:', error);
        }
    }

    loadRevenueChart() {
        const ctx = document.getElementById('revenueChart').getContext('2d');
        
        if (this.charts.revenue) {
            this.charts.revenue.destroy();
        }

        this.charts.revenue = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'],
                datasets: [{
                    label: 'Doanh thu (VNĐ)',
                    data: [1200000, 1500000, 1800000, 2000000, 2200000, 2500000, 2100000],
                    backgroundColor: 'rgba(99, 102, 241, 0.8)',
                    borderColor: '#6366f1',
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true,
                        ticks: {
                            callback: function(value) {
                                return value.toLocaleString() + 'đ';
                            }
                        }
                    }
                }
            }
        });
    }

    loadRestaurantsChart() {
        const ctx = document.getElementById('restaurantsChart').getContext('2d');
        
        if (this.charts.restaurants) {
            this.charts.restaurants.destroy();
        }

        this.charts.restaurants = new Chart(ctx, {
            type: 'horizontalBar',
            data: {
                labels: ['Nhà hàng ABC', 'Quán ăn XYZ', 'Cafe DEF', 'Pizza GHK', 'Burger IJK'],
                datasets: [{
                    label: 'Số đơn hàng',
                    data: [45, 38, 32, 28, 25],
                    backgroundColor: [
                        '#6366f1',
                        '#8b5cf6',
                        '#10b981',
                        '#f59e0b',
                        '#ef4444'
                    ]
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                indexAxis: 'y',
                scales: {
                    x: {
                        beginAtZero: true
                    }
                }
            }
        });
    }

    showOrderDetails(orderId) {
        // Mock order details
        const orderDetails = {
            id: orderId,
            order_number: 'ORD-001',
            restaurant_name: 'Nhà hàng ABC',
            customer_name: 'Nguyễn Văn A',
            items: [
                { name: 'Phở bò', quantity: 2, price: 75000 },
                { name: 'Nước ngọt', quantity: 1, price: 15000 }
            ],
            total_amount: 165000,
            delivery_fee: 15000,
            status: 'processing',
            delivery_address: '123 Nguyễn Huệ, Q1, TP.HCM',
            delivery_phone: '0123456789',
            notes: 'Giao hàng nhanh',
            created_at: new Date().toISOString()
        };

        const modalBody = document.getElementById('order-details');
        modalBody.innerHTML = `
            <div class="row">
                <div class="col-md-6">
                    <h6>Thông tin đơn hàng</h6>
                    <p><strong>Mã đơn:</strong> ${orderDetails.order_number}</p>
                    <p><strong>Nhà hàng:</strong> ${orderDetails.restaurant_name}</p>
                    <p><strong>Khách hàng:</strong> ${orderDetails.customer_name}</p>
                    <p><strong>Trạng thái:</strong> <span class="badge status-${orderDetails.status}">${this.getStatusText(orderDetails.status)}</span></p>
                </div>
                <div class="col-md-6">
                    <h6>Thông tin giao hàng</h6>
                    <p><strong>Địa chỉ:</strong> ${orderDetails.delivery_address}</p>
                    <p><strong>Số điện thoại:</strong> ${orderDetails.delivery_phone}</p>
                    <p><strong>Ghi chú:</strong> ${orderDetails.notes}</p>
                </div>
            </div>
            <hr>
            <h6>Sản phẩm</h6>
            <div class="table-responsive">
                <table class="table table-sm">
                    <thead>
                        <tr>
                            <th>Tên sản phẩm</th>
                            <th>Số lượng</th>
                            <th>Giá</th>
                            <th>Thành tiền</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${orderDetails.items.map(item => `
                            <tr>
                                <td>${item.name}</td>
                                <td>${item.quantity}</td>
                                <td>${this.formatCurrency(item.price)}</td>
                                <td>${this.formatCurrency(item.price * item.quantity)}</td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>
            </div>
            <div class="row">
                <div class="col-md-6">
                    <p><strong>Phí giao hàng:</strong> ${this.formatCurrency(orderDetails.delivery_fee)}</p>
                </div>
                <div class="col-md-6">
                    <p><strong>Tổng cộng:</strong> ${this.formatCurrency(orderDetails.total_amount + orderDetails.delivery_fee)}</p>
                </div>
            </div>
        `;

        const modal = new bootstrap.Modal(document.getElementById('orderModal'));
        modal.show();
    }

    updateOrderStatus(orderId) {
        // Implementation for updating order status
        this.showNotification('Tính năng cập nhật trạng thái đơn hàng', 'info');
    }

    trackOrder(orderId) {
        // Implementation for tracking order
        this.showNotification('Tính năng theo dõi đơn hàng', 'info');
    }

    handleLocationUpdate(data) {
        console.log('Location update received:', data);
        // Update map and tracking information
        this.showNotification(`Cập nhật vị trí đơn hàng ${data.order_id}`, 'info');
    }

    handleOrderStatusUpdate(data) {
        console.log('Order status update received:', data);
        // Update order status in UI
        this.showNotification(`Cập nhật trạng thái đơn hàng ${data.order_id}`, 'info');
    }

    filterOrders() {
        const status = document.getElementById('status-filter').value;
        // Implementation for filtering orders
        this.showNotification(`Lọc đơn hàng theo trạng thái: ${status}`, 'info');
    }

    refreshOrders() {
        this.loadOrders();
        this.showNotification('Đã làm mới danh sách đơn hàng', 'success');
    }

    refreshUsers() {
        this.loadUsers();
        this.showNotification('Đã làm mới danh sách người dùng', 'success');
    }

    showDashboard() {
        this.hideAllSections();
        document.getElementById('dashboard-section').style.display = 'block';
        this.loadDashboard();
    }

    hideAllSections() {
        const sections = ['dashboard-section', 'orders-section', 'tracking-section', 'users-section', 'analytics-section'];
        sections.forEach(section => {
            document.getElementById(section).style.display = 'none';
        });
    }

    showLoading() {
        const modal = document.getElementById('loadingModal');
        if (modal) {
            const bsModal = new bootstrap.Modal(modal, {
                backdrop: 'static',
                keyboard: false
            });
            bsModal.show();
        }
    }

    hideLoading() {
        const modal = document.getElementById('loadingModal');
        if (modal) {
            const bsModal = bootstrap.Modal.getInstance(modal);
            if (bsModal) {
                bsModal.hide();
            }
        }
    }

    showNotification(message, type = 'info') {
        const notification = document.createElement('div');
        notification.className = `alert alert-${type === 'error' ? 'danger' : type} alert-dismissible fade show notification`;
        notification.innerHTML = `
            ${message}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        `;
        
        document.body.appendChild(notification);
        
        setTimeout(() => {
            notification.remove();
        }, 5000);
    }

    formatCurrency(amount) {
        return new Intl.NumberFormat('vi-VN', {
            style: 'currency',
            currency: 'VND'
        }).format(amount);
    }

    formatDateTime(dateString) {
        const date = new Date(dateString);
        return date.toLocaleString('vi-VN');
    }

    getStatusText(status) {
        const statusMap = {
            'pending': 'Chờ xử lý',
            'processing': 'Đang xử lý',
            'shipped': 'Đang giao',
            'delivered': 'Đã giao',
            'cancelled': 'Đã hủy',
            'preparing': 'Chuẩn bị',
            'picked_up': 'Đã lấy hàng',
            'on_the_way': 'Đang giao'
        };
        return statusMap[status] || status;
    }

    logout() {
        if (confirm('Bạn có chắc chắn muốn đăng xuất?')) {
            // Clear any stored data
            localStorage.clear();
            sessionStorage.clear();
            
            // Redirect to login page or show login form
            this.showNotification('Đã đăng xuất thành công', 'success');
            
            // In a real application, you would redirect to login page
            // window.location.href = '/login.html';
        }
    }
}

// Initialize admin panel when page loads
let adminPanel;
document.addEventListener('DOMContentLoaded', () => {
    adminPanel = new AdminPanel();
});

// Global functions for HTML onclick events
function showDashboard() {
    adminPanel.showDashboard();
}

function showOrders() {
    adminPanel.showOrders();
}

function showTracking() {
    adminPanel.showTracking();
}

function showUsers() {
    adminPanel.showUsers();
}

function showAnalytics() {
    adminPanel.showAnalytics();
}

function logout() {
    adminPanel.logout();
}

function filterOrders() {
    adminPanel.filterOrders();
}

function refreshOrders() {
    adminPanel.refreshOrders();
}

function refreshUsers() {
    adminPanel.refreshUsers();
}

function loadAnalytics() {
    adminPanel.loadAnalytics();
}
