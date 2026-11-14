import 'package:callerapp_frontend/presentation/models/contact_medium.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:callerapp_frontend/resources/styles/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class ProspectContactOptionsSheet extends StatefulWidget {
  const ProspectContactOptionsSheet({
    super.key,
    required this.prospect,
    required this.agendaVerified,
  });

  final ProspectRecord prospect;
  final bool agendaVerified;

  @override
  State<ProspectContactOptionsSheet> createState() =>
      _ProspectContactOptionsSheetState();
}

class _ProspectContactOptionsSheetState
    extends State<ProspectContactOptionsSheet> {
  ContactMedium? _selected;

  bool _available(ContactMedium medium) =>
      medium == ContactMedium.facebook || medium.isAvailable(widget.prospect);

  String? _subtitle(ContactMedium medium) {
    if (!_available(medium)) {
      return switch (medium) {
        ContactMedium.llamada ||
        ContactMedium.whatsapp => 'Sin teléfono válido',
        ContactMedium.correo => 'Sin correo válido',
        ContactMedium.facebook => 'No disponible',
      };
    }
    return switch (medium) {
      ContactMedium.llamada || ContactMedium.whatsapp => widget.prospect.phone,
      ContactMedium.correo => widget.prospect.email,
      ContactMedium.facebook =>
        'Abre Facebook; no busca el perfil del prospecto',
    };
  }

  String get _notice {
    final selected = _selected;
    if (selected == null) {
      return 'Al continuar se abrirá el medio que elijas. Al volver, te llevaremos al detalle del prospecto para registrar el resultado y, si quieres, agendar el siguiente seguimiento.';
    }
    return switch (selected) {
      ContactMedium.llamada => 'Se abrirá el marcador. Al terminar la llamada, el detalle te pedirá registrar el resultado y agendar el siguiente seguimiento.',
      ContactMedium.whatsapp => 'Se abrirá WhatsApp. Al volver, el formulario de seguimiento tendrá WhatsApp seleccionado.',
      ContactMedium.correo => 'Se abrirá tu aplicación de correo. Al volver, el formulario de seguimiento tendrá Correo seleccionado.',
      ContactMedium.facebook => 'Se abrirá Facebook; no se buscará el perfil del prospecto. Al volver, el formulario tendrá Facebook seleccionado.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.prospect.name.toUpperCase(),
              style: TextStyle(
                fontFamily: 'BebasNeue',
                fontSize: 28,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.agendaVerified
                  ? 'Este prospecto no tiene seguimientos pendientes.'
                  : 'No se pudo verificar la agenda de este prospecto.',
              style: const TextStyle(fontFamily: 'SulphurPoint', fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.secondaryActionFill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _notice,
                style: TextStyle(
                  fontFamily: 'SulphurPoint',
                  color: palette.secondaryActionForeground,
                ),
              ),
            ),
            const SizedBox(height: 16),
            for (final medium in ContactMedium.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _option(medium, theme, palette),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CANCELAR'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _selected == null
                        ? null
                        : () => Navigator.pop(context, _selected),
                    child: const Text('SÍ, CONTINUAR'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _option(ContactMedium medium, ThemeData theme, AppPalette palette) {
    final enabled = _available(medium);
    final selected = _selected == medium;
    return Material(
      color: selected
          ? palette.secondaryActionFill
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        enabled: enabled,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: enabled ? () => setState(() => _selected = medium) : null,
        leading: CircleAvatar(
          backgroundColor: switch (medium) {
            ContactMedium.llamada => AppColors.prospectActionCall,
            ContactMedium.whatsapp => AppColors.prospectActionWhastapp,
            ContactMedium.facebook => AppColors.prospectActionFacebook,
            ContactMedium.correo => AppColors.prospectActionMail,
          },
          child: Icon(medium.icon, color: AppColors.textDarkColor, size: 20),
        ),
        title: Text(
          medium.actionLabel,
          style: const TextStyle(
            fontFamily: 'SulphurPoint',
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(_subtitle(medium) ?? ''),
        trailing: selected
            ? Icon(Iconsax.tick_circle, color: palette.secondaryActionForeground)
            : null,
      ),
    );
  }
}
