// Configuration
const API_BASE_URL = 'http://localhost:3000/api';
let authToken = localStorage.getItem('token') || sessionStorage.getItem('token') || '';
let isDemoMode = localStorage.getItem('demoMode') === 'true';
let socket = null;
let charts = {};

// Initialize on page load
document.addEventListener('DOMContentLoaded', function() {
    if (!checkAuth()) {
        return; // Don't proceed if not authenticated
    }
    
    // Display user info
    displayUserInfo();
    
    initializeSocketIO();
    loadDashboard();
});

// Check authentication
function checkAuth() {
    if (!authToken) {
        // Redirect to login page
        console.warn('No auth token found. Redirecting to login...');
        window.location.href = 'login.html';
        return false;
    }
    
    return true;
}

// Display user information in navbar
function displayUserInfo() {
    const userStr = localStorage.getItem('user') || sessionStorage.getItem('user');
    if (userStr) {
        try {
            const user = JSON.parse(userStr);
            const userNameElement = document.getElementById('user-name');
            if (userNameElement) {
                userNameElement.textContent = user.name || user.email || 'Admin';
            }
            console.log('Logged in as:', user.name || user.email);
        } catch (e) {
            console.error('Error parsing user data:', e);
        }
    }
    
    // Show demo badge if in demo mode
    if (isDemoMode) {
        const demoBadge = document.getElementById('demo-badge');
        if (demoBadge) {
            demoBadge.style.display = 'inline';
        }
        console.log('%c🎭 DEMO MODE ACTIVE - Using mock data', 'color: orange; font-weight: bold; font-size: 14px;');
    }
}

// Initialize Socket.IO for real-time updates
function initializeSocketIO() {
    socket = io('http://localhost:3000', {
        transports: ['websocket', 'polling']
    });

    socket.on('connect', () => {
        console.log('Connected to Socket.IO server');
    });

    socket.on('order-status-updated', (data) => {
        console.log('Order status updated:', data);
        showNotification('Đơn hàng đã được cập nhật', 'info');
        // Refresh current view
        refreshCurrentView();
    });

    socket.on('new-order', (data) => {
        console.log('New order received:', data);
        showNotification('Có đơn hàng mới!', 'success');
        refreshCurrentView();
    });

    socket.on('disconnect', () => {
        console.log('Disconnected from Socket.IO server');
    });
}

// API Helper function
async function apiCall(endpoint, method = 'GET', data = null) {
    // Demo mode: return mock data
    if (isDemoMode) {
        return getMockData(endpoint, method, data);
    }

    const options = {
        method,
        headers: {
            'Content-Type': 'application/json',
        }
    };

    if (authToken) {
        options.headers['Authorization'] = `Bearer ${authToken}`;
    }

    if (data && (method === 'POST' || method === 'PUT' || method === 'PATCH')) {
        options.body = JSON.stringify(data);
    }

    try {
        const response = await fetch(`${API_BASE_URL}${endpoint}`, options);
        const result = await response.json();

        if (!response.ok) {
            // Handle 401 Unauthorized
            if (response.status === 401) {
                console.error('Unauthorized access. Redirecting to login...');
                localStorage.removeItem('token');
                sessionStorage.removeItem('token');
                localStorage.removeItem('user');
                sessionStorage.removeItem('user');
                window.location.href = 'login.html';
                throw new Error('Session expired. Please login again.');
            }
            throw new Error(result.message || 'API request failed');
        }

        return result;
    } catch (error) {
        console.error('API Error:', error);
        
        // Don't show error notification for auth redirect
        if (!error.message.includes('Session expired')) {
            showNotification(error.message || 'Lỗi kết nối API', 'error');
        }
        throw error;
    }
}

// Navigation functions
function showDashboard() {
    hideAllSections();
    document.getElementById('dashboard-section').style.display = 'block';
    setActiveMenu(0);
    loadDashboard();
}

function showOrders() {
    hideAllSections();
    document.getElementById('orders-section').style.display = 'block';
    setActiveMenu(1);
    loadOrders();
}

function showTracking() {
    hideAllSections();
    document.getElementById('tracking-section').style.display = 'block';
    setActiveMenu(2);
    loadActiveDeliveries();
}

