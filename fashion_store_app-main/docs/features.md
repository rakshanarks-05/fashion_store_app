# Features

## Implemented — stack

| Layer | Technology |
|--------|------------|
| **UI** | Flutter (Material 3), feature-first folders |
| **State & DI** | [Riverpod](https://pub.dev/packages/flutter_riverpod) (`ProviderScope` in `lib/main.dart`) |
| **Backend** | [Firebase](https://firebase.google.com/) — Auth, Firestore, Storage |
| **Structure** | Clean Architecture per feature: `domain/` → `data/` → `presentation/` |

Firebase is initialized in `lib/core/services/firebase_bootstrap.dart` using **`lib/firebase_options.dart`**. This branch includes committed **`firebase.json`**, **`android/app/google-services.json`**, and updated options for Firebase project **`fashion-store-app-e5662`**. For iOS builds, add **`GoogleService-Info.plist`**; use **`dart run flutterfire_cli:flutterfire configure`** if you switch projects or add platforms.

---

## Implemented — shop home (`ProductPage`)

Presentation-focused shop screen: header, search, promotional carousel, categories, horizontal product rails, flash sale with countdown, and a “Just For You” grid — **backed by live Firestore data** (not mock).

| Item | Detail |
|------|--------|
| **Entry route** | `/` → `lib/features/product/presentation/pages/product_page.dart` |
| **Products** | `productListProvider` — `StreamProvider<List<Product>>` over `ProductRepository.watchAllProducts()` (Firestore `products`, real-time snapshots) |
| **Category names** | `categoryIdToNameProvider` — `StreamProvider<Map<String, String>>` over `categories` docs (document id → `name` field). Drives **filter chip labels** and **category grid titles**; products still filter by `Product.categoryId` |
| **Category gender (shop “For”)** | `categoryIdToGenderProvider` — `StreamProvider<Map<String, String>>` from `CategoryRemoteDataSource.watchCategoryIdToGender()` (document id → normalized `gender`: `male` / `female` / `both`, plus `kids` when Firestore stores child synonyms). Feeds **`ShopForAudience`** filtering — **not** category name heuristics (`shop_for_audience.dart`: `categoryIdMatchesShopFor`, `filterProductsByShopForAudience`). |
| **Shop catalog** | `shopCatalogProvider` — after **For** audience narrowing, builds `ShopCatalog.fromFirestoreProducts` from products + `categoryIdToName` (`product_shop_providers.dart`) |
| **Category grid (2×2 collage)** | Each **`CategoryGridCard`** shows four quadrants. **`ShopCatalog`** fills **`thumbnailUrls`** with up to **four distinct** image URLs from products in that category (products sorted by **`createdAt`**, URLs deduped across each product’s **`images`** gallery). Empty quadrants render **“No Image”**—the UI does **not** repeat the first image to pad the grid. |
| **Filters** | **For** — `homeForAudienceProvider` (`ShopForAudience`). **Category** — `categoryFilterIndexProvider` + `shopFilterChipsFor` / `filterCategoryIds`; chips incompatible with **For** + Firestore **`gender`** are faded (`categoryIdMatchesShopFor`). **Drawer** — header tune → `HomeFilterDrawer`: draft For, category, **price** (`homePriceRangeFilterProvider`); **Apply** / **Reset**; tune badge via `homeAppliedFilterCount` (`home_filter_utils.dart`). Home **search** pipeline order — see **Product search** below. |
| **Pull-to-refresh** | `ref.invalidate(productListProvider)` |
| **Product list (browse)** | `/browse` → `lib/features/product/presentation/pages/product_list_page.dart` — same `products` stream via `filteredProductsProvider`; optional Firestore delete; Admin + cart shortcuts in the app bar |

### Product search (shop home)

High-level idea: **filter the already-streamed catalog in memory** so typing does **not** issue extra Firestore reads per keystroke. The live `products` snapshot from `productListProvider` is the single source. The home pipeline applies **For**, **category chip**, **search**, then **drawer price** in order.

| Concern | Approach |
|--------|----------|
| **Query input** | `homeSearchQueryProvider` — `HomeSearchNotifier` debounces text (**400 ms**), trims whitespace, clears when empty. |
| **Filtering** | `homeSearchFilteredProductsProvider`: **For** (`filterProductsByShopForAudience` + `categoryIdToGenderProvider`) → **category chip** (`applyCategoryChipFilter` in `home_controller.dart`) → **search** (`filterProductsBySearchQuery` — case-insensitive substring on **name**, **description**, and **resolved category label** from `categoryIdToNameProvider`; falls back to raw `categoryId`) → **price** (`filterProductsByHomePriceRange` + `homePriceRangeFilterProvider`). |
| **Derived UI models** | `homeSearchFilteredProductsProvider` → `homeSearchShopItemsProvider` maps to `ShopProductItem` for the grid. |
| **Data layer** | `ProductService` documents that shop access uses the repository stream; **search does not call Firestore** — it reuses the cached list (see class doc in `product_service.dart`). |
| **UI** | Header uses `SearchBarWidget` (`search_bar_widget.dart`); when the debounced query is non-empty, **`ProductPage`** inserts a **Search results** block **above** banners and rails (`ProductGridWidget` + empty/loading/error). |

---

**Sections (top to bottom):** header (Home title, search, **tune** opens filter drawer), category chips, sale banner carousel, category grid, top products, new items rail, flash sale, most popular rail, just-for-you grid. When search is active, **Search results** appears near the top (after chips).

**Categories → See All** — `SectionHeader` + `SeeAllTrailing` calls `Navigator.pushNamed(context, '/categories')` to open the full category tree (see **Implemented — category (All Categories)** below).

**Bottom navigation (shop home)** — `ShopHomeBottomNavigationBar`: **Home** (stay on `/`), **Cart** → `/cart`, **Profile** → `/profile`. Wishlist and Orders are reached from **`AppDrawer`** (or other routes), not from this three-tab bar. Other screens may use the five-slot **`ShopBottomNavigationBar`** or the same home bar where appropriate; checkout flow still uses **`/checkout`** from the cart bar (see **Implemented — checkout**).

**Add to cart (signed-in)** — Shop surfaces open an **Add to Cart** modal bottom sheet (slides up, dimmed barrier, dismiss via tap-outside / drag-down / close X). The sheet lets the user adjust **quantity** and select **size**, then calls `CartNotifier.addWithQuantity(productId, quantity, selectedSize: size)` via `cartNotifierProvider`.  
**Guest behavior:** the sheet does **not** open; a SnackBar is shown instead (“Sign in to add items to your cart.”).  
**Implementation:** `showAddToCartSheetIfSignedIn(context, ref, product: item)` in `lib/features/product/presentation/widgets/add_to_cart_sheet.dart`.

**Visual tokens** — `lib/features/product/presentation/theme/shop_tokens.dart`.

**Catalog mapping** — `ShopCatalog.fromFirestoreProducts` in `shop_catalog.dart` (Equatable). Banners, chips, and tiles derive from product documents; **empty primary image** or failed network loads use **`ProductNetworkImage`** (`CachedNetworkImage` + optional Cloudinary transforms) → **`assets/images/product_placeholder.png`** (declared in `pubspec.yaml`).

---

## Implemented — category (All Categories)

High-level idea: **browse Firestore `categories` on-device**, filter rows by **user gender** and **gender tab**, show each row’s **thumbnail from the first product in that category** when possible, and **expand a category inline** to list its products (same list-row cards as a dedicated page would use—no separate route).

| Concern | Approach |
|--------|----------|
| **Data — categories** | `CategoryService` reads `categories`, maps to `CategoryDocument` (`lib/features/category/data/category_service.dart`). Documents include `name`, `imageUrl`, optional `gender` (`male` / `female` / `both`); missing/invalid `gender` behaves as `both` for filtering. |
| **Fetch + retry** | `fetchedCategoriesProvider` — `FutureProvider<List<CategoryDocument>>` (invalidate this on **Retry** after errors). |
| **User vs catalog gender** | `currentUserCatalogGenderProvider` supplies `"male"` or `"female"` for **which category documents** are returned (category `gender` must match user or be `both`). Independent of the **All / Female / Male** tab used to hide/show rows in the UI (`genderTabProvider`). |
| **Merged UI model** | `allCategoriesCatalogProvider` — `Provider<AsyncValue<List<CatalogCategoryGroup>>>`: builds groups from fetched docs, then watches **`productListProvider`** and sets each row’s **`imageUrl`** to the **chronologically first product** in that category (`createdAt` ascending; ties/`null` use stable `id` order) when that product has a non-empty primary **`imageUrl`**; otherwise keeps the category document’s `imageUrl`. Rebuilds when the product stream updates. |
| **Tab filter** | `GenderTab` + `CatalogCategoryGroup.visibleFor` / `CategoryAudience` — filters which rows appear under All vs Female vs Male (default tab: **All**). |
| **Expansion** | `expandedCategoryIdProvider` — at most one expanded card; auto-adjusts when the gender tab or fetched list changes. |
| **Inline products** | Expanding a row does **not** navigate away. `CategoryProductsExpandedList` (`category_products_expanded_list.dart`) watches **`categoryProductsShopItemsProvider(categoryId)`** — in-memory filter on **`productListProvider`** by `Product.categoryId`, mapped to **`ShopProductItem`** + **`ProductListRowCard`**, with loading/empty/error. Subcategory pills (if present) render above the product list inside the same expanded panel. |
| **Add to cart** | Same bottom sheet as the shop: `showAddToCartSheetIfSignedIn(context, ref, product: item)` (guests see a sign-in SnackBar; signed-in users can pick quantity and submit). |

| Item | Detail |
|------|--------|
| **Route** | `/categories` → `AllCategoriesScreen` |
| **Entry from shop** | `ProductPage` — Categories section, **See All** |
| **Models** | `GenderTab`, `CatalogCategoryGroup`, `CategoryAudience`; Firestore shape in **`CategoryDocument`** (`lib/core/firestore_create/models/category_document.dart`) |
| **UI** | `AllCategoriesHeader`, `GenderTabBar`, `ExpandableCategoryCard` (header + chevron toggle expand; optional subcategory grid + inline product list), `JustForYouCategoryRow` |

**Folder layout:** `lib/features/category/` — `data/` (`category_service.dart`), `presentation/` (`screens`, `widgets`, `providers`, `models`). Browse helpers live under product: `category_browse_providers.dart`, `product_list_row_card.dart`, `product_search_empty_state.dart`.

---

## Implemented — authentication

| Item | Detail |
|------|--------|
| **Routes** | `/login` → `LoginPage`; `/register` → `RegisterPage` (sign-up only; named route uses default `isEditMode: false`) |
| **Use cases** | `LoginWithEmailUseCase`, `RegisterWithEmailUseCase`; **`RegisterWithProfileUseCase`** — email/password sign-up, optional Auth display name, then writes **`users/{uid}`** (email, phone E.164, display name, **`photoUrl`**, **`address`**). **`UpdateUserProfileUseCase`** (profile feature) — updates Auth display name + merges **editable** Firestore fields **without** writing **`email`** (immutable for account identity) |
| **Edit profile (reuse register UI)** | **`RegisterPage`** accepts **`isEditMode`** + optional **`RegisterFormUserData`** (merged from Auth + **`UserProfile`**). Opened from **Profile → header “Edit profile”** (`MaterialPageRoute`, not `/register`). In edit mode: title **Edit Profile**, primary action **Update Profile**; email **read-only**; password fields **hidden**; name, phone, address, avatar editable; submit calls **`UpdateUserProfileUseCase`**. Phone is stored as **E.164**; the register form now formats phone without a country picker: if the user enters a full `+<digits>` value it is preserved, otherwise the app assumes **US `+1`** and uses the entered digits as the national number. |
| **Optional REST placeholders** | `lib/features/profile/data/datasources/user_profile_remote_api_placeholders.dart` — documented stubs if a non-Firestore API replaces writes later |
| **Data** | `AuthRemoteDataSource` → Firebase Auth; `AuthRepositoryImpl` |
| **State** | `authStateProvider` (`StreamProvider<AppUser?>`), `authRepositoryProvider`, use-case providers in `auth_providers.dart`; **`registerWithProfileUseCaseProvider`** in `register_providers.dart`; **`updateUserProfileUseCaseProvider`** in `profile_providers.dart` |
| **Profile image (sign-up)** | User picks a photo on **`RegisterPage`** → **`pickAndUploadProfilePhotoToCloudinary`** → Cloudinary (**`profilesUploadFolder`**) → URL persisted on registration |

---

## Implemented — product (data & domain)

| Item | Detail |
|------|--------|
| **Entity** | `Product` — `id`, `name`, `description`, `price`, **`images`** (`List<ProductImageRef>`: `imageUrl`, `publicId` per slot), **`imageUrl` / `publicId` getters** (primary = first gallery image), `categoryId`, `collectionId` (optional), `isFeatured`, `createdAt` |
| **Model** | `ProductModel` — `fromJson` / `fromFirestore` / `toJson`; reads **`images`** array and/or legacy **`imageUrl`** + **`publicId`**; Firestore `category` or `categoryId` → `categoryId`; `isFeatured`, `createdAt` (Timestamp) |
| **Data** | `ProductRemoteDataSource` — Firestore `products`: futures (`getAllProducts`, `getFeaturedProducts`, `getProductsByCategory`, …) and streams (`watchAllProducts`, …); `Filter.or` on `category` / `categoryId` where needed; `CategoryRemoteDataSource` — `watchCategoryIdToName()` and **`watchCategoryIdToGender()`** for `categories` |
| **Repository** | `ProductRepositoryImpl` — lists normalized with `List<Product>.from(...)` for web-safe generics; `ProductRepository` exposes futures + streams |
| **Firestore** | Top-level `products` — typical fields: `name`, `description`, `price`, **`images`** (array of `{ imageUrl, publicId }`), **`imageUrl` / `publicId`** (primary, for backward compatibility), `category` (or `categoryId`), `isFeatured`, `createdAt` (Timestamp), optional `collectionId` |
| **Use case** | `GetProductsUseCase` |
| **State** | `productListProvider` (stream), `productsProvider` (mirror), `filteredProductsProvider`, `productCategoryFilterProvider`, `productRepositoryProvider`, `categoryRemoteDataSourceProvider`, `categoryIdToNameProvider`, **`categoryIdToGenderProvider`**; shop home: **`homeForAudienceProvider`**, **`homePriceRangeFilterProvider`**, `categoryFilterIndexProvider`, `homeSearchQueryProvider`, `homeSearchFilteredProductsProvider`, `homeSearchShopItemsProvider` (`home_search_providers.dart`) |

`ProductListPage` (`lib/features/product/presentation/pages/product_list_page.dart`) supports add-to-cart (requires signed-in user); shows a snackbar if guest. List **leading** images use **`ProductNetworkImage`** with **`CloudinaryVariant.thumbnail`** when URLs are valid Cloudinary delivery links.

---

## Implemented — Firestore catalog writes (`firestore_create`)

Programmatic **create** APIs for top-level catalog collections (no separate “migration” step; collections appear on first write).

| Item | Detail |
|------|--------|
| **Location** | `lib/core/firestore_create/` — barrel: `firestore_create.dart` |
| **Models** | `ProductDocument`, `CategoryDocument`, `CollectionDocument` — Equatable DTOs with `toFirestoreMap()` / `fromFirestore` where applicable; **`ProductDocument`** includes **`images`** (gallery) and duplicates primary **`imageUrl` / `publicId`** for older readers; **`createdAt`** set on create |
| **Service** | `FirestoreCreateService` — `createProduct`, `createCategory`, `createCollection`; batches (`createProductsBatch`, `createCategoriesBatch`, `createCollectionsBatch`, `createCatalogBatch`); `createProductsBatchChunked` when product count exceeds Firestore’s per-batch limit (500) |
| **Helpers** | Top-level `createProduct` / `createCategory` / `createCollection`; `resolveDocumentId` (empty id → Firestore auto-id); `FirestoreCreateException` |
| **Paths** | `FirestorePaths` in `lib/core/constants/firestore_paths.dart` — `products`, `categories`, `collections`, plus `orders`, `users`, `cart`, `wishlist` |

**`CollectionDocument`** models a **curated group** (e.g. season / featured line): `name`, `description`, `imageUrl`, stored under Firestore collection `collections`. Products reference it via **`collectionId`**.

---

## Implemented — Admin (optional UI)

| Item | Detail |
|------|--------|
| **Flag** | `lib/core/config/feature_flags.dart` — `FeatureFlags.enableAdmin` is true if `enableAdminInSource` is `true` **or** build uses `--dart-define=ENABLE_CREATE_MODE=true` |
| **Route** | `/admin` → `AdminPage` (`lib/features/admin/presentation/pages/admin_page.dart`) |
| **Drawer** | When the flag is on, `AppDrawer` shows **Admin** → `/admin` |
| **Behavior** | Signed-out: auth CTA. Signed-in: **Save category** (optional document id, name, gender; image URL field removed in this branch) and **New product** with **multi-image picker** (`MultiImagePickerWidget`): each file uploads via **`CloudinaryService`** (unsigned preset), then **`FirestoreCreateService.createProduct`** writes **`ProductDocument`** with **`images`** + server **`createdAt`**. Product **collection id** input was removed from Admin UI; products are saved with `collectionId: ''`. At least one product image required. SnackBars + full-screen busy overlay during work |
| **DI** | `firestoreCreateServiceProvider`; **`cloudinaryServiceProvider`** from `core_providers` |

---

## Implemented — Cloudinary & client images

| Item | Detail |
|------|--------|
| **Config** | `lib/core/constants/cloudinary_config.dart` — `cloudName`, **`uploadPreset`** (unsigned; must match Cloudinary Dashboard), **`rootUploadFolder`** (now `fashion_store_app`), plus subfolders like **`profilesUploadFolder`** — uploads can set Cloudinary’s **`folder`** field when the preset allows it |
| **Service** | `lib/services/cloudinary_service.dart` — multipart upload to Cloudinary; optional **`folder`** on **`uploadImage`**; returns `secure_url` + `public_id`; **`thumbnailUrl` / `mediumUrl`** helpers insert transform segments into the same stored URL |
| **Profile avatars** | **`pickAndUploadProfilePhotoToCloudinary`** (`lib/features/profile/presentation/utils/profile_photo_cloudinary.dart`) — bottom sheet (camera / gallery) → **`CloudinaryService.uploadImage`** with **`profilesUploadFolder`** → returns HTTPS URL for Firestore **`photoUrl`**. Used from **`RegisterPage`** (sign-up preview + **`RegisterWithProfileUseCase`**) and **`ProfilePage`** (tap header **`ProfileHeader`** avatar → **`ProfileRepository.saveUserProfile`**) |
| **UI** | `ProductNetworkImage` — **`cached_network_image`** + optional **`CloudinaryVariant`** (thumbnail / medium / original) for list and shop tiles |

Admin (see section above) requires **deployed Firestore rules** that allow signed-in writes to `products`, `categories`, and `collections` (see [Architecture](./architecture.md#firestore-layout)).

---

## Implemented — cart

End-to-end cart for **signed-in** users: Firestore persistence under `users/{uid}/cart`, Riverpod state, shop home add-to-cart, cart screen UI, totals, error handling, and unit tests for pricing helpers.

| Item | Detail |
|------|--------|
| **Route** | `/cart` → `CartPage` (`lib/features/cart/presentation/pages/cart_page.dart`) |
| **Domain** | `CartItem` (`productId`, `quantity`, `selectedSize`); `CartRepository` — `addItem`, `getItems`, `removeItem`, `setItemQuantity`, `setItemSelection`, **`clearCart`** |
| **Use cases** | `AddToCartUseCase`, `RemoveFromCartUseCase`, `SetCartItemQuantityUseCase`, **`ClearCartUseCase`** |
| **Data** | `CartRemoteDataSource` / `CartRemoteDataSourceImpl` — **`addItem`** (transaction: merge quantity on same `productId` doc, no duplicate lines, persists `selectedSize` when provided), **`fetchItems`**, **`removeItem`**, **`setItemQuantity`**, **`setItemSelection`** (quantity + size update in one write; deletes doc if `quantity <= 0`), **`clearCart`** (batched deletes, chunked at 450 ops per batch); `CartRepositoryImpl`; `CartItemModel` |
| **Presentation — state** | `cartNotifierProvider` (`StateNotifierProvider<CartNotifier, CartState>`): **`add`**, **`addWithQuantity`** (with optional `selectedSize`), **`setItemSelection`** (used by cart edit sheet), **`remove`**, **`incrementQuantity`**, **`decrementQuantity`** (removes line at qty 1), **`clear`**, **`refresh`**; `CartState` includes **`items`**, **`loading`**, **`isGuest`**, **`errorMessage`**; mutations avoid full-screen loading where possible |
| **Presentation — UI providers** | `cart_ui_providers.dart` — **`cartResolvedLinesProvider`** (`List<CartResolvedLine>` joined to **`productListProvider`**); **`cartOrderTotalProvider`** (**`computeCartOrderTotal`**); **`cartShippingAddressProvider`** — **session override** only (empty until the user taps **Edit** on a shipping card and saves); **`resolvedCartShippingAddressProvider`** — **effective** delivery line: non-empty session override, else **`UserProfile.address`** from **`userProfileProvider`**, else empty; **`shippingAddressDisplayLabel`** — card copy when resolved is empty (hint to save address in Profile or tap edit); **`wishlistProductsForCartProvider`** (wishlist products not already in cart) |
| **Presentation — UI** | Shipping card, line items (`CartItemWidget`), **`CartQuantitySelector`**, wishlist rows, **`CartCheckoutBar`** (total + **Checkout** → pushes **`/checkout`**), empty and guest states; header **clear cart** (confirm dialog); load failure **Retry**; **`ref.listen`** surfaces **`errorMessage`** via SnackBar. Cart line subtitles now display persisted selected size instead of a hardcoded `Size M`. |
| **Cart item edit UX** | Each cart line has an **Edit** action that opens the Add-to-cart sheet prefilled with current quantity + size; save updates the existing line via `setItemSelection` (does not create a duplicate line). |
| **Shop integration** | `ProductPage` — add-to-cart on **Just For You** and **New Items** (see **Implemented — shop home**) |
| **Tests** | `test/cart_order_total_test.dart` — `computeCartOrderTotal`, `CartItemHelper.quantityFor` |

**Guest behavior:** cart is not loaded from Firestore; `CartPage` shows a sign-in prompt. After sign-in, cart loads from the user’s subcollection.

**Persistence:** cart documents survive app restarts (Firestore). Clearing the cart removes all `users/{uid}/cart/*` documents.

---

## Implemented — checkout

Review and pricing step **before** the dedicated payment screen: **signed-in** users with a non-empty cart. Composes existing cart, product, and auth providers (no separate cart repository).

| Item | Detail |
|------|--------|
| **Route** | `/checkout` → `CheckoutPage` (`lib/features/checkout/presentation/screens/checkout/checkout_page.dart`) |
| **Entry** | `CartPage` — **`CartCheckoutBar`** `onCheckout` → `Navigator.pushNamed(context, '/checkout')` |
| **Cart & totals** | **`cartResolvedLinesProvider`**, **`computeCartOrderTotal`** (subtotal); delivery fee **0** (Standard) or **500 LKR** (Express) via **`checkoutShippingOptionProvider`**; voucher discount via **`checkoutVoucherDiscountProvider`** (e.g. dialog code **`SAVE10`** → 10% off subtotal); optional **5% line-item discount** when **`checkoutFivePercentPromoEnabledProvider`** is on (aligned with the payment screen total) |
| **Session UI state** | **`checkout_providers.dart`** — `CheckoutShippingOption` (standard / express), `CheckoutPaymentMethod` (card / cash on delivery), contact phone string, voucher discount amount, **`checkoutFivePercentPromoEnabledProvider`** (toggle for the promo chip) |
| **Shared address** | **`resolvedCartShippingAddressProvider`** for display, validation before **Pay**, and order persistence (see **Implemented — cart** — shipping providers). Session edits still update **`cartShippingAddressProvider`** from cart / checkout / payment dialogs |
| **Contact** | Phone from **`checkoutContactPhoneProvider`**; email from **`authStateProvider`** → `AppUser.email` (display name derived from email local-part for the shipping card title line) |
| **Continue to payment** | **Pay** uses **`Navigator.push` → `MaterialPageRoute`** to **`PaymentMethodScreen`** (named route **`/payment`** in `RouteSettings` for back-stack). This avoids relying only on hash **`/#/payment`** on web, where the payment scaffold could paint unreliably. If the catalog is still loading and subtotal is 0, checkout waits once on **`productListProvider.future`** so the first tap can navigate. |
| **Place order** | **`placeOrderAfterSuccessfulPayment`** in **`lib/features/checkout/domain/place_order.dart`** — reads **`resolvedCartShippingAddressProvider`** for **`OrderShippingAddressModel.addressLine`** (profile-backed when session override is empty), builds **`OrderModel`**, persists via **`OrderService.createOrder`**, then clears the cart; invoked from the payment flow (`order_placement_controller`). |
| **Guards** | **`authStateProvider`**: loading → spinner; error → snack + pop; signed out → snack + pop; **empty cart** (after load) → snack + pop |
| **UI modules** | `widgets/address_card_widget.dart`, `contact_info_card_widget.dart`, `order_item_widget.dart`, `shipping_options_widget.dart`, `payment_method_widget.dart`, `price_summary_widget.dart`; tokens in **`theme/checkout_tokens.dart`** |

**Folder layout:** `lib/features/checkout/` — `domain/` (`place_order.dart`), `presentation/screens/checkout/`, `presentation/widgets/`, `presentation/providers/`, `presentation/theme/`.

---

## Implemented — payment (method screen)

Second step after checkout: confirm address/contact/items, pick **card** (mock saved card + add-new) or **cash on delivery**, then **Pay** through the payment service flow (success / processing / failure routes).

| Item | Detail |
|------|--------|
| **Route** | `/payment` → `PaymentMethodScreen` (`lib/features/payment/presentation/screens/payment/payment_method_screen.dart`), registered in **`lib/app.dart`** for deep links / hash navigation |
| **Entry** | Primary path: **`CheckoutPage`** **Pay** → **`MaterialPageRoute`** (see **Implemented — checkout**). Direct URL: **`/#/payment`** (same widget) |
| **Auth** | **`authStateProvider`**: loading → spinner; error / signed out → blocked message (no guest checkout on this flow) |
| **Data** | Same cart/checkout providers as checkout: resolved lines, **`resolvedCartShippingAddressProvider`** for the shipping card and pay guard, contact, shipping option, voucher, optional **5% promo** flag (totals match checkout when the flag is on) |
| **Layout (web)** | Body is a **scrollable column** (own **`ScrollController`**) inside a **fixed-height** scaffold region; **`SavedPaymentCardWidget`** uses **`IntrinsicHeight`** around a stretched **Row** so layout works under scroll constraints (avoids “infinite height” flex errors on Flutter web) |
| **Orders list refresh** | After a successful place-order, **`ref.invalidate(ordersForUserProvider)`** so **`StreamProvider`**-based consumers (and any **`invalidate`** listeners) pick up the new document (see **Implemented — orders & My Orders**) |
| **Saved card settings** | Settings action on the saved-card panel opens `CardPaymentScreen` prefilled with current holder + expiry. In edit mode, card number input is optional; leaving it blank keeps the existing last-4 digits. |
| **Success flow (current branch)** | After successful payment/order creation, the flow returns to **`/cart`** and shows **`Order confirmed`** (floating SnackBar) instead of redirecting to `/orders`. |
| **UI** | Pay bar + **`ShopBottomNavigationBar`**; payment tokens in **`lib/features/payment/presentation/theme/payment_tokens.dart`**; widgets under **`presentation/widgets/`** (e.g. **`SavedPaymentCardWidget`**, **`PaymentOptionTile`**) |

**Folder layout:** `lib/features/payment/` — `presentation/` (screens, widgets, theme, providers), `services/` (e.g. payment orchestration), plus card/success/failure screens colocated under `presentation/screens/payment/`.

---

## Implemented — orders & My Orders

End-to-end **order persistence** and a **My Orders** screen that shows the signed-in user’s orders from Firestore in **real time** (no mock data).

| Item | Detail |
|------|--------|
| **Route** | `/orders` → `OrdersPage` → **`MyOrdersScreen`** (`lib/features/order/presentation/pages/orders_page.dart` → `presentation/screens/my_orders_screen.dart`) |
| **Create path** | After a successful payment, **`placeOrderAfterSuccessfulPayment`** (`lib/features/checkout/domain/place_order.dart`) writes to **`orders/{orderId}`** with **`userId`**, line **`items`**, **`totalAmount`**, payment + order status, **`shippingAddress`**, server timestamps for **`createdAt`** / **`updatedAt`** |
| **Domain** | **`OrderModel`**, **`OrderLineItemModel`**, **`OrderShippingAddressModel`** — `fromJson` / `toJson` with Firestore **`Timestamp`** handling (`lib/features/order/domain/entities/order_model.dart`) |
| **Data** | **`OrderService`** (`lib/features/order/data/services/order_service.dart`) — **`watchUserOrdersStream(userId)`** listens to **`where('userId', isEqualTo: userId)`** and sorts by **`createdAt` descending in memory** (avoids needing a composite Firestore index for `where` + `orderBy`); **`getUserOrders`** same pattern; **`createOrder`**, **`getOrderById`**, **`updateOrderStatus`** |
| **Repository** | **`OrderRepositoryImpl`** implements **`OrderRepository`** (`getOrdersForUser`) for one-shot reads; **`GetOrdersUseCase`** wraps the repository if you need it outside streams |
| **State (Riverpod)** | **`orderServiceProvider`**, **`orderRepositoryProvider`**, **`ordersForUserProvider`** — **`StreamProvider<List<OrderModel>>`** using **`FirebaseAuth.currentUser?.uid`** (with **`authStateProvider`** watched so the stream rebuilds on sign-in/out); used e.g. to **`invalidate`** after placing an order from **`PaymentMethodScreen`** |
| **My Orders UI** | **`StreamBuilder`** over the user’s order stream; **loading** → centered **`CircularProgressIndicator`**; **empty** → “No Orders Yet”; **error** → short message (e.g. missing index / network), **pull-to-refresh** to retry; **`ListView.builder`** + **`OrderCard`** (track/review callbacks wired as no-ops until flows exist); **`RefreshIndicator`** on list and empty/error scrollables. If the currently selected order chip has no matches while orders exist, the screen auto-selects the best-matching chip for the highlighted/newest order to avoid blank initial paint. |
| **Firestore** | Collection **`orders`** (see [Architecture](./architecture.md#firestore-layout)); rules should restrict reads to the owner via **`userId`** |

**Note:** If you later switch to **`orderBy('createdAt')` in the Firestore query**, add a **composite index** (`userId` + `createdAt`) in the console or **`firestore.indexes.json`** and deploy.

---

## Implemented — wishlist

| Item | Detail |
|------|--------|
| **Route** | `/wishlist` → `WishlistPage` |
| **Use case** | `GetWishlistUseCase` |
| **Data** | `users/{uid}/wishlist/{productId}` |
| **State** | `wishlistForUserProvider` |
| **Repository** | Also exposes `addItem` for future UI |

---

## Implemented — profile

| Item | Detail |
|------|--------|
| **Route** | `/profile` → `ProfilePage` (`lib/features/profile/presentation/pages/profile_page.dart`) |
| **Use cases** | `GetUserProfileUseCase`; **`UpdateUserProfileUseCase`** — Firestore **`ProfileRepository.updateUserEditableProfile`** merges **`displayName`**, **`phoneNumber`**, **`photoUrl`**, **`address`** (no **`email`** in merge payload) |
| **Data** | Document `users/{uid}` — e.g. `email`, `phoneNumber`, `displayName`, `photoUrl`, **`address`** (optional; used as default **delivery address** when cart/checkout session override is empty — see **Implemented — cart** / **checkout**) |
| **State** | `userProfileProvider` (`FutureProvider<UserProfile?>`); **`authStateProvider`** for guest vs signed-in and **email** subtitle |
| **Shell** | No `AppBar`; **`AppDrawer`** (menu control in header); **`ShopBottomNavigationBar`** with **Profile** tab selected (index 4), same destinations as shop home |
| **Auth UX** | **Guest:** dashboard-style layout, **Sign in** CTA → `/login`, guarded taps. **Signed in:** full scroll with **Logout** → `authRepositoryProvider.signOut()` |
| **Edit profile** | **`ProfileHeader` → “Edit profile”** opens **`RegisterPage(isEditMode: true, …)`** with **`RegisterFormUserData.merge`**; success **`invalidate`s** `userProfileProvider`. In edit mode, fields show explicit labels (Name, Email, Phone, Address) above inputs. |
| **Profile photo (Cloudinary)** | Signed-in users: **tap the header avatar** → same flow as register (**`pickAndUploadProfilePhotoToCloudinary`**) → update **`users/{uid}`** via **`profileRepositoryProvider.saveUserProfile`** (preserves other fields including **`address`**) → **`ref.invalidate(userProfileProvider)`**. Loading overlay on the avatar while uploading |

**UI (top to bottom):** `ProfileHeader` (avatar — **tappable when signed in** for photo change; optional menu, **My Activity**, wallet / notifications / settings, **Hello, {first name}**, subtitle, **Edit profile** → edit flow above); **Announcement** banner; **Recently viewed** …; **My Orders** …; **Stories** …; divider; **Account** list — My Orders, Payment Methods, Notifications; **Settings** …; **Logout** …. (Wishlist and Addresses options were removed in this branch.)

**Presentation layout** — `lib/features/profile/presentation/`:

| Path | Role |
|------|------|
| `theme/profile_ui_tokens.dart` | Profile-specific colors, spacing, radii, shadows (e.g. accent `#1D61FF`) |
| `widgets/profile_header.dart` | `ProfileHeader` |
| `widgets/profile_section_title.dart` | `SectionTitle` |
| `widgets/profile_option_tile.dart` | `ProfileOptionTile` |
| `widgets/profile_announcement_banner.dart` | Announcement card |
| `widgets/profile_recently_viewed_row.dart` | Recently viewed circles |
| `widgets/profile_order_status_chips.dart` | Order status chips |
| `widgets/profile_stories_row.dart` | `ProfileStoriesRow`, `ProfileStoryItem` |

Reuses **`ShopBottomNavigationBar`** and **`ShopTokens`** from the product feature for consistency with the shop shell.

---

## Implemented — shared shell

| Item | Detail |
|------|--------|
| **Navigation drawer** | `lib/core/widgets/app_drawer.dart` — Products (reset to `/`), Cart, Wishlist, Orders, Profile, Sign in / Sign out; optional **Admin** when `FeatureFlags.enableAdmin` is true (catalog creation with multi-image upload — **no** separate “Add product” route). **`ProfilePage`** exposes it from the header menu icon (no `AppBar` leading). |
| **Feature flags** | `lib/core/config/feature_flags.dart` — Admin toggle (see **Implemented — Admin** above) |
| **Core DI** | `lib/core/providers/core_providers.dart` — `FirebaseFirestore`, `FirebaseAuth`, `FirebaseStorage`, `FirebaseStorageService` |
| **Storage helper** | `FirebaseStorageService` — e.g. product images under paths from `storage_paths.dart` |
| **Product image fallback** | `lib/core/constants/product_assets.dart` — placeholder path; **`pubspec.yaml`** `flutter.assets` includes `assets/images/product_placeholder.png` |

---

## Implemented — tests

| Item | Detail |
|------|--------|
| **Smoke** | `test/widget_test.dart` — basic scaffold render |
| **Cart logic** | `test/cart_order_total_test.dart` — `computeCartOrderTotal` (sums, unknown products, per-line rounding), `CartItemHelper.quantityFor` — no Firebase required |

---

## Planned / next steps

- **Visual / backend search** — optional **image / visual** search (camera affordance on the bar) or **server-side** text search (e.g. Algolia, Firestore full-text) if the catalog outgrows comfortable **client-side** filtering on the home stream.
- **Product detail** — taps from shop cards and list rows.
- **Checkout completion** — extend payment success UX / order detail beyond current **My Orders** list (e.g. track shipment, reviews) — persistence path: **`placeOrderAfterSuccessfulPayment`** + **`OrderService`**.  
- **Firestore rules & indexes** — tighten catalog writes (today any signed-in user can write `products` / `categories` / `collections` for Admin); add composite indexes only if you add multi-field queries (e.g. `where` + `orderBy` on different fields).

Update this file when behavior or routes change.

---

## Dependencies (current)

Authoritative list: `pubspec.yaml`. Notable packages:

- `flutter_riverpod` — state and dependency injection.
- `equatable` — value equality (domain entities, shop models).
- `firebase_core` ^3.15.2, `firebase_auth` ^5.7.0, `cloud_firestore` ^5.6.12, `firebase_storage` ^12.4.10 — Firebase integration (aligned with the latest dependency refresh on this branch).
- `http`, `http_parser`, `image_picker`, `cached_network_image` — Cloudinary uploads + gallery pickers + cached product images.

---

## Related documentation

- [Architecture](./architecture.md) — folder layout, routes, Firestore paths.
- [Project overview](./project-overview.md).
- [Coding standards](./coding-standards.md).
