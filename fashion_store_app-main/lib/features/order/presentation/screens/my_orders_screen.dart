import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../product/presentation/widgets/shop_bottom_navigation_bar.dart';
import '../../domain/entities/order_model.dart';
import '../providers/order_providers.dart';
import '../theme/my_orders_tokens.dart';
import '../widgets/order_card.dart';

/// My Orders — pixel-aligned with the design reference ("To Recieve" title as in mockup).
class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key, this.highlightOrderId});

  final String? highlightOrderId;

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> {
  /// Avoids creating a new [Stream] each build (which would reset [StreamBuilder]).
  String? _streamUid;
  Stream<List<OrderModel>>? _ordersStream;

  _OrdersFilter _filter = _OrdersFilter.toReceive;
  String? _pendingHighlightId;

  Stream<List<OrderModel>> _ordersStreamForUid(String? uid) {
    if (uid == _streamUid && _ordersStream != null) return _ordersStream!;
    _streamUid = uid;
    if (uid == null || uid.isEmpty) {
      _ordersStream = Stream<List<OrderModel>>.value(<OrderModel>[]);
    } else {
      _ordersStream =
          ref.read(orderServiceProvider).watchUserOrdersStream(uid);
    }
    return _ordersStream!;
  }

  Future<void> _onRefresh() async {
    setState(() {
      _streamUid = null;
      _ordersStream = null;
    });
    await Future<void>.delayed(Duration.zero);
  }

  void _onNavTap(BuildContext context, int index) {
    final nav = Navigator.of(context);
    switch (index) {
      case 0:
        nav.pushNamedAndRemoveUntil('/', (r) => false);
        break;
      case 1:
        nav.pushNamed('/wishlist');
        break;
      case 2:
        break;
      case 3:
        nav.pushNamed('/cart');
        break;
      case 4:
        nav.pushNamed('/profile');
        break;
    }
  }

  String _ordersErrorMessage(Object error) {
    if (error is FirebaseException && error.code == 'failed-precondition') {
      return 'Orders could not be loaded. Add a Firestore index for '
          'collection "orders" on fields userId (Ascending) and '
          'createdAt (Descending), then try again.';
    }
    return 'Something went wrong while loading your orders. Pull down to retry.';
  }

  String get _filterLabel => switch (_filter) {
        _OrdersFilter.toPay => 'To Pay',
        _OrdersFilter.toReceive => 'To Receive',
        _OrdersFilter.toReview => 'To Review',
      };

  bool _matchesFilter(OrderModel o) {
    return _matchesFilterFor(o, _filter);
  }

  bool _matchesFilterFor(OrderModel o, _OrdersFilter filter) {
    final payment = o.paymentStatus.trim().toLowerCase();
    final status = o.orderStatus.trim().toLowerCase();

    switch (filter) {
      case _OrdersFilter.toPay:
        // "To Pay" → payment is still pending / failed (not completed).
        return payment == 'pending' || payment == 'failed';
      case _OrdersFilter.toReceive:
        // "To Receive" → paid and in transit / not yet delivered.
        if (payment != 'paid') return false;
        return status == 'placed' ||
            status == 'processing' ||
            status == 'shipped';
      case _OrdersFilter.toReview:
        // "To Review" → delivered orders (commonly the point where review is relevant).
        return status == 'delivered';
    }
  }

  _OrdersFilter _filterForOrder(OrderModel o) {
    final payment = o.paymentStatus.trim().toLowerCase();
    final status = o.orderStatus.trim().toLowerCase();
    if (payment == 'pending' || payment == 'failed') return _OrdersFilter.toPay;
    if (status == 'delivered') return _OrdersFilter.toReview;
    return _OrdersFilter.toReceive;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authStateProvider);
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    _pendingHighlightId ??= widget.highlightOrderId?.trim();

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: MyOrdersTokens.pageBackground,
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: MyOrdersTokens.primaryBlue,
            ),
      ),
      child: Scaffold(
        backgroundColor: MyOrdersTokens.pageBackground,
        bottomNavigationBar: ShopHomeBottomNavigationBar(
          currentIndex: 2,
          onTap: (i) => _onNavTap(context, i),
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  MyOrdersTokens.screenHorizontal,
                  8,
                  MyOrdersTokens.screenHorizontal,
                  12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _Avatar(
                      imageUrl:
                          'https://picsum.photos/seed/fs-profile/200/200',
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'To Recieve',
                            style: TextStyle(
                              color: MyOrdersTokens.textPrimary,
                              fontSize: MyOrdersTokens.titleLarge,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'My Orders',
                            style: TextStyle(
                              color: MyOrdersTokens.textSecondary,
                              fontSize: MyOrdersTokens.subtitle,
                              fontWeight: FontWeight.w400,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const _HeaderActions(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  MyOrdersTokens.screenHorizontal,
                  0,
                  MyOrdersTokens.screenHorizontal,
                  12,
                ),
                child: _OrdersFilterChips(
                  value: _filter,
                  onChanged: (v) => setState(() => _filter = v),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<OrderModel>>(
                  stream: _ordersStreamForUid(uid),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return RefreshIndicator(
                        onRefresh: _onRefresh,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 120),
                            _OrdersMessage(
                              message: _ordersErrorMessage(snapshot.error!),
                            ),
                          ],
                        ),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    final orders = snapshot.data ?? <OrderModel>[];
                    final highlightId = _pendingHighlightId;
                    OrderModel? highlightedOrder;
                    if (highlightId != null && highlightId.isNotEmpty) {
                      for (final o in orders) {
                        if (o.orderId == highlightId) {
                          highlightedOrder = o;
                          break;
                        }
                      }
                      if (highlightedOrder != null) {
                        final desired = _filterForOrder(highlightedOrder!);
                        if (_filter != desired) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _filter = desired);
                          });
                        }
                      }
                    }

                    var filtered = orders.where(_matchesFilter).toList();

                    // If a redirect lands on a filter that has no matching rows
                    // (e.g. newly placed COD order while "To Receive" is active),
                    // auto-switch to the most relevant filter instead of showing
                    // an empty page.
                    if (filtered.isEmpty && orders.isNotEmpty) {
                      final focusOrder = highlightedOrder ?? orders.first;
                      final fallbackFilter = _filterForOrder(focusOrder);
                      final fallback = orders
                          .where((o) => _matchesFilterFor(o, fallbackFilter))
                          .toList();
                      if (fallback.isNotEmpty) {
                        if (_filter != fallbackFilter) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _filter = fallbackFilter);
                          });
                        }
                        filtered = fallback;
                      }
                    }

                    if (highlightedOrder != null) {
                      filtered.removeWhere((o) => o.orderId == highlightedOrder!.orderId);
                      filtered.insert(0, highlightedOrder!);
                    }
                    if (filtered.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: _onRefresh,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            Center(
                              child: Text(
                                'No Orders Yet',
                                style: TextStyle(
                                  color: MyOrdersTokens.textSecondary,
                                  fontSize: MyOrdersTokens.subtitle,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: _onRefresh,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          MyOrdersTokens.screenHorizontal,
                          4,
                          MyOrdersTokens.screenHorizontal,
                          24,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final order = filtered[index];
                          final highlight = highlightId != null &&
                              highlightId.isNotEmpty &&
                              order.orderId == highlightId;
                          return RepaintBoundary(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                bottom: MyOrdersTokens.cardGap,
                              ),
                              child: OrderCard(
                                order: order,
                                highlighted: highlight,
                                onTrack: () {},
                                onReview: () {},
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrdersMessage extends StatelessWidget {
  const _OrdersMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: MyOrdersTokens.textSecondary,
            fontSize: MyOrdersTokens.subtitle,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.network(
        imageUrl,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 48,
          height: 48,
          color: const Color(0xFFE0E0E0),
        ),
      ),
    );
  }
}

class _HeaderActions extends StatelessWidget {
  const _HeaderActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CircleIconButton(
          filled: false,
          child: Icon(
            Icons.crop_free_rounded,
            size: 22,
            color: MyOrdersTokens.primaryBlue,
          ),
        ),
        const SizedBox(width: 8),
        _CircleIconButton(
          filled: true,
          showNotificationDot: true,
          child: Icon(
            Icons.filter_list_rounded,
            size: 22,
            color: MyOrdersTokens.primaryBlue,
          ),
        ),
        const SizedBox(width: 8),
        _CircleIconButton(
          filled: false,
          child: Icon(
            Icons.settings_outlined,
            size: 22,
            color: MyOrdersTokens.primaryBlue,
          ),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.child,
    this.filled = false,
    this.showNotificationDot = false,
  });

  final Widget child;
  final bool filled;
  final bool showNotificationDot;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {},
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? MyOrdersTokens.iconCircleFill : Colors.transparent,
                border: filled
                    ? null
                    : Border.all(
                        color: MyOrdersTokens.primaryBlue,
                        width: 1.5,
                      ),
              ),
              alignment: Alignment.center,
              child: child,
            ),
            if (showNotificationDot)
              const Positioned(
                right: 6,
                top: 6,
                child: _NotificationDot(),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationDot extends StatelessWidget {
  const _NotificationDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: MyOrdersTokens.primaryBlue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
    );
  }
}

enum _OrdersFilter { toPay, toReceive, toReview }

class _OrdersFilterChips extends StatelessWidget {
  const _OrdersFilterChips({required this.value, required this.onChanged});

  final _OrdersFilter value;
  final ValueChanged<_OrdersFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip(_OrdersFilter v, String label, {bool showDot = false}) {
      final selected = value == v;
      final bg = selected ? MyOrdersTokens.primaryBlue.withValues(alpha: 0.12) : Colors.white;
      final border = selected ? MyOrdersTokens.primaryBlue : MyOrdersTokens.iconCircleFill;
      final text = selected ? MyOrdersTokens.primaryBlue : MyOrdersTokens.textPrimary;

      return Material(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: () => onChanged(v),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: border, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: text,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (showDot) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: MyOrdersTokens.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip(_OrdersFilter.toPay, 'To Pay'),
          const SizedBox(width: 10),
          chip(_OrdersFilter.toReceive, 'To Receive', showDot: true),
          const SizedBox(width: 10),
          chip(_OrdersFilter.toReview, 'To Review'),
        ],
      ),
    );
  }
}
