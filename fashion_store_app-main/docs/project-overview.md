# Project overview

## Purpose

**Fashion Store Application** is a cross-platform Flutter client for a fashion retail experience: shop-style browsing, Firebase-backed catalog and user data, cart/wishlist/orders/profile, and email authentication.

## High-level idea

| Theme | What we do |
|--------|------------|
| **Catalog truth** | **Firestore** (`products`, `categories`, …) is the live catalog. The app streams documents and maps them into domain **`Product`** models—no mock product lists on the shop home. |
| **Product media** | Each product can store a **gallery**: Firestore field **`images`** as an array of `{ imageUrl, publicId }`, plus **`imageUrl` / `publicId`** on the first image for older readers. List/cart/checkout use the **primary** image via getters. |
| **Uploads** | **Cloudinary** receives images from the client using an **unsigned upload preset** (config in `lib/core/constants/cloudinary_config.dart`). No API secret in the app. Delivery URLs support **on-the-fly transforms** (thumbnail / medium) in `ProductNetworkImage` without storing multiple URLs per size. |
| **Profile photos** | **User avatars** use the same Cloudinary unsigned flow: pick camera or gallery → **`CloudinaryService.uploadImage`** with optional **`profilesUploadFolder`** → store the returned **`secure_url`** on **`users/{uid}.photoUrl`** in Firestore. **Register** (`RegisterPage`) can set a photo during sign-up; **Profile** (`ProfilePage`) lets signed-in users **tap the header avatar** to replace it. Shared helper: **`pickAndUploadProfilePhotoToCloudinary`** (`lib/features/profile/presentation/utils/profile_photo_cloudinary.dart`). |
| **Profile & address** | **Edit profile** (Profile header) reuses **`RegisterPage`** in **`isEditMode`**: update name, phone, **`address`**, photo; email read-only; **`UpdateUserProfileUseCase`** merges Firestore fields without changing **`email`**. Optional **`users/{uid}.address`** feeds **`resolvedCartShippingAddressProvider`** so **cart / checkout / payment** show the saved line as the default delivery address unless the user overrides it in-session (**`cartShippingAddressProvider`**). |
| **Phone (E.164)** | Phone numbers are stored as **E.164** strings on `users/{uid}.phoneNumber`. The Register/Edit Profile form formats phone without a country picker: if the user enters `+<digits>` it is preserved; otherwise the app assumes **US `+1`** and combines it with the entered digits. |
| **Vendor / admin entry** | **Admin** (feature-flagged) is the place to **create categories and products**, including **multiple images per product** (pick many → upload each → save `ProductDocument` via `FirestoreCreateService`). There is no separate “Add product” route. |
| **Shop home — categories** | Category tiles are **not** a single hero photo: each card shows a **2×2 collage**. We take up to **four distinct image URLs** from products in that category (newest products first, deduped across the gallery). Missing quadrants show a **“No Image”** placeholder— we do **not** repeat one image to fill the grid. |
| **All Categories list** | Full-screen list of **`categories`** documents (filtered by user/catalog gender). Each row’s **48×48 thumbnail** prefers the **first product** in that category (by `createdAt`, oldest first); falls back to the category’s **`imageUrl`**. Expanding a row shows **products for that `categoryId`** inline (list rows + cart), not a separate page. See [Features](./features.md) — *Implemented — category (All Categories)*. |
| **Product search (shop home)** | The header search bar drives a **debounced** query; results are **filtered in memory** on the same Firestore `products` stream — **no extra reads per keystroke**. Order: **For** (audience vs each category’s Firestore **`gender`**) → **category chip** → **text** match on **name**, **description**, and **category label** → optional **drawer price** range. See [Features](./features.md) — *Product search (shop home)*. |
| **Shopping flow** | Same app shell: browse → cart (signed-in) → checkout → payment mock → orders persisted in Firestore. Current UI flow returns to **cart** with an **Order confirmed** message after successful payment. |

For feature-level detail, see **[Features](./features.md)** and **[Architecture](./architecture.md)**.

## Repository

| Item | Detail |
|------|--------|
| Package name | `fashion_store_application` |
| SDK | Dart `^3.11.3` (see `pubspec.yaml`) |
| Platforms | As enabled in the Flutter project (Android, iOS, web, desktop) |

## Current status

The app is **past the default counter template**. It includes:

