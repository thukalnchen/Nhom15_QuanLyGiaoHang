import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
	// Tự động chọn host phù hợp:
	// - Web (Chrome): localhost
	// - Android Emulator: 10.0.2.2 (trỏ tới máy host)
	static String get baseUrl {
		final host = kIsWeb ? 'localhost' : '10.0.2.2';
		return 'http://$host:3000/api';
	}

	// Endpoints
	static const String register = '/auth/register';
	static const String login = '/auth/login';
	static const String myOrders = '/users/me/orders';
	static const String orders = '/orders';
	static const String feedbacks = '/feedbacks';
	static const String notifications = '/users/me/notifications';

	static String orderDetail(int id) => '/orders/$id';
	static String initiatePayment(int id) => '/orders/$id/initiate-payment';
}

