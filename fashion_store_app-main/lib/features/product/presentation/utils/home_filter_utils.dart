import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/product.dart';
import '../models/shop_catalog.dart';
import '../models/shop_for_audience.dart';

/// True when the range covers the full product price span (no effective filter).
bool isHomePriceRangeFullSpan(
  RangeValues range,
  ({double min, double max}) bounds, {
  double epsilon = 0.5,
}) {
  return range.start <= bounds.min + epsilon && range.end >= bounds.max - epsilon;
}

/// Active filter count for the home filter icon badge (For + category + price).
int homeAppliedFilterCount({
  required ShopForAudience forAudience,
  required int categoryFilterIndex,
  required RangeValues? priceRangeFilter,
}) {
  var n = 0;
  if (forAudience != ShopForAudience.everyone) n++;
  if (categoryFilterIndex != 0) n++;
  if (priceRangeFilter != null) n++;
  return n;
}

bool productPassesHomePriceFilter(double price, RangeValues? filter) {
  if (filter == null) return true;
  return price >= filter.start && price <= filter.end;
}

List<Product> filterProductsByHomePriceRange(
  List<Product> list,
  RangeValues? filter,
) {
  if (filter == null) return list;
  return list
      .where((p) => productPassesHomePriceFilter(p.price, filter))
      .toList(growable: false);
}

List<ShopProductItem> filterShopItemsByHomePriceRange(
  List<ShopProductItem> list,
  RangeValues? filter,
) {
  if (filter == null) return list;
  return list
      .where((p) => productPassesHomePriceFilter(p.price, filter))
      .toList(growable: false);
}

/// Min/max across [products] for slider bounds; guarantees start < end.
({double min, double max}) homePriceBoundsFromProducts(List<Product> products) {
  if (products.isEmpty) return (min: 0.0, max: 1.0);
  var lo = products.first.price;
  var hi = products.first.price;
  for (final p in products) {
    lo = math.min(lo, p.price);
    hi = math.max(hi, p.price);
  }
  if (lo >= hi) {
    hi = lo + 1;
  }
  return (min: lo, max: hi);
}
