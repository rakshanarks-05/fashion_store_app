# fashion_store_application

Fashion Store — Flutter app with Firebase (Auth, Firestore, Storage), Riverpod, and feature-first Clean Architecture.

## Documentation

- **[Project overview](docs/project-overview.md)** — purpose, **high-level product idea** (catalog + media + shop UX), stack, Firebase setup, how to run.  
- **[Architecture](docs/architecture.md)** — folders, routes, Firestore layout.  
- **[Features](docs/features.md)** — implemented behavior.  
- **[Coding standards](docs/coding-standards.md)**

At a glance: **Firestore** holds the catalog and user data; **product galleries** are stored as an `images` array plus legacy primary `imageUrl`; **Cloudinary** handles client-side image uploads (unsigned preset); the **shop home** filters by **For** (audience) using each category’s **`gender`** field, offers a **filter drawer** (For, category, price), and runs **debounced in-memory search** on the same `products` stream; the category grid uses a **2×2 collage** of up to four distinct product images per category; **Admin** (optional flag) is where vendors add categories/products with **multi-image** upload.

**Firebase:** root **`firebase.json`**, **`lib/firebase_options.dart`**, and **`android/app/google-services.json`** are configured for Firebase project **`fashion-store-app-e5662`**. See the project overview for iOS plist and console steps.

## Getting started

From the repo root: `flutter pub get`, then `flutter run`. Use `flutter analyze` and `flutter test` before merging.

### Flutter resources

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)  
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)  
- [Flutter documentation](https://docs.flutter.dev/)
