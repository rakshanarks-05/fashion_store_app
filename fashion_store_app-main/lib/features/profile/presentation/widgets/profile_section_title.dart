import 'package:flutter/material.dart';

import '../theme/profile_ui_tokens.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ProfileUiTokens.screenHorizontal),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: ProfileUiTokens.textPrimary,
              ),
        ),
      ),
    );
  }
}
