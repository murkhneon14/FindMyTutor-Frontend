import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/theme.dart';

/// Single invisible focus field plus four visible digit boxes — supports full
/// paste and system OTP autofill ([AutofillHints.oneTimeCode]).
class OtpFourDigitField extends StatefulWidget {
  const OtpFourDigitField({
    super.key,
    required this.controller,
    required this.focusNode,
    this.autofocus = true,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool autofocus;

  @override
  State<OtpFourDigitField> createState() => _OtpFourDigitFieldState();
}

class _OtpFourDigitFieldState extends State<OtpFourDigitField> {
  void _listener() {
    setState(() {});
  }

  void _focusListener() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_listener);
    widget.focusNode.addListener(_focusListener);
  }

  @override
  void didUpdateWidget(covariant OtpFourDigitField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_listener);
      widget.controller.addListener(_listener);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_focusListener);
      widget.focusNode.addListener(_focusListener);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_focusListener);
    widget.controller.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final text = widget.controller.text;
    final accent = theme.primaryColor;
    final caretRaw = widget.focusNode.hasPrimaryFocus
        ? (widget.controller.selection.isValid
            ? widget.controller.selection.baseOffset.clamp(0, 4)
            : text.length.clamp(0, 4))
        : -1;
    final hlIdx = caretRaw < 0 ? -1 : caretRaw.clamp(0, 3);

    return AutofillGroup(
      child: SizedBox(
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                autofocus: widget.autofocus,
                autocorrect: false,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                minLines: 1,
                maxLines: 1,
                maxLength: 4,
                showCursor: false,
                autofillHints: const [AutofillHints.oneTimeCode],
                obscureText: false,
                cursorWidth: 0,
                decoration: InputDecoration(
                  filled: false,
                  counterText: '',
                  isCollapsed: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                ),
                style: theme.textTheme.titleLarge?.copyWith(
                  height: 1,
                  letterSpacing: 32,
                  color: Colors.transparent,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
              ),
            ),
            IgnorePointer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (index) {
                  final ch =
                      index < text.length ? text.substring(index, index + 1) : '';
                  final wide =
                      widget.focusNode.hasPrimaryFocus && hlIdx == index;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: index == 0 ? 0 : 6),
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? AppTheme.darkCardColor
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            width: wide ? 2 : 1,
                            color: wide
                                ? accent
                                : isDarkMode
                                    ? Colors.white24
                                    : theme.dividerColor,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          ch,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
