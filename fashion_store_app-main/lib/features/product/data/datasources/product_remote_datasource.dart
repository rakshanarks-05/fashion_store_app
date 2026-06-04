import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> fetchProducts({String? category});

  Future<List<ProductModel>> getAllProducts();

  Future<List<ProductModel>> getFeaturedProducts();

  Future<List<ProductModel>> getProductsByCategory(String category);

  Stream<List<ProductModel>> watchAllProducts();

  Stream<List<ProductModel>> watchFeaturedProducts();

  Stream<List<ProductModel>> watchProductsByCategory(String category);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  ProductRemoteDataSourceImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection(FirestorePaths.products);

  void _logError(String method, Object error, StackTrace stackTrace) {
    developer.log(
      'ProductRemoteDataSource.$method failed',
      name: 'FashionStore',
      error: error,
      stackTrace: stackTrace,
    );
  }

  List<ProductModel> _mapAndSortByCreatedAt(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final list = docs.map((d) => ProductModel.fromFirestore(d)).toList();
    list.sort((a, b) {
      final ta = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final tb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return tb.compareTo(ta);
    });
    return list;
  }

  @override
  Future<List<ProductModel>> fetchProducts({String? category}) async {
    try {
      if (category == null || category.isEmpty) {
        return getAllProducts();
      }
      return getProductsByCategory(category);
    } catch (e, st) {
      _logError('fetchProducts', e, st);
      rethrow;
    }
  }

  @override
  Future<List<ProductModel>> getAllProducts() async {
    try {
      final snapshot = await _products.get();
      return _mapAndSortByCreatedAt(snapshot.docs);
    } catch (e, st) {
      _logError('getAllProducts', e, st);
      rethrow;
    }
  }

  @override
  Future<List<ProductModel>> getFeaturedProducts() async {
    try {
      final snapshot =
          await _products.where('isFeatured', isEqualTo: true).get();
      return _mapAndSortByCreatedAt(snapshot.docs);
    } catch (e, st) {
      _logError('getFeaturedProducts', e, st);
      rethrow;
    }
  }

  @override
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    try {
      final snapshot = await _products
          .where(
            Filter.or(
              Filter('category', isEqualTo: category),
              Filter('categoryId', isEqualTo: category),
            ),
          )
          .get();
      return _mapAndSortByCreatedAt(snapshot.docs);
    } catch (e, st) {
      _logError('getProductsByCategory', e, st);
      rethrow;
    }
  }

  @override
  Stream<List<ProductModel>> watchAllProducts() {
    return _products.snapshots().handleError((Object e, StackTrace st) {
      _logError('watchAllProducts', e, st);
    }).map((snapshot) => _mapAndSortByCreatedAt(snapshot.docs));
  }

  @override
  Stream<List<ProductModel>> watchFeaturedProducts() {
    return _products
        .where('isFeatured', isEqualTo: true)
        .snapshots()
        .handleError((Object e, StackTrace st) {
      _logError('watchFeaturedProducts', e, st);
    }).map((snapshot) => _mapAndSortByCreatedAt(snapshot.docs));
  }

  @override
  Stream<List<ProductModel>> watchProductsByCategory(String category) {
    return _products
        .where(
          Filter.or(
            Filter('category', isEqualTo: category),
            Filter('categoryId', isEqualTo: category),
          ),
        )
        .snapshots()
        .handleError((Object e, StackTrace st) {
      _logError('watchProductsByCategory', e, st);
    }).map((snapshot) => _mapAndSortByCreatedAt(snapshot.docs));
  }
}
