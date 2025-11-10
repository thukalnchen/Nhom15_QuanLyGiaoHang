const express = require('express');
const crypto = require('crypto');
const { URLSearchParams } = require('url');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const pool = require('../config/database');

const SHIPPING_BASE_FEE = 18000;
const SHIPPING_STEP_FEE = 5000;
const SHIPPING_STEP_WEIGHT = 0.5; // kg
const EXPRESS_SURCHARGE = 12000;
const ECONOMY_DISCOUNT = 2000;
const INSURANCE_RATE = 0.005; // 0.5%
const INSURANCE_THRESHOLD = 3000000; // VND
const PAYMENT_EXPIRATION_MINUTES = parseInt(process.env.PAYMENT_EXPIRATION_MINUTES || '15', 10);
const PAYMENT_GATEWAY_SECRET = process.env.PAYMENT_GATEWAY_SECRET || 'mock_secret_123';
const PAYMENT_GATEWAY_BASE_URL =
  process.env.PAYMENT_GATEWAY_BASE_URL || 'http://localhost:3000/api/payment/mock/checkout';
const PAYMENT_GATEWAY_PROVIDER = process.env.PAYMENT_GATEWAY_PROVIDER || 'jnt_mock_gateway';
const PAYMENT_CURRENCY = 'VND';

const normalizeNumber = (value, fallback = 0) => {
  if (value === null || value === undefined || value === '') {
    return fallback;
  }
  const parsed = typeof value === 'number' ? value : parseFloat(value);
  if (Number.isNaN(parsed)) {
    return fallback;
  }
  return parsed;
};

const sanitizeString = (value) => {
  if (value === null || value === undefined) return '';
  return String(value).trim();
};

const calculateChargeableWeight = ({ weightKg, lengthCm, widthCm, heightCm }) => {
  const weight = normalizeNumber(weightKg, 0.5);
  const volumetricWeight = normalizeNumber(lengthCm, 0) * normalizeNumber(widthCm, 0) * normalizeNumber(heightCm, 0);
  const volumetricKg = volumetricWeight > 0 ? volumetricWeight / 6000 : 0;
  return Math.max(weight, volumetricKg, 0.5);
};

const calculateShippingFee = (chargeableWeight, serviceType) => {
  const steps = Math.ceil(chargeableWeight / SHIPPING_STEP_WEIGHT);
  let fee = SHIPPING_BASE_FEE + Math.max(0, steps - 1) * SHIPPING_STEP_FEE;

  switch (serviceType) {
    case 'express':
      fee += EXPRESS_SURCHARGE;
      break;
    case 'economy':
      fee = Math.max(12000, fee - ECONOMY_DISCOUNT);
      break;
    default:
      break;
  }

  return Math.round(fee);
};

const calculateInsuranceFee = (declaredValue) => {
  const value = normalizeNumber(declaredValue, 0);
  if (value <= 0 || value < INSURANCE_THRESHOLD) return 0;
  return Math.round(value * INSURANCE_RATE);
};

const buildPaymentSignature = ({ orderId, reference, amount, currency = PAYMENT_CURRENCY }) => {
  const payload = `${orderId}|${reference}|${amount}|${currency}`;
  return crypto.createHmac('sha256', PAYMENT_GATEWAY_SECRET).update(payload).digest('hex');
};

const buildPaymentUrl = ({ orderId, reference, amount, currency = PAYMENT_CURRENCY }) => {
  const signature = buildPaymentSignature({ orderId, reference, amount, currency });
  const searchParams = new URLSearchParams({
    orderId: String(orderId),
    ref: reference,
    amount: String(amount),
    currency,
    signature
  });

  const separator = PAYMENT_GATEWAY_BASE_URL.includes('?') ? '&' : '?';

  return {
    url: `${PAYMENT_GATEWAY_BASE_URL}${separator}${searchParams.toString()}`,
    signature
  };
};

const mapTransactionRow = (row) => {
  if (!row) return null;
  return {
    id: row.id,
    reference: row.reference,
    provider: row.provider,
    amount: Number(row.amount),
    currency: row.currency,
    status: row.status,
    payment_url: row.payment_url,
    signature: row.signature,
    expires_at: row.expires_at,
    paid_amount: row.paid_amount !== null ? Number(row.paid_amount) : null,
    completed_at: row.completed_at,
    created_at: row.created_at,
    updated_at: row.updated_at
  };
};

