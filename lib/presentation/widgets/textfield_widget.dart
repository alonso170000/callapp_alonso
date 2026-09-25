import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:callerapp_frontend/resources/styles/styles.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';

class CustomTextField extends StatefulWidget {
  final String hintText;
  final bool isPassword;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final Color fillColor;
  final Color textColor;
  final Color labelColor;
  final Color focusedLabelColor;
  final Color? labelBackgroundColor;
  final double labelHorizontalPadding;
  final Color iconColor;
  final Color focusedBorderColor;
  final Color enabledBorderColor;
  final Gradient? gradienteBorde;
  final Gradient? gradienteBordeEnfocado;
  final double borderWidth;
  final double focusedBorderWidth;
  final IconData? prefixIcon;
  final Widget? prefixWidget;
  final String? prefixText;
  final String? helperText;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  const CustomTextField({
    super.key,
    required this.hintText,
    this.isPassword = false,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.fillColor = AppColors.whiteColor,
    this.textColor = AppColors.textDarkColor,
    this.labelColor = AppColors.textMutedColor,
    this.focusedLabelColor = AppColors.primaryColor,
    this.labelBackgroundColor,
    this.labelHorizontalPadding = 8,
    this.iconColor = AppColors.textMutedColor,
    this.focusedBorderColor = AppColors.primaryColor,
    this.enabledBorderColor = AppColors.transparentColor,
    this.gradienteBorde,
    this.gradienteBordeEnfocado,
    this.borderWidth = 0,
    this.focusedBorderWidth = 1.4,
    this.prefixIcon,
    this.prefixWidget,
    this.prefixText,
    this.helperText,
    this.errorText,
    this.onChanged,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  const CustomTextField.auth({
    super.key,
    required this.hintText,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    required this.prefixIcon,
    this.prefixWidget,
    this.prefixText,
    this.helperText,
    this.errorText,
    this.onChanged,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  }) : fillColor = Colors.transparent,
       textColor = AppColors.whiteColor,
       labelColor = AppColors.authFieldLabel,
       focusedLabelColor = AppColors.authCyan,
       labelBackgroundColor = AppColors.authPanelTop,
       labelHorizontalPadding = 12,
       iconColor = AppColors.authFieldLabel,
       focusedBorderColor = AppColors.authCyan,
       enabledBorderColor = AppColors.authPurple,
       gradienteBorde = AppColors.mainGradient,
       gradienteBordeEnfocado = AppColors.authFieldFocusedGradient,
       borderWidth = 1.3,
       focusedBorderWidth = 1.6;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  final FocusNode _focusNode = FocusNode();
  late TextEditingController _controller;
  late bool _controllerPropio;
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    // Si es contraseña, inicia oculto, si no, se muestra normal
    _obscureText = widget.isPassword;
    _controllerPropio = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_actualizarLabel);
    _focusNode.addListener(() {
      if (mounted) {
        setState(() {});
      }

      if (_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 350), () {
          if (!mounted) return;

          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 0.25,
          );
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller == widget.controller) return;

    _controller.removeListener(_actualizarLabel);

    if (_controllerPropio) {
      _controller.dispose();
    }

    _controllerPropio = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_actualizarLabel);
  }

