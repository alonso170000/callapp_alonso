import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/widgets/home/home_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/profile_screen.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/agenda_screen.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/prospects_screen.dart';

import 'package:callerapp_frontend/presentation/widgets/navigation_bar_widget.dart';

class HomeScreen extends StatefulWidget {
  static const name = 'home-screen';

  const HomeScreen({super.key, this.loadActivities, this.loadProspects});
  final Future<List<AgendaActivity>> Function()? loadActivities;
  final Future<List<ProspectRecord>> Function()? loadProspects;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedDestination = 0;
  final AgendaController _agendaController = AgendaController();
  final ProspectsController _prospectsController = ProspectsController();

  @override
  void dispose() {
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
                    onActivity: (activity) {
                      _agendaController.openActivity(activity);
                    },
                    onAddProspect: () {
                      setState(() => _selectedDestination = 1);
                      _prospectsController.openNewProspect();
                    },
                  ),
                  ProspectsScreen(
                    controller: _prospectsController,
                    loadProspects: widget.loadProspects,
                  ),
                  AgendaScreen(
                    controller: _agendaController,
                    loadActivities: widget.loadActivities,
                    loadProspects: widget.loadProspects,
                  ),
                  const ProfileScreen(),
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
