import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/presentation/widgets/profile/edit_profile_dialog.dart';
import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/widgets/notifications/notifications_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:callerapp_frontend/presentation/models/profile_models.dart';
import 'package:callerapp_frontend/presentation/widgets/profile/profile_widgets.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late ProfileData _profile;
  bool _notifications = true;
  int _reminder = 15;

  @override
  void initState() {
    super.initState();
    final auth = AuthService.instance;
    _profile = ProfileData(
      name: auth.userName,
      phone: auth.phone ?? 'No disponible',
      email: auth.email ?? 'No disponible',
    );
  }

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
      backgroundColor: AppColors.homeBackground,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('RECORDATORIOS', style: profileHeading),
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
  Widget build(BuildContext context) => ListView(
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
              style: profileHeading.copyWith(fontSize: 30),
            ),
          ),
          IconButton.filled(
            tooltip: 'Notificaciones',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: AppColors.homeWarmText,
            ),
            onPressed: () => showNotificationsSheet(context),
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
            onPressed: () => showNotificationsSheet(context),
          ),
          ProfileSettingRow(
            title: 'NOTIFICACIONES',
            value: _notifications ? 'Activado' : 'Desactivado',
            titleColor: AppColors.profileConfiguracion,
            icon: _notifications ? Icons.close : Icons.check,
            actionLabel: 'Cambiar notificaciones',
            onPressed: () => setState(() => _notifications = !_notifications),
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
            value: 'Claro',
            titleColor: AppColors.profileConfiguracion,
            icon: Icons.dark_mode_outlined,
            actionLabel: 'Apariencia',
            onPressed: () => _message('El tema oscuro aún no está disponible.'),
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
        child: Text('${DateTime.now().year} V1.0.0', style: profileHeading),
      ),
    ],
  );
}
