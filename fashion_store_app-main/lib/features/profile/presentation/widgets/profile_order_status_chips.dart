import 'package:flutter/material.dart';

import '../theme/profile_ui_tokens.dart';

class ProfileOrderStatusChips extends StatelessWidget {
  const ProfileOrderStatusChips({super.key, this.onChipTap});

  final ValueChanged<String>? onChipTap;

  static const _items = [
    _ChipData(label: 'To Pay', showDot: false),
    _ChipData(label: 'To Receive', showDot: true),
    _ChipData(label: 'To Review', showDot: false),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: ProfileUiTokens.screenHorizontal),
        itemCount: _items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final item = _items[i];
          return _StatusChip(
            label: item.label,
            showDot: item.showDot,
            onTap: onChipTap != null ? () => onChipTap!(item.label) : null,
          );
        },
      ),
    );
  }
}

class _ChipData {
  const _ChipData({required this.label, required this.showDot});

  final String label;
  final bool showDot;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.showDot,
    this.onTap,
  });

  final String label;
  final bool showDot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ProfileUiTokens.chipFill,
      borderRadius: BorderRadius.circular(ProfileUiTokens.chipRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ProfileUiTokens.chipRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: ProfileUiTokens.textPrimary,
                    ),
              ),
              if (showDot) ...[
                const SizedBox(width: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: ProfileUiTokens.statusDot,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
