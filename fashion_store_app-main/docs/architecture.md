# Architecture

## Concept (short)

The app is a **Flutter client** on top of **Firebase** (Auth, Firestore, Storage). The **catalog** lives in Firestore; **product photos** are often delivered via **Cloudinary** URLs stored on each product (gallery `images` array + primary `imageUrl`). **User profile avatars** also use **Cloudinary** (unsigned client upload, then **`secure_url`** stored as **`users/{uid}.photoUrl`** — see [Features](./features.md) — *Implemented — Cloudinary & client images* and *Implemented — profile*). **Admin** (optional) uploads many images per product from the device, then writes **`ProductDocument`** through **`FirestoreCreateService`**. The **shop home** builds **`ShopCatalog`** from streamed `products` and maps **category tiles** to a **2×2 collage** of up to four **distinct** image URLs per category (see [Features](./features.md), shop home + category grid rows).

## Stack

| Area | Choice |
|------|--------|
| **Framework** | Flutter (Dart) |
| **UI** | Material 3 (`MaterialApp`, `ThemeData` in `lib/app.dart`) |
| **State & DI** | Riverpod — `ProviderScope` in `lib/main.dart`; feature providers compose `core` providers |
| **Backend** | Firebase (Auth, Firestore, Storage) |
| **Analysis** | `flutter_lints` (`analysis_options.yaml`) |

## App entry & routing

| File | Responsibility |
|------|------------------|
| `lib/main.dart` | `bootstrapFirebase()`, `runApp(ProviderScope(child: FashionStoreApp()))` |
| `lib/app.dart` | `MaterialApp`, theme, **named routes** |
| `lib/firebase_options.dart` | Platform Firebase options for project `fashion-store-app-e5662` (regenerate with FlutterFire CLI when the project or platforms change) |
| `firebase.json` (repo root) | FlutterFire output map: Android `google-services.json` + Dart `firebase_options.dart`; optional **`firestore.indexes.json`** for deployed composite indexes (empty by default; order list does not require a composite index) |

### Named routes

| Route | Screen | Notes |
|-------|--------|--------|
| `/` | `ProductPage` | Shop home — live Firestore `products` + `categories` (display names + **`gender`** map for **For** filtering) |
| `/browse` | `ProductListPage` | Firestore-backed list |
| `/categories` | `AllCategoriesScreen` | Firestore **`categories`** list + gender filters + inline products per expanded row; pushed from shop **Categories → See All** (see [Features](./features.md) — *Implemented — category (All Categories)*) |
| `/login` | `LoginPage` | Email/password |
| `/cart` | `CartPage` | Full cart UI; Firestore-backed lines for signed-in users including persisted `selectedSize`; guest sign-in CTA; checkout bar pushes **`/checkout`** (see **Implemented — cart** / **checkout** in [features.md](./features.md)) |
| `/checkout` | `CheckoutPage` | Review address, items, shipping option, voucher; **Pay** opens **`PaymentMethodScreen`** via **`MaterialPageRoute`** (see **Implemented — checkout / payment** in [features.md](./features.md)) |
| `/payment` | `PaymentMethodScreen` | Payment method + Pay; also reachable as **`/#/payment`**; same providers as checkout for totals (see [features.md](./features.md)) |
| `/wishlist` | `WishlistPage` | Signed-in wishlist |
| `/orders` | `OrdersPage` | User’s orders |
| `/profile` | `ProfilePage` | User doc on `users/{uid}`; dashboard-style UI, `ShopBottomNavigationBar`, guest vs signed-in flows (see **Implemented — profile** in [features.md](./features.md)) |
| `/admin` | `AdminPage` | Optional catalog seeding UI; only useful when **`FeatureFlags.enableAdmin`** is true (see [features.md](./features.md)) |

## `lib/core/` (shared)

