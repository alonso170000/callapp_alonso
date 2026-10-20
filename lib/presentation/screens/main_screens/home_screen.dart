import 'dart:async';

import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/widgets/home/home_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/profile_screen.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/agenda_screen.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/prospects_screen.dart';
import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/notification_service.dart';
import 'package:callerapp_frontend/services/prospects_service.dart';

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
  final AgendaController _agendaController = AgendaController();
  final ProspectsController _prospectsController = ProspectsController();
  final ProspectsService _assignmentService = ProspectsService();
  Timer? _assignmentTimer;
  bool _checkingAssignments = false;
  Set<int>? _knownProspectIds;
  String? _knownAssignmentScope;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.loadProspects == null) {
      unawaited(_checkAssignments());
      _assignmentTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => unawaited(_checkAssignments()),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.loadProspects == null) {
      unawaited(_checkAssignments());
    }
  }

  Future<void> _checkAssignments() async {
    if (_checkingAssignments) return;
    final userId = AuthService.instance.userId;
    final developmentId = AuthService.instance.developmentId;
    if (userId == null || developmentId == null) return;
    final scope = '$userId:$developmentId';
    if (_knownAssignmentScope != scope) {
      _knownAssignmentScope = scope;
      _knownProspectIds = null;
    }
    _checkingAssignments = true;
    try {
      final prospects = await _assignmentService.fetch();
      final currentIds = prospects
          .map((item) => item.id)
          .whereType<int>()
          .toSet();
      final previousIds = _knownProspectIds;
      final newlyVisible = previousIds == null
          ? <int>{}
          : currentIds.difference(previousIds);
      _knownProspectIds = currentIds;
      await NotificationService.instance.syncAssignedProspects(
        prospects,
        userId: userId,
        developmentId: developmentId,
        newlyVisibleProspectIds: newlyVisible,
      );
    } catch (_) {
      // La siguiente consulta o el refresco manual volverá a intentarlo.
    } finally {
      _checkingAssignments = false;
    }
  }

  void _openNotificationActivity(AgendaActivity activity) {
    if (activity.type == 'nuevo_prospecto' && activity.prospectId != null) {
      setState(() => _selectedDestination = 1);
      _prospectsController.openProspect(activity.prospectId!);
      return;
    }
    _agendaController.openActivity(activity);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _assignmentTimer?.cancel();
    _assignmentService.dispose();
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