function showUsers() {
    hideAllSections();
    document.getElementById('users-section').style.display = 'block';
    setActiveMenu(3);
    loadUsers();
}

function showAnalytics() {
    hideAllSections();
    document.getElementById('analytics-section').style.display = 'block';
    setActiveMenu(4);
    loadAnalytics();
}

function hideAllSections() {
    const sections = ['dashboard-section', 'orders-section', 'tracking-section', 'users-section', 'analytics-section'];
    sections.forEach(section => {
        const element = document.getElementById(section);
        if (element) {
            element.style.display = 'none';
        }
    });
}

function setActiveMenu(index) {
    const navLinks = document.querySelectorAll('.sidebar .nav-link');
    navLinks.forEach((link, i) => {
        if (i === index) {
            link.classList.add('active');
        } else {
            link.classList.remove('active');
        }
    });
}

// Dashboard functions
async function loadDashboard() {
    try {
        showLoading();
        
        // Load dashboard statistics
        const statsResponse = await apiCall('/admin/stats');
        
        if (statsResponse.status === 'success') {
            const stats = statsResponse.data;
            
            // Update stat cards
            document.getElementById('total-orders').textContent = stats.totalOrders || 0;
            document.getElementById('delivered-orders').textContent = stats.deliveredOrders || 0;
            document.getElementById('processing-orders').textContent = stats.processingOrders || 0;
            document.getElementById('total-revenue').textContent = formatCurrency(stats.totalRevenue || 0);
            
            // Update charts
            updateOrdersChart(stats.ordersChart || []);
            updateStatusChart(stats.statusCounts || {});
        }
        
        // Load recent orders
        const ordersResponse = await apiCall('/admin/orders?limit=5');
        if (ordersResponse.status === 'success') {
            displayRecentOrders(ordersResponse.data.orders);
        }
        
        hideLoading();
    } catch (error) {
        console.error('Error loading dashboard:', error);
        hideLoading();
    }
}

function displayRecentOrders(orders) {
    const tbody = document.getElementById('recent-orders-table');
    if (!tbody) return;
    
    tbody.innerHTML = '';
    
    if (orders.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" class="text-center">Chưa có đơn hàng nào</td></tr>';
        return;
    }
    
    orders.forEach(order => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${order.order_number}</td>
            <td>${order.restaurant_name}</td>
            <td>${order.customer_name || 'N/A'}</td>
            <td>${formatCurrency(parseFloat(order.total_amount) + parseFloat(order.delivery_fee))}</td>
            <td><span class="badge status-${order.status}">${getStatusText(order.status)}</span></td>
            <td>${formatDateTime(order.created_at)}</td>
        `;
        row.style.cursor = 'pointer';
        row.onclick = () => showOrderDetails(order.id);
        tbody.appendChild(row);
    });
}

// Orders functions
async function loadOrders() {
    try {
        showLoading();
        
        const statusFilter = document.getElementById('status-filter').value;
        let endpoint = '/admin/orders?limit=50';
        
        if (statusFilter) {
            endpoint += `&status=${statusFilter}`;
        }
        
        const response = await apiCall(endpoint);
        
        if (response.status === 'success') {
            displayOrders(response.data.orders);
        }
        
        hideLoading();
    } catch (error) {
        console.error('Error loading orders:', error);
        hideLoading();
    }
}

function displayOrders(orders) {
    const tbody = document.getElementById('orders-table');
    if (!tbody) return;
    
    tbody.innerHTML = '';
    
    if (orders.length === 0) {
        tbody.innerHTML = '<tr><td colspan="8" class="text-center">Không có đơn hàng nào</td></tr>';
        return;
    }
    
    orders.forEach(order => {
        const items = JSON.parse(order.items || '[]');
        const itemsText = items.map(item => `${item.name} x${item.quantity}`).join(', ');
        
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${order.order_number}</td>
            <td>${order.restaurant_name}</td>
            <td>
                <div>${order.customer_name || 'N/A'}</div>
                <small class="text-muted">${order.customer_email || ''}</small>
            </td>
            <td>
                <small>${itemsText.substring(0, 50)}${itemsText.length > 50 ? '...' : ''}</small>
            </td>
            <td>${formatCurrency(parseFloat(order.total_amount) + parseFloat(order.delivery_fee))}</td>
            <td><span class="badge status-${order.status}">${getStatusText(order.status)}</span></td>
            <td>${formatDateTime(order.created_at)}</td>
            <td>
                <button class="btn btn-sm btn-primary" onclick="showOrderDetails(${order.id})">
                    <i class="fas fa-eye"></i>
                </button>
            </td>
        `;
        tbody.appendChild(row);
    });
}

