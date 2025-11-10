const express = require('express');
const crypto = require('crypto');
const router = express.Router();
const pool = require('../config/database');

const PAYMENT_GATEWAY_SECRET = process.env.PAYMENT_GATEWAY_SECRET || 'mock_secret_123';

const normalizeStatus = (status) => {
  if (!status) return null;
  return String(status).trim().toLowerCase();
};

const mapGatewayStatus = (status) => {
  switch (status) {
    case 'success':
      return 'succeeded';
    case 'failed':
      return 'failed';
    case 'cancelled':
      return 'cancelled';
    default:
      return status;
  }
};

const buildWebhookSignature = ({ orderId, reference, status, paidAmount }) => {
  const payload = `${orderId}|${reference}|${status}|${paidAmount ?? ''}`;
  return crypto.createHmac('sha256', PAYMENT_GATEWAY_SECRET).update(payload).digest('hex');
};

const applyPaymentUpdate = async ({
  client,
  order,
  transaction,
  normalizedStatus,
  paidAmount,
  payload,
  reference
}) => {
  if (
    transaction.status === 'succeeded' &&
    normalizedStatus === 'success' &&
    order.payment_status === 'paid'
  ) {
    return { alreadyProcessed: true, mappedStatus: mapGatewayStatus(normalizedStatus) };
  }

  const mappedStatus = mapGatewayStatus(normalizedStatus);
  const paidAmountNumber =
    paidAmount !== undefined && paidAmount !== null ? Number(paidAmount) : null;

  await client.query(
    `UPDATE payment_transactions
     SET status = $1,
         paid_amount = $2,
         gateway_payload = $3::jsonb,
         completed_at = CASE WHEN $4 THEN NOW() ELSE completed_at END,
         updated_at = NOW()
     WHERE id = $5`,
    [
      mappedStatus,
      paidAmountNumber,
      JSON.stringify(payload ?? { source: 'mock_gateway' }),
      mappedStatus === 'succeeded',
      transaction.id
    ]
  );

  switch (normalizedStatus) {
    case 'success': {
      await client.query('SELECT set_config($1, $2, true)', [
        'order.status_change_description',
        paidAmountNumber !== null
          ? `Thanh toán online thành công - số tiền: ${paidAmountNumber} VND (ref: ${reference})`
          : `Thanh toán online thành công (ref: ${reference})`
      ]);
      await client.query('SELECT set_config($1, $2, true)', [
        'order.status_change_actor',
        'payment-gateway'
      ]);

      await client.query(
        `UPDATE orders
         SET payment_status = $1,
             status = CASE
               WHEN status IN ('pending', 'cod_pending') THEN 'processing'
               ELSE status
             END,
             total_amount = shipping_fee + insurance_fee,
             updated_at = CURRENT_TIMESTAMP
         WHERE id = $2`,
        ['paid', order.id]
      );
      break;
    }
    case 'failed': {
      await client.query(
        `UPDATE orders
         SET payment_status = $1,
             updated_at = CURRENT_TIMESTAMP
         WHERE id = $2`,
        ['failed', order.id]
      );
      await client.query(
        `INSERT INTO order_status_history (order_id, status, description, created_by)
         VALUES ($1, $2, $3, $4)`,
        [
          order.id,
          order.status,
          `Thanh toán online thất bại (ref: ${reference})`,
          'payment-gateway'
        ]
      );
      break;
    }
    case 'cancelled': {
      await client.query(
        `UPDATE orders
         SET payment_status = $1,
             updated_at = CURRENT_TIMESTAMP
         WHERE id = $2`,
        ['cancelled', order.id]
      );
      await client.query(
        `INSERT INTO order_status_history (order_id, status, description, created_by)
         VALUES ($1, $2, $3, $4)`,
        [
          order.id,
          order.status,
          `Thanh toán online bị hủy (ref: ${reference})`,
          'payment-gateway'
        ]
      );
      break;
    }
    default:
      break;
  }

  return { alreadyProcessed: false, mappedStatus };
};

