import 'package:callerapp_frontend/presentation/widgets/app_press_bounce.dart';
import 'package:callerapp_frontend/presentation/widgets/onboarding/onboarding_widgets.dart';
import 'package:callerapp_frontend/resources/styles/styles.dart';
import 'package:callerapp_frontend/services/cube_acr_audio_service.dart';
import 'package:callerapp_frontend/services/onboarding_controller.dart';
import 'package:callerapp_frontend/services/permissions_service.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  static const name = 'onboarding';

  const OnboardingScreen({
    super.key,
    this.permissionsService,
    this.audioService,
    this.controller,
  });

  final PermissionsService? permissionsService;
  final CubeAcrAudioService? audioService;
  final OnboardingController? controller;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver {
  late final PermissionsService _permissionsService;
  late final CubeAcrAudioService _audioService;
  late final OnboardingController _controller;
  final PageController _pageController = PageController();

  int _step = 0;
  PermissionSnapshot? _permissions;
  bool _loadingPermissions = true;
  bool _requestingNotifications = false;
  bool _requestingCalls = false;
  bool _requestingExactAlarms = false;
  bool _linkingFolder = false;
  bool _finishing = false;
  String? _folderName;
  String? _error;

  @override
  void initState() {
    super.initState();
    _permissionsService =
        widget.permissionsService ?? PermissionsService.instance;
    _audioService = widget.audioService ?? CubeAcrAudioService();
    _controller = widget.controller ?? OnboardingController.instance;
    WidgetsBinding.instance.addObserver(this);
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    await Future.wait([_refreshPermissions(), _loadFolder()]);
  }

  Future<void> _loadFolder() async {
    try {
      final name = await _audioService.folderName();
      if (!mounted) return;
      setState(() => _folderName = name);
    } on AudioImportException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error = 'No se pudo consultar la carpeta de grabaciones. Puedes continuar sin vincularla.',
      );
    }
  }

  Future<void> _refreshPermissions() async {
    try {
      final value = await _permissionsService.status();
      if (!mounted) return;
      setState(() {
        _permissions = value;
        _loadingPermissions = false;
      });
    } on PermissionsException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingPermissions = false;
        _error = error.message;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goTo(int step) async {
    await _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
    if (!mounted) return;
    setState(() => _step = step);
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    try {
      final permissions = await _permissionsService.status();
      if (!mounted) return;
      setState(() => _permissions = permissions);
      if (!_allPermissionsGranted(permissions)) {
        setState(() {
          _finishing = false;
          _error = 'Debes permitir todos los accesos para continuar.';
        });
        await _goTo(1);
        return;
      }
    } on PermissionsException catch (error) {
      if (!mounted) return;
      setState(() {
        _finishing = false;
        _error = error.message;
      });
      await _goTo(1);
      return;
    }
    await _controller.complete();
    if (!mounted) return;
    setState(() => _finishing = false);
  }

  bool _allPermissionsGranted(PermissionSnapshot? permissions) =>
      permissions?.notifications == true &&
      permissions?.callsGranted == true &&
      permissions?.exactAlarms == true;

  Future<void> _requestNotifications() async {
    setState(() {
      _requestingNotifications = true;
      _error = null;
    });
    try {
      final value = await _permissionsService.requestNotificationPermission();
      if (!mounted) return;
      setState(() => _permissions = value);
    } on PermissionsException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _requestingNotifications = false);
    }
  }

  Future<void> _requestCalls() async {
    setState(() {
      _requestingCalls = true;
      _error = null;
    });
    try {
      final value = await _permissionsService.requestCallPermissions();
      if (!mounted) return;
      setState(() => _permissions = value);
    } on PermissionsException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _requestingCalls = false);
    }
  }

  Future<void> _requestExactAlarms() async {
    setState(() {
      _requestingExactAlarms = true;
      _error = null;
    });
    try {
      await _permissionsService.requestExactAlarms();
      if (!mounted) return;
      await _refreshPermissions();
    } on PermissionsException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _requestingExactAlarms = false);
    }
  }

  Future<void> _openSettings() async {
    try {
      await _permissionsService.openAppSettings();
    } on PermissionsException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    }
  }

  Future<void> _linkFolder() async {
    setState(() {
      _linkingFolder = true;
      _error = null;
    });
    try {
      final name = await _audioService.linkFolder();
      if (!mounted) return;
      if (name != null) setState(() => _folderName = name);
    } on AudioImportException {
      if (!mounted) return;
      setState(
        () => _error = 'No se pudo vincular la carpeta. Inténtalo de nuevo.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error = 'No se pudo vincular la carpeta. Inténtalo de nuevo.',
      );
    } finally {
      if (mounted) setState(() => _linkingFolder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [_welcomePage(), _permissionsPage(), _audioPage()],
              ),
            ),
            OnboardingStepDots(current: _step, total: 3),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.error),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: _actions(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _page(List<Widget> children) => SingleChildScrollView(
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );

  Widget _title(String value) => Text(
    value,
    textAlign: TextAlign.center,
    style: profileHeading.copyWith(
      fontSize: 30,
      color: Theme.of(context).colorScheme.primary,
    ),
  );

  Widget _welcomePage() => _page([
    const Icon(Icons.phone_in_talk_outlined, size: 72),
    const SizedBox(height: 20),
    _title('BIENVENIDO A CALLAPP'),
    const SizedBox(height: 16),
    const Text(
      'Antes de empezar, revisa estos accesos para que todo funcione correctamente en tu teléfono.',
      textAlign: TextAlign.justify,
    ),
    const SizedBox(height: 20),
    ...[
      'Notificaciones para recordatorios y prospectos asignados.',
      'Acceso al registro de llamadas para medir la duración real.',
      'Carpeta de grabaciones para adjuntar los audios de Cube ACR.',
    ].map(_bullet),
  ]);

  Widget _bullet(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_outline,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    ),
  );

  Widget _permissionsPage() {
    final permissions = _permissions;
    return _page([
      _title('PERMISOS DEL DISPOSITIVO'),
      const SizedBox(height: 12),
      const Text(
        'Autoriza cada permiso con el botón. Puedes cambiarlos después desde los ajustes de Android.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      Text(
        'Debes permitir todos los accesos para continuar.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
      ),
      const SizedBox(height: 16),
      if (_loadingPermissions)
        const Center(child: CircularProgressIndicator())
      else ...[
        PermissionTile(
          icon: Icons.notifications_outlined,
          title: 'NOTIFICACIONES',
          description:
              'Avisos de recordatorios, visitas y prospectos asignados.',
          granted: permissions?.notifications ?? false,
          busy: _requestingNotifications,
          onRequest: _requestNotifications,
          onOpenSettings: _openSettings,
        ),
        PermissionTile(
          icon: Icons.call_outlined,
          title: 'LLAMADAS',
          description:
              'Permite medir la duración real y detectar si sigues en llamada.',
          granted: permissions?.callsGranted ?? false,
          busy: _requestingCalls,
          onRequest: _requestCalls,
          onOpenSettings: _openSettings,
        ),
        PermissionTile(
          icon: Icons.alarm_outlined,
          title: 'ALARMAS EXACTAS',
          description: 'Necesario para que los recordatorios suenen a la hora programada.',
          granted: permissions?.exactAlarms ?? false,
          busy: _requestingExactAlarms,
          onRequest: _requestExactAlarms,
          onOpenSettings: _openSettings,
        ),
      ],
    ]);
  }

  Widget _audioPage() => _page([
    _title('GRABACIONES DE LLAMADAS'),
    const SizedBox(height: 14),
    const Text(
      'CallApp no graba las llamadas. Adjunta los audios que Cube ACR guarda en tu teléfono.',
      textAlign: TextAlign.center,
    ),
    const SizedBox(height: 18),
    const Text('1. Instala y configura Cube ACR para grabar tus llamadas.'),
    const SizedBox(height: 8),
    const Text(
      '2. Vincula aquí la carpeta "Documents/CubeCallRecorder/All" donde Cube ACR guarda los audios.',
    ),
    const SizedBox(height: 8),
    const Text(
      '3. Al registrar una llamada, se podrá buscar y adjuntar la grabación.',
    ),
    const SizedBox(height: 20),
    Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CARPETA DE GRABACIONES',
              style: profileHeading.copyWith(
                fontSize: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(_folderName ?? 'Sin vincular'),
          ],
        ),
      ),
    ),
    const SizedBox(height: 12),
    const Text(
      'Los audios se copian al almacenamiento privado de la app; tu carpeta original no se modifica.',
      textAlign: TextAlign.center,
    ),
  ]);

  Widget _actions() {
    final hasFolder = _folderName != null;
    final permissionsGranted = _allPermissionsGranted(_permissions);
    final primaryLabel = switch (_step) {
      0 => 'COMENZAR',
      1 => 'CONTINUAR',
      _ => hasFolder ? 'FINALIZAR' : 'VINCULAR CARPETA',
    };
    final primaryBusy =
        _finishing ||
        (_step == 1 &&
            (_loadingPermissions ||
                _requestingNotifications ||
                _requestingCalls ||
                _requestingExactAlarms)) ||
        (_step == 2 && _linkingFolder);
    final primaryEnabled = !primaryBusy && (_step != 1 || permissionsGranted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppPressBounce(
          enabled: primaryEnabled,
          child: FilledButton(
            onPressed: !primaryEnabled
                ? null
                : () {
                    if (_step < 2) {
                      _goTo(_step + 1);
                    } else if (hasFolder) {
                      _finish();
                    } else {
                      _linkFolder();
                    }
                  },
            child: Text(primaryBusy ? 'PROCESANDO…' : primaryLabel),
          ),
        ),
        if (_step == 2 && hasFolder) ...[
          const SizedBox(height: 4),
          AppPressBounce(
            enabled: !_finishing && !_linkingFolder,
            child: TextButton(
              onPressed: _finishing || _linkingFolder ? null : _linkFolder,
              child: const Text('CAMBIAR CARPETA'),
            ),
          ),
        ],
      ],
    );
  }
}
