import 'package:callerapp_frontend/presentation/validators/profile_validators.dart';
import 'package:flutter/material.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';

class EditProfileDialog extends StatefulWidget {
  final String field;
  final String value;
  const EditProfileDialog({
    super.key,
    required this.field,
    required this.value,
  });
  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _form = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: widget.value);
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AppColors.homeBackground,
    title: Text('Editar ${widget.field.toLowerCase()}'),
    content: Form(
      key: _form,
      child: TextFormField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: widget.field),
        keyboardType: widget.field == 'Correo'
            ? TextInputType.emailAddress
            : widget.field == 'Teléfono'
            ? TextInputType.phone
            : TextInputType.name,
        validator: (value) =>
            ProfileValidators.field(value, field: widget.field),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(context, _controller.text.trim());
          }
        },
        child: const Text('Guardar'),
      ),
    ],
  );
}
