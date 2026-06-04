import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Single line item stored under `orders/{id}.items`.
class OrderLineItemModel extends Equatable {
  const OrderLineItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.imageUrl,
  });

  final String productId;
  final String productName;
  final int quantity;

  /// Unit price (one item) in the store currency.
  final double price;
  final String imageUrl;

  factory OrderLineItemModel.fromJson(Map<String, dynamic> json) {
    return OrderLineItemModel(
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.round() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'price': price,
        'imageUrl': imageUrl,
      };

  OrderLineItemModel copyWith({
    String? productId,
    String? productName,
    int? quantity,
    double? price,
    String? imageUrl,
  }) {
    return OrderLineItemModel(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  List<Object?> get props => [productId, productName, quantity, price, imageUrl];
}

/// Shipping snapshot on the order document.
class OrderShippingAddressModel extends Equatable {
  const OrderShippingAddressModel({
    required this.name,
    required this.phone,
    required this.addressLine,
    required this.city,
    required this.postalCode,
  });

  final String name;
  final String phone;
  final String addressLine;
  final String city;
  final String postalCode;

  factory OrderShippingAddressModel.fromJson(Map<String, dynamic> json) {
    return OrderShippingAddressModel(
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      addressLine: json['addressLine'] as String? ?? '',
      city: json['city'] as String? ?? '',
      postalCode: json['postalCode'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'addressLine': addressLine,
        'city': city,
        'postalCode': postalCode,
      };

  OrderShippingAddressModel copyWith({
    String? name,
    String? phone,
    String? addressLine,
    String? city,
    String? postalCode,
  }) {
    return OrderShippingAddressModel(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      addressLine: addressLine ?? this.addressLine,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
    );
  }

  @override
  List<Object?> get props => [name, phone, addressLine, city, postalCode];
}

/// Firestore document model for `orders/{orderId}`.
///
/// Field names match the deployed schema: [orderId] duplicates the document id.
class OrderModel extends Equatable {
  const OrderModel({
    required this.orderId,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    required this.shippingAddress,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Same value as the document id (set on create).
  final String orderId;
  final String userId;
  final List<OrderLineItemModel> items;
  final double totalAmount;
  final String paymentMethod;

  /// `Pending` | `Paid` | `Failed`
  final String paymentStatus;

  /// `Placed` | `Processing` | `Shipped` | `Delivered` | `Cancelled`
  final String orderStatus;
  final OrderShippingAddressModel shippingAddress;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Parses Firestore data; [id] is the document id.
  factory OrderModel.fromJson(Map<String, dynamic> json, String id) {
    final itemsRaw = json['items'];
    final items = <OrderLineItemModel>[];
    if (itemsRaw is List) {
      for (final e in itemsRaw) {
        if (e is Map<String, dynamic>) {
          items.add(OrderLineItemModel.fromJson(e));
        } else if (e is Map) {
          items.add(OrderLineItemModel.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }

    final shipRaw = json['shippingAddress'];
    OrderShippingAddressModel shipping;
    if (shipRaw is Map<String, dynamic>) {
      shipping = OrderShippingAddressModel.fromJson(shipRaw);
    } else if (shipRaw is Map) {
      shipping = OrderShippingAddressModel.fromJson(
        Map<String, dynamic>.from(shipRaw),
      );
    } else {
      shipping = const OrderShippingAddressModel(
        name: '',
        phone: '',
        addressLine: '',
        city: '',
        postalCode: '',
      );
    }

    final totalAmount =
        (json['totalAmount'] as num?)?.toDouble() ??
            (json['total'] as num?)?.toDouble() ??
            0;

    final orderStatus =
        json['orderStatus'] as String? ?? json['status'] as String? ?? 'Placed';

    DateTime readTs(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return OrderModel(
      orderId: json['orderId'] as String? ?? id,
      userId: json['userId'] as String? ?? '',
      items: items,
      totalAmount: totalAmount,
      paymentMethod: json['paymentMethod'] as String? ?? '',
      paymentStatus: json['paymentStatus'] as String? ?? 'Pending',
      orderStatus: orderStatus,
      shippingAddress: shipping,
      createdAt: readTs(json['createdAt']),
      updatedAt: readTs(json['updatedAt']),
    );
  }

  /// Client-side JSON (Timestamps as [Timestamp] for Firestore writes when needed).
  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'userId': userId,
        'items': items.map((e) => e.toJson()).toList(),
        'totalAmount': totalAmount,
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
        'orderStatus': orderStatus,
        'shippingAddress': shippingAddress.toJson(),
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  OrderModel copyWith({
    String? orderId,
    String? userId,
    List<OrderLineItemModel>? items,
    double? totalAmount,
    String? paymentMethod,
    String? paymentStatus,
    String? orderStatus,
    OrderShippingAddressModel? shippingAddress,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderModel(
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      orderStatus: orderStatus ?? this.orderStatus,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        orderId,
        userId,
        items,
        totalAmount,
        paymentMethod,
        paymentStatus,
        orderStatus,
        shippingAddress,
        createdAt,
        updatedAt,
      ];
}