router.post('/webhook', async (req, res) => {
  const { order_id: orderId, reference, status, paid_amount: paidAmount } = req.body || {};
  const providedSignature = req.body?.signature;

  if (!orderId || !reference || !status) {
    return res.status(400).json({ error: 'Thiếu thông tin bắt buộc trong webhook payload' });
  }

  const normalizedStatus = normalizeStatus(status);

  if (!['success', 'failed', 'cancelled'].includes(normalizedStatus)) {
    return res.status(400).json({ error: 'Trạng thái thanh toán không hợp lệ' });
  }

  if (!providedSignature) {
    return res.status(400).json({ error: 'Thiếu chữ ký (signature) trong payload' });
  }

  const expectedSignature = buildWebhookSignature({
    orderId,
    reference,
    status: normalizedStatus,
    paidAmount: paidAmount ?? ''
  });

  if (expectedSignature !== providedSignature) {
    return res.status(401).json({ error: 'Chữ ký không hợp lệ' });
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const orderResult = await client.query(
      `SELECT 
        id,
        user_id,
        payment_method,
        payment_status,
        payment_reference,
        status,
        shipping_fee,
        insurance_fee,
        total_amount
       FROM orders
       WHERE id = $1
       FOR UPDATE`,
      [orderId]
    );

    if (orderResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Không tìm thấy đơn hàng' });
    }

    const order = orderResult.rows[0];

    if (order.payment_method !== 'online') {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'Đơn hàng không đăng ký thanh toán online' });
    }

    if (!order.payment_reference || order.payment_reference !== reference) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'Không khớp tham chiếu thanh toán' });
    }

    if (order.payment_status === 'paid' && normalizedStatus === 'success') {
      await client.query('ROLLBACK');
      return res.status(200).json({
        message: 'Đơn hàng đã được cập nhật trước đó',
        order_id: orderId
      });
    }

    const transactionResult = await client.query(
      `SELECT
        id,
        status,
        reference
       FROM payment_transactions
       WHERE order_id = $1 AND reference = $2
       ORDER BY created_at DESC
       LIMIT 1
       FOR UPDATE`,
      [orderId, reference]
    );

    if (transactionResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Không tìm thấy giao dịch thanh toán' });
    }

    const transaction = transactionResult.rows[0];

    const { alreadyProcessed, mappedStatus } = await applyPaymentUpdate({
      client,
      order,
      transaction,
      normalizedStatus,
      paidAmount,
      payload: req.body,
      reference
    });

    if (alreadyProcessed) {
      await client.query('ROLLBACK');
      return res.status(200).json({
        message: 'Giao dịch đã được cập nhật trước đó',
        order_id: orderId,
        reference,
        payment_status: mappedStatus
      });
    }

    await client.query('COMMIT');

    return res.json({
      message: 'Webhook xử lý thành công',
      order_id: orderId,
      reference,
      payment_status: mappedStatus
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Payment webhook error:', error);
    return res.status(500).json({ error: 'Không thể xử lý webhook' });
  } finally {
    client.release();
  }
});

