import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/presentation/widgets/profile/edit_profile_dialog.dart';
import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/widgets/notifications/notifications_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:callerapp_frontend/presentation/models/profile_models.dart';
import 'package:callerapp_frontend/presentation/widgets/profile/profile_widgets.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:callerapp_frontend/services/appearance_controller.dart';
import 'package:callerapp_frontend/presentation/widgets/profile/appearance_sheet.dart';
import 'package:callerapp_frontend/services/notification_service.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.onNotificationActivity});
  final ValueChanged<AgendaActivity>? onNotificationActivity;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late ProfileData _profile;
  int _reminder = 15;

  @override
  void initState() {
    super.initState();
    AppearanceController.instance.addListener(_appearanceChanged);
    NotificationService.instance.addListener(_notificationsChanged);
    final auth = AuthService.instance;
    _profile = ProfileData(
      name: auth.userName,
      phone: auth.phone ?? 'No disponible',
      email: auth.email ?? 'No disponible',
      rol: auth.activeDevelopment?['rol'] as String? ?? 'No disponible',
    );
  }

  void _appearanceChanged() {
    if (mounted) setState(() {});
  }

  void _notificationsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppearanceController.instance.removeListener(_appearanceChanged);
    NotificationService.instance.removeListener(_notificationsChanged);
    super.dispose();
  }

  void _chooseAppearance() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => AppearanceSheet(controller: AppearanceController.instance),
  );

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _edit(String field, String value) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => EditProfileDialog(field: field, value: value),
    );
    if (!mounted || result == null) return;
    setState(
      () => _profile = switch (field) {
        'Nombre' => _profile.copyWith(name: result),
        'Teléfono' => _profile.copyWith(phone: result),
        _ => _profile.copyWith(email: result),
      },
    );
    _message('Cambio guardado solo en esta sesión.');
  }

  Future<void> _chooseReminder() async {
    final result = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'RECORDATORIOS',
              style: profileHeading.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            for (final minutes in [5, 15, 30, 60])
              ListTile(
                title: Text('$minutes minutos antes'),
                trailing: minutes == _reminder ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(context, minutes),
              ),
          ],
        ),
      ),
    );
    if (mounted && result != null) setState(() => _reminder = result);
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: AppearanceController.instance.reload,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      key: const PageStorageKey('profile-scroll'),
      padding: EdgeInsets.fromLTRB(
        28,
        12,
        28,
        118 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'MI PERFIL',
                style: profileHeading.copyWith(
                  fontSize: 30,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            IconButton.filled(
              tooltip: 'Notificaciones',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.homeWarmText,
              ),
              onPressed: () async {
                final activity = await showNotificationsSheet(context);
                if (activity != null) {
                  widget.onNotificationActivity?.call(activity);
                }
              },
              icon: const Icon(Iconsax.notification),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ProfileIdentity(
          profile: _profile,
          role: AuthService.instance.activeDevelopment?['rol'] as String?,
        ),
        const SizedBox(height: 26),
        ProfileSection(
          title: 'DATOS PERSONALES',
          children: [
            ProfileSettingRow(
              title: 'NOMBRE',
              value: _profile.name,
              titleColor: AppColors.profileDatos,
              icon: Iconsax.edit_2_copy,
              actionLabel: 'Editar nombre',
              onPressed: () => _edit('Nombre', _profile.name),
            ),
            ProfileSettingRow(
              title: 'TELÉFONO',
              value: _profile.phone,
              titleColor: AppColors.profileDatos,
              icon: Iconsax.edit_2_copy,
              actionLabel: 'Editar teléfono',
              onPressed: () => _edit('Teléfono', _profile.phone),
            ),
            ProfileSettingRow(
              title: 'CORREO',
              value: _profile.email,
              titleColor: AppColors.profileDatos,
              icon: Iconsax.edit_2_copy,
              actionLabel: 'Editar correo',
              onPressed: () => _edit('Correo', _profile.email),
            ),
            ProfileSettingRow(
              title: 'ROL',
              value: _profile.rol,
              titleColor: AppColors.profileDatos,
              icon: Iconsax.edit_2_copy,
              actionLabel: 'Editar rol',
              onPressed: () => _edit('Rol', _profile.rol),
            ),
          ],
        ),
        const SizedBox(height: 18),
        ProfileSection(
          title: 'NOTIFICACIONES',
          children: [
            ProfileSettingRow(
              title: 'BANDEJA DE NOTIFICACIONES',
              value: 'Consultar avisos',
              titleColor: AppColors.profileConfiguracion,
              icon: Icons.chevron_right,
              actionLabel: 'Abrir notificaciones',
              onPressed: () async {
                final activity = await showNotificationsSheet(context);
                if (activity != null) {
                  widget.onNotificationActivity?.call(activity);
                }
              },
            ),
            ProfileSettingRow(
              title: 'NOTIFICACIONES',
              value: NotificationService.instance.enabled
                  ? 'Activado'
                  : 'Desactivado',
              titleColor: AppColors.profileConfiguracion,
              icon: NotificationService.instance.enabled
                  ? Icons.close
                  : Icons.check,
              actionLabel: 'Cambiar notificaciones',
              onPressed: () => NotificationService.instance.setEnabled(
                !NotificationService.instance.enabled,
              ),
            ),
            ProfileSettingRow(
              title: 'RECORDATORIOS',
              value: '$_reminder minutos antes',
              titleColor: AppColors.profileConfiguracion,
              icon: Icons.expand_more,
              actionLabel: 'Cambiar recordatorios',
              onPressed: _chooseReminder,
            ),
          ],
        ),
        const SizedBox(height: 18),
        ProfileSection(
          title: 'CONFIGURACIÓN',
          children: [
            ProfileSettingRow(
              title: 'APARIENCIA',
              value: AppearanceController.instance.appearance.label,
              titleColor: AppColors.profileConfiguracion,
              icon: Icons.dark_mode_outlined,
              actionLabel: 'Apariencia',
              onPressed: _chooseAppearance,
            ),
          ],
        ),
        const SizedBox(height: 18),
        ProfileSection(
          title: 'SINCRONIZACIÓN',
          children: [
            ProfileSettingRow(
              title: 'ÚLTIMA SINCRONIZACIÓN',
              value: 'Sin sincronizar',
              titleColor: AppColors.profileSincronizacion,
              icon: Icons.sync,
              actionLabel: 'Sincronizar',
              onPressed: () => _message(
                'La sincronización estará disponible al conectar el servicio.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Center(
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFAA3034),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            onPressed: () {
              AuthService.instance.logout();
              context.go('/login');
            },
            child: const Text(
              'CERRAR SESIÓN',
              style: TextStyle(fontFamily: 'BebasNeue', fontSize: 19),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Center(
          child: Text(
            '${DateTime.now().year} V1.0.0',
            style: profileHeading.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    ),
  );
}
