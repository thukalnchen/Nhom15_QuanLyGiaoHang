const PDFDocument = require('pdfkit');
const fs = require('fs');
const path = require('path');
const { pool } = require('../config/database');

// Generate receipt PDF
const generateReceiptPDF = async (orderId) => {
  try {
    // Fetch order details
    const orderQuery = `
      SELECT 
        o.*,
        u1.full_name as sender_name, u1.phone_number as sender_phone,
        u2.full_name as receiver_name, u2.phone_number as receiver_phone,
        d.full_name as driver_name, d.phone_number as driver_phone
      FROM orders o
      LEFT JOIN users u1 ON o.user_id = u1.id
      LEFT JOIN users u2 ON o.user_id = u2.id
      LEFT JOIN users d ON o.driver_id = d.id
      WHERE o.id = $1
    `;
    
    const result = await pool.query(orderQuery, [orderId]);
    
    if (result.rows.length === 0) {
      throw new Error('Order not found');
    }
    
    const order = result.rows[0];
    
    // Create PDF
    const doc = new PDFDocument({ margin: 50 });
    
    // Generate filename
    const filename = `receipt_${order.order_code}_${Date.now()}.pdf`;
    const filepath = path.join(__dirname, '../uploads/receipts', filename);
    
    // Ensure directory exists
    const dir = path.dirname(filepath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    
    // Pipe PDF to file
    const stream = fs.createWriteStream(filepath);
    doc.pipe(stream);
    
    // Add content
    // Header
    doc.fontSize(24)
       .fillColor('#F26522')
       .text('LALAMOVE EXPRESS', { align: 'center' })
       .fontSize(16)
       .fillColor('#000000')
       .text('HÓA ĐƠN GIAO HÀNG', { align: 'center' })
       .moveDown();
    
    // Order information
    doc.fontSize(12)
       .fillColor('#F26522')
       .text('THÔNG TIN ĐƠN HÀNG', { underline: true })
       .fillColor('#000000')
       .moveDown(0.5);
    
    doc.fontSize(10)
       .text(`Mã đơn hàng: ${order.order_code}`, { continued: true })
       .text(`      Ngày tạo: ${new Date(order.created_at).toLocaleString('vi-VN')}`)
       .text(`Trạng thái: ${getStatusText(order.status)}`)
       .text(`Phương thức thanh toán: ${order.payment_method === 'cod' ? 'COD' : 'Online'}`)
       .moveDown();
    
    // Sender information
    doc.fontSize(12)
       .fillColor('#F26522')
       .text('NGƯỜI GỬI', { underline: true })
       .fillColor('#000000')
       .moveDown(0.5);
    
    doc.fontSize(10)
       .text(`Tên: ${order.sender_name || 'N/A'}`)
       .text(`Số điện thoại: ${order.sender_phone || order.pickup_phone}`)
       .text(`Địa chỉ: ${order.pickup_address}`)
       .moveDown();
    
    // Receiver information
    doc.fontSize(12)
       .fillColor('#F26522')
       .text('NGƯỜI NHẬN', { underline: true })
       .fillColor('#000000')
       .moveDown(0.5);
    
    doc.fontSize(10)
       .text(`Tên: ${order.receiver_name || 'N/A'}`)
       .text(`Số điện thoại: ${order.receiver_phone || order.delivery_phone}`)
       .text(`Địa chỉ: ${order.delivery_address}`)
       .moveDown();
    
    // Package information
    if (order.package_size || order.package_weight) {
      doc.fontSize(12)
         .fillColor('#F26522')
         .text('THÔNG TIN GÓI HÀNG', { underline: true })
         .fillColor('#000000')
         .moveDown(0.5);
      
      if (order.package_size) {
        doc.fontSize(10).text(`Kích thước: ${order.package_size}`);
      }
      if (order.package_weight) {
        doc.fontSize(10).text(`Cân nặng: ${order.package_weight}`);
      }
      if (order.package_type) {
        doc.fontSize(10).text(`Loại hàng: ${order.package_type}`);
      }
      doc.moveDown();
    }
    
    // Driver information
    if (order.driver_name) {
      doc.fontSize(12)
         .fillColor('#F26522')
         .text('THÔNG TIN TÀI XẾ', { underline: true })
         .fillColor('#000000')
         .moveDown(0.5);
      
      doc.fontSize(10)
         .text(`Tên: ${order.driver_name}`)
         .text(`Số điện thoại: ${order.driver_phone}`)
         .text(`Loại xe: ${order.vehicle_type || 'N/A'}`)
         .moveDown();
    }
    
    // Pricing details
    doc.fontSize(12)
       .fillColor('#F26522')
       .text('CHI TIẾT GIÁ', { underline: true })
       .fillColor('#000000')
       .moveDown(0.5);
    
    const distance = order.distance || 0;
    const baseFee = order.base_fee || 0;
    const distanceFee = order.distance_fee || 0;
    const serviceFee = order.service_fee || 0;
    const totalAmount = order.total_amount || 0;
    
    doc.fontSize(10)
       .text(`Khoảng cách: ${distance.toFixed(2)} km`)
       .text(`Phí cơ bản: ${formatCurrency(baseFee)}`)
       .text(`Phí khoảng cách: ${formatCurrency(distanceFee)}`)
       .text(`Phí dịch vụ: ${formatCurrency(serviceFee)}`)
       .moveDown(0.5);
    
    // Total (larger font)
    doc.fontSize(14)
       .fillColor('#F26522')
       .text(`TỔNG CỘNG: ${formatCurrency(totalAmount)}`, { align: 'right' })
       .moveDown();
    
    // Payment status
    doc.fontSize(10)
       .fillColor('#000000')
       .text(`Trạng thái thanh toán: ${order.payment_status === 'paid' ? 'Đã thanh toán' : 'Chưa thanh toán'}`, { align: 'right' });
    
    // Footer
    doc.moveDown(2)
       .fontSize(8)
       .fillColor('#666666')
       .text('Cảm ơn quý khách đã sử dụng dịch vụ Lalamove Express!', { align: 'center' })
       .text('Hotline: 1900-xxxx | Email: support@lalamove.vn', { align: 'center' });
    
    // Add page numbers
    const range = doc.bufferedPageRange();
    for (let i = range.start; i < range.start + range.count; i++) {
      doc.switchToPage(i);
      doc.fontSize(8)
         .fillColor('#666666')
         .text(`Trang ${i + 1} / ${range.count}`,
           50,
           doc.page.height - 50,
           { align: 'center' }
         );
    }
    
    // Finalize PDF
    doc.end();
    
    // Wait for file to be written
    await new Promise((resolve, reject) => {
      stream.on('finish', resolve);
      stream.on('error', reject);
    });
    
    return {
      filename,
      filepath,
      url: `/uploads/receipts/${filename}`
    };
  } catch (error) {
    console.error('Error generating receipt PDF:', error);
    throw error;
  }
};

// Helper function to format currency
const formatCurrency = (amount) => {
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND'
  }).format(amount);
};

// Helper function to get status text
const getStatusText = (status) => {
  const statusMap = {
    'pending': 'Chờ xử lý',
    'confirmed': 'Đã xác nhận',
    'received_at_warehouse': 'Đã nhận tại kho',
    'classified': 'Đã phân loại',
    'assigned': 'Đã phân công tài xế',
    'picked_up': 'Đã lấy hàng',
    'in_transit': 'Đang giao',
    'delivered': 'Đã giao',
    'completed': 'Hoàn thành',
    'cancelled': 'Đã hủy'
  };
  return statusMap[status] || status;
};

module.exports = {
  generateReceiptPDF
};