router.get('/mock/checkout', async (req, res) => {
  const { orderId, ref: reference } = req.query;

  if (!orderId || !reference) {
    return res
      .status(400)
      .send('Thiếu tham số orderId hoặc ref để hiển thị trang thanh toán.');
  }

  const client = await pool.connect();

  try {
    const result = await client.query(
      `SELECT
        pt.order_id,
        pt.reference,
        pt.amount,
        pt.currency,
        pt.status,
        pt.expires_at,
        pt.created_at,
        o.tracking_number,
        o.receiver_name,
        o.payment_status
       FROM payment_transactions pt
       JOIN orders o ON o.id = pt.order_id
       WHERE pt.order_id = $1
         AND pt.reference = $2
       ORDER BY pt.created_at DESC
       LIMIT 1`,
      [orderId, reference]
    );

    if (result.rows.length === 0) {
      return res
        .status(404)
        .send('Không tìm thấy giao dịch thanh toán tương ứng.');
    }

    const tx = result.rows[0];
    const amount = Number(tx.amount || 0);
    const amountFormatted = amount.toLocaleString('vi-VN');
    const expiresAt = tx.expires_at
      ? new Date(tx.expires_at).toLocaleString('vi-VN')
      : 'Không xác định';
    const createdAt = tx.created_at
      ? new Date(tx.created_at).toLocaleString('vi-VN')
      : '';

    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.send(`<!DOCTYPE html>
<html lang="vi">
  <head>
    <meta charset="utf-8" />
    <title>J&T Express - Cổng thanh toán mô phỏng</title>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <style>
      body {
        font-family: "Segoe UI", Roboto, sans-serif;
        background: #f5f6fb;
        margin: 0;
        padding: 0;
        color: #1f1f1f;
      }
      .container {
        max-width: 560px;
        margin: 32px auto;
        background: #fff;
        border-radius: 16px;
        box-shadow: 0 12px 32px rgba(16, 24, 40, 0.12);
        padding: 32px;
      }
      h1 {
        font-size: 22px;
        margin-bottom: 8px;
        color: #c02026;
      }
      .badge {
        display: inline-block;
        padding: 4px 12px;
        border-radius: 999px;
        font-size: 12px;
        font-weight: 600;
        background: #fbe9ea;
        color: #c02026;
        margin-bottom: 18px;
      }
      .info-line {
        display: flex;
        justify-content: space-between;
        font-size: 15px;
        margin-bottom: 10px;
      }
      .info-line span:first-child {
        color: #6f7787;
      }
      .card {
        border: 1px solid #e5e7ef;
        border-radius: 12px;
        padding: 20px;
        margin: 20px 0;
        background: #fafafa;
      }
      .card h2 {
        margin: 0 0 12px 0;
        font-size: 18px;
      }
      .card label {
        display: block;
        margin-bottom: 6px;
        font-weight: 600;
        color: #394150;
      }
      .card input, .card select {
        width: 100%;
        padding: 10px 12px;
        border-radius: 8px;
        border: 1px solid #cdd5df;
        margin-bottom: 12px;
        font-size: 15px;
      }
      .action-buttons {
        display: flex;
        gap: 12px;
        flex-wrap: wrap;
        margin-top: 12px;
      }
      button {
        flex: 1;
        min-width: 160px;
        padding: 12px;
        border: none;
        border-radius: 10px;
        cursor: pointer;
        font-size: 15px;
        font-weight: 600;
      }
      .btn-success {
        background: linear-gradient(135deg, #12b76a, #079455);
        color: #fff;
      }
      .btn-failed {
        background: linear-gradient(135deg, #f04438, #d92d20);
        color: #fff;
      }
      .btn-cancel {
        background: #f2f4f7;
        color: #475467;
      }
      .divider {
        height: 1px;
        background: #e4e7ec;
        margin: 20px 0;
      }
      .bank-info {
        background: #f9fafb;
        border-radius: 12px;
        padding: 16px;
        border: 1px dashed #cdd5df;
      }
      .bank-info h3 {
        margin-top: 0;
        font-size: 16px;
        color: #183153;
      }
      .bank-info p {
        margin: 6px 0;
        font-size: 14px;
      }
      .result {
        margin-top: 16px;
        padding: 12px 16px;
        border-radius: 10px;
        display: none;
        font-weight: 600;
      }
      .result.success {
        background: #ecfdf3;
        color: #027a48;
      }
      .result.error {
        background: #fef3f2;
        color: #b42318;
      }
    </style>
  </head>
  <body>
    <div class="container">
      <div class="badge">J&T Express - Sandbox</div>
      <h1>Thanh toán đơn hàng #${reference}</h1>
      <div class="info-line">
        <span>Mã vận đơn:</span>
        <span>${tx.tracking_number || 'Chưa cấp'}</span>
      </div>
      <div class="info-line">
        <span>Tên người nhận:</span>
        <span>${tx.receiver_name || '---'}</span>
      </div>
      <div class="info-line">
        <span>Số tiền cần thanh toán:</span>
        <span><strong>${amountFormatted} ${tx.currency || 'VND'}</strong></span>
      </div>
      <div class="info-line">
        <span>Trạng thái đơn:</span>
        <span>${tx.payment_status || 'pending'}</span>
      </div>
      <div class="info-line">
        <span>Thời gian tạo giao dịch:</span>
        <span>${createdAt}</span>
      </div>
      <div class="info-line">
        <span>Hết hạn thanh toán:</span>
        <span>${expiresAt}</span>
      </div>

      <div class="bank-info">
        <h3>Thông tin chuyển khoản</h3>
        <p>Ngân hàng: Vietcombank - CN TP.HCM</p>
        <p>Số tài khoản: <strong>1023 4567 888</strong></p>
        <p>Tên thụ hưởng: <strong>CTY CP GIAO NHAN J&T EXPRESS</strong></p>
        <p>Nội dung chuyển khoản: <strong>${reference}</strong></p>
      </div>

      <div class="card">
        <h2>Nhập thông tin thẻ (mô phỏng)</h2>
        <label>Số thẻ</label>
        <input id="card-number" placeholder="4111 1111 1111 1111" />
        <label>Họ tên trên thẻ</label>
        <input id="card-name" placeholder="NGUYEN VAN A" />
        <div style="display: flex; gap: 12px;">
          <div style="flex: 1;">
            <label>MM/YY</label>
            <input id="card-exp" placeholder="12/28" />
          </div>
          <div style="flex: 1;">
            <label>CVV</label>
            <input id="card-cvv" placeholder="123" />
          </div>
        </div>
        <label>Số tiền sẽ thanh toán (VND)</label>
        <input id="paid-amount" type="number" value="${amount}" />

        <div class="action-buttons">
          <button class="btn-success" id="btn-success">Thanh toán thành công</button>
          <button class="btn-failed" id="btn-failed">Thanh toán thất bại</button>
          <button class="btn-cancel" id="btn-cancel">Hủy giao dịch</button>
        </div>
        <div class="result" id="result"></div>
      </div>

      <p style="font-size: 13px; color: #6f7787;">
        * Đây là môi trường sandbox phục vụ thử nghiệm đồ án. Không ghi nhận giao dịch tài chính thật.
      </p>
    </div>

    <script>
      const apiEndpoint = '/api/payment/mock/${reference}/complete';
      const resultBox = document.getElementById('result');

      async function sendStatus(status) {
        resultBox.style.display = 'none';
        const paidAmountInput = document.getElementById('paid-amount');
        const paidAmountValue = paidAmountInput.value ? Number(paidAmountInput.value) : null;

        try {
          const response = await fetch(apiEndpoint, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              status,
              paid_amount: status === 'success' ? paidAmountValue : null
            })
          });

          const data = await response.json();
          if (!response.ok) {
            throw new Error(data.error || 'Giao dịch thất bại.');
          }

          resultBox.textContent = data.message || 'Đã cập nhật trạng thái thanh toán.';
          resultBox.className = 'result success';
          resultBox.style.display = 'block';
        } catch (error) {
          resultBox.textContent = error.message;
          resultBox.className = 'result error';
          resultBox.style.display = 'block';
        }
      }

      document.getElementById('btn-success').addEventListener('click', () => sendStatus('success'));
      document.getElementById('btn-failed').addEventListener('click', () => sendStatus('failed'));
      document.getElementById('btn-cancel').addEventListener('click', () => sendStatus('cancelled'));
    </script>
  </body>
</html>`);
  } catch (error) {
    console.error('Render mock checkout error:', error);
    res.status(500).send('Không thể hiển thị trang thanh toán.');
  } finally {
    client.release();
  }
});

