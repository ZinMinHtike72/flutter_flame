import "package:app_ui_kit/theme/app_spacing.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

const _boxHeight = 60.0;
const _caretHeight = 24.0;
const _caretWidth = 2.0;
const _blinkPeriod = Duration(milliseconds: 1000);
const _borderDuration = Duration(milliseconds: 180);
const _popDuration = Duration(milliseconds: 260);

/// One box per digit for one-time codes. [value] is owned by the caller:
/// setting it to "" clears the boxes. Supports SMS code autofill.
class AppOtpField extends StatefulWidget {
  /// Creates a code field with [length] boxes.
  const AppOtpField({
    required this.length,
    required this.value,
    required this.onChanged,
    super.key,
    this.hasError = false,
    this.enabled = true,
    this.autofocus = false,
    this.semanticsLabel,
  });

  /// Number of digits.
  final int length;

  /// Digits entered so far.
  final String value;

  /// Receives the digits whenever they change.
  final ValueChanged<String> onChanged;

  /// Outlines every box in the error color.
  final bool hasError;

  /// Whether the field accepts input.
  final bool enabled;

  /// Opens the keyboard when first shown and again whenever the field is
  /// re-enabled, such as after a rejected code.
  final bool autofocus;

  /// Caller-localized description for screen readers.
  final String? semanticsLabel;

  @override
  State<AppOtpField> createState() => _AppOtpFieldState();
}

class _AppOtpFieldState extends State<AppOtpField>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );
  final FocusNode _focusNode = FocusNode();
  late final AnimationController _caret = AnimationController(
    vsync: this,
    duration: _blinkPeriod,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _caret.value = 1;
    } else if (!_caret.isAnimating) {
      _caret.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AppOtpField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autofocus && widget.enabled && !oldWidget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _caret.dispose();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.semanticsLabel,
    textField: true,
    child: SizedBox(
      height: _boxHeight,
      child: Stack(
        children: [
          ListenableBuilder(
            listenable: Listenable.merge([_controller, _focusNode]),
            builder: (context, _) => Row(
              children: [
                for (final index in List.generate(widget.length, (i) => i)) ...[
                  if (index > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(child: _buildBox(context, index)),
                ],
              ],
            ),
          ),
          Positioned.fill(
            child: ExcludeSemantics(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                autofocus: widget.autofocus,
                expands: true,
                maxLines: null,
                showCursor: false,
                enableInteractiveSelection: false,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.length),
                ],
                style: const TextStyle(color: Colors.transparent),
                decoration: const InputDecoration(
                  isCollapsed: true,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                ),
                onChanged: widget.onChanged,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildBox(BuildContext context, int index) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = _controller.text;
    final digit = index < text.length ? text[index] : null;
    final isActive =
        _focusNode.hasFocus &&
        widget.enabled &&
        index == text.length.clamp(0, widget.length - 1);
    final borderColor = widget.hasError
        ? colors.error
        : isActive
        ? colors.primary
        : digit != null
        ? colors.primary.withValues(alpha: 0.45)
        : colors.onSurface.withValues(alpha: 0.12);
    return AnimatedContainer(
      duration: _borderDuration,
      decoration: BoxDecoration(
        color: isActive
            ? colors.primary.withValues(alpha: 0.06)
            : colors.onSurface.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(AppSpacing.md - 2),
        border: Border.all(
          color: borderColor,
          width: isActive || widget.hasError ? 1.8 : 1.2,
        ),
      ),
      alignment: Alignment.center,
      child: digit != null
          ? TweenAnimationBuilder<double>(
              key: ValueKey("$index-$digit"),
              tween: Tween(begin: 0.4, end: 1),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : _popDuration,
              curve: Curves.easeOutBack,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Text(
                digit,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: widget.hasError ? colors.error : colors.onSurface,
                ),
              ),
            )
          : isActive && digit == null && text.length < widget.length
          ? FadeTransition(
              opacity: _caret,
              child: SizedBox(
                width: _caretWidth,
                height: _caretHeight,
                child: ColoredBox(color: colors.primary),
              ),
            )
          : null,
    );
  }
}