function filterOrders() {
    loadOrders();
}

function refreshOrders() {
    loadOrders();
}

async function showOrderDetails(orderId) {
    try {
        showLoading();
        
        const response = await apiCall(`/admin/orders/${orderId}`);
        
        if (response.status === 'success') {
            const order = response.data.order;
            const items = JSON.parse(order.items || '[]');
            
            const modalBody = document.getElementById('order-details');
            modalBody.innerHTML = `
                <div class="row">
                    <div class="col-md-6">
                        <h6>Thông tin đơn hàng</h6>
                        <p><strong>Mã đơn:</strong> ${order.order_number}</p>
                        <p><strong>Nhà hàng:</strong> ${order.restaurant_name}</p>
                        <p><strong>Trạng thái:</strong> <span class="badge status-${order.status}">${getStatusText(order.status)}</span></p>
                        <p><strong>Thời gian:</strong> ${formatDateTime(order.created_at)}</p>
                    </div>
                    <div class="col-md-6">
                        <h6>Thông tin khách hàng</h6>
                        <p><strong>Tên:</strong> ${order.customer_name || 'N/A'}</p>
                        <p><strong>Email:</strong> ${order.customer_email || 'N/A'}</p>
                        <p><strong>SĐT:</strong> ${order.customer_phone || order.delivery_phone || 'N/A'}</p>
                        <p><strong>Địa chỉ:</strong> ${order.delivery_address}</p>
                    </div>
                </div>
                
                <hr>
                
                <h6>Sản phẩm</h6>
                <table class="table table-sm">
                    <thead>
                        <tr>
                            <th>Tên</th>
                            <th>Số lượng</th>
                            <th>Giá</th>
                            <th>Tổng</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${items.map(item => `
                            <tr>
                                <td>${item.name}</td>
                                <td>${item.quantity}</td>
                                <td>${formatCurrency(item.price)}</td>
                                <td>${formatCurrency(item.price * item.quantity)}</td>
                            </tr>
                        `).join('')}
                    </tbody>
                    <tfoot>
                        <tr>
                            <td colspan="3" class="text-end"><strong>Tạm tính:</strong></td>
                            <td><strong>${formatCurrency(order.total_amount)}</strong></td>
                        </tr>
                        <tr>
                            <td colspan="3" class="text-end"><strong>Phí giao hàng:</strong></td>
                            <td><strong>${formatCurrency(order.delivery_fee)}</strong></td>
                        </tr>
                        <tr>
                            <td colspan="3" class="text-end"><strong>Tổng cộng:</strong></td>
                            <td><strong>${formatCurrency(parseFloat(order.total_amount) + parseFloat(order.delivery_fee))}</strong></td>
                        </tr>
                    </tfoot>
                </table>
                
                ${order.notes ? `
                    <hr>
                    <h6>Ghi chú</h6>
                    <p>${order.notes}</p>
                ` : ''}
                
                <hr>
                
                <div class="mb-3">
                    <label class="form-label"><strong>Cập nhật trạng thái</strong></label>
                    <select class="form-select" id="order-status-select">
                        <option value="pending" ${order.status === 'pending' ? 'selected' : ''}>Chờ xử lý</option>
                        <option value="processing" ${order.status === 'processing' ? 'selected' : ''}>Đang xử lý</option>
                        <option value="shipped" ${order.status === 'shipped' ? 'selected' : ''}>Đang giao</option>
                        <option value="delivered" ${order.status === 'delivered' ? 'selected' : ''}>Đã giao</option>
                        <option value="cancelled" ${order.status === 'cancelled' ? 'selected' : ''}>Đã hủy</option>
                    </select>
                </div>
            `;
            
            // Store current order ID for update
            modalBody.dataset.orderId = orderId;
            
            // Show modal
            const modal = new bootstrap.Modal(document.getElementById('orderModal'));
            modal.show();
        }
        
        hideLoading();
    } catch (error) {
        console.error('Error loading order details:', error);
        hideLoading();
    }
}