router.post('/mock/:reference/complete', async (req, res) => {
  const { reference } = req.params;
  const { status, paid_amount: paidAmount } = req.body || {};
  const normalizedStatus = normalizeStatus(status);

  if (!['success', 'failed', 'cancelled'].includes(normalizedStatus)) {
    return res.status(400).json({ error: 'Trạng thái không hợp lệ.' });
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const transactionResult = await client.query(
      `SELECT
        id,
        order_id,
        status,
        amount,
        currency
       FROM payment_transactions
       WHERE reference = $1
       ORDER BY created_at DESC
       LIMIT 1
       FOR UPDATE`,
      [reference]
    );

    if (transactionResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Không tìm thấy giao dịch.' });
    }

    const transaction = transactionResult.rows[0];

    const orderResult = await client.query(
      `SELECT 
        id,
        user_id,
        payment_method,
        payment_status,
        payment_reference,
        status,
        shipping_fee,
        insurance_fee,
        total_amount
       FROM orders
       WHERE id = $1
       FOR UPDATE`,
      [transaction.order_id]
    );

    if (orderResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Không tìm thấy đơn hàng.' });
    }

    const order = orderResult.rows[0];

    if (order.payment_method !== 'online') {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'Đơn hàng không đăng ký thanh toán online' });
    }

    if (!order.payment_reference || order.payment_reference !== reference) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'Mã tham chiếu không trùng khớp đơn hàng' });
    }

    const { alreadyProcessed, mappedStatus } = await applyPaymentUpdate({
      client,
      order,
      transaction,
      normalizedStatus,
      paidAmount: paidAmount ?? transaction.amount,
      payload: {
        source: 'mock_gateway_page',
        status: normalizedStatus,
        paid_amount: paidAmount ?? transaction.amount,
        completed_at: new Date().toISOString()
      },
      reference
    });

    if (alreadyProcessed) {
      await client.query('ROLLBACK');
      return res.status(200).json({
        message: 'Giao dịch đã được xử lý trước đó.',
        order_id: order.id,
        reference,
        payment_status: mappedStatus
      });
    }

    await client.query('COMMIT');

    return res.json({
      message: 'Đã cập nhật trạng thái thanh toán mock.',
      order_id: order.id,
      reference,
      payment_status: mappedStatus
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Mock payment completion error:', error);
    return res.status(500).json({ error: 'Không thể cập nhật giao dịch mock.' });
  } finally {
    client.release();
  }
});

module.exports = router;


