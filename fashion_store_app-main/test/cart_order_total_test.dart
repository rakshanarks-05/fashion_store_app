import 'package:fashion_store_application/features/cart/domain/entities/cart_item.dart';
import 'package:fashion_store_application/features/cart/presentation/models/cart_resolved_line.dart';
import 'package:fashion_store_application/features/cart/presentation/providers/cart_providers.dart';
import 'package:fashion_store_application/features/cart/presentation/utils/cart_formatters.dart';
import 'package:fashion_store_application/features/product/domain/entities/product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeCartOrderTotal', () {
    test('sums price × quantity per line', () {
      final p = Product(
        id: 'a',
        name: 'Shirt',
        description: '',
        price: 2150,
        categoryId: 'c',
      );
      final lines = [
        CartResolvedLine(
          cartItem: const CartItem(productId: 'a', quantity: 2),
          product: p,
        ),
      ];
      expect(computeCartOrderTotal(lines), 4300);
    });

    test('ignores lines without catalog product', () {
      final lines = [
        const CartResolvedLine(
          cartItem: CartItem(productId: 'missing', quantity: 5),
          product: null,
        ),
      ];
      expect(computeCartOrderTotal(lines), 0);
    });

    test('rounds each line to whole currency units', () {
      final p = Product(
        id: 'b',
        name: 'Hat',
        description: '',
        price: 100.6,
        categoryId: 'c',
      );
      final lines = [
        CartResolvedLine(
          cartItem: const CartItem(productId: 'b', quantity: 1),
          product: p,
        ),
      ];
      expect(computeCartOrderTotal(lines), 101);
    });
  });

  group('CartItemHelper.quantityFor', () {
    test('returns quantity for known product id', () {
      const items = [
        CartItem(productId: 'x', quantity: 3),
        CartItem(productId: 'y', quantity: 1),
      ];
      expect(CartItemHelper.quantityFor(items, 'x'), 3);
      expect(CartItemHelper.quantityFor(items, 'y'), 1);
    });

    test('returns 0 when id not found', () {
      expect(CartItemHelper.quantityFor(const [], 'z'), 0);
    });
  });
}
