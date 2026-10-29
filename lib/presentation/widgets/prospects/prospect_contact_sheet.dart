import 'package:flutter/material.dart';

class ProspectContactSheet extends StatelessWidget {
  const ProspectContactSheet({
    super.key,
    required this.name,
    required this.phone,
    required this.email,
    required this.onCopyPhone,
  });

  final String name;
  final String phone;
  final String email;
  final VoidCallback onCopyPhone;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          SelectableText(phone, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          SelectableText(email, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onCopyPhone,
            icon: const Icon(Icons.copy_outlined),
            label: const Text('COPIAR TELÉFONO'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CERRAR'),
          ),
        ],
      ),
    ),
  );
}
