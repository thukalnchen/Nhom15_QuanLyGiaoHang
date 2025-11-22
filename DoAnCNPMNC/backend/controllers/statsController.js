const { pool } = require('../config/database');

// Get revenue statistics
exports.getRevenueStats = async (req, res) => {
  try {
    const { period = '30', startDate, endDate } = req.query;
    
    let dateFilter = '';
    const params = [];
    let paramIndex = 1;
    
    if (startDate && endDate) {
      dateFilter = `WHERE DATE(created_at) BETWEEN $${paramIndex} AND $${paramIndex + 1}`;
      params.push(startDate, endDate);
      paramIndex += 2;
    } else {
      // Use period (days)
      const days = parseInt(period) || 30;
      dateFilter = `WHERE created_at >= NOW() - INTERVAL '${days} days'`;
    }
    
    // Revenue by day
    const revenueByDayQuery = `
      SELECT 
        DATE(created_at) as date,
        COUNT(*) as order_count,
        COALESCE(SUM(total_amount), 0) as total_revenue,
        COALESCE(SUM(delivery_fee), 0) as delivery_fee_total,
        COALESCE(SUM(base_fare), 0) as base_fare_total,
        COALESCE(SUM(service_fee), 0) as service_fee_total
      FROM orders
      ${dateFilter}
      GROUP BY DATE(created_at)
      ORDER BY date ASC
    `;
    
    // Revenue by month
    const revenueByMonthQuery = `
      SELECT 
        DATE_TRUNC('month', created_at) as month,
        COUNT(*) as order_count,
        COALESCE(SUM(total_amount), 0) as total_revenue,
        COALESCE(SUM(delivery_fee), 0) as delivery_fee_total,
        COALESCE(SUM(base_fare), 0) as base_fare_total,
        COALESCE(SUM(service_fee), 0) as service_fee_total
      FROM orders
      ${dateFilter}
      GROUP BY DATE_TRUNC('month', created_at)
      ORDER BY month ASC
    `;
    
    // Overall summary
    const summaryQuery = `
      SELECT 
        COUNT(*) as total_orders,
        COALESCE(SUM(total_amount), 0) as total_revenue,
        COALESCE(SUM(delivery_fee), 0) as total_delivery_fee,
        COALESCE(AVG(total_amount), 0) as avg_order_value,
        COUNT(DISTINCT user_id) as unique_customers
      FROM orders
      ${dateFilter}
    `;
    
    const [revenueByDay, revenueByMonth, summary] = await Promise.all([
      pool.query(revenueByDayQuery, params),
      pool.query(revenueByMonthQuery, params),
      pool.query(summaryQuery, params)
    ]);
    
    res.json({
      success: true,
      data: {
        byDay: revenueByDay.rows.map(row => ({
          date: row.date,
          orderCount: parseInt(row.order_count),
          totalRevenue: parseFloat(row.total_revenue),
          deliveryFee: parseFloat(row.delivery_fee_total),
          baseFare: parseFloat(row.base_fare_total),
          serviceFee: parseFloat(row.service_fee_total)
        })),
        byMonth: revenueByMonth.rows.map(row => ({
          month: row.month,
          orderCount: parseInt(row.order_count),
          totalRevenue: parseFloat(row.total_revenue),
          deliveryFee: parseFloat(row.delivery_fee_total),
          baseFare: parseFloat(row.base_fare_total),
          serviceFee: parseFloat(row.service_fee_total)
        })),
        summary: {
          totalOrders: parseInt(summary.rows[0].total_orders),
          totalRevenue: parseFloat(summary.rows[0].total_revenue),
          totalDeliveryFee: parseFloat(summary.rows[0].total_delivery_fee),
          avgOrderValue: parseFloat(summary.rows[0].avg_order_value),
          uniqueCustomers: parseInt(summary.rows[0].unique_customers)
        }
      }
    });
  } catch (error) {
    console.error('Error getting revenue stats:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi tải thống kê doanh thu',
      error: error.message
    });
  }
};