const estimateDeliveryWindow = (serviceType) => {
  const now = new Date();
  const pickup = new Date(now.getTime() + 4 * 60 * 60 * 1000); // +4h

  let deliveryDays = 2;
  switch (serviceType) {
    case 'express':
      deliveryDays = 1;
      break;
    case 'economy':
      deliveryDays = 4;
      break;
    default:
      deliveryDays = 2;
  }
  const delivery = new Date(now.getTime() + deliveryDays * 24 * 60 * 60 * 1000);

  return { estimatedPickup: pickup, estimatedDelivery: delivery };
};

const fetchOrderDetail = async (orderId, userId, client = pool) => {
  const orderResult = await client.query(
    `SELECT 
      o.id,
      o.user_id,
      o.tracking_number,
      o.sender_name,
      o.sender_phone,
      o.sender_address,
      o.sender_city,
      o.sender_district,
      o.sender_ward,
      o.receiver_name,
      o.receiver_phone,
      o.receiver_address,
      o.receiver_city,
      o.receiver_district,
      o.receiver_ward,
      o.package_type,
      o.service_type,
      o.pickup_type,
      o.pickup_notes,
      o.parcel_weight,
      o.parcel_length,
      o.parcel_width,
      o.parcel_height,
      o.declared_value,
      o.cod_amount,
      o.insurance_fee,
      o.shipping_fee,
      o.total_amount,
      o.payment_method,
      o.payment_status,
      o.payment_reference,
      o.estimated_pickup,
      o.estimated_delivery,
      o.status,
      o.notes,
      o.created_at,
      o.updated_at
    FROM orders o
    WHERE o.id = $1 AND o.user_id = $2`,
    [orderId, userId]
  );

  if (orderResult.rows.length === 0) {
    return null;
  }

  const order = orderResult.rows[0];

  const itemsResult = await client.query(
    `SELECT 
      id,
      item_name,
      quantity,
      weight,
      price
    FROM order_items
    WHERE order_id = $1
    ORDER BY id ASC`,
    [orderId]
  );

  const historyResult = await client.query(
    `SELECT
      id,
      status,
      description,
      created_by,
      created_at
    FROM order_status_history
    WHERE order_id = $1
    ORDER BY created_at ASC`,
    [orderId]
  );

  const paymentResult = await client.query(
    `SELECT
      id,
      reference,
      provider,
      amount,
      currency,
      status,
      payment_url,
      signature,
      expires_at,
      paid_amount,
      completed_at,
      created_at,
      updated_at
    FROM payment_transactions
    WHERE order_id = $1
    ORDER BY created_at DESC
    LIMIT 1`,
    [orderId]
  );

  order.items = itemsResult.rows;
  order.status_history = historyResult.rows;
  order.payment_transaction = mapTransactionRow(paymentResult.rows[0]);

  return order;
};

