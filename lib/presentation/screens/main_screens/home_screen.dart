import 'dart:async';

import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/widgets/home/home_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/profile_screen.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/agenda_screen.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/prospects_screen.dart';
import 'package:callerapp_frontend/services/notification_service.dart';
import 'package:callerapp_frontend/services/prospect_assignment_controller.dart';
import 'package:callerapp_frontend/services/outbox_service.dart';
import 'package:callerapp_frontend/data/local/pending_operations_store.dart';
import 'package:callerapp_frontend/presentation/models/sync_models.dart';
import 'package:callerapp_frontend/presentation/widgets/sync_conflicts_sheet.dart';
import 'package:callerapp_frontend/presentation/widgets/sync_pending_sheet.dart';
import 'package:callerapp_frontend/presentation/widgets/sync_status_indicator.dart';

import 'package:callerapp_frontend/presentation/widgets/navigation_bar_widget.dart';

class HomeScreen extends StatefulWidget {
  static const name = 'home-screen';

  const HomeScreen({super.key, this.loadActivities, this.loadProspects});
  final Future<List<AgendaActivity>> Function()? loadActivities;
  final Future<List<ProspectRecord>> Function()? loadProspects;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedDestination = 0;
  bool _wasSyncing = false;
  int _seenRevision = 0;
  final AgendaController _agendaController = AgendaController();
  final HomeDashboardController _homeDashboardController =
      HomeDashboardController();
  final ProspectsController _prospectsController = ProspectsController();
  final ProspectAssignmentController _assignmentController =
      ProspectAssignmentController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _wasSyncing = OutboxService.instance.isSyncing;
    _seenRevision = OutboxService.instance.revision;
    OutboxService.instance.addListener(_outboxChanged);
    if (widget.loadProspects == null) _assignmentController.start();
    NotificationService.instance.pendingProspectId.addListener(
      _pendingProspectChanged,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPendingProspect());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.loadProspects == null) {
      unawaited(_assignmentController.check());
      unawaited(OutboxService.instance.flush());
    }
  }

  String _operationTitle(PendingOperation operation) =>
      switch (operation.kind) {
        'agenda.create' => 'CREAR ACTIVIDAD',
        'agenda.update' => 'EDITAR ACTIVIDAD',
        'agenda.complete' => 'COMPLETAR ACTIVIDAD',
        'agenda.cancel' => 'CANCELAR ACTIVIDAD',
        'agenda.delete' => 'ELIMINAR ACTIVIDAD',
        'prospect.create' => 'CREAR PROSPECTO',
        'prospect.update' => 'EDITAR PROSPECTO',
        'prospect.follow_up' => 'REGISTRAR SEGUIMIENTO',
        'prospect.discovery' => 'GUARDAR DISCOVERY',
        _ => 'CAMBIO PENDIENTE',
      };

  Future<void> _showSyncConflicts() async {
    final outbox = OutboxService.instance;
    final conflicts = outbox.operations
        .where((operation) => operation.state == PendingOperationState.conflict)
        .toList();
    if (conflicts.isEmpty || !mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => SyncConflictsSheet(
        conflicts: [
          for (final operation in conflicts)
            SyncConflictViewData(
              id: operation.id,
              title: _operationTitle(operation),
              message:
                  operation.lastError ?? 'El servidor rechazó este cambio.',
              attemptCount: operation.attemptCount,
            ),
        ],
        onRetry: (id) async {
          await outbox.retry(
            conflicts.firstWhere((operation) => operation.id == id),
          );
          _refreshSyncedViews();
        },
        onDiscard: (id) async {
          await outbox.discard(
            conflicts.firstWhere((operation) => operation.id == id),
          );
          _refreshSyncedViews();
        },
      ),
    );
  }

  void _refreshSyncedViews() {
    _homeDashboardController.refresh();
    _agendaController.refresh();
    _prospectsController.refresh();
  }

  Future<void> _showSyncPending() async {
    final outbox = OutboxService.instance;
    final pending = outbox.operations
        .where((operation) => operation.state != PendingOperationState.conflict)
        .toList();
    if (pending.isEmpty || !mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => SyncPendingSheet(
        issues: [
          for (final operation in pending)
            SyncPendingViewData(
              id: operation.id,
              title: _operationTitle(operation),
              message:
                  operation.lastError ??
                  'En espera de conexión para sincronizar.',
              attemptCount: operation.attemptCount,
            ),
        ],
        onRetry: (_) async {
          await outbox.flush();
          _refreshSyncedViews();
        },
      ),
    );
  }

  /// Al terminar una sincronización con trabajo real, los datos de las tres
  /// pestañas pueden haber cambiado (un seguimiento crea una actividad y
  /// actualiza el prospecto), así que se refrescan una sola vez. Un vaciado
  /// sin operaciones no dispara peticiones para no encadenar sincronizaciones.
  void _outboxChanged() {
    final service = OutboxService.instance;
    final changed = service.revision != _seenRevision;
    _seenRevision = service.revision;
    final syncing = service.isSyncing;
    if (_wasSyncing && !syncing && changed && mounted) _refreshSyncedViews();
    _wasSyncing = syncing;
  }

  Future<void> _syncNow() async {
    await OutboxService.instance.flush();
    if (mounted) _refreshSyncedViews();
  }

  Widget _syncStatus() => ListenableBuilder(
    listenable: OutboxService.instance,
    builder: (context, _) {
      final outbox = OutboxService.instance;
      return SyncStatusIndicator(
        pendingCount: outbox.pendingCount,
        conflictCount: outbox.conflictCount,
        syncing: outbox.isSyncing,
        onSync: _syncNow,
        onConflicts: _showSyncConflicts,
        onPending: _showSyncPending,
      );
    },
  );

  void _pendingProspectChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openPendingProspect();
    });
  }

  void _openPendingProspect() {
    final prospectId = NotificationService.instance.takePendingProspectId();
    if (prospectId == null || !mounted) return;
    setState(() => _selectedDestination = 1);
    _prospectsController.openProspect(prospectId);
  }

  void _openNotificationActivity(AgendaActivity activity) {
    if (activity.type == NotificationService.assignmentType &&
        activity.prospectId != null) {
      setState(() => _selectedDestination = 1);
      _prospectsController.openProspect(activity.prospectId!);
      return;
    }
    _agendaController.openActivity(activity);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    OutboxService.instance.removeListener(_outboxChanged);
    NotificationService.instance.pendingProspectId.removeListener(
      _pendingProspectChanged,
    );
    _assignmentController.dispose();
    _homeDashboardController.dispose();
    _agendaController.dispose();
    _prospectsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: DecoratedBox(
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
        child: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: IndexedStack(
                index: _selectedDestination,
                children: [
                  HomeDashboard(
                    controller: _homeDashboardController,
                    active: _selectedDestination == 0,
                    loadActivities: widget.loadActivities,
                    loadProspects: widget.loadProspects,
                    onAgenda: (date, ids, label) {
                      _agendaController.showFromHome(date, ids, label);
                      setState(() => _selectedDestination = 2);
                    },
                    onProspects: (ids, label) {
                      _prospectsController.showFromHome(ids, label);
                      setState(() => _selectedDestination = 1);
                    },
                    onActivity: _openNotificationActivity,
                    onAddProspect: () {
                      setState(() => _selectedDestination = 1);
                      _prospectsController.openNewProspect();
                    },
                    syncStatus: _syncStatus(),
                  ),
                  ProspectsScreen(
                    controller: _prospectsController,
                    loadProspects: widget.loadProspects,
                    onNotificationActivity: _openNotificationActivity,
                  ),
                  AgendaScreen(
                    controller: _agendaController,
                    loadActivities: widget.loadActivities,
                    loadProspects: widget.loadProspects,
                    onNotificationActivity: _openNotificationActivity,
                    syncStatus: _syncStatus(),
                  ),
                  ProfileScreen(
                    onNotificationActivity: _openNotificationActivity,
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 18,
              child: SafeArea(
                top: false,
                child: NavigationBarWidget(
                  destinationIndex: _selectedDestination,
                  onDestinationSelected: (index) =>
                      setState(() => _selectedDestination = index),
                  onAddAgenda: _agendaController.openNewActivity,
                  onAddProspect: _prospectsController.openNewProspect,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
