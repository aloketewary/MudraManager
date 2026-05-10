import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';

class CommonTextInputField extends ConsumerStatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final IconData? iconData;
  final TextInputType inputType;
  final FormFieldValidator<String>? validateField;
  final ValueChanged<String>? onChanged;

  const CommonTextInputField({
    super.key,
    this.controller,
    this.labelText = '',
    this.iconData,
    this.inputType = TextInputType.text,
    this.hintText,
    this.validateField,
    this.onChanged,
  });

  @override
  ConsumerState<CommonTextInputField> createState() => _CommonTextInputFieldState();
}

class _CommonTextInputFieldState extends ConsumerState<CommonTextInputField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  late TextEditingController _effectiveController;

  @override
  void initState() {
    super.initState();
    _effectiveController = widget.controller ?? TextEditingController();
    _focusNode.addListener(_onFocusChange);
    _effectiveController.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(CommonTextInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_onTextChanged);
      if (oldWidget.controller == null) _effectiveController.dispose();
      _effectiveController = widget.controller ?? TextEditingController();
      _effectiveController.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _effectiveController.removeListener(_onTextChanged);
    if (widget.controller == null) _effectiveController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() => setState(() => _isFocused = _focusNode.hasFocus);
  void _onTextChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(ref.watch(spacingProvider).radiusSmall);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: _isFocused ? [BoxShadow(color: color.primary.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
        ),
        child: TextFormField(
          controller: _effectiveController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            prefixIcon: widget.iconData != null ? Icon(widget.iconData, color: _isFocused ? color.primary : color.onSurfaceVariant) : null,
            suffixIcon: _effectiveController.text.isNotEmpty && _isFocused
                ? IconButton(
                    icon: const Icon(LucideIcons.circleX, size: 20),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _effectiveController.clear();
                      widget.onChanged?.call('');
                    },
                    tooltip: AppLocalizations.of(context)!.common_clear,
                  )
                : null,
            border: OutlineInputBorder(borderRadius: radius),
            focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: color.primary, width: 2.0)),
            enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: color.outline, width: 1.0)),
          ),
          textInputAction: TextInputAction.next,
          keyboardType: widget.inputType,
          validator: widget.validateField,
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}
