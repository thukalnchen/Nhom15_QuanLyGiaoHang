const { pool } = require('../config/database');

// Get revenue report
const getRevenueReport = async (req, res) => {
  try {
    const { period = 'today' } = req.query;

    // Get overall revenue stats
    const overallQuery = `
      SELECT 
        COUNT(*) as total_orders,
        SUM(CASE WHEN status = 'delivered' THEN 1 ELSE 0 END) as delivered_orders,
        SUM(total_amount) as total_revenue,
        SUM(delivery_fee) as delivery_revenue,
        SUM(CASE WHEN status = 'delivered' THEN total_amount ELSE 0 END) as actual_revenue,
        AVG(total_amount) as avg_order_value
      FROM orders
      WHERE DATE(created_at) = CURRENT_DATE
    `;

    const monthQuery = `
      SELECT 
        COUNT(*) as total_orders,
        SUM(total_amount) as total_revenue
      FROM orders
      WHERE DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE)
    `;

    const yearQuery = `
      SELECT 
        COUNT(*) as total_orders,
        SUM(total_amount) as total_revenue
      FROM orders
      WHERE DATE_TRUNC('year', created_at) = DATE_TRUNC('year', CURRENT_DATE)
    `;

    // Revenue by vehicle type
    const byVehicleQuery = `
      SELECT 
        COALESCE(vehicle_type, 'unknown') as vehicle_type,
        COUNT(*) as count,
        SUM(total_amount) as revenue
      FROM orders
      WHERE DATE(created_at) = CURRENT_DATE
      GROUP BY vehicle_type
      ORDER BY revenue DESC
    `;

    const [overall, monthly, yearly, byVehicle] = await Promise.all([
      pool.query(overallQuery),
      pool.query(monthQuery),
      pool.query(yearQuery),
      pool.query(byVehicleQuery)
    ]);

    res.json({
      status: 'success',
      data: {
        today: {
          total_revenue: parseFloat(overall.rows[0]?.total_revenue || 0),
          delivery_revenue: parseFloat(overall.rows[0]?.delivery_revenue || 0),
          actual_revenue: parseFloat(overall.rows[0]?.actual_revenue || 0),
          avg_order_value: parseFloat(overall.rows[0]?.avg_order_value || 0),
          total_orders: parseInt(overall.rows[0]?.total_orders || 0),
          delivered_orders: parseInt(overall.rows[0]?.delivered_orders || 0)
        },
        monthly: {
          total_revenue: parseFloat(monthly.rows[0]?.total_revenue || 0),
          total_orders: parseInt(monthly.rows[0]?.total_orders || 0)
        },
        yearly: {
          total_revenue: parseFloat(yearly.rows[0]?.total_revenue || 0),
          total_orders: parseInt(yearly.rows[0]?.total_orders || 0)
        },
        by_vehicle: byVehicle.rows.map(row => ({
          type: row.vehicle_type,
          count: parseInt(row.count),
          revenue: parseFloat(row.revenue || 0)
        }))
      }
    });
  } catch (error) {
    console.error('Error getting revenue report:', error);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi tải báo cáo doanh thu',
      error: error.message
    });
  }
};

// Get delivery statistics
const getDeliveryStatistics = async (req, res) => {
  try {
    // By status
    const byStatusQuery = `
      SELECT 
        status,
        COUNT(*) as count,
        ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 2) as percentage
      FROM orders
      GROUP BY status
      ORDER BY count DESC
    `;

    // By time of day
    const byTimeQuery = `
      SELECT 
        CASE
          WHEN EXTRACT(HOUR FROM created_at) BETWEEN 6 AND 11 THEN 'morning'
          WHEN EXTRACT(HOUR FROM created_at) BETWEEN 12 AND 17 THEN 'afternoon'
          WHEN EXTRACT(HOUR FROM created_at) BETWEEN 18 AND 23 THEN 'evening'
          ELSE 'night'
        END as time_period,
        COUNT(*) as count
      FROM orders
      GROUP BY 
        CASE
          WHEN EXTRACT(HOUR FROM created_at) BETWEEN 6 AND 11 THEN 'morning'
          WHEN EXTRACT(HOUR FROM created_at) BETWEEN 12 AND 17 THEN 'afternoon'
          WHEN EXTRACT(HOUR FROM created_at) BETWEEN 18 AND 23 THEN 'evening'
          ELSE 'night'
        END
      ORDER BY 
        CASE
          WHEN EXTRACT(HOUR FROM created_at) BETWEEN 6 AND 11 THEN 1
          WHEN EXTRACT(HOUR FROM created_at) BETWEEN 12 AND 17 THEN 2
          WHEN EXTRACT(HOUR FROM created_at) BETWEEN 18 AND 23 THEN 3
          ELSE 4
        END
    `;

    // Success rate
    const successRateQuery = `
      SELECT 
        COUNT(*) as total_orders,
        COUNT(CASE WHEN status = 'delivered' THEN 1 END) as delivered_orders,
        COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as cancelled_orders,
        ROUND(COUNT(CASE WHEN status = 'delivered' THEN 1 END)::numeric / NULLIF(COUNT(*), 0) * 100, 2) as success_rate
      FROM orders
    `;

    const [byStatus, byTime, successRate] = await Promise.all([
      pool.query(byStatusQuery),
      pool.query(byTimeQuery),
      pool.query(successRateQuery)
    ]);

    res.json({
      status: 'success',
      data: {
        by_status: byStatus.rows,
        by_time: byTime.rows,
        success_rate: successRate.rows[0]
      }
    });
  } catch (error) {
    console.error('Error getting delivery statistics:', error);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi tải thống kê giao hàng',
      error: error.message
    });
  }
};

