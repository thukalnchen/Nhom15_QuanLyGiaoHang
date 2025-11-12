// 📋 HOW TO USE STORIES #20-24 SCREENS

import 'package:flutter/material.dart';
import 'stories_20_24_management.dart';

class ScreenManagementExample {
  /// Example 1: Get all Stories #20-24 routes
  static void exampleGetAllRoutes() {
    final allRoutes = <String, WidgetBuilder>{};
    
    // Story #20: Orders Management
    allRoutes.addAll(OrdersManagementScreens.getRoutes(null));
    
    // Story #21: Driver Assignment
    allRoutes.addAll(DriverAssignmentScreens.getRoutes(null));
    
    // Story #22: Route Management
    allRoutes.addAll(RouteManagementScreens.getRoutes(null));
    
    // Story #23: Pricing Policy
    allRoutes.addAll(PricingPolicyScreens.getRoutes(null));
    
    // Story #24: Reporting
    allRoutes.addAll(ReportingScreens.getRoutes(null));
  }

  /// Example 2: Navigate to Orders List
  static void navigateToOrdersList(BuildContext context) {
    Navigator.pushNamed(
      context,
      OrdersManagementScreens.ordersListScreen,
    );
  }

  /// Example 3: Navigate to Driver Assignment
  static void navigateToAssignDriver(BuildContext context) {
    Navigator.pushNamed(
      context,
      DriverAssignmentScreens.assignDriverScreen,
    );
  }

  /// Example 4: Navigate to Dashboard
  static void navigateToDashboard(BuildContext context) {
    Navigator.pushNamed(
      context,
      ReportingScreens.dashboardScreen,
    );
  }

  /// Example 5: Setup routes in MaterialApp
  static Map<String, WidgetBuilder> setupStoriesRoutes() {
    final routes = <String, WidgetBuilder>{};
    
    // Add all Stories #20-24 routes
    routes.addAll(OrdersManagementScreens.getRoutes(null));
    routes.addAll(DriverAssignmentScreens.getRoutes(null));
    routes.addAll(RouteManagementScreens.getRoutes(null));
    routes.addAll(PricingPolicyScreens.getRoutes(null));
    routes.addAll(ReportingScreens.getRoutes(null));
    
    return routes;
  }
}

/// Integration in main.dart:
/// 
/// ```dart
/// void main() {
///   runApp(const MyApp());
/// }
/// 
/// class MyApp extends StatelessWidget {
///   const MyApp({Key? key}) : super(key: key);
/// 
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       title: 'Food Delivery App',
///       theme: ThemeData(primarySwatch: Colors.blue),
///       home: const SplashScreen(),
///       routes: {
///         // Add Stories #20-24 routes
///         ...ScreenManagementExample.setupStoriesRoutes(),
///         // Add other existing routes
///       },
///     );
///   }
/// }
/// ```

// ==================== SCREEN CONSTANTS ====================

class StoriesScreenRoutes {
  // Story #20
  static const ordersListScreen = 'orders_list';
  static const orderDetailsScreen = 'order_details';
  static const updateOrderStatusScreen = 'update_order_status';
  static const updateOrderDetailsScreen = 'update_order_details';
  static const orderStatisticsScreen = 'order_statistics';

  // Story #21
  static const availableDriversScreen = 'available_drivers';
  static const assignDriverScreen = 'assign_driver';
  static const reassignDriverScreen = 'reassign_driver';
  static const driverWorkloadScreen = 'driver_workload';

  // Story #22
  static const zonesListScreen = 'zones_list';
  static const createZoneScreen = 'create_zone';
  static const updateZoneScreen = 'update_zone';
  static const deleteZoneScreen = 'delete_zone';
  static const zoneSearchScreen = 'zone_search';
  static const routesListScreen = 'routes_list';
  static const createRouteScreen = 'create_route';
  static const updateRouteScreen = 'update_route';

  // Story #23
  static const pricingTableScreen = 'pricing_table';
  static const updatePricingScreen = 'update_pricing';
  static const surchargesScreen = 'surcharges';
  static const createSurchargeScreen = 'create_surcharge';
  static const updateSurchargeScreen = 'update_surcharge';
  static const discountsScreen = 'discounts';
  static const createDiscountScreen = 'create_discount';
  static const validateDiscountScreen = 'validate_discount';

  // Story #24
  static const revenueReportScreen = 'revenue_report';
  static const deliveryStatsScreen = 'delivery_stats';
  static const driverPerformanceScreen = 'driver_performance';
  static const customerAnalyticsScreen = 'customer_analytics';
  static const dashboardScreen = 'dashboard';
}

// ==================== TOTAL SCREENS: 28 ====================
// Story #20: 5 screens
// Story #21: 4 screens
// Story #22: 8 screens
// Story #23: 8 screens
// Story #24: 5 screens
