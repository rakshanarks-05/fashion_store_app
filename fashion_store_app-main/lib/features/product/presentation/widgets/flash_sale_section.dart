import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/widgets/product_network_image.dart';
import '../models/shop_catalog.dart';
import '../theme/shop_tokens.dart';
import 'price_tag.dart';

class FlashSaleSection extends StatefulWidget {
  const FlashSaleSection({
    super.key,
    required this.items,
    this.crossAxisCount = 3,
  });

  final List<ShopProductItem> items;
  final int crossAxisCount;

  @override
  State<FlashSaleSection> createState() => _FlashSaleSectionState();
}

class _FlashSaleSectionState extends State<FlashSaleSection> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = const Duration(minutes: 36, seconds: 58);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remaining.inSeconds <= 0) {
          _remaining = const Duration(hours: 24);
        } else {
          _remaining -= const Duration(seconds: 1);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final h = _remaining.inHours.remainder(24);
    final m = _remaining.inMinutes.remainder(60);
    final s = _remaining.inSeconds.remainder(60);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ShopTokens.screenHorizontal),
          child: Row(
            children: [
              Text(
                'Flash Sale',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: ShopTokens.sectionTitle,
                      color: ShopTokens.textPrimary,
                    ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.timer_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              _TimeBox(value: _two(h)),
              const SizedBox(width: 6),
              _TimeBox(value: _two(m)),
              const SizedBox(width: 6),
              _TimeBox(value: _two(s)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;
            final pad = ShopTokens.screenHorizontal * 2;
            final inner = maxW - pad;
            final spacing = 10.0;
            final cols = widget.crossAxisCount;
            final tile = (inner - spacing * (cols - 1)) / cols;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: ShopTokens.screenHorizontal),
              child: Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (var i = 0; i < widget.items.length; i++)
                    SizedBox(
                      width: tile,
                      child: FlashSaleTile(item: widget.items[i]),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _TimeBox extends StatelessWidget {
  const _TimeBox({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ShopTokens.searchFill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: ShopTokens.textPrimary,
        ),
      ),
    );
  }
}

class FlashSaleTile extends StatelessWidget {
  const FlashSaleTile({super.key, required this.item});

  final ShopProductItem item;

  @override
  Widget build(BuildContext context) {
    final pct = item.discountPercent ?? 20;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ShopTokens.imageRadius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ProductNetworkImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ShopTokens.saleBadge,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '-$pct%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        PriceTag(amount: item.price, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
