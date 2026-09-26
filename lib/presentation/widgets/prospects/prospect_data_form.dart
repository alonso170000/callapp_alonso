import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/validators/profile_validators.dart';

class ProspectDataForm extends StatefulWidget {
  final ProspectRecord prospect;
  final ValueChanged<String> onSaved;

  const ProspectDataForm({
    super.key,
    required this.prospect,
    required this.onSaved,
  });

  @override
  State<ProspectDataForm> createState() => _ProspectDataFormState();
}

class _ProspectDataFormState extends State<ProspectDataForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.prospect.name);
  late final _city = TextEditingController(text: widget.prospect.city);
  late final _phone = TextEditingController(text: widget.prospect.phone);
  late final _email = TextEditingController(text: widget.prospect.email);
  late final _company = TextEditingController(text: widget.prospect.company);
  late final _occupation = TextEditingController(
    text: widget.prospect.occupation,
  );
  Map<String, String>? _saved;

  List<TextEditingController> get _controllers => [
    _name,
    _city,
    _phone,
    _email,
    _company,
    _occupation,
  ];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  InputDecoration _decoration() => InputDecoration(
    filled: true,
    fillColor: const Color(0xFFAD393E),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    errorStyle: const TextStyle(color: Color(0xFF8B1116)),
  );

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 15)),
        const SizedBox(height: 3),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: _decoration(),
        ),
      ],
    ),
  );

  void _cancel() => setState(() {
    _name.text = _saved?['name'] ?? widget.prospect.name;
    _city.text = _saved?['city'] ?? widget.prospect.city;
    _phone.text = _saved?['phone'] ?? widget.prospect.phone;
    _email.text = _saved?['email'] ?? widget.prospect.email;
    _company.text = _saved?['company'] ?? widget.prospect.company;
    _occupation.text = _saved?['occupation'] ?? widget.prospect.occupation;
    _formKey.currentState?.reset();
  });

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    _saved = {
      'name': _name.text.trim(),
      'city': _city.text.trim(),
      'phone': _phone.text.trim(),
      'email': _email.text.trim(),
      'company': _company.text.trim(),
      'occupation': _occupation.text.trim(),
    };
    widget.onSaved('Prospecto · Datos actualizados');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Datos guardados en esta vista.')),
    );
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
      color: const Color(0xFFFFCED1),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Form(
      key: _formKey,
      child: Column(
        children: [
          _field(
            'Nombre',
            _name,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'El nombre es obligatorio'
                : null,
          ),
          _field('Ciudad', _city),
          _field(
            'Teléfono',
            _phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d+\s()-]')),
            ],
            validator: (value) =>
                ProfileValidators.field(value, field: 'Teléfono'),
          ),
          _field(
            'Email',
            _email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) =>
                ProfileValidators.field(value, field: 'Correo'),
          ),
          _field('Empresa', _company),
          _field('Ocupación', _occupation),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFAC4549),
                  ),
                  onPressed: _cancel,
                  child: const Text('CANCELAR'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4CA382),
                  ),
                  onPressed: _save,
                  child: const Text('GUARDAR'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