| Area | Summary |
|------|---------|
| **Architecture** | Feature-first **Clean Architecture** (`domain` / `data` / `presentation`) under `lib/features/*` |
| **State** | **Riverpod** for UI state and dependency injection |
| **Backend** | **Firebase** Auth, Firestore, Storage |
| **Shop UI** | **`ProductPage`** at `/` — live `products` + **`shopCatalogProvider`**; category **names** (`categoryIdToNameProvider`) and **gender** (`categoryIdToGenderProvider`) from `categories`; **For** audience filter; **tune** drawer (For, category, price); debounced **in-memory** search; **2×2** category grid (see **High-level idea** above) |
| **All Categories** | **`AllCategoriesScreen`** at **`/categories`** — Firestore **`categories`** (via **`CategoryService`**), gender tab + per-user category filtering, row thumbnails from each category’s **earliest product** when available, **inline expanded product list** per category (`lib/features/category/`); opened from shop **Categories → See All** |
| **Product list** | **`ProductListPage`** at **`/browse`** — `lib/features/product/presentation/pages/product_list_page.dart`; `filteredProductsProvider`; optional Firestore delete; Admin + cart in the app bar; thumbnails via **`ProductNetworkImage`** |
| **Account & commerce shells** | **`/login`**, **`/cart`**, **`/checkout`** → **`/payment`** (payment method screen after **Pay**), **`/wishlist`**, **`/orders`**, **`/profile`** |
| **Orders & My Orders** | **`/orders`** → **`MyOrdersScreen`** — lists the signed-in user’s documents from Firestore **`orders`** (query **`userId`**, newest-first via client-side sort on **`createdAt`**). **`OrderService`** exposes **`watchUserOrdersStream`**; the UI uses **`StreamBuilder`**, **`RefreshIndicator`**, and loading / empty (“No Orders Yet”) / error states. New orders are written after a successful payment via **`placeOrderAfterSuccessfulPayment`** → **`OrderService.createOrder`**. Riverpod **`ordersForUserProvider`** is a **`StreamProvider<List<OrderModel>>`** (invalidated after checkout success so lists stay fresh). See **[Features](./features.md)** (section **Implemented — orders & My Orders**). |
| **Profile UI** | **`ProfilePage`** — scrollable dashboard-style profile; **Edit profile** opens the shared register form in edit mode with visible field labels; account/settings lists and logout; shares **`ShopBottomNavigationBar`** with the shop when opened from the Profile tab. Wishlist and Addresses options were removed from the profile account section in this branch. |
| **Navigation** | **`AppDrawer`** (e.g. Products → home, Cart, Wishlist, Orders, Profile); shop home **`ShopHomeBottomNavigationBar`**: Home, Cart, Profile; **`Navigator.pushNamed('/categories')`** from Categories **See all**; cart **Checkout** → **`/checkout`**; checkout **Pay** → payment screen via **`MaterialPageRoute`** (see [Features](./features.md) — **Implemented — payment**) |
| **Firestore catalog writes** | **`lib/core/firestore_create/`** — `ProductDocument`, `CategoryDocument`, `CollectionDocument`; **`FirestoreCreateService`** (single + batch creates, optional auto ids, `FirestoreCreateException`) |
| **Admin (optional)** | **`FeatureFlags`** — drawer **Admin** + **`/admin`** — signed-in **category/product** creation; products support **multi-image** pick → **Cloudinary** upload → **`ProductDocument`** with `images` array + `createdAt` (see [Features](./features.md)). Category image URL input and product collection-id input were removed from Admin UI in this branch. |

Shared wiring lives in **`lib/core/`** (constants, **feature flags**, **firestore_create**, errors, Firebase bootstrap, storage helper, `core_providers`, `AppDrawer`). Entry: **`lib/main.dart`** → **`lib/app.dart`**.

For a feature-by-feature breakdown and Firestore shapes, see **[Features](./features.md)** and **[Architecture](./architecture.md)**.

## Branch UI refactor highlights

- Cart lines now persist and display selected size (`selectedSize`) across cart/checkout/payment.
- Cart supports inline **Edit** action that reopens Add-to-cart sheet with prefilled size/quantity.
- Payment card **Settings** now opens editable, prefilled card form (holder/expiry; optional card number in edit mode).
- Payment success flow currently returns to **`/cart`** with an **Order confirmed** snackbar.
- Profile account section removed **Wishlist** and **Addresses** options; edit profile fields show visible labels.

## Firebase setup (required to run against real data)

**Committed in the repository (Firebase configuration + dependency upgrades):**

| File | Role |
|------|------|
| **`firebase.json`** | FlutterFire / Firebase CLI metadata: default Android app output and Dart config mapping into **`lib/firebase_options.dart`**. |
| **`lib/firebase_options.dart`** | `DefaultFirebaseOptions` per platform (Android, iOS, web, macOS, Windows) for project **`fashion-store-app-e5662`**. |
| **`android/app/google-services.json`** | Android Google Services plugin config for the same Firebase app. |

**Firebase package versions** (see `pubspec.yaml`): `firebase_core` ^3.15.2, `firebase_auth` ^5.7.0, `cloud_firestore` ^5.6.12, `firebase_storage` ^12.4.10.

**You still need in the Firebase console:** **Authentication** (e.g. Email/Password), **Firestore**, and **Storage** enabled as the app uses them; **Firestore security rules** deployed from **`firestore.rules`** (see [Architecture — Firestore layout](./architecture.md#firestore-layout)) so catalog writes and Admin work for signed-in users.

**iOS:** add **`GoogleService-Info.plist`** to the Runner target when building for iOS (not committed in this repo yet). Regenerate or extend config with **`dart run flutterfire_cli:flutterfire configure`** if you change the Firebase project or add platforms.

Until Firebase is configured for your target platform, initialization may fail at runtime; the widget test avoids bootstrapping the full app.

## Getting started

- Install the [Flutter SDK](https://docs.flutter.dev/get-started/install) and run `flutter doctor`.  
- From the project root: `flutter pub get`, then `flutter run` (or target a specific device).  
- Run **`flutter analyze`** and **`flutter test`** before merging.

## Related documentation

- [Architecture](./architecture.md) — folders, routes, DI, Firestore.  
- [Features](./features.md) — implemented behavior and planned work.  
- [Coding standards](./coding-standards.md) — Dart/Flutter conventions.
