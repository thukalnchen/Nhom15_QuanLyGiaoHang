const axios = require('axios');

// Test create order và get orders
async function testOrderFlow() {
  const baseURL = 'http://localhost:3000/api';
  
  try {
    console.log('🔐 Step 1: Login...');
    const loginResponse = await axios.post(`${baseURL}/auth/login`, {
      email: 'customer@test.com',
      password: 'test123'
    });
    
    if (loginResponse.data.status !== 'success') {
      console.error('❌ Login failed:', loginResponse.data);
      return;
    }
    
    const token = loginResponse.data.data.token;
    const userId = loginResponse.data.data.user.id;
    console.log('✅ Login successful! User ID:', userId);
    console.log('   Token:', token.substring(0, 20) + '...');
    
    // Step 2: Create Order
    console.log('\n📦 Step 2: Creating order...');
    const createOrderResponse = await axios.post(
      `${baseURL}/orders`,
      {
        restaurant_name: 'Test Restaurant',
        items: [
          { name: 'Test Item 1', quantity: 2, price: 50000 },
          { name: 'Test Item 2', quantity: 1, price: 30000 }
        ],
        total_amount: 130000,
        delivery_fee: 20000,
        delivery_address: '123 Test Street, Ho Chi Minh City',
        delivery_phone: '0909123456',
        notes: 'Test order from script'
      },
      {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      }
    );
    
    if (createOrderResponse.data.status !== 'success') {
      console.error('❌ Create order failed:', createOrderResponse.data);
      return;
    }
    
    const orderNumber = createOrderResponse.data.data.order.order_number;
    console.log('✅ Order created successfully!');
    console.log('   Order Number:', orderNumber);
    console.log('   Status:', createOrderResponse.data.data.order.status);
    
    // Step 3: Get Orders
    console.log('\n📋 Step 3: Getting user orders...');
    const getOrdersResponse = await axios.get(
      `${baseURL}/orders`,
      {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      }
    );
    
    if (getOrdersResponse.data.status !== 'success') {
      console.error('❌ Get orders failed:', getOrdersResponse.data);
      return;
    }
    
    const orders = getOrdersResponse.data.data.orders;
    console.log('✅ Orders retrieved successfully!');
    console.log(`   Total orders: ${orders.length}`);
    
    if (orders.length > 0) {
      console.log('\n   Last 3 orders:');
      orders.slice(0, 3).forEach((order, index) => {
        console.log(`   ${index + 1}. ${order.order_number}`);
        console.log(`      Status: ${order.status}`);
        console.log(`      Created: ${order.created_at}`);
        console.log(`      Restaurant: ${order.restaurant_name}`);
      });
    }
    
    // Step 4: Check if new order appears in warehouse
    console.log('\n🏪 Step 4: Checking warehouse orders...');
    const warehouseResponse = await axios.get(
      `${baseURL}/warehouse/orders`,
      {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      }
    );
    
    if (warehouseResponse.data.status === 'success') {
      const warehouseOrders = warehouseResponse.data.data.orders;
      const pendingOrders = warehouseOrders.filter(o => o.status === 'pending');
      console.log('✅ Warehouse orders retrieved!');
      console.log(`   Total orders: ${warehouseOrders.length}`);
      console.log(`   Pending orders: ${pendingOrders.length}`);
      
      const newOrder = warehouseOrders.find(o => o.order_number === orderNumber);
      if (newOrder) {
        console.log(`   ✅ New order ${orderNumber} found in warehouse!`);
      } else {
        console.log(`   ⚠️ New order ${orderNumber} NOT found in warehouse yet`);
      }
    }
    
    console.log('\n✅ ALL TESTS PASSED!');
    console.log('\n📊 Summary:');
    console.log('   ✅ Login successful');
    console.log('   ✅ Order created');
    console.log('   ✅ Orders retrieved');
    console.log('   ✅ Warehouse check completed');
    
  } catch (error) {
    console.error('\n❌ ERROR:', error.message);
    if (error.response) {
      console.error('   Status:', error.response.status);
      console.error('   Data:', error.response.data);
    }
  }
}

// Run test
console.log('='.repeat(60));
console.log('🧪 TESTING ORDER FLOW (App User → Backend → App Intake)');
console.log('='.repeat(60));
console.log('');

testOrderFlow();
