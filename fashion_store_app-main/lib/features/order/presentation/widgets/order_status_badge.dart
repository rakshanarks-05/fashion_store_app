import 'package:flutter/material.dart';

import '../theme/my_orders_tokens.dart';

/// How status is rendered: mockup matches the reference (bold black + blue check for delivered).
enum OrderStatusBadgeStyle {
  mockup,
  semantic,
}

/// Maps backend [orderStatus] strings to on-screen labels (e.g. Processing → Packed).
String orderStatusDisplayLabel(String orderStatus) {
  switch (orderStatus) {
    case 'Processing':
      return 'Packed';
    case 'Shipped':
      return 'Shipped';
    case 'Delivered':
      return 'Delivered';
    case 'Placed':
      return 'Pending';
    case 'Cancelled':
      return 'Cancelled';
    default:
      return orderStatus;
  }
}

Color orderStatusSemanticColor(String orderStatus) {
  switch (orderStatus) {
    case 'Delivered':
      return const Color(0xFF2E7D32);
    case 'Processing':
    case 'Shipped':
      return const Color(0xFFE65100);
    case 'Cancelled':
      return const Color(0xFFC62828);
    case 'Placed':
    default:
      return const Color(0xFF757575);
  }
}

/// Reusable order status: mockup style (screenshot) or semantic pill colors.
class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({
    super.key,
    required this.orderStatus,
    this.style = OrderStatusBadgeStyle.mockup,
  });

  final String orderStatus;
  final OrderStatusBadgeStyle style;

  @override
  Widget build(BuildContext context) {
    final label = orderStatusDisplayLabel(orderStatus);
    final delivered = orderStatus == 'Delivered';

    if (style == OrderStatusBadgeStyle.semantic) {
      final bg = orderStatusSemanticColor(orderStatus).withValues(alpha: 0.12);
      final fg = orderStatusSemanticColor(orderStatus);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: MyOrdersTokens.statusLine,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: MyOrdersTokens.textPrimary,
            fontSize: MyOrdersTokens.statusLine,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        if (delivered) ...[
          const SizedBox(width: 4),
          Icon(
            Icons.check_circle,
            size: 18,
            color: MyOrdersTokens.primaryBlue,
          ),
        ],
      ],
    );
  }
}
