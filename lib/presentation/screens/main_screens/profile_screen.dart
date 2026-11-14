import 'dart:async';

import 'package:callerapp_frontend/services/auth_service.dart';
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
import 'package:callerapp_frontend/data/local/local_scope.dart';
import 'package:callerapp_frontend/data/local/profile_preferences_store.dart';
import 'package:callerapp_frontend/data/local/app_database.dart';
import 'package:callerapp_frontend/services/business_clock.dart';
import 'package:callerapp_frontend/services/cube_acr_audio_service.dart';
import 'package:callerapp_frontend/services/outbox_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.onNotificationActivity,
    this.audioService,
  });
  final ValueChanged<AgendaActivity>? onNotificationActivity;
  final CubeAcrAudioService? audioService;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late ProfileData _profile;
  late final CubeAcrAudioService _audioService;
  final _preferences = ProfilePreferencesStore();
  final _database = AppDatabase.instance;
  int _reminder = 15;
  DateTime? _lastSync;
  String? _audioFolder;
  bool _loadingAudioFolder = true;

  @override
  void initState() {
    super.initState();
    AppearanceController.instance.addListener(_appearanceChanged);
    NotificationService.instance.addListener(_notificationsChanged);
    OutboxService.instance.addListener(_syncChanged);
    _audioService = widget.audioService ?? CubeAcrAudioService();
    final auth = AuthService.instance;
    _profile = ProfileData(
      name: auth.userName,
      phone: auth.phone ?? 'No disponible',
      email: auth.email ?? 'No disponible',
      rol: auth.activeDevelopment?['rol'] as String? ?? 'No disponible',
    );
    _loadReminder();
    _loadSyncStatus();
    unawaited(_loadAudioFolder());
  }

  LocalScope? get _scope {
    final auth = AuthService.instance;
    final userId = auth.userId;
    final developmentId = auth.developmentId;
    return userId == null || developmentId == null
        ? null
        : LocalScope(userId: userId, developmentId: developmentId);
  }

  Future<void> _loadReminder() async {
    final scope = _scope;
    if (scope == null) return;
    final value = await _preferences.read(scope);
    if (mounted && value?.reminderMinutes != null) {
      setState(() => _reminder = value!.reminderMinutes!);
    }
  }

  Future<void> _loadSyncStatus() async {
    final scope = _scope;
    if (scope == null) return;
    final value = await _database.lastRefreshedAt(scope);
    if (mounted) setState(() => _lastSync = value);
  }

  Future<void> _loadAudioFolder() async {
    try {
      final name = await _audioService.folderName();
      if (mounted) {
        setState(() {
          _audioFolder = name;
          _loadingAudioFolder = false;
        });
      }
    } on AudioImportException {
      if (mounted) setState(() => _loadingAudioFolder = false);
    }
  }

  Future<void> _linkAudioFolder() async {
    if (_audioFolder != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Cambiar carpeta de grabaciones'),
          content: const Text(
            'Los audios se buscarán en la nueva carpeta. Elige la carpeta raíz de Cube ACR.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('CANCELAR'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('CONTINUAR'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    try {
      final name = await _audioService.linkFolder();
      if (!mounted || name == null) return;
      setState(() => _audioFolder = name);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Carpeta vinculada: $name')));
    } on AudioImportException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo vincular la carpeta de Cube ACR.'),
        ),
      );
    }
  }

  void _appearanceChanged() {
    if (mounted) setState(() {});
  }

  void _notificationsChanged() {
    if (mounted) setState(() {});
  }

  void _syncChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppearanceController.instance.removeListener(_appearanceChanged);
    NotificationService.instance.removeListener(_notificationsChanged);
    OutboxService.instance.removeListener(_syncChanged);
    super.dispose();
  }

  void _chooseAppearance() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => AppearanceSheet(controller: AppearanceController.instance),
  );

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
    if (mounted && result != null) {
      setState(() => _reminder = result);
      final scope = _scope;
      if (scope != null) await _preferences.setReminderMinutes(scope, result);
    }
  }

  String get _syncValue {
    final outbox = OutboxService.instance;
    if (outbox.isSyncing) return 'Sincronizando';
    if (outbox.conflictCount > 0) {
      return '${outbox.conflictCount} conflicto(s) por resolver';
    }
    if (outbox.pendingCount > 0) {
      return '${outbox.pendingCount} cambio(s) pendientes';
    }
    final lastSync = _lastSync;
    if (lastSync == null) return 'Sin datos sincronizados';
    final value = businessTimeFromInstant(lastSync);
    final date =
        '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
    final time =
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    return '$date · $time';
  }

  Future<void> _syncNow() async {
    await OutboxService.instance.flush();
    await _loadSyncStatus();
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
              icon: Icons.check,
              actionLabel: 'Datos personales no editables',
            ),
            ProfileSettingRow(
              title: 'TELÉFONO',
              value: _profile.phone,
              titleColor: AppColors.profileDatos,
              icon: Icons.check,
              actionLabel: 'Datos personales no editables',
            ),
            ProfileSettingRow(
              title: 'CORREO',
              value: _profile.email,
              titleColor: AppColors.profileDatos,
              icon: Icons.check,
              actionLabel: 'Datos personales no editables',
            ),
            ProfileSettingRow(
              title: 'ROL',
              value: _profile.rol,
              titleColor: AppColors.profileDatos,
              icon: Icons.check,
              actionLabel: 'Datos personales no editables',
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
            ProfileSettingRow(
              title: 'CARPETA DE GRABACIONES',
              value: _loadingAudioFolder
                  ? 'Comprobando…'
                  : _audioFolder ?? 'Sin vincular',
              titleColor: AppColors.profileConfiguracion,
              icon: Icons.folder_open,
              actionLabel: _audioFolder == null
                  ? 'Vincular carpeta de Cube ACR'
                  : 'Cambiar carpeta de Cube ACR',
              onPressed: _loadingAudioFolder ? null : _linkAudioFolder,
            ),
          ],
        ),
        const SizedBox(height: 18),
        ProfileSection(
          title: 'SINCRONIZACIÓN',
          children: [
            ProfileSettingRow(
              title: 'ÚLTIMA SINCRONIZACIÓN',
              value: _syncValue,
              titleColor: AppColors.profileSincronizacion,
              icon: Icons.sync,
              actionLabel: 'Sincronizar',
              onPressed: _syncNow,
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
