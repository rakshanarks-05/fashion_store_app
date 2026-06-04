import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/firestore_paths.dart';
import '../models/category_document.dart';
import '../models/collection_document.dart';
import '../models/product_document.dart';
import '../utils/firestore_create_exception.dart';
import '../utils/firestore_document_id.dart';

/// Writes catalog documents (products, categories, collections) to Firestore.
///
/// Firestore creates collection "containers" implicitly on first write; no extra
/// setup is required beyond defining paths in [FirestorePaths].
class FirestoreCreateService {
  FirestoreCreateService(this._firestore);

  final FirebaseFirestore _firestore;

  // --- Single-document creates ---

  /// Persists one product. If [product.id] is empty, an auto-generated id is used.
  ///
  /// Returns the document id that was written (never empty).
  Future<String> createProduct(ProductDocument product) async {
    try {
      final id = resolveDocumentId(
        _firestore,
        FirestorePaths.products,
        product.id,
      );
      await _firestore
          .collection(FirestorePaths.products)
          .doc(id)
          .set(product.toFirestoreMap());
      return id;
    } catch (e, st) {
      Error.throwWithStackTrace(
        FirestoreCreateException('Failed to create product', e),
        st,
      );
    }
  }

  /// Persists one category. If [category.id] is empty, an auto-generated id is used.
  Future<String> createCategory(CategoryDocument category) async {
    try {
      final id = resolveDocumentId(
        _firestore,
        FirestorePaths.categories,
        category.id,
      );
      await _firestore
          .collection(FirestorePaths.categories)
          .doc(id)
          .set(category.toFirestoreMap());
      return id;
    } catch (e, st) {
      Error.throwWithStackTrace(
        FirestoreCreateException('Failed to create category', e),
        st,
      );
    }
  }

  /// Persists one collection document. If [collection.id] is empty, an auto-generated id is used.
  Future<String> createCollection(CollectionDocument collection) async {
    try {
      final id = resolveDocumentId(
        _firestore,
        FirestorePaths.collections,
        collection.id,
      );
      await _firestore
          .collection(FirestorePaths.collections)
          .doc(id)
          .set(collection.toFirestoreMap());
      return id;
    } catch (e, st) {
      Error.throwWithStackTrace(
        FirestoreCreateException('Failed to create collection', e),
        st,
      );
    }
  }

  // --- Batch creates (atomic single commit per batch, max 500 ops) ---

  /// Commits multiple writes in one batch. Throws if the batch exceeds Firestore limits.
  Future<void> createProductsBatch(Iterable<ProductDocument> products) async {
    final list = products.toList();
    if (list.isEmpty) return;
    await _runBatched(list, (batch, i, items) {
      final product = items[i];
      final id = resolveDocumentId(
        _firestore,
        FirestorePaths.products,
        product.id,
      );
      batch.set(
        _firestore.collection(FirestorePaths.products).doc(id),
        product.toFirestoreMap(),
      );
    }, 'products batch');
  }

  /// Batch-create categories.
  Future<void> createCategoriesBatch(Iterable<CategoryDocument> categories) async {
    final list = categories.toList();
    if (list.isEmpty) return;
    await _runBatched(list, (batch, i, items) {
      final category = items[i];
      final id = resolveDocumentId(
        _firestore,
        FirestorePaths.categories,
        category.id,
      );
      batch.set(
        _firestore.collection(FirestorePaths.categories).doc(id),
        category.toFirestoreMap(),
      );
    }, 'categories batch');
  }

  /// Batch-create collection documents.
  Future<void> createCollectionsBatch(
    Iterable<CollectionDocument> collections,
  ) async {
    final list = collections.toList();
    if (list.isEmpty) return;
    await _runBatched(list, (batch, i, items) {
      final col = items[i];
      final id = resolveDocumentId(
        _firestore,
        FirestorePaths.collections,
        col.id,
      );
      batch.set(
        _firestore.collection(FirestorePaths.collections).doc(id),
        col.toFirestoreMap(),
      );
    }, 'collections batch');
  }

  /// Runs a single [WriteBatch] mixing products, categories, and collections.
  ///
  /// Total operations must be ≤ 500 (Firestore limit).
  Future<void> createCatalogBatch({
    Iterable<ProductDocument> products = const [],
    Iterable<CategoryDocument> categories = const [],
    Iterable<CollectionDocument> collections = const [],
  }) async {
    final productList = products.toList();
    final categoryList = categories.toList();
    final collectionList = collections.toList();
    final total =
        productList.length + categoryList.length + collectionList.length;
    if (total == 0) return;
    if (total > 500) {
      throw FirestoreCreateException(
        'Catalog batch has $total operations; Firestore allows at most 500.',
      );
    }

    final batch = _firestore.batch();
    try {
      for (final product in productList) {
        final id = resolveDocumentId(
          _firestore,
          FirestorePaths.products,
          product.id,
        );
        batch.set(
          _firestore.collection(FirestorePaths.products).doc(id),
          product.toFirestoreMap(),
        );
      }
      for (final category in categoryList) {
        final id = resolveDocumentId(
          _firestore,
          FirestorePaths.categories,
          category.id,
        );
        batch.set(
          _firestore.collection(FirestorePaths.categories).doc(id),
          category.toFirestoreMap(),
        );
      }
      for (final col in collectionList) {
        final id = resolveDocumentId(
          _firestore,
          FirestorePaths.collections,
          col.id,
        );
        batch.set(
          _firestore.collection(FirestorePaths.collections).doc(id),
          col.toFirestoreMap(),
        );
      }
      await batch.commit();
    } catch (e, st) {
      if (e is FirestoreCreateException) rethrow;
      Error.throwWithStackTrace(
        FirestoreCreateException('Failed to commit catalog batch', e),
        st,
      );
    }
  }

  /// Splits large lists into multiple commits of at most [chunkSize] operations.
  Future<void> createProductsBatchChunked(
    Iterable<ProductDocument> products, {
    int chunkSize = 450,
  }) async {
    final list = products.toList();
    for (var i = 0; i < list.length; i += chunkSize) {
      final chunk = list.sublist(
        i,
        i + chunkSize > list.length ? list.length : i + chunkSize,
      );
      await createProductsBatch(chunk);
    }
  }

  Future<void> _runBatched<T>(
    List<T> items,
    void Function(WriteBatch batch, int index, List<T> items) addOp,
    String label,
  ) async {
    const maxOps = 500;
    if (items.length > maxOps) {
      throw FirestoreCreateException(
        '$label: ${items.length} ops exceeds Firestore batch limit ($maxOps). '
        'Use chunked helpers or split the input.',
      );
    }
    try {
      final batch = _firestore.batch();
      for (var i = 0; i < items.length; i++) {
        addOp(batch, i, items);
      }
      await batch.commit();
    } catch (e, st) {
      Error.throwWithStackTrace(
        FirestoreCreateException('Failed to commit $label', e),
        st,
      );
    }
  }
}

/// Top-level helpers for quick one-off scripts or tests (inject [firestore]).
Future<String> createProduct(
  FirebaseFirestore firestore,
  ProductDocument product,
) =>
    FirestoreCreateService(firestore).createProduct(product);

Future<String> createCategory(
  FirebaseFirestore firestore,
  CategoryDocument category,
) =>
    FirestoreCreateService(firestore).createCategory(category);

Future<String> createCollection(
  FirebaseFirestore firestore,
  CollectionDocument collection,
) =>
    FirestoreCreateService(firestore).createCollection(collection);
