import 'package:flutter/material.dart';

import '../screens/my_orders_screen.dart';

/// Entry route for My Orders (Firestore-backed list for the signed-in user).
class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final highlightOrderId = args is String && args.trim().isNotEmpty ? args.trim() : null;
    return MyOrdersScreen(highlightOrderId: highlightOrderId);
  }
}