router.post('/', authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const {
    sender = {},
    receiver = {},
    parcel = {},
    service = {},
    payment = {},
    notes = '',
    items = []
  } = req.body || {};

  const senderName = sanitizeString(sender.name);
  const senderPhone = sanitizeString(sender.phone);
  const senderAddress = sanitizeString(sender.address);
  const receiverName = sanitizeString(receiver.name);
  const receiverPhone = sanitizeString(receiver.phone);
  const receiverAddress = sanitizeString(receiver.address);

  if (!senderName || !senderPhone || !senderAddress || !receiverName || !receiverPhone || !receiverAddress) {
    return res.status(400).json({ error: 'Thiếu thông tin người gửi hoặc người nhận' });
  }

  const serviceType = sanitizeString(service.type).toLowerCase() || 'standard';
  const packageType = sanitizeString(parcel.type) || 'tài liệu';
  const pickupType = sanitizeString(service.pickupType).toLowerCase() || 'door_to_door';

  const weightKg = normalizeNumber(parcel.weightKg, 0.5);
  const chargeableWeight = calculateChargeableWeight({
    weightKg,
    lengthCm: parcel.lengthCm,
    widthCm: parcel.widthCm,
    heightCm: parcel.heightCm
  });
  const shippingFee = calculateShippingFee(chargeableWeight, serviceType);
  const insuranceFee = calculateInsuranceFee(parcel.declaredValue);

  const paymentMethod = sanitizeString(payment.method).toLowerCase() === 'online' ? 'online' : 'cod';
  const codAmount = paymentMethod === 'cod' ? normalizeNumber(payment.codAmount, 0) : 0;
  const totalAmount = shippingFee + insuranceFee + codAmount;

  const { estimatedPickup, estimatedDelivery } = estimateDeliveryWindow(serviceType);

  const paymentStatus =
    paymentMethod === 'online'
      ? 'pending'
      : 'cod_pending';

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const insertOrderResult = await client.query(
      `INSERT INTO orders (
        user_id,
        sender_name,
        sender_phone,
        sender_address,
        sender_city,
        sender_district,
        sender_ward,
        receiver_name,
        receiver_phone,
        receiver_address,
        receiver_city,
        receiver_district,
        receiver_ward,
        package_type,
        service_type,
        pickup_type,
        pickup_notes,
        parcel_weight,
        parcel_length,
        parcel_width,
        parcel_height,
        declared_value,
        cod_amount,
        insurance_fee,
        shipping_fee,
        total_amount,
        payment_method,
        payment_status,
        estimated_pickup,
        estimated_delivery,
        status,
        notes
      )
      VALUES (
        $1, $2, $3, $4, $5, $6, $7,
        $8, $9, $10, $11, $12, $13,
        $14, $15, $16, $17,
        $18, $19, $20, $21,
        $22, $23, $24, $25,
        $26, $27, $28, $29, $30,
        $31, $32
      )
      RETURNING 
        id,
        tracking_number,
        status,
        created_at`,
      [
        userId,
        senderName,
        senderPhone,
        senderAddress,
        sanitizeString(sender.city),
        sanitizeString(sender.district),
        sanitizeString(sender.ward),
        receiverName,
        receiverPhone,
        receiverAddress,
        sanitizeString(receiver.city),
        sanitizeString(receiver.district),
        sanitizeString(receiver.ward),
        packageType,
        serviceType,
        pickupType,
        sanitizeString(service.pickupNotes),
        weightKg,
        normalizeNumber(parcel.lengthCm, null),
        normalizeNumber(parcel.widthCm, null),
        normalizeNumber(parcel.heightCm, null),
        normalizeNumber(parcel.declaredValue, null),
        codAmount,
        insuranceFee,
        shippingFee,
        totalAmount,
        paymentMethod,
        paymentStatus,
        estimatedPickup,
        estimatedDelivery,
        'pending',
        sanitizeString(notes)
      ]
    );

    const newOrder = insertOrderResult.rows[0];
    const orderId = newOrder.id;

    if (Array.isArray(items) && items.length > 0) {
      const insertItemPromises = items
        .filter((item) => sanitizeString(item.name))
        .map((item) =>
          client.query(
            `INSERT INTO order_items (
              order_id,
              item_name,
              quantity,
              weight,
              price
            ) VALUES ($1, $2, $3, $4, $5)`,
            [
              orderId,
              sanitizeString(item.name),
              Math.max(1, parseInt(item.quantity, 10) || 1),
              normalizeNumber(item.weightKg, null),
              normalizeNumber(item.price, null)
            ]
          )
        );

      await Promise.all(insertItemPromises);
    }

    await client.query('COMMIT');

    const order = await fetchOrderDetail(orderId, userId);
    return res.status(201).json({
      message: 'Tạo đơn hàng thành công',
      order
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Create order error:', error);
    return res.status(500).json({ error: 'Không thể tạo đơn hàng, vui lòng thử lại sau' });
  } finally {
    client.release();
  }
});

router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const orderId = parseInt(req.params.id, 10);
    if (Number.isNaN(orderId)) {
      return res.status(400).json({ error: 'ID đơn hàng không hợp lệ' });
    }

    const order = await fetchOrderDetail(orderId, req.user.id);

    if (!order) {
      return res.status(404).json({ error: 'Không tìm thấy đơn hàng' });
    }

    return res.json({
      message: 'Lấy thông tin đơn hàng thành công',
      order
    });
  } catch (error) {
    console.error('Get order detail error:', error);
    return res.status(500).json({ error: 'Không thể lấy thông tin đơn hàng' });
  }
});

