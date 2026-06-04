import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../domain/entities/app_user.dart';

class AppUserModel extends AppUser {
  const AppUserModel({required super.id, super.email});

  factory AppUserModel.fromFirebase(fb.User user) {
    return AppUserModel(id: user.uid, email: user.email);
  }
}
