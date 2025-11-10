import '../config/api_config.dart';
import '../models/order.dart';
import '../models/order_form_data.dart';
import 'api_service.dart';

class OrderService {
  static Future<List<Order>> getMyOrders() async {
    try {
      final response = await ApiService.get(ApiConfig.myOrders);
      if (response['orders'] != null) {
        return (response['orders'] as List<dynamic>)
            .map((json) => Order.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Không thể tải danh sách đơn hàng: $e');
    }
  }

  static Future<Order> createOrder(OrderFormData data) async {
    try {
      final response = await ApiService.post(
        ApiConfig.orders,
        data.toJson(),
      );
      if (response['order'] != null) {
        return Order.fromJson(response['order'] as Map<String, dynamic>);
      }
      throw Exception('API không trả về dữ liệu đơn hàng');
    } catch (e) {
      throw Exception('Không thể tạo đơn hàng: $e');
    }
  }

  static Future<Order> getOrderDetail(int id) async {
    try {
      final response = await ApiService.get(ApiConfig.orderDetail(id));
      if (response['order'] != null) {
        return Order.fromJson(response['order'] as Map<String, dynamic>);
      }
      throw Exception('API không trả về dữ liệu đơn hàng');
    } catch (e) {
      throw Exception('Không thể lấy thông tin đơn hàng: $e');
    }
  }

  static Future<PaymentInitResult> initiateOnlinePayment(int id) async {
    try {
      final response = await ApiService.post(ApiConfig.initiatePayment(id), {});
      if (response['payment'] != null) {
        return PaymentInitResult.fromJson(
          response['payment'] as Map<String, dynamic>,
        );
      }
      throw Exception('API không trả về thông tin thanh toán');
    } catch (e) {
      throw Exception('Không thể khởi tạo thanh toán: $e');
    }
  }
}

