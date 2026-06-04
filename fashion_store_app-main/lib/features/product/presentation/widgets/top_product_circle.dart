import 'package:flutter/material.dart';

import '../../../../core/widgets/product_network_image.dart';
import '../theme/shop_tokens.dart';

class TopProductCircle extends StatelessWidget {
  const TopProductCircle({super.key, required this.imageUrl, this.onTap});

  final String imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: ShopTokens.cardShadow,
            ),
            child: ClipOval(
              child: ProductNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                cloudinaryVariant: CloudinaryVariant.thumbnail,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
