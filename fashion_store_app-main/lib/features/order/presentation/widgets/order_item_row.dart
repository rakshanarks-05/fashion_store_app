import 'package:flutter/material.dart';

import '../theme/my_orders_tokens.dart';
import 'order_status_badge.dart';

/// Middle column: order id, delivery line, status (aligned to design reference).
class OrderItemRow extends StatelessWidget {
  const OrderItemRow({
    super.key,
    required this.orderId,
    required this.deliveryMethod,
    required this.orderStatus,
    this.statusStyle = OrderStatusBadgeStyle.mockup,
  });

  final String orderId;
  final String deliveryMethod;
  final String orderStatus;
  final OrderStatusBadgeStyle statusStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order #$orderId',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: MyOrdersTokens.textPrimary,
                fontSize: MyOrdersTokens.cardTitle,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              deliveryMethod,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: MyOrdersTokens.textSecondary,
                fontSize: MyOrdersTokens.cardMeta,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ],
        ),
        OrderStatusBadge(orderStatus: orderStatus, style: statusStyle),
      ],
    );
  }
}
