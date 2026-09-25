import 'package:flutter/material.dart';
import 'package:callerapp_frontend/resources/styles/styles.dart';

// Este es mi widget para los textos o labels de la app
class LabelWidget extends StatelessWidget {
  // Aquí guardo el texto que se va a mostrar
  final String texto;

  // Aquí guardo el tamaño de la letra
  final double tamanio;

  // Aquí guardo el color del texto
  final Color color;

  // Aquí guardo si el texto va normal, en negritas, etc.
  final FontWeight peso;

  // Aquí guardo la alineación del texto
  final TextAlign alineacion;

  // Esto es por si el texto va a funcionar como botón
  final VoidCallback? accion;

  // Constructor del widget
  const LabelWidget({
    super.key,
    required this.texto,
    this.tamanio = 14,
    this.color = Colors.white,
    this.peso = FontWeight.normal,
    this.alineacion = TextAlign.center,
    this.accion,
  });

  @override
  Widget build(BuildContext context) {
    // Aquí creo el texto con las propiedades que manden desde otra pantalla
    Widget label = Text(
      texto,
      textAlign: alineacion,
      style: TextStyle(fontSize: tamanio, color: color, fontWeight: peso),
    );

    // Si el label tiene una acción, entonces lo hago clickeable
    if (accion != null) {
      return GestureDetector(onTap: accion, child: label);
    }

    // Si no tiene acción, solo regreso el texto normal
    return label;
  }
}

class AuthDividerLabel extends StatelessWidget {
  final String text;

  const AuthDividerLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 3,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: AppStyles.textLabel(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 3,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
