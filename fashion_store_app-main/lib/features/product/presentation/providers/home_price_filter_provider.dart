import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// When `null`, home search and featured grid are not restricted by price.
/// When set, only products with `price` in \[[start], [end]\] (inclusive) are shown.
final homePriceRangeFilterProvider = StateProvider<RangeValues?>((ref) => null);
