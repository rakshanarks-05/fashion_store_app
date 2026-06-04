import 'package:flutter/material.dart';

import '../../../../core/widgets/product_network_image.dart';
import '../../domain/entities/order_model.dart';
import '../theme/my_orders_tokens.dart';
import 'order_item_row.dart';
import 'order_status_badge.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    this.deliveryMethod = 'Standard Delivery',
    this.statusStyle = OrderStatusBadgeStyle.mockup,
    this.highlighted = false,
    this.onTrack,
    this.onReview,
  });

  final OrderModel order;
  final String deliveryMethod;
  final OrderStatusBadgeStyle statusStyle;
  final bool highlighted;
  final VoidCallback? onTrack;
  final VoidCallback? onReview;

  bool get _isDelivered => order.orderStatus == 'Delivered';

  int get _itemCount {
    var n = 0;
    for (final i in order.items) {
      n += i.quantity;
    }
    if (n == 0) n = order.items.length;
    return n;
  }

  String get _itemCountLabel {
    final n = _itemCount;
    return n == 1 ? '1 item' : '$n items';
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final inner = w - MyOrdersTokens.screenHorizontal * 2;
    final imageW = (inner * 0.28).clamp(88.0, 104.0);

    final highlightColor = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MyOrdersTokens.cardRadius),
        boxShadow: MyOrdersTokens.cardShadows,
        color: Colors.white,
        border: highlighted
            ? Border.all(color: highlightColor.withValues(alpha: 0.45), width: 2)
            : null,
      ),
      padding: const EdgeInsets.all(MyOrdersTokens.cardInnerPadding),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
                SizedBox(
                  width: imageW,
                  child: _OrderImageCollage(
                    items: order.items,
                    imageRadius: MyOrdersTokens.imageRadius,
                    layoutSize: imageW,
                  ),
                ),
            const SizedBox(width: 12),
            Expanded(
              child: OrderItemRow(
                orderId: order.orderId,
                deliveryMethod: deliveryMethod,
                orderStatus: order.orderStatus,
                statusStyle: statusStyle,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 76,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ItemCountPill(label: _itemCountLabel),
                  _isDelivered
                      ? _ReviewButton(onPressed: onReview)
                      : _TrackButton(onPressed: onTrack),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemCountPill extends StatelessWidget {
  const _ItemCountPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: MyOrdersTokens.itemCountPill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: MyOrdersTokens.textPrimary,
          fontSize: MyOrdersTokens.itemCount,
          fontWeight: FontWeight.w600,
          height: 1.1,
        ),
      ),
    );
  }
}

class _TrackButton extends StatelessWidget {
  const _TrackButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: MyOrdersTokens.primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: const Text('Track'),
      ),
    );
  }
}

class _ReviewButton extends StatelessWidget {
  const _ReviewButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: MyOrdersTokens.primaryBlue,
          side: const BorderSide(color: MyOrdersTokens.primaryBlue, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: const Text('Review'),
      ),
    );
  }
}

class _OrderImageCollage extends StatelessWidget {
  const _OrderImageCollage({
    required this.items,
    required this.imageRadius,
    required this.layoutSize,
  });

  final List<OrderLineItemModel> items;
  final double imageRadius;
  final double layoutSize;

  List<String> get _urls {
    final urls = <String>[];
    for (final i in items) {
      for (var q = 0; q < i.quantity && urls.length < 8; q++) {
        urls.add(i.imageUrl);
      }
    }
    if (urls.isEmpty) {
      return [''];
    }
    return urls;
  }

  @override
  Widget build(BuildContext context) {
    final urls = _urls;
    if (urls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(imageRadius),
        child: SizedBox(
          width: layoutSize,
          height: layoutSize,
          child: ProductNetworkImage(imageUrl: urls.first, fit: BoxFit.cover),
        ),
      );
    }
    if (urls.length == 2) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(imageRadius),
        child: SizedBox(
          width: layoutSize,
          height: layoutSize,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ProductNetworkImage(
                  imageUrl: urls[0],
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: ProductNetworkImage(
                  imageUrl: urls[1],
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final u0 = urls.isNotEmpty ? urls[0] : '';
    final u1 = urls.length > 1 ? urls[1] : u0;
    final u2 = urls.length > 2 ? urls[2] : u0;
    final u3 = urls.length > 3 ? urls[3] : '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(imageRadius),
      child: SizedBox(
        width: layoutSize,
        height: layoutSize,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: ProductNetworkImage(imageUrl: u0, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: ProductNetworkImage(imageUrl: u1, fit: BoxFit.cover),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: ProductNetworkImage(imageUrl: u2, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: u3.isEmpty
                        ? ColoredBox(
                            color: const Color(0xFFE0E0E0),
                            child: const SizedBox.expand(),
                          )
                        : ProductNetworkImage(imageUrl: u3, fit: BoxFit.cover),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