async function updateOrderStatus() {
    try {
        const modalBody = document.getElementById('order-details');
        const orderId = modalBody.dataset.orderId;
        const newStatus = document.getElementById('order-status-select').value;
        
        showLoading();
        
        const response = await apiCall(`/admin/orders/${orderId}/status`, 'PUT', {
            status: newStatus
        });
        
        if (response.status === 'success') {
            showNotification('Cập nhật trạng thái thành công!', 'success');
            
            // Close modal
            const modal = bootstrap.Modal.getInstance(document.getElementById('orderModal'));
            modal.hide();
            
            // Refresh current view
            refreshCurrentView();
        }
        
        hideLoading();
    } catch (error) {
        console.error('Error updating order status:', error);
        hideLoading();
    }
}

// Tracking functions
async function loadActiveDeliveries() {
    try {
        showLoading();
        
        const response = await apiCall('/admin/deliveries/active');
        
        if (response.status === 'success') {
            displayActiveDeliveries(response.data);
        }
        
        hideLoading();
    } catch (error) {
        console.error('Error loading active deliveries:', error);
        hideLoading();
    }
}

function displayActiveDeliveries(deliveries) {
    const container = document.getElementById('active-deliveries');
    if (!container) return;
    
    container.innerHTML = '';
    
    if (deliveries.length === 0) {
        container.innerHTML = '<p class="text-muted text-center">Không có đơn hàng đang giao</p>';
        return;
    }
    
    deliveries.forEach(delivery => {
        const item = document.createElement('div');
        item.className = 'order-item';
        item.innerHTML = `
            <div class="d-flex justify-content-between align-items-start">
                <div>
                    <h6 class="mb-1">${delivery.order_number}</h6>
                    <small class="text-muted">${delivery.restaurant_name}</small>
                </div>
                <span class="badge status-${delivery.status}">${getStatusText(delivery.status)}</span>
            </div>
            <hr class="my-2">
            <div class="small">
                <i class="fas fa-user me-1"></i> ${delivery.customer_name || 'N/A'}<br>
                <i class="fas fa-phone me-1"></i> ${delivery.customer_phone || 'N/A'}<br>
                <i class="fas fa-map-marker-alt me-1"></i> ${delivery.delivery_address.substring(0, 50)}...
            </div>
            ${delivery.current_latitude && delivery.current_longitude ? `
                <div class="mt-2">
                    <small class="text-success">
                        <i class="fas fa-location-arrow me-1"></i>
                        Vị trí hiện tại: ${delivery.current_latitude.toFixed(6)}, ${delivery.current_longitude.toFixed(6)}
                    </small>
                </div>
            ` : ''}
        `;
        container.appendChild(item);
    });
}

// Users functions
async function loadUsers() {
    try {
        showLoading();
        
        const response = await apiCall('/admin/users?limit=50');
        
        if (response.status === 'success') {
            displayUsers(response.data.users);
        }
        
        hideLoading();
    } catch (error) {
        console.error('Error loading users:', error);
        hideLoading();
    }
}

