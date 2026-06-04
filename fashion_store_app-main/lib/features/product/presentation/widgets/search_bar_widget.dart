import 'package:flutter/material.dart';

import '../theme/shop_tokens.dart';

/// Reusable shop search field: leading search icon, hint, optional clear, optional camera.
class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({
    super.key,
    required this.controller,
    this.hintText = 'Search products...',
    this.onChanged,
    this.onSubmitted,
    this.onCameraTap,
    this.onClear,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onCameraTap;
  final VoidCallback? onClear;
  final bool autofocus;

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  void _handleClear() {
    widget.controller.clear();
    widget.onClear?.call();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final showClear = widget.controller.text.isNotEmpty;
    final scheme = Theme.of(context).colorScheme;

    return TextField(
      controller: widget.controller,
      autofocus: widget.autofocus,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      textInputAction: TextInputAction.search,
      style: const TextStyle(
        fontSize: ShopTokens.body,
        color: ShopTokens.textPrimary,
      ),
      decoration: InputDecoration(
        isDense: true,
        hintText: widget.hintText,
        hintStyle: TextStyle(
          color: ShopTokens.textSecondary.withValues(alpha: 0.85),
          fontSize: ShopTokens.body,
        ),
        filled: true,
        fillColor: ShopTokens.searchFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.9),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: scheme.primary,
            width: 1.6,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 12,
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: ShopTokens.textSecondary,
          size: 22,
        ),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showClear)
              IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.close, color: ShopTokens.textSecondary),
                onPressed: _handleClear,
              ),
            if (widget.onCameraTap != null)
              IconButton(
                icon: Icon(
                  Icons.photo_camera_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: widget.onCameraTap,
              ),
          ],
        ),
      ),
    );
  }
}