  void _actualizarLabel() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_actualizarLabel);

    if (_controllerPropio) {
      _controller.dispose();
    }

    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double radioBorde = AppStyles.textFieldBorderRadius(context);
    final bool tieneBordeDegradado =
        widget.gradienteBorde != null || widget.gradienteBordeEnfocado != null;
    final Gradient? gradienteActual = widget.errorText != null
        ? const LinearGradient(colors: [Color(0xFFFF5F78), Color(0xFFFFA0AE)])
        : _focusNode.hasFocus
        ? widget.gradienteBordeEnfocado ?? widget.gradienteBorde
        : widget.gradienteBorde;
    final double anchoBordeActual = _focusNode.hasFocus
        ? widget.focusedBorderWidth
        : widget.borderWidth;
    final bool labelEstaFlotando =
        _focusNode.hasFocus || _controller.text.isNotEmpty;
    final bool usarLabelConFondo =
        widget.labelBackgroundColor != null && labelEstaFlotando;
    final TextStyle labelTextStyle = TextStyle(
      color: _focusNode.hasFocus ? widget.focusedLabelColor : widget.labelColor,
      fontSize: _focusNode.hasFocus ? 14 : AppStyles.textTextfield(context),
      fontWeight: _focusNode.hasFocus ? FontWeight.w700 : FontWeight.normal,
      backgroundColor: widget.labelBackgroundColor,
    );

    final textField = TextField(
      focusNode: _focusNode,
      controller: _controller,
      obscureText: _obscureText,
      keyboardType: widget.keyboardType,
      textCapitalization: widget.textCapitalization,
      inputFormatters: widget.inputFormatters,
      onChanged: widget.onChanged,
      cursorColor: widget.focusedBorderColor,
      style: TextStyle(color: widget.textColor, fontSize: 16),
      decoration: InputDecoration(
        labelText: usarLabelConFondo ? null : widget.hintText,
        label: !usarLabelConFondo
            ? null
            : Container(
                color: widget.labelBackgroundColor,
                padding: EdgeInsets.symmetric(
                  horizontal: widget.labelHorizontalPadding,
                ),
                child: Text(widget.hintText, style: labelTextStyle),
              ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: TextStyle(
          color: widget.labelColor,
          fontSize: AppStyles.textTextfield(context),
        ),
        floatingLabelStyle: TextStyle(
          color: widget.focusedLabelColor,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        fillColor: widget.fillColor,
        filled: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppStyles.textFieldPaddingHorizontal(context),
          vertical: AppStyles.textFieldPaddingVertical(context),
        ),
        prefixIcon:
            widget.prefixWidget ??
            (widget.prefixIcon == null
                ? null
                : Icon(widget.prefixIcon, color: widget.iconColor)),
        prefixText: widget.prefixText,
        prefixStyle: TextStyle(
          color: widget.textColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radioBorde),
          borderSide: tieneBordeDegradado
              ? BorderSide.none
              : BorderSide(
                  color: widget.enabledBorderColor,
                  width: widget.borderWidth,
                ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radioBorde),
          borderSide: tieneBordeDegradado
              ? BorderSide.none
              : BorderSide(
                  color: widget.enabledBorderColor,
                  width: widget.borderWidth,
                ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radioBorde),
          borderSide: tieneBordeDegradado
              ? BorderSide.none
              : BorderSide(
                  color: widget.focusedBorderColor,
                  width: widget.focusedBorderWidth,
                ),
        ),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText
                      ? FluentIcons.eye_off_16_regular
                      : FluentIcons.eye_16_regular,
                  color: widget.iconColor,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,
      ),
    );

    final Widget decoratedTextField =
        !tieneBordeDegradado || gradienteActual == null
        ? textField
        : CustomPaint(
            painter: _GradientTextFieldBorderPainter(
              gradient: gradienteActual,
              strokeWidth: anchoBordeActual,
              borderRadius: radioBorde,
            ),
            child: textField,
          );

    final supportingText = widget.errorText ?? widget.helperText;
    if (supportingText == null) return decoratedTextField;

    final hasError = widget.errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        decoratedTextField,
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Semantics(
            liveRegion: hasError,
            child: Text(
              supportingText,
              style: TextStyle(
                color: hasError
                    ? const Color(0xFFFF8A9B)
                    : AppColors.whiteColor.withValues(alpha: 0.72),
                fontSize: 12,
                fontWeight: hasError ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GradientTextFieldBorderPainter extends CustomPainter {
  final Gradient gradient;
  final double strokeWidth;
  final double borderRadius;

  const _GradientTextFieldBorderPainter({
    required this.gradient,
    required this.strokeWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (strokeWidth <= 0) return;

    final rect = Offset.zero & size;
    final strokeOffset = strokeWidth / 2;
    final borderRect = rect.deflate(strokeOffset);
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        borderRect,
        Radius.circular(
          (borderRadius - strokeOffset).clamp(0, borderRadius).toDouble(),
        ),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GradientTextFieldBorderPainter oldDelegate) {
    return oldDelegate.gradient != gradient ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.borderRadius != borderRadius;
  }
}
