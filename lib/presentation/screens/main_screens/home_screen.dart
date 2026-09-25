import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/profile_screen.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/agenda_screen.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/prospects_screen.dart';
import 'package:callerapp_frontend/presentation/models/home_models.dart';
import 'package:callerapp_frontend/presentation/widgets/home/home_dashboard_widgets.dart';
import 'package:callerapp_frontend/presentation/widgets/navigation_bar_widget.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';

class HomeScreen extends StatefulWidget {
  static const name = 'home-screen';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedDestination = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.homeBackground),
        child: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: IndexedStack(
                index: _selectedDestination,
                children: [
                  CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 118),
                        sliver: SliverList.list(
                          children: [
                            const HomeHeader(userName: 'Leonardo Pérez'),
                            const SizedBox(height: 18),
                            WeeklyProgressStrip(days: demoWeeklyProgress),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: MetricSummaryCard(
                                    metric: demoDashboardMetrics[0],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: MetricSummaryCard(
                                    metric: demoDashboardMetrics[1],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ProspectSection(
                              title: 'Prospectos del día',
                              color: AppColors.homeOrangeSection,
                              prospects: demoTodayProspects,
                              height: 166,
                            ),
                            const SizedBox(height: 20),
                            ProspectSection(
                              title: 'Prospectos nuevos',
                              color: AppColors.homeBlueSection,
                              prospects: demoNewProspects,
                              showAddButton: true,
                              height: 136,
                            ),
                            const SizedBox(height: 20),
                            ProspectSection(
                              title: 'Llamadas atrasadas',
                              color: AppColors.homeRedSection,
                              prospects: demoLateCalls,
                              height: 136,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const ProspectsScreen(),
                  const AgendaScreen(),
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
                  onDestinationSelected: (index) =>
                      setState(() => _selectedDestination = index),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