function displayUsers(users) {
    const tbody = document.getElementById('users-table');
    if (!tbody) return;
    
    tbody.innerHTML = '';
    
    if (users.length === 0) {
        tbody.innerHTML = '<tr><td colspan="7" class="text-center">Chưa có người dùng nào</td></tr>';
        return;
    }
    
    users.forEach(user => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${user.id}</td>
            <td>${user.name}</td>
            <td>${user.email}</td>
            <td>${user.phone || 'N/A'}</td>
            <td>${user.address ? user.address.substring(0, 40) + '...' : 'N/A'}</td>
            <td>${formatDateTime(user.created_at)}</td>
            <td>
                <button class="btn btn-sm btn-primary" onclick="viewUserDetails(${user.id})">
                    <i class="fas fa-eye"></i>
                </button>
            </td>
        `;
        tbody.appendChild(row);
    });
}

function refreshUsers() {
    loadUsers();
}

function viewUserDetails(userId) {
    // TODO: Implement user details view
    showNotification('Xem chi tiết người dùng - Coming soon!', 'info');
}

// Analytics functions
async function loadAnalytics() {
    try {
        showLoading();
        
        const period = document.getElementById('analytics-period')?.value || 7;
        const response = await apiCall(`/admin/analytics?period=${period}`);
        
        if (response.status === 'success') {
            const data = response.data;
            
            // Update revenue chart
            updateRevenueChart(data.revenueByDay || []);
            
            // Update restaurants chart
            updateRestaurantsChart(data.topRestaurants || []);
        }
        
        hideLoading();
    } catch (error) {
        console.error('Error loading analytics:', error);
        hideLoading();
    }
}

// Chart functions
function updateOrdersChart(data) {
    const ctx = document.getElementById('ordersChart');
    if (!ctx) return;
    
    // Destroy existing chart if any
    if (charts.ordersChart) {
        charts.ordersChart.destroy();
    }
    
    const labels = data.map(item => formatDate(item.date));
    const values = data.map(item => item.count);
    
    charts.ordersChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: labels,
            datasets: [{
                label: 'Số đơn hàng',
                data: values,
                borderColor: '#6366f1',
                backgroundColor: 'rgba(99, 102, 241, 0.1)',
                tension: 0.4,
                fill: true
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: true,
            plugins: {
                legend: {
                    display: false
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: {
                        stepSize: 1
                    }
                }
            }
        }
    });
}

function updateStatusChart(statusCounts) {
    const ctx = document.getElementById('statusChart');
    if (!ctx) return;
    
    // Destroy existing chart if any
    if (charts.statusChart) {
        charts.statusChart.destroy();
    }
    
    const labels = ['Chờ xử lý', 'Đang xử lý', 'Đang giao', 'Đã giao', 'Đã hủy'];
    const data = [
        statusCounts.pending || 0,
        statusCounts.processing || 0,
        statusCounts.shipped || 0,
        statusCounts.delivered || 0,
        statusCounts.cancelled || 0
    ];
    
    const colors = ['#f59e0b', '#6366f1', '#8b5cf6', '#10b981', '#ef4444'];
    
    charts.statusChart = new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: labels,
            datasets: [{
                data: data,
                backgroundColor: colors
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: true,
            plugins: {
                legend: {
                    position: 'bottom'
                }
            }
        }
    });
}

function updateRevenueChart(data) {
    const ctx = document.getElementById('revenueChart');
    if (!ctx) return;
    
    // Destroy existing chart if any
    if (charts.revenueChart) {
        charts.revenueChart.destroy();
    }
    
    const labels = data.map(item => formatDate(item.date));
    const values = data.map(item => parseFloat(item.revenue));
    
    charts.revenueChart = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: labels,
            datasets: [{
                label: 'Doanh thu (VNĐ)',
                data: values,
                backgroundColor: '#10b981'
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: true,
            plugins: {
                legend: {
                    display: false
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: {
                        callback: function(value) {
                            return formatCurrency(value);
                        }
                    }
                }
            }
        }
    });
}

function updateRestaurantsChart(data) {
    const ctx = document.getElementById('restaurantsChart');
    if (!ctx) return;
    
    // Destroy existing chart if any
    if (charts.restaurantsChart) {
        charts.restaurantsChart.destroy();
    }
    
    const labels = data.map(item => item.restaurant_name);
    const values = data.map(item => parseInt(item.order_count));
    
    charts.restaurantsChart = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: labels,
            datasets: [{
                label: 'Số đơn hàng',
                data: values,
                backgroundColor: '#6366f1'
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: true,
            indexAxis: 'y',
            plugins: {
                legend: {
                    display: false
                }
            },
            scales: {
                x: {
                    beginAtZero: true,
                    ticks: {
                        stepSize: 1
                    }
                }
            }
        }
    });
}

// Utility functions
function formatCurrency(amount) {
    return new Intl.NumberFormat('vi-VN', {
        style: 'currency',
        currency: 'VND'
    }).format(amount);
}

function formatDateTime(dateString) {
    if (!dateString) return 'N/A';
    const date = new Date(dateString);
    return new Intl.DateTimeFormat('vi-VN', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit'
    }).format(date);
}

function formatDate(dateString) {
    if (!dateString) return 'N/A';
    const date = new Date(dateString);
    return new Intl.DateTimeFormat('vi-VN', {
        month: '2-digit',
        day: '2-digit'
    }).format(date);
}

function getStatusText(status) {
    const statusMap = {
        'pending': 'Chờ xử lý',
        'processing': 'Đang xử lý',
        'shipped': 'Đang giao',
        'delivered': 'Đã giao',
        'cancelled': 'Đã hủy'
    };
    return statusMap[status] || status;
}

function showLoading() {
    const modal = new bootstrap.Modal(document.getElementById('loadingModal'));
    modal.show();
}

function hideLoading() {
    const modalElement = document.getElementById('loadingModal');
    const modal = bootstrap.Modal.getInstance(modalElement);
    if (modal) {
        modal.hide();
    }
}

function showNotification(message, type = 'info') {
    // Create notification element
    const notification = document.createElement('div');
    notification.className = `alert alert-${type === 'error' ? 'danger' : type} alert-dismissible fade show notification`;
    notification.innerHTML = `
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;
    
    document.body.appendChild(notification);
    
    // Auto remove after 5 seconds
    setTimeout(() => {
        notification.remove();
    }, 5000);
}

function refreshCurrentView() {
    // Determine which section is currently visible and refresh it
    const sections = {
        'dashboard-section': loadDashboard,
        'orders-section': loadOrders,
        'tracking-section': loadActiveDeliveries,
        'users-section': loadUsers,
        'analytics-section': loadAnalytics
    };
    
    for (const [sectionId, loadFunction] of Object.entries(sections)) {
        const section = document.getElementById(sectionId);
        if (section && section.style.display !== 'none') {
            loadFunction();
            break;
        }
    }
}

function logout() {
    // Clear all stored data
    localStorage.removeItem('token');
    sessionStorage.removeItem('token');
    localStorage.removeItem('user');
    sessionStorage.removeItem('user');
    localStorage.removeItem('demoMode');
    authToken = '';
    
    // Disconnect socket
    if (socket) {
        socket.disconnect();
    }
    
    // Redirect to login page
    window.location.href = 'login.html';
}

// Mock data for demo mode
function getMockData(endpoint, method, data) {
    console.log('Demo mode: returning mock data for', endpoint);
    
    // Simulate API delay
    return new Promise((resolve) => {
        setTimeout(() => {
            if (endpoint === '/admin/stats') {
                resolve({
                    status: 'success',
                    data: {
                        totalOrders: 150,
                        deliveredOrders: 120,
                        processingOrders: 25,
                        totalRevenue: 45000000,
                        statusCounts: {
                            pending: 10,
                            processing: 15,
                            shipped: 5,
                            delivered: 120,
                            cancelled: 5
                        },
                        ordersChart: generateMockChartData(7)
                    }
                });
            } else if (endpoint.includes('/admin/orders')) {
                resolve({
                    status: 'success',
                    data: {
                        orders: generateMockOrders(),
                        pagination: {
                            total: 150,
                            limit: 50,
                            offset: 0
                        }
                    }
                });
            } else if (endpoint.includes('/admin/deliveries/active')) {
                resolve({
                    status: 'success',
                    data: generateMockActiveDeliveries()
                });
            } else if (endpoint.includes('/admin/users')) {
                resolve({
                    status: 'success',
                    data: {
                        users: generateMockUsers(),
                        pagination: {
                            total: 50,
                            limit: 50,
                            offset: 0
                        }
                    }
                });
            } else if (endpoint.includes('/admin/analytics')) {
                resolve({
                    status: 'success',
                    data: {
                        revenueByDay: generateMockRevenueData(7),
                        topRestaurants: generateMockRestaurants(),
                        statusDistribution: [
                            { status: 'pending', count: 10 },
                            { status: 'processing', count: 15 },
                            { status: 'delivered', count: 120 }
                        ],
                        avgDeliveryTime: 35.5
                    }
                });
            } else if (method === 'PUT' && endpoint.includes('/status')) {
                resolve({
                    status: 'success',
                    message: 'Cập nhật trạng thái thành công',
                    data: { id: 1, status: data.status }
                });
            } else {
                resolve({ status: 'success', data: {} });
            }
        }, 500);
    });
}

function generateMockChartData(days) {
    const data = [];
    const today = new Date();
    for (let i = days - 1; i >= 0; i--) {
        const date = new Date(today);
        date.setDate(date.getDate() - i);
        data.push({
            date: date.toISOString().split('T')[0],
            count: Math.floor(Math.random() * 20) + 5
        });
    }
    return data;
}

function generateMockOrders() {
    const orders = [];
    const statuses = ['pending', 'processing', 'shipped', 'delivered', 'cancelled'];
    const restaurants = ['KFC', 'Lotteria', 'Pizza Hut', 'Highland Coffee', 'Starbucks'];
    
    for (let i = 0; i < 10; i++) {
        orders.push({
            id: i + 1,
            order_number: `ORD-${Date.now()}-${i}`,
            restaurant_name: restaurants[Math.floor(Math.random() * restaurants.length)],
            customer_name: `Khách hàng ${i + 1}`,
            customer_email: `customer${i + 1}@example.com`,
            customer_phone: `098765${String(i).padStart(4, '0')}`,
            items: JSON.stringify([
                { name: 'Món ăn 1', quantity: 2, price: 50000 },
                { name: 'Món ăn 2', quantity: 1, price: 30000 }
            ]),
            total_amount: 130000,
            delivery_fee: 20000,
            delivery_address: `123 Đường ABC, Quận ${i + 1}, TP.HCM`,
            status: statuses[Math.floor(Math.random() * statuses.length)],
            created_at: new Date(Date.now() - Math.random() * 7 * 24 * 60 * 60 * 1000).toISOString(),
            updated_at: new Date().toISOString()
        });
    }
    return orders;
}

function generateMockActiveDeliveries() {
    const deliveries = [];
    const restaurants = ['KFC', 'Lotteria', 'Pizza Hut'];
    
    for (let i = 0; i < 3; i++) {
        deliveries.push({
            id: i + 1,
            order_number: `ORD-ACTIVE-${i}`,
            restaurant_name: restaurants[i],
            customer_name: `Khách hàng ${i + 1}`,
            customer_phone: `098765${String(i).padStart(4, '0')}`,
            delivery_address: `123 Đường XYZ, Quận ${i + 1}, TP.HCM`,
            status: i % 2 === 0 ? 'processing' : 'shipped',
            current_latitude: 10.762622 + (Math.random() - 0.5) * 0.1,
            current_longitude: 106.660172 + (Math.random() - 0.5) * 0.1,
            last_location_update: new Date().toISOString()
        });
    }
    return deliveries;
}

function generateMockUsers() {
    const users = [];
    for (let i = 0; i < 10; i++) {
        users.push({
            id: i + 1,
            name: `Người dùng ${i + 1}`,
            email: `user${i + 1}@example.com`,
            phone: `098765${String(i).padStart(4, '0')}`,
            address: `${i + 1} Đường ABC, Quận ${i % 10 + 1}, TP.HCM`,
            created_at: new Date(Date.now() - Math.random() * 90 * 24 * 60 * 60 * 1000).toISOString(),
            updated_at: new Date().toISOString()
        });
    }
    return users;
}

function generateMockRevenueData(days) {
    const data = [];
    const today = new Date();
    for (let i = days - 1; i >= 0; i--) {
        const date = new Date(today);
        date.setDate(date.getDate() - i);
        data.push({
            date: date.toISOString().split('T')[0],
            revenue: Math.floor(Math.random() * 5000000) + 1000000,
            order_count: Math.floor(Math.random() * 20) + 5
        });
    }
    return data;
}

function generateMockRestaurants() {
    return [
        { restaurant_name: 'KFC', order_count: 45, total_revenue: 12000000 },
        { restaurant_name: 'Lotteria', order_count: 38, total_revenue: 9500000 },
        { restaurant_name: 'Pizza Hut', order_count: 32, total_revenue: 11000000 },
        { restaurant_name: 'Highland Coffee', order_count: 28, total_revenue: 7000000 },
        { restaurant_name: 'Starbucks', order_count: 25, total_revenue: 8500000 }
    ];
}

// Auto-refresh every 30 seconds for real-time data
setInterval(() => {
    if (!isDemoMode) {
        refreshCurrentView();
    }
}, 30000);