| Path | Role |
|------|------|
| `constants/` | `app_constants`, `firestore_paths`, `storage_paths` |
| `config/` | `feature_flags.dart` — e.g. Admin toggle (`enableAdminInSource`, `ENABLE_CREATE_MODE` compile define) |
| `firestore_create/` | Catalog write helpers: document models, `FirestoreCreateService`, utils (see [features.md](./features.md#implemented--firestore-catalog-writes-firestore_create)) |
| `errors/` | `failures`, `exceptions` |
| `utils/result.dart` | Simple `Result` / `Ok` / `Err` |
| `services/firebase_bootstrap.dart` | `WidgetsFlutterBinding` + `Firebase.initializeApp` |
| `services/firebase_storage_service.dart` | Upload helpers wrapping `FirebaseStorage` |
| `providers/core_providers.dart` | `firebaseFirestoreProvider`, `firebaseAuthProvider`, `firebaseStorageProvider`, `firebaseStorageServiceProvider`, **`cloudinaryServiceProvider`**, **`firestoreServiceProvider`** |
| `constants/product_assets.dart` | Bundled placeholder path for missing product images |
| `constants/cloudinary_config.dart` | Public Cloudinary `cloudName` + unsigned **`uploadPreset`** (no secret in app); optional **`profilesUploadFolder`** for user avatar uploads |
| `widgets/app_drawer.dart` | Drawer navigation + auth-aware sign out + optional **Admin** entry |
| `widgets/product_network_image.dart` | `ProductNetworkImage` — `CachedNetworkImage`, optional Cloudinary transforms, or `ProductAssets` fallback |

### `lib/services/` (client integrations)

| Path | Role |
|------|------|
| `cloudinary_service.dart` | Unsigned multipart image upload (optional **`folder`** per upload); `thumbnailUrl` / `mediumUrl` URL helpers |
| `firestore_service.dart` | `deleteProduct` (Firestore doc only) for catalog admin lists; product **creates** use `FirestoreCreateService` |

**Core DI** (`core_providers.dart`) also exposes **`cloudinaryServiceProvider`** alongside Firebase singletons.

## Feature modules (`lib/features/<name>/`)

Each feature follows **Clean Architecture**:

```
features/<feature>/
  domain/
    entities/
    repositories/     # abstract contracts
    usecases/
  data/
    models/           # DTOs / Firestore mapping (extend or map to entities)
    datasources/      # Firebase / remote APIs
    repositories/     # implementations of domain contracts
  presentation/
    providers/        # Riverpod
    pages/
    widgets/          # optional; product shop has many here
```

### Auth

- **Domain:** `AppUser`, `AuthRepository`, login/register use cases; **`RegisterWithProfileUseCase`** (sign-up + Firestore `users/{uid}` profile write including optional **`address`**)  
- **Data:** `AuthRemoteDataSource` (Firebase Auth), `AuthRepositoryImpl`, `AppUserModel`  
- **Presentation:** `auth_providers.dart`, `login_page.dart`, **`register_page.dart`** — shared **Register / Edit profile** form; **`isEditMode`** + **`RegisterFormUserData`** for profile edits; **`register_providers.dart`** (`registerWithProfileUseCaseProvider`). Edit mode is opened from **`ProfilePage`** via **`MaterialPageRoute`**, not the `/register` route. Phone is stored as **E.164**; the register form formats it without a country picker: preserves `+<digits>` input, otherwise assumes **US `+1`**.

### Product

- **Domain:** `Product` (`description`, **`images`** / primary **`imageUrl`** getters, `categoryId`, `collectionId`, `isFeatured`, `createdAt`, …), `ProductRepository` (futures + streams: `watchAllProducts`, `watchFeaturedProducts`, `watchProductsByCategory`, …), `GetProductsUseCase`  
- **Data:** `ProductRemoteDataSource` (Firestore `products`, queries + real-time snapshots), `CategoryRemoteDataSource` (`categories` → id→**name** and id→**gender** streams for shop UI), `ProductRepositoryImpl` (`ProductModel` mapping; list copies for web subtype safety)  
- **Presentation:** `product_providers.dart` (`productListProvider`, `categoryIdToNameProvider`, **`categoryIdToGenderProvider`**), `product_list_page.dart`, `product_page.dart` + `widgets/` (e.g. **`HomeFilterDrawer`**, **`CategoryFilterBar`**, **`ShopHomeBottomNavigationBar`**), `models/shop_catalog.dart`, `models/shop_for_audience.dart`, `providers/home_for_audience_provider.dart`, `providers/home_price_filter_provider.dart`, `providers/product_shop_providers.dart` (`shopCatalogProvider`), `providers/home_search_providers.dart`, `controllers/home_controller.dart` (category chip + search helpers), `utils/home_filter_utils.dart`, `theme/shop_tokens.dart`.  
- **Shop home filtering:** **For** audience and category-chip relevance use Firestore **`categories.gender`** via `categoryIdToGenderProvider`, not category **name** substring rules. Search + price are **client-side** on the streamed list; see [Features](./features.md) — *Product search (shop home)* and *Implemented — shop home*.

### Admin (optional)

- **Presentation feature:** `lib/features/admin/presentation/` — `pages/admin_page.dart`, `providers/admin_providers.dart` (`firestoreCreateServiceProvider`). **Multi-image** product flow uses **`CloudinaryService`** + **`MultiImagePickerWidget`** (`lib/widgets/`).  
- **Depends on:** `core/firestore_create`, `core/config/feature_flags`, `core_providers` (`cloudinaryServiceProvider`), signed-in user for Firestore writes per **`firestore.rules`**.

### Category

- **Data:** `lib/features/category/data/category_service.dart` — reads Firestore **`categories`**, maps to **`CategoryDocument`**, filters by user/catalog **`gender`** (`male` / `female` / `both`).  
- **Presentation:** `lib/features/category/presentation/` — `screens/all_categories_screen.dart`, `widgets/` (header, gender bar, **`ExpandableCategoryCard`**, **`CategoryProductsExpandedList`**, Just for You row), `providers/all_categories_providers.dart` (`fetchedCategoriesProvider`, **`allCategoriesCatalogProvider`** merged with **`productListProvider`** for row thumbnails), `models/all_categories_models.dart`.  
- **Product integration:** `category_browse_providers.dart` (`categoryProductsShopItemsProvider`) filters the live product stream by `categoryId` for inline lists; **`ProductListRowCard`** / **`ProductSearchEmptyState`** live under **`features/product/presentation/widgets/`**.  
- **Shop home:** Category **names** and **gender** maps come from **`categoryIdToNameProvider`** / **`categoryIdToGenderProvider`** (`CategoryRemoteDataSource`) in the **product** feature — separate read path from **All Categories** (`CategoryService`), though both use the `categories` collection.  
- **Shared styling:** `ShopTokens` from `features/product/presentation/theme/shop_tokens.dart`.  
- **Route:** `/categories` in `lib/app.dart`.

### Cart

- **Domain:** `CartItem` (`productId`, `quantity`, `selectedSize`); `CartRepository` (`addItem`, `getItems`, `removeItem`, `setItemQuantity`, `setItemSelection`, `clearCart`); use cases — `AddToCartUseCase`, `RemoveFromCartUseCase`, `SetCartItemQuantityUseCase`, `ClearCartUseCase`  
- **Data:** `CartRemoteDataSource` (transaction merge on add, persists `selectedSize`; `setItemSelection` for quantity+size edits; batch clear), `CartRepositoryImpl`, `CartItemModel`  
- **Presentation:** `cart_providers.dart` (`CartNotifier`, `CartState` with `errorMessage`, plus `setItemSelection`), `cart_ui_providers.dart` (`cartResolvedLinesProvider`, `cartOrderTotalProvider`, `wishlistProductsForCartProvider`, **`cartShippingAddressProvider`** session override, **`resolvedCartShippingAddressProvider`**, **`shippingAddressDisplayLabel`**), `pages/cart_page.dart`, `widgets/` (`cart_item_widget`, `cart_quantity_selector`, `cart_checkout_bar`, `cart_shipping_address_card`, `cart_wishlist_row_widget`, `cart_empty_state`), `theme/cart_tokens.dart`, `utils/cart_formatters.dart` (`computeCartOrderTotal`, LKR formatting + size-aware subtitle). Cart lines expose an **Edit** action that reopens `AddToCartSheet` with prefilled quantity/size.  
- **Tests:** `test/cart_order_total_test.dart`

### Checkout

- **Domain:** `place_order.dart` — **`placeOrderAfterSuccessfulPayment`** builds **`OrderModel`** (uses **`resolvedCartShippingAddressProvider`** for shipping line text), persists via **`OrderService`**, clears cart  
- **Presentation:** `lib/features/checkout/presentation/` — `screens/checkout/checkout_page.dart` (scrollable flow + sticky total/**Pay** bar + `ShopBottomNavigationBar`); `widgets/` (`address_card_widget`, `contact_info_card_widget`, `order_item_widget`, `shipping_options_widget`, `payment_method_widget`, `price_summary_widget`); `providers/checkout_providers.dart` (shipping option, payment method, contact phone, voucher discount, optional 5% promo flag); `theme/checkout_tokens.dart`.  
- **Integration:** Reuses `cartNotifierProvider`, `cartResolvedLinesProvider`, **`resolvedCartShippingAddressProvider`** (and session `cartShippingAddressProvider` when the user edits the dialog), `categoryIdToNameProvider`, `authStateProvider`, `userProfileProvider` (indirectly via resolved shipping), and `computeCartOrderTotal` / `productCartSubtitle` from the cart/product layers. Route **`/checkout`** registered in `lib/app.dart`; opened from **`CartCheckoutBar`** on `CartPage`. **Pay** pushes **`PaymentMethodScreen`** with **`MaterialPageRoute`**, not only `pushNamed('/payment')`.

### Payment

- **Presentation:** `lib/features/payment/presentation/` — `screens/payment/` (`payment_method_screen.dart`, card / processing / success / failure flows), `widgets/` (`saved_payment_card_widget`, `payment_option_tile`, …), `theme/payment_tokens.dart`, `providers/payment_providers.dart`. Saved-card **Settings** opens `CardPaymentScreen` in edit mode with prefilled holder/expiry; card number is optional in edit mode (blank keeps existing last4).  
- **Services:** `lib/features/payment/services/payment_service.dart` — orchestrates the pay action from the method screen.  
- **Route:** **`/payment`** in `lib/app.dart` for direct navigation; primary UX is **checkout → Pay → `MaterialPageRoute`** (see [Features](./features.md) — **Implemented — payment**). On success, the current branch flow returns to **`/cart`** and shows an **Order confirmed** snackbar.

### Order

- **Domain:** `OrderModel` (aggregate: line items, shipping snapshot, totals, statuses, timestamps), `OrderRepository` (optional one-shot fetch), `GetOrdersUseCase` (available; list UI uses `OrderService` streams directly)  
- **Data:** `OrderService` — Firestore `orders` collection (`FirestorePaths.orders`): `createOrder`, `watchUserOrdersStream` (real-time query `where userId == …`, **newest-first via in-memory sort** on `createdAt` to avoid composite indexes), `getUserOrders`, `getOrderById`, `updateOrderStatus`; `OrderRepositoryImpl` implements `OrderRepository` over `OrderService`  
- **Presentation:** `order_providers.dart` (`orderServiceProvider`, `orderRepositoryProvider`, `ordersForUserProvider` as **`StreamProvider<List<OrderModel>>`** keyed off `FirebaseAuth.currentUser?.uid` + `authStateProvider`), `order_placement_controller.dart`; **My Orders** UI: `presentation/screens/my_orders_screen.dart` (`StreamBuilder` + `RefreshIndicator`, loading / empty / error states), `presentation/widgets/order_card.dart` and related tokens/widgets under `presentation/`

### Wishlist

- **Domain:** `WishlistItem`, `WishlistRepository`, `GetWishlistUseCase`  
- **Data:** `WishlistRemoteDataSource` (`users/{uid}/wishlist`), `WishlistRepositoryImpl`, `WishlistItemModel`  
- **Presentation:** `wishlist_providers.dart`, `wishlist_page.dart`

### Profile

- **Domain:** `UserProfile` (includes optional **`address`** for default delivery), `ProfileRepository`, `GetUserProfileUseCase`, **`UpdateUserProfileUseCase`** (Auth display name + Firestore merge of editable fields **without** `email`)  
- **Data:** `ProfileRemoteDataSource` (`users/{uid}` document; **`saveUserProfile`** full write; **`mergeUserProfileFields`** for edits that omit `email`), `ProfileRepositoryImpl`, `UserProfileModel` (`toJson` vs `toEditableFirestoreMap`)  
- **Presentation:** `profile_providers.dart` (**`userProfileProvider`**, **`updateUserProfileUseCaseProvider`**), `profile_page.dart`, `theme/profile_ui_tokens.dart`, and composable widgets under `presentation/widgets/` (`ProfileHeader`, …)  
- **Profile photo uploads:** `presentation/utils/profile_photo_cloudinary.dart` (`pickAndUploadProfilePhotoToCloudinary`) — shared with **`RegisterPage`** (auth feature) for sign-up avatars; **`ProfileHeader`** exposes **`onAvatarTap`** / **`avatarUploading`** for in-app updates; **Edit profile** navigates to **`RegisterPage`** edit mode (see **Auth**)

## Dependency injection pattern

1. **Core** exposes low-level singletons (`FirebaseFirestore`, etc.).  
2. **Data** providers build datasources and repository implementations.  
3. **Domain** use cases receive repositories via constructor injection in provider `Provider<>` factories.  
4. **Presentation** uses `FutureProvider`, `StreamProvider`, `StateNotifierProvider`, etc., and `ref.watch` / `ref.read`.

Tests can override providers with `ProviderScope(overrides: [...])`.

## Firestore layout

| Path / collection | Purpose |
|-------------------|---------|
| `products` | Catalog: `name`, `description`, `price`, **`images`** (array of `{ imageUrl, publicId }`), **`imageUrl` / `publicId`** (primary, for backward compatibility), `category` or `categoryId`, `isFeatured`, `createdAt` (Timestamp), optional `collectionId` |
| `categories` | Category docs: `name`, `imageUrl`, optional `gender` (`male` / `female` / `both`; app normalizes child synonyms to `kids` for shop **For**) — **read** by shop home for labels (`categoryIdToNameProvider`) and **For** / chip logic (`categoryIdToGenderProvider`); **All Categories** via `CategoryService` + `CategoryDocument`; Admin / `firestore_create` writes |
| `collections` | Curated groups: `name`, `description`, `imageUrl`; products reference via `collectionId` |
| `orders` | Order documents: `orderId`, `userId`, `items[]`, `totalAmount`, `paymentMethod`, `paymentStatus`, `orderStatus`, `shippingAddress`, `createdAt` / `updatedAt` (Timestamps; writes use `FieldValue.serverTimestamp()` where applicable) |
| `users/{uid}` | Profile fields: e.g. `email`, `phoneNumber`, `displayName`, `photoUrl`, optional **`address`** (default source for **resolved** cart/checkout delivery line when no session override); registration rules may require `email` + `phoneNumber` on create |
| `users/{uid}/cart/{productId}` | `productId`, `quantity`, optional `selectedSize` |
| `users/{uid}/wishlist/{productId}` | `productId` |

**Security (see repo `firestore.rules`):** users may read/write their own `users/{uid}` subtree (cart, wishlist) under auth; `products`, `categories`, and `collections` are world-readable with **create/update/delete** for **any signed-in user** (suitable for dev / Admin — tighten for production, e.g. admin-only). Orders scoped by `userId`.

## Firebase Storage

- Path helpers: `lib/core/constants/storage_paths.dart` (e.g. `products/{productId}/{fileName}`).  
- Uploads: `FirebaseStorageService` from `core_providers`.

## Native configuration

- **Android:** `com.google.gms.google-services` in Gradle; **`android/app/google-services.json`** is committed and wired via **`firebase.json`**.  
- **iOS:** `GoogleService-Info.plist` in the Runner target (add when building for iOS; align with the same Firebase project as `firebase_options.dart`).

## Build & assets

- **`pubspec.yaml`** — dependencies and Flutter assets/fonts  
- **Bundled images** — e.g. `assets/images/product_placeholder.png` for product UIs when `imageUrl` is empty or fails (`ProductNetworkImage`)  
- **Platform folders** — `android/`, `ios/`, `web/`, desktop as maintained by Flutter

## Testing

- **`test/`** — `flutter_test`; smoke tests should avoid requiring a configured Firebase project unless using fakes or emulators.  
- **`test/cart_order_total_test.dart`** — pure Dart tests for `computeCartOrderTotal` and `CartItemHelper` (no Firebase).

## References

- [Flutter architecture concepts](https://docs.flutter.dev/app-architecture)  
- [Project overview](./project-overview.md)  
- [Features](./features.md)
