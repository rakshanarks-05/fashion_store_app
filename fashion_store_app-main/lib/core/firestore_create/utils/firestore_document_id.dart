import 'package:cloud_firestore/cloud_firestore.dart';

/// If [explicitId] is blank, returns a new auto-id for [collectionPath] without
/// writing a document (uses Firestore's document id generator).
String resolveDocumentId(
  FirebaseFirestore firestore,
  String collectionPath,
  String explicitId,
) {
  final trimmed = explicitId.trim();
  if (trimmed.isEmpty) {
    return firestore.collection(collectionPath).doc().id;
  }
  return trimmed;
}
