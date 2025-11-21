// Configuration
const API_BASE_URL = 'http://localhost:3000/api';
const AUTO_REFRESH_INTERVAL = 45000;
const LOADING_SPINNER_DELAY = 150;
let authToken = localStorage.getItem('token') || sessionStorage.getItem('token') || '';
let isDemoMode = localStorage.getItem('demoMode') === 'true';
let socket = null;
let charts = {};
let loadingModalInstance = null;
let loadingTimeout = null;
let activeLoadingRequests = 0;
let refreshInProgress = false;
let suppressNotifications = false;

function getLoadingModalInstance() {
    if (typeof bootstrap === 'undefined') {
        console.error('Bootstrap is not loaded');
        return null;
    }

    const modalElement = document.getElementById('loadingModal');
    if (!modalElement) {
        console.warn('Loading modal element not found');
        return null;
    }

    if (!loadingModalInstance) {
        loadingModalInstance = bootstrap.Modal.getOrCreateInstance(modalElement, {
            backdrop: 'static',
            keyboard: false
        });
    }

    return loadingModalInstance;
}

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
    // Close existing socket if any
    if (socket && socket.connected) {
        socket.disconnect();
        socket = null;
    }

    socket = io('http://localhost:3000', {
        // Use polling only for better stability (websocket seems unstable after upgrade)
        transports: ['polling'],
        // Reconnection settings with exponential backoff
        reconnection: true,
        reconnectionDelay: 1000, // Start with 1 second
        reconnectionDelayMax: 10000, // Maximum 10 seconds between attempts
        reconnectionAttempts: Infinity, // Try to reconnect forever
        timeout: 60000, // Longer connection timeout (60 seconds)
        // Keep alive settings
        forceNew: false, // Reuse connection if possible
        autoConnect: true,
        // Disable upgrade to websocket (keep polling stable)
        upgrade: false, // Don't auto-upgrade to websocket
        // Compression (disable to reduce overhead)
        perMessageDeflate: false,
        // Additional stability settings
        rememberUpgrade: false, // Don't remember upgrade preference
        // Multiple connection handling
        multiplex: false // Don't multiplex connections
    });

    socket.on('connect', () => {
        const transport = socket.io.engine.transport.name;
        console.log(`[Socket.IO] Connected to server (transport: ${transport})`);
        
        // Clear any error notifications on successful connection
        if (socket.reconnecting) {
            console.log('[Socket.IO] Successfully reconnected to server');
        }

    // Monitor transport upgrades with error handling
    socket.io.engine.on('upgrade', () => {
        const newTransport = socket.io.engine.transport.name;
        console.log(`[Socket.IO] Transport upgraded to: ${newTransport}`);
    });

    // Handle transport errors - will automatically fallback to polling
    socket.io.engine.on('error', (error) => {
        console.error(`[Socket.IO] Engine error:`, error.message || error);
        // Connection will automatically try to reconnect with fallback transport
    });

    // Handle upgrade errors - will stay on polling
    socket.io.engine.on('upgradeError', (error) => {
        console.warn(`[Socket.IO] Upgrade error, staying on polling:`, error.message || error);
    });
    });

    // Handle ping/pong for keep-alive - respond immediately
    socket.on('ping', (data) => {
        try {
            socket.emit('pong', { timestamp: Date.now() });
        } catch (error) {
            console.error('[Socket.IO] Error sending pong:', error);
        }
    });

    socket.on('connect_error', (error) => {
        console.error('[Socket.IO] Connection error:', error.message || error);
        // Don't show error notification on every connection attempt
        // The reconnection will happen automatically with exponential backoff
    });

    socket.on('reconnect_attempt', (attemptNumber) => {
        const delay = Math.min(1000 * Math.pow(2, attemptNumber - 1), 10000);
        console.log(`[Socket.IO] Attempting to reconnect (attempt ${attemptNumber}, delay: ${delay}ms)...`);
    });

    socket.on('reconnect', (attemptNumber) => {
        console.log(`[Socket.IO] Successfully reconnected after ${attemptNumber} attempts`);
    });

    socket.on('reconnect_error', (error) => {
        console.error('[Socket.IO] Reconnection error:', error.message || error);
    });

    socket.on('reconnect_failed', () => {
        console.error('[Socket.IO] Failed to reconnect to server after all attempts');
        // Show error notification only after all reconnection attempts failed
        showNotification('Mất kết nối với máy chủ. Vui lòng tải lại trang.', 'error');
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

    socket.on('disconnect', (reason) => {
        const transport = socket.io?.engine?.transport?.name || 'unknown';
        console.log(`[Socket.IO] Disconnected from server, reason: ${reason}, transport: ${transport}`);
        
        // Handle different disconnect reasons
        if (reason === 'io server disconnect') {
            // Server forcefully disconnected (e.g., kicked out)
            console.log('[Socket.IO] Server disconnected client - reconnecting manually...');
            socket.connect();
        } else if (reason === 'transport close') {
            // Transport closed (network issue, timeout, idle, etc.)
            console.log('[Socket.IO] Transport closed - will attempt to reconnect automatically with fallback transport');
            // Automatic reconnection will handle this - will try polling if websocket failed
        } else if (reason === 'ping timeout') {
            // Client didn't respond to ping in time
            console.log('[Socket.IO] Ping timeout - will attempt to reconnect automatically');
        } else if (reason === 'transport error') {
            // Transport error occurred - will fallback to polling
            console.log('[Socket.IO] Transport error - will attempt to reconnect with fallback transport (polling)');
        } else {
            console.log(`[Socket.IO] Disconnected: ${reason} - will attempt to reconnect automatically`);
        }
        // All reasons except 'io server disconnect' will trigger automatic reconnection
    });

    socket.on('error', (error) => {
        console.error('Socket.IO error:', error);
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

    if (!authToken) {
        authToken = localStorage.getItem('token') || sessionStorage.getItem('token') || '';
    }
    if (authToken) {
        options.headers['Authorization'] = `Bearer ${authToken}`;
    }

    if (data && (method === 'POST' || method === 'PUT' || method === 'PATCH')) {
        options.body = JSON.stringify(data);
    }

    try {
        const response = await fetch(`${API_BASE_URL}${endpoint}`, options);

        // Check status code before parsing
        const contentType = response.headers.get('content-type');
        const isJson = contentType && contentType.includes('application/json');
        
        let result = {};
        
        if (response.status === 429) {
            // Rate limit error - try to parse JSON, fallback to text
            const rawText = await response.text();
            try {
                result = JSON.parse(rawText);
            } catch {
                // Not JSON, use default message
                result = {
                    status: 'error',
                    message: 'Too many requests. Please wait a moment and try again.',
                    retryAfter: 60 // Default retry after 60 seconds
                };
            }
            
            const retryAfter = result.retryAfter || 60;
            throw new Error(`${result.message || 'Quá nhiều yêu cầu. Vui lòng đợi '}${retryAfter} giây rồi thử lại.`);
        }

        const rawText = await response.text();
        if (rawText) {
            try {
                result = JSON.parse(rawText);
            } catch (parseError) {
                console.error('Không thể parse JSON từ API:', parseError);
                console.error('Response text:', rawText.substring(0, 200));
                // If not JSON and status is error, use response text as message
                if (!response.ok) {
                    throw new Error(rawText.length < 200 ? rawText : `Lỗi từ server: ${response.status} ${response.statusText}`);
                }
                throw new Error('Dữ liệu trả về không hợp lệ');
            }
        }

        if (!response.ok) {
            if (response.status === 401) {
                console.error('Unauthorized access. Redirecting to login...');
                localStorage.removeItem('token');
                sessionStorage.removeItem('token');
                localStorage.removeItem('user');
                sessionStorage.removeItem('user');
                window.location.href = 'login.html';
                throw new Error('Session expired. Please login again.');
            }
            throw new Error(result.message || `API request failed: ${response.status} ${response.statusText}`);
        }

        return result;
    } catch (error) {
        console.error('API Error:', error);
        
        // Don't show error notification for auth redirect
        if (!suppressNotifications && !error.message.includes('Session expired')) {
            // For rate limit errors, show warning instead of error
            const isRateLimit = error.message.includes('Quá nhiều yêu cầu') || error.message.includes('Too many');
            showNotification(error.message || 'Lỗi kết nối API', isRateLimit ? 'warning' : 'error');
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

function showShippers() {
    hideAllSections();
    const section = document.getElementById('shippers-section');
    if (section) {
        section.style.display = 'block';
    }
    setActiveMenu(3);
    loadShippers();
}

function showUsers() {
    hideAllSections();
    document.getElementById('users-section').style.display = 'block';
    setActiveMenu(4);
    loadUsers();
}

function showAnalytics() {
    hideAllSections();
    document.getElementById('analytics-section').style.display = 'block';
    setActiveMenu(5);
    loadAnalytics();
}

function hideAllSections() {
    const sections = ['dashboard-section', 'orders-section', 'tracking-section', 'shippers-section', 'users-section', 'analytics-section', 'areas-section', 'cod-section'];
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

function showAreas() {
    hideAllSections();
    document.getElementById('areas-section').style.display = 'block';
    setActiveMenu(6);
    loadAreas();
}

// US-19 & US-12: Show COD Reconciliation
function showCodReconciliation() {
    hideAllSections();
    document.getElementById('cod-section').style.display = 'block';
    setActiveMenu(7);
    // Ensure loading is reset before loading COD orders
    if (activeLoadingRequests > 0) {
        activeLoadingRequests = 0;
    }
    if (loadingTimeout) {
        clearTimeout(loadingTimeout);
        loadingTimeout = null;
    }
    const modal = getLoadingModalInstance();
    if (modal) {
        try {
            modal.hide();
        } catch (e) {
            // Ignore
        }
    }
    loadCodOrders();
}

// Dashboard functions
async function loadDashboard(options = {}) {
    const { silent = false } = options;
    try {
        if (!silent) {
            showLoading();
        }

        const [statsResult, ordersResult] = await Promise.allSettled([
            apiCall('/admin/stats'),
            apiCall('/admin/orders?limit=5')
        ]);

        if (statsResult.status === 'fulfilled') {
            const statsResponse = statsResult.value;
            if (statsResponse.status === 'success') {
                const stats = statsResponse.data;

                const totalOrdersEl = document.getElementById('total-orders');
                const deliveredOrdersEl = document.getElementById('delivered-orders');
                const processingOrdersEl = document.getElementById('processing-orders');
                const totalRevenueEl = document.getElementById('total-revenue');

                if (totalOrdersEl) totalOrdersEl.textContent = stats.totalOrders || 0;
                if (deliveredOrdersEl) deliveredOrdersEl.textContent = stats.deliveredOrders || 0;
                if (processingOrdersEl) processingOrdersEl.textContent = stats.processingOrders || 0;
                if (totalRevenueEl) totalRevenueEl.textContent = formatCurrency(stats.totalRevenue || 0);

                updateOrdersChart(stats.ordersChart || []);
                updateStatusChart(stats.statusCounts || {});
            } else if (!silent) {
                showNotification(statsResponse.message || 'Không thể tải thống kê.', 'error');
            }
        } else {
            console.error('Error loading dashboard stats:', statsResult.reason);
            if (!silent) {
                showNotification('Không thể tải thống kê.', 'error');
            }
        }

        if (ordersResult.status === 'fulfilled') {
            const ordersResponse = ordersResult.value;
            if (ordersResponse.status === 'success') {
                displayRecentOrders(ordersResponse.data?.orders || []);
            } else if (!silent) {
                showNotification(ordersResponse.message || 'Không thể tải đơn hàng gần đây.', 'error');
            }
        } else {
            console.error('Error loading recent orders:', ordersResult.reason);
            if (!silent) {
                showNotification('Không thể tải đơn hàng gần đây.', 'error');
            }
        }
    } catch (error) {
        console.error('Error loading dashboard:', error);
        if (!silent) {
            showNotification(error.message || 'Không thể tải Dashboard', 'error');
        }
    } finally {
        if (!silent) {
            hideLoading();
        }
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
let selectedOrderIds = new Set();
let currentPage = 1;
let totalPages = 1;

async function loadOrders(options = {}) {
    const { silent = false, page = 1 } = options;
    try {
        if (!silent) {
            showLoading();
        }

        const statusFilter = document.getElementById('status-filter')?.value || '';
        const searchFilter = document.getElementById('search-filter')?.value || '';
        const startDate = document.getElementById('start-date-filter')?.value || '';
        const endDate = document.getElementById('end-date-filter')?.value || '';
        
        let endpoint = '/admin/orders?limit=50&offset=' + ((page - 1) * 50);
        
        if (statusFilter) {
            endpoint += `&status=${statusFilter}`;
        }
        if (searchFilter) {
            endpoint += `&search=${encodeURIComponent(searchFilter)}`;
        }
        if (startDate) {
            endpoint += `&startDate=${startDate}`;
        }
        if (endDate) {
            endpoint += `&endDate=${endDate}`;
        }
        
        const response = await apiCall(endpoint);
        
        if (response.status === 'success') {
            displayOrders(response.data?.orders || []);
            const pagination = response.data?.pagination || {};
            totalPages = pagination.pages || 1;
            currentPage = page;
            displayPagination(pagination);
        } else if (!silent) {
            showNotification(response.message || 'Không thể tải danh sách đơn hàng', 'error');
        }
    } catch (error) {
        console.error('Error loading orders:', error);
        if (!silent) {
            showNotification(error.message || 'Không thể tải danh sách đơn hàng', 'error');
        }
    } finally {
        if (!silent) {
            hideLoading();
        }
    }
}

function displayOrders(orders) {
    const tbody = document.getElementById('orders-table');
    if (!tbody) return;
    
    tbody.innerHTML = '';
    
    if (orders.length === 0) {
        tbody.innerHTML = '<tr><td colspan="10" class="text-center">Không có đơn hàng nào</td></tr>';
        return;
    }
    
    orders.forEach(order => {
        let items = [];
        if (Array.isArray(order.items)) {
            items = order.items;
        } else if (typeof order.items === 'string') {
            try {
                items = JSON.parse(order.items || '[]');
            } catch (err) {
                console.warn('Không thể parse items:', err);
                items = [];
            }
        } else if (order.items && typeof order.items === 'object') {
            items = Object.values(order.items);
        }
        const itemsText = items.map(item => `${item.name} x${item.quantity}`).join(', ');
        const isSelected = selectedOrderIds.has(order.id);
        
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>
                <input type="checkbox" class="order-checkbox" value="${order.id}" ${isSelected ? 'checked' : ''} onchange="toggleOrderSelection(${order.id})">
            </td>
            <td>${order.order_number}</td>
            <td>${order.restaurant_name || 'N/A'}</td>
            <td>
                <div>${order.customer_name || 'N/A'}</div>
                <small class="text-muted">${order.customer_email || ''}</small>
            </td>
            <td>
                <small>${itemsText.substring(0, 50)}${itemsText.length > 50 ? '...' : ''}</small>
            </td>
            <td>${formatCurrency(parseFloat(order.total_amount || 0) + parseFloat(order.delivery_fee || 0))}</td>
            <td><span class="badge status-${order.status}">${getStatusText(order.status)}</span></td>
            <td>${order.shipper?.full_name || '<span class="text-muted">Chưa gán</span>'}</td>
            <td>${formatDateTime(order.created_at)}</td>
            <td>
                <div class="btn-group btn-group-sm">
                    <button class="btn btn-primary" onclick="showOrderDetails(${order.id})" title="Xem chi tiết">
                        <i class="fas fa-eye"></i>
                    </button>
                    <button class="btn btn-warning" onclick="showEditOrderModal(${order.id})" title="Chỉnh sửa">
                        <i class="fas fa-edit"></i>
                    </button>
                </div>
            </td>
        `;
        tbody.appendChild(row);
    });
}

function displayPagination(pagination) {
    const paginationEl = document.getElementById('orders-pagination');
    if (!paginationEl) return;
    
    if (totalPages <= 1) {
        paginationEl.innerHTML = `<small class="text-muted">Tổng: ${pagination.total || 0} đơn hàng</small>`;
        return;
    }
    
    let html = `<small class="text-muted">Tổng: ${pagination.total || 0} đơn hàng</small>`;
    html += '<nav><ul class="pagination pagination-sm mb-0">';
    
    // Previous button
    html += `<li class="page-item ${currentPage === 1 ? 'disabled' : ''}">
        <a class="page-link" href="#" onclick="loadOrders({page: ${currentPage - 1}}); return false;">Trước</a>
    </li>`;
    
    // Page numbers
    for (let i = 1; i <= totalPages; i++) {
        if (i === 1 || i === totalPages || (i >= currentPage - 2 && i <= currentPage + 2)) {
            html += `<li class="page-item ${i === currentPage ? 'active' : ''}">
                <a class="page-link" href="#" onclick="loadOrders({page: ${i}}); return false;">${i}</a>
            </li>`;
        } else if (i === currentPage - 3 || i === currentPage + 3) {
            html += '<li class="page-item disabled"><span class="page-link">...</span></li>';
        }
    }
    
    // Next button
    html += `<li class="page-item ${currentPage === totalPages ? 'disabled' : ''}">
        <a class="page-link" href="#" onclick="loadOrders({page: ${currentPage + 1}}); return false;">Sau</a>
    </li>`;
    
    html += '</ul></nav>';
    paginationEl.innerHTML = html;
}

function toggleOrderSelection(orderId) {
    if (selectedOrderIds.has(orderId)) {
        selectedOrderIds.delete(orderId);
    } else {
        selectedOrderIds.add(orderId);
    }
    updateSelectAllCheckbox();
}

function toggleSelectAllOrders() {
    const checkbox = document.getElementById('select-all-orders');
    const checkboxes = document.querySelectorAll('.order-checkbox');
    
    checkboxes.forEach(cb => {
        const orderId = parseInt(cb.value);
        if (checkbox.checked) {
            selectedOrderIds.add(orderId);
            cb.checked = true;
        } else {
            selectedOrderIds.delete(orderId);
            cb.checked = false;
        }
    });
}

function updateSelectAllCheckbox() {
    const checkbox = document.getElementById('select-all-orders');
    const checkboxes = document.querySelectorAll('.order-checkbox');
    if (checkbox && checkboxes.length > 0) {
        checkbox.checked = checkboxes.length === selectedOrderIds.size && checkboxes.length > 0;
    }
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
            let items = [];
            if (Array.isArray(order.items)) {
                items = order.items;
            } else if (typeof order.items === 'string') {
                try {
                    items = JSON.parse(order.items || '[]');
                } catch (err) {
                    console.warn('Không thể parse items:', err);
                    items = [];
                }
            } else if (order.items && typeof order.items === 'object') {
                items = Object.values(order.items);
            }
            
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
        } else {
            showNotification(response.message || 'Không thể tải chi tiết đơn hàng', 'error');
        }
    } catch (error) {
        console.error('Error loading order details:', error);
        showNotification(error.message || 'Không thể tải chi tiết đơn hàng', 'error');
    } finally {
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
async function loadActiveDeliveries(options = {}) {
    const { silent = false } = options;
    try {
        if (!silent) {
            showLoading();
        }

        const response = await apiCall('/admin/deliveries/active');
        
        if (response.status === 'success') {
            displayActiveDeliveries(response.data);
        }
        
    } catch (error) {
        console.error('Error loading active deliveries:', error);
    } finally {
        if (!silent) {
            hideLoading();
        }
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
            ${delivery.latitude && delivery.longitude ? `
                <div class="mt-2">
                    <small class="text-success">
                        <i class="fas fa-location-arrow me-1"></i>
                        Vị trí hiện tại: ${delivery.latitude.toFixed(6)}, ${delivery.longitude.toFixed(6)}
                    </small>
                </div>
            ` : ''}
        `;
        container.appendChild(item);
    });
}

// Shippers functions
async function loadShippers(options = {}) {
    const { silent = false } = options;
    try {
        if (!silent) {
            showLoading();
        }
        const statusFilter = document.getElementById('shipper-status-filter');
        const status = statusFilter ? statusFilter.value : '';
        let endpoint = '/admin/shippers';
        if (status) {
            endpoint += `?status=${status}`;
        }
        const response = await apiCall(endpoint);
        if (response.status === 'success') {
            displayShippers(response.data || []);
        }
    } catch (error) {
        console.error('Error loading shippers:', error);
    } finally {
        if (!silent) {
            hideLoading();
        }
    }
}

function displayShippers(shippers) {
    const tbody = document.getElementById('shippers-table');
    if (!tbody) return;

    tbody.innerHTML = '';

    if (!shippers || shippers.length === 0) {
        tbody.innerHTML = '<tr><td colspan="8" class="text-center">Chưa có hồ sơ shipper</td></tr>';
        return;
    }

    shippers.forEach(shipper => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${shipper.full_name || 'N/A'}</td>
            <td>${shipper.email || 'N/A'}</td>
            <td>${shipper.phone || 'N/A'}</td>
            <td>${shipper.vehicle_type || 'N/A'}</td>
            <td>${shipper.vehicle_plate || 'N/A'}</td>
            <td>${renderShipperStatusBadge(shipper.status)}</td>
            <td>${formatDateTime(shipper.created_at)}</td>
            <td>
                <button class="btn btn-sm btn-primary" onclick="showShipperDetails(${shipper.id})">
                    <i class="fas fa-eye"></i>
                </button>
            </td>
        `;
        tbody.appendChild(row);
    });
}

function refreshShippers() {
    loadShippers();
}

async function showShipperDetails(shipperId) {
    try {
        showLoading();
        const response = await apiCall(`/admin/shippers/${shipperId}`);
        if (response.status === 'success') {
            const shipper = response.data;
            const modalBody = document.getElementById('shipper-details');
            modalBody.dataset.shipperId = shipper.id;
            modalBody.innerHTML = `
                <div class="row">
                    <div class="col-md-6">
                        <h6>Thông tin tài khoản</h6>
                        <p><strong>Họ tên:</strong> ${shipper.full_name || 'N/A'}</p>
                        <p><strong>Email:</strong> ${shipper.email || 'N/A'}</p>
                        <p><strong>Số điện thoại:</strong> ${shipper.phone || 'N/A'}</p>
                        <p><strong>Địa chỉ:</strong> ${shipper.address || 'N/A'}</p>
                        <p><strong>Trạng thái:</strong> ${renderShipperStatusBadge(shipper.status)}</p>
                        <p><strong>Ngày đăng ký:</strong> ${formatDateTime(shipper.created_at)}</p>
                    </div>
                    <div class="col-md-6">
                        <h6>Thông tin xe & giấy tờ</h6>
                        <p><strong>Loại xe:</strong> ${shipper.vehicle_type || 'N/A'}</p>
                        <p><strong>Biển số:</strong> ${shipper.vehicle_plate || 'N/A'}</p>
                        <p><strong>Bằng lái:</strong> ${shipper.driver_license_number || 'N/A'}</p>
                        <p><strong>CCCD/CMND:</strong> ${shipper.identity_card_number || 'N/A'}</p>
                        <p><strong>Ngày duyệt:</strong> ${shipper.approved_at ? formatDateTime(shipper.approved_at) : 'Chưa duyệt'}</p>
                    </div>
                </div>
                <hr>
                <div class="mb-3">
                    <label class="form-label">Ghi chú nội bộ</label>
                    <textarea class="form-control" id="shipper-notes-input" rows="3" placeholder="Nhập ghi chú cho shipper">${shipper.notes || ''}</textarea>
                </div>
            `;

            const modal = new bootstrap.Modal(document.getElementById('shipperModal'));
            modal.show();
        }
        hideLoading();
    } catch (error) {
        console.error('Error loading shipper details:', error);
        hideLoading();
    }
}

async function updateShipperStatusFromModal(status) {
    const modalBody = document.getElementById('shipper-details');
    const shipperId = modalBody.dataset.shipperId;
    if (!shipperId) {
        showNotification('Không xác định được shipper', 'error');
        return;
    }

    if (status === 'rejected' && !confirm('Bạn có chắc chắn muốn từ chối hồ sơ shipper này?')) {
        return;
    }

    try {
        showLoading();
        const notes = document.getElementById('shipper-notes-input')?.value || '';
        const response = await apiCall(`/admin/shippers/${shipperId}/status`, 'PATCH', {
            status,
            notes
        });

        if (response.status === 'success') {
            showNotification('Cập nhật trạng thái shipper thành công', 'success');
            const modal = bootstrap.Modal.getInstance(document.getElementById('shipperModal'));
            if (modal) {
                modal.hide();
            }
            loadShippers();
        }
        hideLoading();
    } catch (error) {
        console.error('Error updating shipper status:', error);
        hideLoading();
    }
}

// Users functions
async function loadUsers(options = {}) {
    const { silent = false } = options;
    try {
        if (!silent) {
            showLoading();
        }

        const response = await apiCall('/admin/users?limit=50');
        
        if (response.status === 'success') {
            displayUsers(response.data.users);
        }
        
    } catch (error) {
        console.error('Error loading users:', error);
    } finally {
        if (!silent) {
            hideLoading();
        }
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
async function loadAnalytics(options = {}) {
    const { silent = false } = options;
    try {
        if (!silent) {
            showLoading();
        }

        const period = document.getElementById('analytics-period')?.value || 7;
        const response = await apiCall(`/admin/analytics?period=${period}`);
        
        if (response.status === 'success') {
            const data = response.data;
            
            // Update revenue chart
            updateRevenueChart(data.revenueByDay || []);
            
            // Update restaurants chart
            updateRestaurantsChart(data.topRestaurants || []);
        }
        
    } catch (error) {
        console.error('Error loading analytics:', error);
    } finally {
        if (!silent) {
            hideLoading();
        }
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

function getShipperStatusText(status) {
    const statusMap = {
        pending: 'Chờ duyệt',
        approved: 'Đã duyệt',
        rejected: 'Từ chối',
        suspended: 'Tạm khóa'
    };
    return statusMap[status] || status;
}

function renderShipperStatusBadge(status) {
    const classes = {
        pending: 'bg-warning text-dark',
        approved: 'bg-success',
        rejected: 'bg-danger',
        suspended: 'bg-secondary'
    };
    const badgeClass = classes[status] || 'bg-light text-dark';
    return `<span class="badge ${badgeClass}">${getShipperStatusText(status)}</span>`;
}

function showLoading() {
    activeLoadingRequests += 1;
    if (loadingTimeout) {
        return;
    }

    loadingTimeout = setTimeout(() => {
        loadingTimeout = null;
        const modal = getLoadingModalInstance();
        if (modal && activeLoadingRequests > 0) {
            modal.show();
        }
    }, LOADING_SPINNER_DELAY);
}

function hideLoading() {
    if (activeLoadingRequests > 0) {
        activeLoadingRequests -= 1;
    }

    if (loadingTimeout) {
        clearTimeout(loadingTimeout);
        loadingTimeout = null;
    }

    // Only hide modal if no active requests
    if (activeLoadingRequests > 0) {
        return;
    }

    const modal = getLoadingModalInstance();
    if (!modal) {
        return;
    }

    try {
        modal.hide();
    } catch (e) {
        console.warn('Error hiding loading modal:', e);
    }

    // Clean up backdrop
    setTimeout(() => {
        const backdrop = document.querySelector('.modal-backdrop');
        if (backdrop && !document.body.classList.contains('modal-open')) {
            backdrop.remove();
        }
        // Remove modal-open class if still present
        if (document.body.classList.contains('modal-open')) {
            document.body.classList.remove('modal-open');
        }
    }, 150);
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

async function refreshCurrentView() {
    if (refreshInProgress) {
        return;
    }
    refreshInProgress = true;
    // Determine which section is currently visible and refresh it
    const sections = {
        'dashboard-section': loadDashboard,
        'orders-section': loadOrders,
        'tracking-section': loadActiveDeliveries,
        'shippers-section': loadShippers,
        'users-section': loadUsers,
        'analytics-section': loadAnalytics,
        'areas-section': loadAreas
    };
    
    try {
        for (const [sectionId, loadFunction] of Object.entries(sections)) {
            const section = document.getElementById(sectionId);
            if (section && section.style.display !== 'none') {
                suppressNotifications = true;
                try {
                    await loadFunction({ silent: true });
                } finally {
                    suppressNotifications = false;
                }
                break;
            }
        }
    } catch (error) {
        console.error('Error refreshing current view:', error);
    } finally {
        refreshInProgress = false;
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
            latitude: 10.762622 + (Math.random() - 0.5) * 0.1,
            longitude: 106.660172 + (Math.random() - 0.5) * 0.1,
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

// Dispatch functions
async function showDispatchModal() {
    if (selectedOrderIds.size === 0) {
        showNotification('Vui lòng chọn ít nhất một đơn hàng để điều phối', 'warning');
        return;
    }
    
    try {
        showLoading();
        const response = await apiCall('/admin/shippers/available');
        
        if (response.status === 'success') {
            const select = document.getElementById('dispatch-shipper-select');
            select.innerHTML = '<option value="">-- Chọn shipper --</option>';
            
            response.data.forEach(shipper => {
                const option = document.createElement('option');
                option.value = shipper.id;
                option.textContent = `${shipper.full_name} (${shipper.vehicle_type || 'N/A'}) - ${shipper.active_orders_count || 0} đơn đang giao`;
                select.appendChild(option);
            });
            
            updateSelectedOrdersList();
            const modal = new bootstrap.Modal(document.getElementById('dispatchModal'));
            modal.show();
        }
    } catch (error) {
        showNotification('Không thể tải danh sách shipper', 'error');
    } finally {
        hideLoading();
    }
}

function updateSelectedOrdersList() {
    const countEl = document.getElementById('selected-orders-count');
    const listEl = document.getElementById('selected-orders-list');
    
    if (countEl) countEl.textContent = selectedOrderIds.size;
    
    if (listEl) {
        if (selectedOrderIds.size === 0) {
            listEl.innerHTML = '<small class="text-muted">Chưa có đơn hàng nào được chọn</small>';
        } else {
            // You can enhance this to show order numbers
            listEl.innerHTML = `<small>Đã chọn ${selectedOrderIds.size} đơn hàng</small>`;
        }
    }
}

async function assignSelectedOrders() {
    const shipperId = document.getElementById('dispatch-shipper-select').value;
    
    if (!shipperId) {
        showNotification('Vui lòng chọn shipper', 'warning');
        return;
    }
    
    if (selectedOrderIds.size === 0) {
        showNotification('Vui lòng chọn ít nhất một đơn hàng', 'warning');
        return;
    }
    
    try {
        showLoading();
        const response = await apiCall('/admin/orders/assign', 'POST', {
            order_ids: Array.from(selectedOrderIds),
            shipper_id: parseInt(shipperId)
        });
        
        if (response.status === 'success') {
            showNotification(response.message || 'Gán đơn hàng thành công!', 'success');
            selectedOrderIds.clear();
            const modal = bootstrap.Modal.getInstance(document.getElementById('dispatchModal'));
            modal.hide();
            loadOrders();
        }
    } catch (error) {
        showNotification(error.message || 'Không thể gán đơn hàng', 'error');
    } finally {
        hideLoading();
    }
}

// Edit order functions
async function showEditOrderModal(orderId) {
    try {
        showLoading();
        const response = await apiCall(`/admin/orders/${orderId}`);
        
        if (response.status === 'success') {
            const order = response.data.order;
            const formEl = document.getElementById('edit-order-form');
            
            formEl.innerHTML = `
                <form id="edit-order-form-content">
                    <input type="hidden" id="edit-order-id" value="${order.id}">
                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label class="form-label">Tên nhà hàng</label>
                            <input type="text" class="form-control" id="edit-restaurant-name" value="${order.restaurant_name || ''}">
                        </div>
                        <div class="col-md-6 mb-3">
                            <label class="form-label">Địa chỉ giao hàng</label>
                            <input type="text" class="form-control" id="edit-delivery-address" value="${order.delivery_address || ''}">
                        </div>
                    </div>
                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label class="form-label">Số điện thoại giao hàng</label>
                            <input type="text" class="form-control" id="edit-delivery-phone" value="${order.delivery_phone || ''}">
                        </div>
                        <div class="col-md-6 mb-3">
                            <label class="form-label">Tên người nhận</label>
                            <input type="text" class="form-control" id="edit-recipient-name" value="${order.recipient_name || ''}">
                        </div>
                    </div>
                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label class="form-label">Số điện thoại người nhận</label>
                            <input type="text" class="form-control" id="edit-recipient-phone" value="${order.recipient_phone || ''}">
                        </div>
                        <div class="col-md-6 mb-3">
                            <label class="form-label">Tổng tiền</label>
                            <input type="number" class="form-control" id="edit-total-amount" value="${order.total_amount || 0}">
                        </div>
                    </div>
                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label class="form-label">Phí giao hàng</label>
                            <input type="number" class="form-control" id="edit-delivery-fee" value="${order.delivery_fee || 0}">
                        </div>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Ghi chú</label>
                        <textarea class="form-control" id="edit-notes" rows="3">${order.notes || ''}</textarea>
                    </div>
                </form>
            `;
            
            const modal = new bootstrap.Modal(document.getElementById('editOrderModal'));
            modal.show();
        }
    } catch (error) {
        showNotification('Không thể tải thông tin đơn hàng', 'error');
    } finally {
        hideLoading();
    }
}

async function saveOrderEdit() {
    const orderId = document.getElementById('edit-order-id').value;
    const data = {
        restaurant_name: document.getElementById('edit-restaurant-name').value,
        delivery_address: document.getElementById('edit-delivery-address').value,
        delivery_phone: document.getElementById('edit-delivery-phone').value,
        recipient_name: document.getElementById('edit-recipient-name').value,
        recipient_phone: document.getElementById('edit-recipient-phone').value,
        total_amount: parseFloat(document.getElementById('edit-total-amount').value),
        delivery_fee: parseFloat(document.getElementById('edit-delivery-fee').value),
        notes: document.getElementById('edit-notes').value
    };
    
    try {
        showLoading();
        const response = await apiCall(`/admin/orders/${orderId}`, 'PATCH', data);
        
        if (response.status === 'success') {
            showNotification('Cập nhật đơn hàng thành công!', 'success');
            const modal = bootstrap.Modal.getInstance(document.getElementById('editOrderModal'));
            modal.hide();
            loadOrders();
        }
    } catch (error) {
        showNotification(error.message || 'Không thể cập nhật đơn hàng', 'error');
    } finally {
        hideLoading();
    }
}

// Areas management functions
async function loadAreas() {
    try {
        showLoading();
        const response = await apiCall('/admin/areas');
        
        if (response.status === 'success') {
            displayAreas(response.data?.areas || []);
        }
    } catch (error) {
        showNotification('Không thể tải danh sách khu vực', 'error');
    } finally {
        hideLoading();
    }
}

function displayAreas(areas) {
    const tbody = document.getElementById('areas-table');
    if (!tbody) return;
    
    tbody.innerHTML = '';
    
    if (areas.length === 0) {
        tbody.innerHTML = '<tr><td colspan="5" class="text-center">Chưa có khu vực nào</td></tr>';
        return;
    }
    
    areas.forEach(area => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${area.code}</td>
            <td>${area.name}</td>
            <td>${area.description || '<span class="text-muted">Không có</span>'}</td>
            <td>${formatDateTime(area.created_at)}</td>
            <td>
                <div class="btn-group btn-group-sm">
                    <button class="btn btn-warning" onclick="showEditAreaModal(${area.id})">
                        <i class="fas fa-edit"></i>
                    </button>
                    <button class="btn btn-danger" onclick="deleteArea(${area.id})">
                        <i class="fas fa-trash"></i>
                    </button>
                </div>
            </td>
        `;
        tbody.appendChild(row);
    });
}

function showCreateAreaModal() {
    document.getElementById('area-modal-title').textContent = 'Thêm khu vực';
    document.getElementById('area-id').value = '';
    document.getElementById('area-name').value = '';
    document.getElementById('area-code').value = '';
    document.getElementById('area-description').value = '';
    const modal = new bootstrap.Modal(document.getElementById('areaModal'));
    modal.show();
}

async function showEditAreaModal(areaId) {
    try {
        showLoading();
        const response = await apiCall(`/admin/areas/${areaId}`);
        
        if (response.status === 'success') {
            const area = response.data;
            document.getElementById('area-modal-title').textContent = 'Chỉnh sửa khu vực';
            document.getElementById('area-id').value = area.id;
            document.getElementById('area-name').value = area.name;
            document.getElementById('area-code').value = area.code;
            document.getElementById('area-description').value = area.description || '';
            const modal = new bootstrap.Modal(document.getElementById('areaModal'));
            modal.show();
        }
    } catch (error) {
        showNotification('Không thể tải thông tin khu vực', 'error');
    } finally {
        hideLoading();
    }
}

async function saveArea() {
    const id = document.getElementById('area-id').value;
    const data = {
        name: document.getElementById('area-name').value,
        code: document.getElementById('area-code').value,
        description: document.getElementById('area-description').value
    };
    
    if (!data.name || !data.code) {
        showNotification('Vui lòng điền đầy đủ thông tin', 'warning');
        return;
    }
    
    try {
        showLoading();
        const endpoint = id ? `/admin/areas/${id}` : '/admin/areas';
        const method = id ? 'PUT' : 'POST';
        const response = await apiCall(endpoint, method, data);
        
        if (response.status === 'success') {
            showNotification(id ? 'Cập nhật khu vực thành công!' : 'Tạo khu vực thành công!', 'success');
            const modal = bootstrap.Modal.getInstance(document.getElementById('areaModal'));
            modal.hide();
            loadAreas();
        }
    } catch (error) {
        showNotification(error.message || 'Không thể lưu khu vực', 'error');
    } finally {
        hideLoading();
    }
}

async function deleteArea(areaId) {
    if (!confirm('Bạn có chắc chắn muốn xóa khu vực này?')) {
        return;
    }
    
    try {
        showLoading();
        const response = await apiCall(`/admin/areas/${areaId}`, 'DELETE');
        
        if (response.status === 'success') {
            showNotification('Xóa khu vực thành công!', 'success');
            loadAreas();
        }
    } catch (error) {
        showNotification(error.message || 'Không thể xóa khu vực', 'error');
    } finally {
        hideLoading();
    }
}

// US-19 & US-12: COD Reconciliation Functions
async function loadCodOrders() {
    // Ensure loading is hidden first
    while (activeLoadingRequests > 0) {
        activeLoadingRequests = 0;
    }
    if (loadingTimeout) {
        clearTimeout(loadingTimeout);
        loadingTimeout = null;
    }
    const modal = getLoadingModalInstance();
    if (modal) {
        try {
            modal.hide();
        } catch (e) {
            // Ignore
        }
    }
    
    try {
        showLoading();
        const filterStatus = document.getElementById('cod-filter-status')?.value || '';
        
        // Get all orders with COD
        let endpoint = '/admin/orders?limit=1000';
        
        const response = await apiCall(endpoint);
        console.log('COD Orders API Response:', response);
        
        if (response && response.status === 'success') {
            let orders = response.data?.orders || [];
            console.log('Total orders received:', orders.length);
            
            // Filter COD orders - only show orders that are actually COD
            const allCodOrders = orders.filter(order => {
                // Check if order has COD (payment_method = 'cod' or is_cod = true)
                const paymentMethod = (order.payment_method || '').toLowerCase();
                const hasCod = paymentMethod === 'cod' || 
                              order.is_cod === true || 
                              order.is_cod === 'true' ||
                              (order.cod_amount && parseFloat(order.cod_amount) > 0);
                
                return hasCod;
            });
            
            console.log('COD orders found:', allCodOrders.length);
            
            // Apply status filter
            let filteredOrders = allCodOrders;
            if (filterStatus === 'pending_collection') {
                filteredOrders = allCodOrders.filter(order => !order.is_cod_collected);
            } else if (filterStatus === 'collected') {
                filteredOrders = allCodOrders.filter(order => order.is_cod_collected && !order.is_cod_received);
            } else if (filterStatus === 'received') {
                filteredOrders = allCodOrders.filter(order => order.is_cod_collected && order.is_cod_received);
            }
            
            console.log('Filtered COD orders:', filteredOrders.length, 'with filter:', filterStatus);
            
            displayCodOrders(filteredOrders);
            updateCodStats(allCodOrders);
        } else {
            console.error('Failed to load orders:', response);
            if (response && response.message) {
                showNotification(response.message || 'Không thể tải danh sách đơn COD', 'error');
            }
        }
    } catch (error) {
        console.error('loadCodOrders error:', error);
        showNotification('Không thể tải danh sách đơn COD: ' + (error.message || 'Lỗi không xác định'), 'error');
    } finally {
        // Force hide loading
        hideLoading();
        // Double check to ensure loading is hidden
        setTimeout(() => {
            if (activeLoadingRequests > 0) {
                activeLoadingRequests = 0;
            }
            const modal = getLoadingModalInstance();
            if (modal) {
                try {
                    modal.hide();
                } catch (e) {
                    // Ignore
                }
            }
        }, 100);
    }
}

function displayCodOrders(orders) {
    const tbody = document.getElementById('cod-orders-table');
    if (!tbody) {
        console.error('COD orders table body not found!');
        return;
    }
    
    tbody.innerHTML = '';
    
    if (orders.length === 0) {
        tbody.innerHTML = '<tr><td colspan="8" class="text-center py-4 text-muted">Chưa có đơn hàng COD nào</td></tr>';
        return;
    }
    
    console.log('Displaying COD orders:', orders.length);
    
    orders.forEach(order => {
        const row = document.createElement('tr');
        const codAmount = parseFloat(order.cod_amount || order.total_amount || 0);
        const isCollected = order.is_cod_collected === true || order.is_cod_collected === 'true';
        const isReceived = order.is_cod_received === true || order.is_cod_received === 'true';
        
        const customerName = order.customer?.full_name || order.user?.full_name || 'N/A';
        const shipperName = order.shipper?.full_name || 'Chưa gán';
        const orderNumber = order.order_number || `#${order.id}`;
        
        row.innerHTML = `
            <td><strong>${orderNumber}</strong></td>
            <td>${customerName}</td>
            <td>${shipperName}</td>
            <td><strong>${formatCurrency(codAmount)}</strong></td>
            <td>
                ${isCollected 
                    ? `<span class="badge bg-success"><i class="fas fa-check me-1"></i>Đã thu</span><br><small class="text-muted">${order.cod_collected_at ? formatDateTime(order.cod_collected_at) : ''}</small>`
                    : '<span class="badge bg-warning"><i class="fas fa-clock me-1"></i>Chờ xác nhận</span>'}
            </td>
            <td>
                ${isReceived 
                    ? `<span class="badge bg-primary"><i class="fas fa-check me-1"></i>Đã nhận</span><br><small class="text-muted">${order.cod_received_at ? formatDateTime(order.cod_received_at) : ''}</small>`
                    : '<span class="badge bg-secondary"><i class="fas fa-minus me-1"></i>Chưa nhận</span>'}
            </td>
            <td><span class="badge bg-info">${getStatusText(order.status)}</span></td>
            <td class="text-center">
                <div class="btn-group btn-group-sm">
                    ${!isCollected 
                        ? `<button class="btn btn-success btn-sm" onclick="confirmCodCollection(${order.id})" title="Xác nhận đã thu COD">
                                <i class="fas fa-check me-1"></i>Đã thu
                            </button>`
                        : ''}
                    ${isCollected && !isReceived 
                        ? `<button class="btn btn-primary btn-sm" onclick="confirmCodReceived(${order.id})" title="Xác nhận đã nhận COD">
                                <i class="fas fa-inbox me-1"></i>Đã nhận
                            </button>`
                        : ''}
                    ${isReceived 
                        ? '<span class="badge bg-success">Hoàn tất</span>'
                        : ''}
                </div>
            </td>
        `;
        tbody.appendChild(row);
    });
}

function updateCodStats(orders) {
    const collectedCount = orders.filter(o => o.is_cod_collected).length;
    const receivedCount = orders.filter(o => o.is_cod_received).length;
    const pendingCollectionCount = orders.filter(o => !o.is_cod_collected).length;
    const totalAmount = orders.reduce((sum, o) => sum + (o.cod_amount || o.total_amount || 0), 0);
    
    document.getElementById('cod-collected-count').textContent = collectedCount;
    document.getElementById('cod-received-count').textContent = receivedCount;
    document.getElementById('cod-pending-collection-count').textContent = pendingCollectionCount;
    document.getElementById('cod-total-amount').textContent = formatCurrency(totalAmount);
}

// Helper function to show confirm dialog using Bootstrap Modal
function showConfirmDialog(message, onConfirm) {
    // Create modal HTML if it doesn't exist
    let confirmModal = document.getElementById('confirmModal');
    if (!confirmModal) {
        confirmModal = document.createElement('div');
        confirmModal.id = 'confirmModal';
        confirmModal.className = 'modal fade';
        confirmModal.innerHTML = `
            <div class="modal-dialog modal-dialog-centered">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title">Xác nhận</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                    </div>
                    <div class="modal-body" id="confirmModalBody">
                        ${message}
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Hủy</button>
                        <button type="button" class="btn btn-primary" id="confirmModalConfirmBtn">Xác nhận</button>
                    </div>
                </div>
            </div>
        `;
        document.body.appendChild(confirmModal);
    }
    
    // Update message
    document.getElementById('confirmModalBody').textContent = message;
    
    // Remove old event listeners
    const confirmBtn = document.getElementById('confirmModalConfirmBtn');
    const newConfirmBtn = confirmBtn.cloneNode(true);
    confirmBtn.parentNode.replaceChild(newConfirmBtn, confirmBtn);
    
    // Add new event listener
    newConfirmBtn.addEventListener('click', () => {
        const modal = bootstrap.Modal.getInstance(confirmModal);
        if (modal) {
            modal.hide();
        }
        if (onConfirm) {
            onConfirm();
        }
    });
    
    // Show modal
    const modal = new bootstrap.Modal(confirmModal);
    modal.show();
}

async function confirmCodCollection(orderId) {
    showConfirmDialog('Xác nhận rằng shipper đã thu COD từ khách hàng?', async () => {
        try {
            showLoading();
            const response = await apiCall('/admin/payments/confirm-collection', 'POST', {
                order_id: orderId
            });
            
            if (response.status === 'success') {
                showNotification('Xác nhận thu COD thành công', 'success');
                loadCodOrders();
            } else {
                showNotification(response.message || 'Không thể xác nhận thu COD', 'error');
            }
        } catch (error) {
            showNotification(error.message || 'Không thể xác nhận thu COD', 'error');
            console.error('confirmCodCollection error:', error);
        } finally {
            hideLoading();
        }
    });
}

async function confirmCodReceived(orderId) {
    showConfirmDialog('Xác nhận rằng shipper đã nộp COD về công ty?', async () => {
        try {
            showLoading();
            const response = await apiCall('/admin/payments/confirm-received', 'POST', {
                order_id: orderId
            });
            
            if (response.status === 'success') {
                showNotification('Xác nhận nhận COD thành công', 'success');
                loadCodOrders();
            } else {
                showNotification(response.message || 'Không thể xác nhận nhận COD', 'error');
            }
        } catch (error) {
            showNotification(error.message || 'Không thể xác nhận nhận COD', 'error');
            console.error('confirmCodReceived error:', error);
        } finally {
            hideLoading();
        }
    });
}

// Auto-refresh at a configurable interval for real-time data
setInterval(() => {
    if (!isDemoMode) {
        refreshCurrentView();
    }
}, AUTO_REFRESH_INTERVAL);
