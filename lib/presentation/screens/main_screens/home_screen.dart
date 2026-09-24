import 'package:callerapp_frontend/presentation/screens/main_screens/prospects_screen.dart';
import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/screens/screens.dart';

class HomeScreen extends StatefulWidget {
  static const name = 'home-screen';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedDestination = 0;
  final List<WeeklyCallProgress> _weeklyProgress = const [
    WeeklyCallProgress(
      dayLabel: 'Lun',
      calls: 7,
      status: CallProgressStatus.completed,
    ),
    WeeklyCallProgress(
      dayLabel: 'Mar',
      calls: 8,
      status: CallProgressStatus.pending,
    ),
    WeeklyCallProgress(
      dayLabel: 'Mie',
      calls: 9,
      status: CallProgressStatus.pending,
    ),
    WeeklyCallProgress(
      dayLabel: 'Jue',
      calls: 10,
      status: CallProgressStatus.completed,
    ),
    WeeklyCallProgress(
      dayLabel: 'Vie',
      calls: 11,
      status: CallProgressStatus.pending,
      isSelected: true,
    ),
    WeeklyCallProgress(
      dayLabel: 'Sab',
      calls: 12,
      status: CallProgressStatus.missed,
    ),
    WeeklyCallProgress(
      dayLabel: 'Dom',
      calls: 13,
      status: CallProgressStatus.missed,
    ),
  ];

  final List<DashboardMetric> _metrics = const [
    DashboardMetric(
      value: 0,
      title: 'Llamadas\nRealizadas',
      backgroundColor: AppColors.homeGreenCard,
    ),
    DashboardMetric(
      value: 23,
      title: 'Llamadas\nPendientes',
      backgroundColor: AppColors.homeYellowCard,
    ),
  ];

  final List<ProspectItem> _todayProspects = const [
    ProspectItem(
      name: 'Betsua',
      subtitle: 'Con Cita',
      timeLabel: '10:00 am',
      avatarColor: Color(0xFFBF4242),
      accentColor: Color(0xFF23C9DC),
    ),
    ProspectItem(
      name: 'Alan Do...',
      subtitle: 'Con Cita',
      timeLabel: '11:30 am',
      avatarColor: Color(0xFF81F59B),
      accentColor: Color(0xFFE753C2),
    ),
    ProspectItem(
      name: 'Juan Uch',
      subtitle: 'Con Cita',
      timeLabel: '12:30 pm',
      avatarColor: Color(0xFF078C88),
      accentColor: Color(0xFFF5DB58),
    ),
    ProspectItem(
      name: 'Manuel',
      avatarColor: Color(0xFFA08AF7),
      accentColor: Color(0xFFA08AF7),
    ),
    ProspectItem(
      name: 'Joshua',
      avatarColor: Color(0xFF93DDF2),
      accentColor: Color(0xFFF9B734),
    ),
  ];

  final List<ProspectItem> _newProspects = const [
    ProspectItem(
      name: 'Karina Do...',
      avatarColor: Color(0xFF86F5A0),
      accentColor: Color(0xFFE64FBF),
    ),
    ProspectItem(
      name: 'Julia Da...',
      avatarColor: Color(0xFF93DDF2),
      accentColor: Color(0xFFFFC334),
    ),
    ProspectItem(
      name: 'Vanesa L.',
      avatarColor: Color(0xFF058F8A),
      accentColor: Color(0xFFE8DA63),
    ),
    ProspectItem(
      name: 'Damian',
      avatarColor: Color(0xFFBF4242),
      accentColor: Color(0xFF23C9DC),
    ),
  ];

  final List<ProspectItem> _lateCalls = const [
    ProspectItem(
      name: 'Julia Da...',
      avatarColor: Color(0xFFA08AF7),
      accentColor: Color(0xFFA08AF7),
    ),
    ProspectItem(
      name: 'Julia Da...',
      avatarColor: Color(0xFF93DDF2),
      accentColor: Color(0xFFFFC334),
    ),
    ProspectItem(
      name: 'Damian',
      avatarColor: Color(0xFFBF4242),
      accentColor: Color(0xFF23C9DC),
    ),
    ProspectItem(
      name: 'Karina Do...',
      avatarColor: Color(0xFF86F5A0),
      accentColor: Color(0xFFE64FBF),
    ),
    ProspectItem(
      name: 'Vanesa L.',
      avatarColor: Color(0xFF058F8A),
      accentColor: Color(0xFFE8DA63),
    ),
  ];

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
                index: _selectedDestination == 1 ? 1 : 0,
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
                            WeeklyProgressStrip(days: _weeklyProgress),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: MetricSummaryCard(metric: _metrics[0]),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: MetricSummaryCard(metric: _metrics[1]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ProspectSection(
                              title: 'Prospectos del día',
                              color: AppColors.homeOrangeSection,
                              prospects: _todayProspects,
                              height: 166,
                            ),
                            const SizedBox(height: 20),
                            ProspectSection(
                              title: 'Prospectos nuevos',
                              color: AppColors.homeBlueSection,
                              prospects: _newProspects,
                              showAddButton: true,
                              height: 136,
                            ),
                            const SizedBox(height: 20),
                            ProspectSection(
                              title: 'Llamadas atrasadas',
                              color: AppColors.homeRedSection,
                              prospects: _lateCalls,
                              height: 136,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const ProspectsScreen(),
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