// Get performance statistics
exports.getPerformanceStats = async (req, res) => {
  try {
    const { period = '30', startDate, endDate } = req.query;
    
    let dateFilter = '';
    const params = [];
    let paramIndex = 1;
    
    if (startDate && endDate) {
      dateFilter = `WHERE DATE(created_at) BETWEEN $${paramIndex} AND $${paramIndex + 1}`;
      params.push(startDate, endDate);
      paramIndex += 2;
    } else {
      const days = parseInt(period) || 30;
      dateFilter = `WHERE created_at >= NOW() - INTERVAL '${days} days'`;
    }
    
    // Performance by status
    const statusStatsQuery = `
      SELECT 
        status,
        COUNT(*) as count
      FROM orders
      ${dateFilter}
      GROUP BY status
      ORDER BY count DESC
    `;
    
    // Performance by day
    const performanceByDayQuery = `
      SELECT 
        DATE(created_at) as date,
        COUNT(*) as total_orders,
        COUNT(*) FILTER (WHERE status = 'delivered') as successful_orders,
        COUNT(*) FILTER (WHERE status = 'cancelled') as cancelled_orders,
        COUNT(*) FILTER (WHERE status IN ('pending', 'processing', 'shipped')) as pending_orders
      FROM orders
      ${dateFilter}
      GROUP BY DATE(created_at)
      ORDER BY date ASC
    `;
    
    // Average delivery time (if we have delivery tracking)
    const avgDeliveryTimeQuery = `
      SELECT 
        AVG(EXTRACT(EPOCH FROM (updated_at - created_at)) / 60) as avg_delivery_time_minutes
      FROM orders
      ${dateFilter}
      AND status = 'delivered'
    `;
    
    // Success rate by vehicle type
    const vehicleTypeStatsQuery = `
      SELECT 
        vehicle_type,
        COUNT(*) as total_orders,
        COUNT(*) FILTER (WHERE status = 'delivered') as successful_orders,
        COUNT(*) FILTER (WHERE status = 'cancelled') as cancelled_orders
      FROM orders
      ${dateFilter}
      AND vehicle_type IS NOT NULL
      GROUP BY vehicle_type
      ORDER BY total_orders DESC
    `;
    
    const [statusStats, performanceByDay, avgDeliveryTime, vehicleTypeStats] = await Promise.all([
      pool.query(statusStatsQuery, params),
      pool.query(performanceByDayQuery, params),
      pool.query(avgDeliveryTimeQuery, params),
      pool.query(vehicleTypeStatsQuery, params)
    ]);
    
    // Calculate success rate
    const totalOrders = statusStats.rows.reduce((sum, row) => sum + parseInt(row.count), 0);
    const successfulOrders = statusStats.rows.find(row => row.status === 'delivered')?.count || 0;
    const cancelledOrders = statusStats.rows.find(row => row.status === 'cancelled')?.count || 0;
    const successRate = totalOrders > 0 ? (successfulOrders / totalOrders) * 100 : 0;
    const cancellationRate = totalOrders > 0 ? (cancelledOrders / totalOrders) * 100 : 0;
    
    res.json({
      success: true,
      data: {
        statusBreakdown: statusStats.rows.map(row => ({
          status: row.status,
          count: parseInt(row.count),
          percentage: totalOrders > 0 ? ((parseInt(row.count) / totalOrders) * 100).toFixed(2) : 0
        })),
        byDay: performanceByDay.rows.map(row => ({
          date: row.date,
          totalOrders: parseInt(row.total_orders),
          successfulOrders: parseInt(row.successful_orders),
          cancelledOrders: parseInt(row.cancelled_orders),
          pendingOrders: parseInt(row.pending_orders),
          successRate: row.total_orders > 0 
            ? ((row.successful_orders / row.total_orders) * 100).toFixed(2) 
            : 0
        })),
        summary: {
          totalOrders,
          successfulOrders: parseInt(successfulOrders),
          cancelledOrders: parseInt(cancelledOrders),
          successRate: parseFloat(successRate.toFixed(2)),
          cancellationRate: parseFloat(cancellationRate.toFixed(2)),
          avgDeliveryTimeMinutes: avgDeliveryTime.rows[0]?.avg_delivery_time_minutes 
            ? parseFloat(avgDeliveryTime.rows[0].avg_delivery_time_minutes.toFixed(2))
            : null
        },
        byVehicleType: vehicleTypeStats.rows.map(row => ({
          vehicleType: row.vehicle_type,
          totalOrders: parseInt(row.total_orders),
          successfulOrders: parseInt(row.successful_orders),
          cancelledOrders: parseInt(row.cancelled_orders),
          successRate: row.total_orders > 0
            ? ((row.successful_orders / row.total_orders) * 100).toFixed(2)
            : 0
        }))
      }
    });
  } catch (error) {
    console.error('Error getting performance stats:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi tải thống kê hiệu suất',
      error: error.message
    });
  }
};

