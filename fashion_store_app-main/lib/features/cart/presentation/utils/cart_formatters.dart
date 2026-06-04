import '../../../product/domain/entities/product.dart';
import '../../../../core/utils/currency_format.dart';
import '../models/cart_resolved_line.dart';

/// Sum of line totals (price × quantity). Unknown products contribute 0.
/// Uses per-line rounding to whole currency units to avoid float drift.
double computeCartOrderTotal(List<CartResolvedLine> lines) {
  var total = 0.0;
  for (final line in lines) {
    final p = line.product;
    if (p == null) continue;
    final lineTotal = (p.price * line.cartItem.quantity).roundToDouble();
    total += lineTotal;
  }
  return total;
}

/// Formats amounts as in the reference: `Rs. 4,300`.
String formatLkr(double amount) {
  return CurrencyFormat.format(amount);
}

/// Subtitle line under product title (category + size placeholder; catalog has no color field).
String productCartSubtitle(
  Product? product,
  String? categoryName, {
  String? selectedSize,
}) {
  final cat = categoryName?.trim();
  final size = selectedSize?.trim();
  final sizeLabel = (size != null && size.isNotEmpty) ? 'Size $size' : 'Size M';
  if (cat != null && cat.isNotEmpty) {
    return '$cat, $sizeLabel';
  }
  return sizeLabel;
}

/// Wishlist row chips: split subtitle into up to two chips.
List<String> wishlistAttributeChips(Product? product, String? categoryName) {
  final line = productCartSubtitle(product, categoryName);
  final parts = line.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  if (parts.length >= 2) {
    return [parts[0], parts[1]];
  }
  if (parts.length == 1) {
    return [parts[0]];
  }
  return const ['—'];
}
