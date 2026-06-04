import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/cart_remote_datasource.dart';
import '../../data/repositories/cart_repository_impl.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/repositories/cart_repository.dart';
import '../../domain/usecases/add_to_cart_usecase.dart';
import '../../domain/usecases/clear_cart_usecase.dart';
import '../../domain/usecases/remove_from_cart_usecase.dart';
import '../../domain/usecases/set_cart_item_quantity_usecase.dart';

final cartRemoteDataSourceProvider = Provider<CartRemoteDataSource>((ref) {
  return CartRemoteDataSourceImpl(ref.watch(firebaseFirestoreProvider));
});

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepositoryImpl(ref.watch(cartRemoteDataSourceProvider));
});

final addToCartUseCaseProvider = Provider<AddToCartUseCase>((ref) {
  return AddToCartUseCase(ref.watch(cartRepositoryProvider));
});

final removeFromCartUseCaseProvider = Provider<RemoveFromCartUseCase>((ref) {
  return RemoveFromCartUseCase(ref.watch(cartRepositoryProvider));
});

final setCartItemQuantityUseCaseProvider =
    Provider<SetCartItemQuantityUseCase>((ref) {
  return SetCartItemQuantityUseCase(ref.watch(cartRepositoryProvider));
});

final clearCartUseCaseProvider = Provider<ClearCartUseCase>((ref) {
  return ClearCartUseCase(ref.watch(cartRepositoryProvider));
});

class CartState extends Equatable {
  const CartState({
    this.items = const [],
    this.loading = false,
    this.isGuest = true,
    this.errorMessage,
  });

  final List<CartItem> items;
  final bool loading;
  final bool isGuest;

  /// Last Firestore / network error for cart operations (cleared on success).
  final String? errorMessage;

  CartState copyWith({
    List<CartItem>? items,
    bool? loading,
    bool? isGuest,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CartState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      isGuest: isGuest ?? this.isGuest,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [items, loading, isGuest, errorMessage];
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier(
    this._addToCart,
    this._removeFromCart,
    this._setQuantity,
    this._clearCartUseCase,
    this._repository,
    this._userId,
  ) : super(CartState(isGuest: _userId.isEmpty)) {
    if (_userId.isNotEmpty) {
      _load(showLoadingIndicator: true);
    }
  }

  final AddToCartUseCase _addToCart;
  final RemoveFromCartUseCase _removeFromCart;
  final SetCartItemQuantityUseCase _setQuantity;
  final ClearCartUseCase _clearCartUseCase;
  final CartRepository _repository;
  final String _userId;

  Future<void> _load({bool showLoadingIndicator = false}) async {
    if (_userId.isEmpty) return;
    if (showLoadingIndicator) {
      state = state.copyWith(loading: true, clearError: true);
    }
    try {
      final items = await _repository.getItems(_userId);
      state = state.copyWith(
        items: items,
        loading: false,
        isGuest: false,
        clearError: true,
      );
    } catch (e, _) {
      state = state.copyWith(
        loading: false,
        isGuest: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Returns `true` if the item was added; `false` if user is not signed in or on failure.
  Future<bool> add(String productId) async {
    if (_userId.isEmpty) return false;
    final wasEmpty = state.items.isEmpty;
    try {
      state = state.copyWith(clearError: true);
      await _addToCart(
        userId: _userId,
        productId: productId,
        quantity: 1,
        selectedSize: null,
      );
      await _load(showLoadingIndicator: wasEmpty);
      return true;
    } catch (e, _) {
      state = state.copyWith(
        loading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Returns `true` if the item was added; `false` if user is not signed in or on failure.
  Future<bool> addWithQuantity(
    String productId,
    int quantity, {
    String? selectedSize,
  }) async {
    if (_userId.isEmpty) return false;
    final q = quantity < 1 ? 1 : quantity;
    final wasEmpty = state.items.isEmpty;
    try {
      state = state.copyWith(clearError: true);
      await _addToCart(
        userId: _userId,
        productId: productId,
        quantity: q,
        selectedSize: selectedSize,
      );
      await _load(showLoadingIndicator: wasEmpty);
      return true;
    } catch (e, _) {
      state = state.copyWith(
        loading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> remove(String productId) async {
    if (_userId.isEmpty) return;
    try {
      state = state.copyWith(clearError: true);
      await _removeFromCart(userId: _userId, productId: productId);
      await _load(showLoadingIndicator: false);
    } catch (e, _) {
      state = state.copyWith(
        loading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> incrementQuantity(String productId) async {
    if (_userId.isEmpty) return;
    final current = CartItemHelper.quantityFor(state.items, productId);
    if (current < 1) {
      await add(productId);
      return;
    }
    try {
      state = state.copyWith(clearError: true);
      await _setQuantity(
        userId: _userId,
        productId: productId,
        quantity: current + 1,
        selectedSize: null,
      );
      await _load(showLoadingIndicator: false);
    } catch (e, _) {
      state = state.copyWith(
        loading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> decrementQuantity(String productId) async {
    if (_userId.isEmpty) return;
    final current = CartItemHelper.quantityFor(state.items, productId);
    if (current <= 1) {
      await remove(productId);
      return;
    }
    try {
      state = state.copyWith(clearError: true);
      await _setQuantity(
        userId: _userId,
        productId: productId,
        quantity: current - 1,
        selectedSize: null,
      );
      await _load(showLoadingIndicator: false);
    } catch (e, _) {
      state = state.copyWith(
        loading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> clear() async {
    if (_userId.isEmpty) return;
    try {
      state = state.copyWith(clearError: true);
      await _clearCartUseCase(userId: _userId);
      await _load(showLoadingIndicator: false);
    } catch (e, _) {
      state = state.copyWith(
        loading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    if (_userId.isEmpty) return;
    await _load(showLoadingIndicator: true);
  }

  Future<bool> setItemSelection(
    String productId, {
    required int quantity,
    String? selectedSize,
  }) async {
    if (_userId.isEmpty) return false;
    final q = quantity < 1 ? 1 : quantity;
    try {
      state = state.copyWith(clearError: true);
      await _setQuantity(
        userId: _userId,
        productId: productId,
        quantity: q,
        selectedSize: selectedSize?.trim(),
      );
      await _load(showLoadingIndicator: false);
      return true;
    } catch (e, _) {
      state = state.copyWith(
        loading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void clearErrorBanner() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }
}

/// Helpers for cart line lookups.
class CartItemHelper {
  const CartItemHelper._();

  static int quantityFor(List<CartItem> items, String productId) {
    for (final i in items) {
      if (i.productId == productId) return i.quantity;
    }
    return 0;
  }
}

final cartNotifierProvider =
    StateNotifierProvider<CartNotifier, CartState>((ref) {
  final auth = ref.watch(authStateProvider);
  final uid = auth.when(
    data: (user) => user?.id ?? '',
    loading: () => '',
    error: (Object? _, StackTrace? _) => '',
  );
  final addUseCase = ref.watch(addToCartUseCaseProvider);
  final removeUseCase = ref.watch(removeFromCartUseCaseProvider);
  final setQtyUseCase = ref.watch(setCartItemQuantityUseCaseProvider);
  final clearUseCase = ref.watch(clearCartUseCaseProvider);
  final repository = ref.watch(cartRepositoryProvider);

  return CartNotifier(
    addUseCase,
    removeUseCase,
    setQtyUseCase,
    clearUseCase,
    repository,
    uid,
  );
});