// Get driver performance report
const getDriverPerformanceReport = async (req, res) => {
  try {
    const query = `
      SELECT 
        u.id,
        u.full_name,
        u.phone,
        u.vehicle_registration,
        COUNT(o.id) as total_orders,
        COUNT(CASE WHEN o.status = 'delivered' THEN 1 END) as delivered_orders,
        SUM(CASE WHEN o.status = 'delivered' THEN o.delivery_fee ELSE 0 END) as total_earnings,
        ROUND(COUNT(CASE WHEN o.status = 'delivered' THEN 1 END)::numeric / NULLIF(COUNT(o.id), 0) * 100, 2) as success_rate
      FROM users u
      LEFT JOIN orders o ON o.driver_id = u.id
      WHERE u.role = 'driver'
      GROUP BY u.id, u.full_name, u.phone, u.vehicle_registration
      HAVING COUNT(o.id) > 0
      ORDER BY total_earnings DESC
      LIMIT 10
    `;

    const result = await pool.query(query);

    res.json({
      status: 'success',
      data: result.rows.map(row => ({
        id: row.id,
        name: row.full_name,
        phone: row.phone,
        vehicle: row.vehicle_registration || 'N/A',
        total_orders: parseInt(row.total_orders),
        delivered_orders: parseInt(row.delivered_orders),
        total_earnings: parseFloat(row.total_earnings || 0),
        success_rate: parseFloat(row.success_rate || 0)
      }))
    });
  } catch (error) {
    console.error('Error getting driver performance report:', error);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi tải báo cáo hiệu suất tài xế',
      error: error.message
    });
  }
};

// Get customer analytics
const getCustomerAnalytics = async (req, res) => {
  try {
    // Total customers
    const totalQuery = `
      SELECT COUNT(DISTINCT user_id) as total_customers
      FROM orders
      WHERE user_id IS NOT NULL
    `;

    // New customers this month  
    const newQuery = `
      SELECT COUNT(DISTINCT user_id) as new_customers
      FROM orders
      WHERE DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE)
      AND user_id IS NOT NULL
    `;

    // Repeat customers
    const repeatQuery = `
      SELECT COUNT(*) as repeat_customers
      FROM (
        SELECT user_id
        FROM orders
        WHERE user_id IS NOT NULL
        GROUP BY user_id
        HAVING COUNT(*) > 1
      ) AS repeat
    `;

    // Top customers
    const topQuery = `
      SELECT 
        u.full_name,
        COUNT(o.id) as total_orders,
        SUM(o.total_amount) as total_spent
      FROM users u
      INNER JOIN orders o ON o.user_id = u.id
      GROUP BY u.id, u.full_name
      ORDER BY total_spent DESC
      LIMIT 10
    `;

    const [total, newCustomers, repeat, top] = await Promise.all([
      pool.query(totalQuery),
      pool.query(newQuery),
      pool.query(repeatQuery),
      pool.query(topQuery)
    ]);

    res.json({
      status: 'success',
      data: {
        total_customers: parseInt(total.rows[0]?.total_customers || 0),
        new_customers: parseInt(newCustomers.rows[0]?.new_customers || 0),
        repeat_customers: parseInt(repeat.rows[0]?.repeat_customers || 0),
        top_customers: top.rows.map(row => ({
          name: row.full_name,
          total_orders: parseInt(row.total_orders),
          total_spent: parseFloat(row.total_spent || 0)
        }))
      }
    });
  } catch (error) {
    console.error('Error getting customer analytics:', error);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi tải phân tích khách hàng',
      error: error.message
    });
  }
};

// Get dashboard summary
const getDashboardSummary = async (req, res) => {
  try {
    const query = `
      SELECT 
        COUNT(*) as total_orders,
        COUNT(CASE WHEN status = 'delivered' THEN 1 END) as delivered_orders,
        COUNT(CASE WHEN status IN ('pending', 'confirmed', 'assigned', 'picked_up', 'in_delivery') THEN 1 END) as in_progress_orders,
        SUM(total_amount) as total_revenue,
        ROUND(COUNT(CASE WHEN status = 'delivered' THEN 1 END)::numeric / NULLIF(COUNT(*), 0) * 100, 2) as success_rate
      FROM orders
      WHERE DATE(created_at) = CURRENT_DATE
    `;

    // Count active drivers
    const driversQuery = `
      SELECT COUNT(*) as active_drivers
      FROM users
      WHERE role = 'driver'
    `;

    const [summary, drivers] = await Promise.all([
      pool.query(query),
      pool.query(driversQuery)
    ]);

    res.json({
      status: 'success',
      data: {
        orders_today: parseInt(summary.rows[0]?.total_orders || 0),
        delivered_today: parseInt(summary.rows[0]?.delivered_orders || 0),
        in_progress: parseInt(summary.rows[0]?.in_progress_orders || 0),
        revenue_today: parseFloat(summary.rows[0]?.total_revenue || 0),
        success_rate: parseFloat(summary.rows[0]?.success_rate || 0),
        active_drivers: parseInt(drivers.rows[0]?.active_drivers || 0)
      }
    });
  } catch (error) {
    console.error('Error getting dashboard summary:', error);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi khi tải tóm tắt dashboard',
      error: error.message
    });
  }
};

module.exports = {
  getRevenueReport,
  getDeliveryStatistics,
  getDriverPerformanceReport,
  getCustomerAnalytics,
  getDashboardSummary
};