router.post('/:id/initiate-payment', authenticateToken, async (req, res) => {
  const orderId = parseInt(req.params.id, 10);
  if (Number.isNaN(orderId)) {
    return res.status(400).json({ error: 'ID đơn hàng không hợp lệ' });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const orderResult = await client.query(
      `SELECT 
        id,
        status,
        payment_method,
        payment_status,
        shipping_fee,
        insurance_fee
      FROM orders
      WHERE id = $1 AND user_id = $2
      FOR UPDATE`,
      [orderId, req.user.id]
    );

    if (orderResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Không tìm thấy đơn hàng' });
    }

    const order = orderResult.rows[0];

    if (order.payment_method !== 'online') {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'Đơn hàng không hỗ trợ thanh toán online' });
    }

    if (order.payment_status === 'paid') {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'Đơn hàng đã được thanh toán' });
    }

    const payableAmount =
      Number(order.shipping_fee || 0) + Number(order.insurance_fee || 0);

    // Hết hạn các giao dịch chờ nhưng đã quá hạn
    await client.query(
      `UPDATE payment_transactions
       SET status = 'expired',
           updated_at = NOW()
       WHERE order_id = $1
         AND status = 'pending'
         AND expires_at IS NOT NULL
         AND expires_at <= NOW()`,
      [orderId]
    );

    // Lấy giao dịch chờ hiện tại (nếu còn hiệu lực)
    const existingTxResult = await client.query(
      `SELECT
        id,
        reference,
        provider,
        amount,
        currency,
        status,
        payment_url,
        signature,
        expires_at,
        paid_amount,
        completed_at,
        created_at,
        updated_at
      FROM payment_transactions
      WHERE order_id = $1
        AND status = 'pending'
      ORDER BY created_at DESC
      LIMIT 1`,
      [orderId]
    );

    let transactionRow = existingTxResult.rows[0];
    let createdNewTransaction = false;

    if (!transactionRow) {
      const reference = `PAY-${Date.now()}-${crypto.randomBytes(4).toString('hex')}`;
      const expiresAt = new Date(Date.now() + PAYMENT_EXPIRATION_MINUTES * 60 * 1000);
      const { url: paymentUrl, signature } = buildPaymentUrl({
        orderId,
        reference,
        amount: payableAmount,
        currency: PAYMENT_CURRENCY
      });

      const insertTxResult = await client.query(
        `INSERT INTO payment_transactions (
          order_id,
          reference,
          provider,
          amount,
          currency,
          status,
          payment_url,
          signature,
          expires_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        RETURNING
          id,
          reference,
          provider,
          amount,
          currency,
          status,
          payment_url,
          signature,
          expires_at,
          paid_amount,
          completed_at,
          created_at,
          updated_at`,
        [
          orderId,
          reference,
          PAYMENT_GATEWAY_PROVIDER,
          payableAmount,
          PAYMENT_CURRENCY,
          'pending',
          paymentUrl,
          signature,
          expiresAt
        ]
      );

      transactionRow = insertTxResult.rows[0];
      createdNewTransaction = true;
    }

    await client.query(
      `UPDATE orders
       SET payment_status = $1,
           payment_reference = $2
       WHERE id = $3`,
      ['pending', transactionRow.reference, orderId]
    );

    if (createdNewTransaction) {
      await client.query(
        `INSERT INTO order_status_history (order_id, status, description, created_by)
         VALUES ($1, $2, $3, $4)`,
        [
          orderId,
          'pending',
          `Khởi tạo thanh toán online - mã tham chiếu ${transactionRow.reference}`,
          'payment-gateway'
        ]
      );
    }

    await client.query('COMMIT');

    return res.json({
      message: createdNewTransaction
        ? 'Khởi tạo thanh toán thành công'
        : 'Giao dịch thanh toán đang chờ được duy trì',
      payment: {
        reference: transactionRow.reference,
        provider: transactionRow.provider,
        amount: Number(transactionRow.amount),
        currency: transactionRow.currency,
        status: transactionRow.status,
        payment_url: transactionRow.payment_url,
        signature: transactionRow.signature,
        expires_at: transactionRow.expires_at
      }
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Initiate payment error:', error);
    return res.status(500).json({ error: 'Không thể khởi tạo thanh toán' });
  } finally {
    client.release();
  }
});

module.exports = router;

