import 'package:flutter/material.dart';
import 'package:callerapp_frontend/resources/styles/styles.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';

class CustomButton extends StatelessWidget {
  final String texto;
  final VoidCallback? accion;
  final Color? colorFondo;
  final Gradient? gradienteFondo;
  final Color colorTexto;
  final Color? colorBorde;
  final Gradient? gradienteBorde;
  final Color? colorSombra;
  final double? alto;
  final double? radio;
  final double anchoBorde;
  final double sombraBlur;
  final Offset sombraOffset;
  final double tamanioTexto;
  final FontWeight peso;
  final Image? imagen;

  const CustomButton({
    super.key,
    required this.texto,
    this.accion,
    this.colorFondo,
    this.gradienteFondo,
    this.colorTexto = AppColors.backgroundColor,
    this.colorBorde,
    this.gradienteBorde,
    this.colorSombra,
    this.alto,
    this.radio,
    this.anchoBorde = 0,
    this.sombraBlur = 0,
    this.sombraOffset = Offset.zero,
    this.tamanioTexto = 18,
    this.peso = FontWeight.w600,
    this.imagen,
  });

  const CustomButton.auth({
    super.key,
    required this.texto,
    required this.accion,
  }) : colorFondo = null,
       gradienteFondo = AppColors.verticalGradient,
       colorTexto = AppColors.whiteColor,
       colorBorde = null,
       gradienteBorde = AppColors.mainGradient,
       colorSombra = AppColors.authButtonShadow,
       alto = null,
       radio = 10,
       anchoBorde = 2,
       sombraBlur = 14,
       sombraOffset = const Offset(0, 6),
       tamanioTexto = 16,
       peso = FontWeight.w700,
       imagen = null;

  @override
  Widget build(BuildContext context) {
    final double altoBoton = alto ?? AppStyles.buttonHeight(context);
    final double radioBoton = radio ?? AppStyles.buttonBorderRadius(context);
    final BorderRadius borderRadius = BorderRadius.circular(radioBoton);
    final bool estaActivo = accion != null;

    final Text textoBoton = Text(
      texto,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: colorTexto,
        fontSize: tamanioTexto,
        fontWeight: peso,
      ),
    );

    final Widget contenido = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: accion,
        borderRadius: borderRadius,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppStyles.textFieldPaddingHorizontal(context),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imagen != null) ...[imagen!, const SizedBox(width: 10)],
              Flexible(child: textoBoton),
            ],
          ),
        ),
      ),
    );

    final BoxDecoration decoracionFondo = BoxDecoration(
      color: gradienteFondo == null ? colorFondo : null,
      gradient: gradienteFondo,
      borderRadius: borderRadius,
      border: gradienteBorde != null || colorBorde == null
          ? null
          : Border.all(color: colorBorde!, width: anchoBorde),
    );

    return Opacity(
      opacity: estaActivo ? 1 : 0.68,
      child: Container(
        width: double.infinity,
        height: altoBoton,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: colorSombra == null
              ? null
              : [
                  BoxShadow(
                    color: colorSombra!,
                    blurRadius: sombraBlur,
                    offset: sombraOffset,
                  ),
                ],
        ),
        child: gradienteBorde == null
            ? Container(decoration: decoracionFondo, child: contenido)
            : Container(
                padding: EdgeInsets.all(anchoBorde),
                decoration: BoxDecoration(
                  gradient: gradienteBorde,
                  borderRadius: borderRadius,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    (radioBoton - anchoBorde).clamp(0, radioBoton).toDouble(),
                  ),
                  child: Container(
                    decoration: decoracionFondo.copyWith(border: null),
                    child: contenido,
                  ),
                ),
              ),
      ),
    );
  }
}

class OutlinedAuthButton extends StatelessWidget {
  final String text;
  final Widget icon;
  final VoidCallback? onPressed;

  const OutlinedAuthButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return Opacity(
      opacity: enabled ? 1 : 0.65,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            height: AppStyles.buttonHeight(context),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.whiteColor.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.whiteColor.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    text,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.whiteColor,
                      fontSize: AppStyles.textButtom(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
