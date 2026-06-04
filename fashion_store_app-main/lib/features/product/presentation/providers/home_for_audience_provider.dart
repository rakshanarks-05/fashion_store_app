import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/shop_for_audience.dart';

/// Browsing audience: narrows products and enables only matching category chips.
final homeForAudienceProvider =
    StateProvider<ShopForAudience>((ref) => ShopForAudience.everyone);
