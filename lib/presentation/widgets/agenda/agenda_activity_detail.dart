import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/widgets/home/home_card_components.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class AgendaActivityDetail extends StatelessWidget {
  final AgendaActivity activity;
  final VoidCallback onClose;
  final VoidCallback onMessage;
  final VoidCallback onCall;
  final VoidCallback onOpenProspect;
  final VoidCallback onEdit;
  final VoidCallback onComplete;
  final VoidCallback onReschedule;

  const AgendaActivityDetail({
    super.key,
    required this.activity,
    required this.onClose,
    required this.onMessage,
    required this.onCall,
    required this.onOpenProspect,
    required this.onEdit,
    required this.onComplete,
    required this.onReschedule,
  });

  static const _months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  static const _days = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  Color get _statusColor => switch (activity.status) {
    AgendaStatus.completed => AppColors.homeGreenCard,
    AgendaStatus.overdue => AppColors.homeRedSection,
    AgendaStatus.pending => AppColors.homeYellowCard,
    AgendaStatus.cancelled => const Color(0xFFB7D1CB),
  };

  String get _time {
    final hour = activity.date.hour % 12 == 0 ? 12 : activity.date.hour % 12;
    final minute = activity.date.minute.toString().padLeft(2, '0');
    return '${hour.toString().padLeft(2, '0')}:$minute ${activity.date.hour < 12 ? 'AM' : 'PM'}';
  }

  Widget _contactAction(
    String tooltip,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    style: IconButton.styleFrom(
      backgroundColor: color,
      foregroundColor: AppColors.primaryColor,
      minimumSize: const Size(38, 38),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    icon: Icon(icon, size: 20),
  );

  Widget _sectionTitle(String title) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.primaryColor,
          fontFamily: 'BebasNeue',
          fontSize: 21,
        ),
      ),
    ),
  );

  Widget _infoCard(String value, String label, String detail, Color color) =>
      Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.black,
                      fontFamily: 'SulphurPoint',
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      height: 0.9,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              detail,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.primaryColor,
                fontFamily: 'SulphurPoint',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black,
                fontFamily: 'SulphurPoint',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 0.95,
              ),
            ),
          ],
        ),
      );

  Widget _prospectCard() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.primaryColor,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFE75AC7),
              child: ClipOval(
                child: Image.asset(
                  'lib/resources/images/Frame.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.prospect,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.homeWarmText,
                      fontFamily: 'BebasNeue',
                      fontSize: 22,
                    ),
                  ),
                  Text(
                    activity.lastContact,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'SulphurPoint',
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            _contactAction(
              'Enviar mensaje',
              Iconsax.message_copy,
              AppColors.homeGreenCard,
              onMessage,
            ),
            const SizedBox(width: 2),
            _contactAction(
              'Llamar al prospecto',
              Iconsax.call_calling_copy,
              AppColors.homeWarmText,
              onCall,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: activity.tags.isEmpty
                    ? const SizedBox.shrink()
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        color: const Color(0xFFEAA4EE),
                        child: Text(
                          activity.tags.first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textDarkColor,
                            fontFamily: 'BebasNeue',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 5),
                child: IconButton(
                  tooltip: 'Ver prospecto',
                  onPressed: onOpenProspect,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    fixedSize: const Size.square(52),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const HomeCardArrow(),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _secondaryAction(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) => Expanded(
    child: OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        backgroundColor: const Color(0xFFACEFE2),
        foregroundColor: AppColors.primaryColor,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),
      icon: Icon(icon, size: 19),
      label: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: const TextStyle(fontFamily: 'BebasNeue', fontSize: 15),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.homeBackground,
    child: Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(10, 13, 16, 16),
          decoration: const BoxDecoration(
            color: AppColors.homeDeepTeal,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Cerrar detalle',
                onPressed: onClose,
                color: Colors.white,
                icon: const Icon(Icons.arrow_back_ios_new),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DETALLE DE ACTIVIDAD',
                      style: TextStyle(
                        color: Color(0xFFA8E6DA),
                        fontFamily: 'SulphurPoint',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Text(
                      activity.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'BebasNeue',
                        fontSize: 27,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  activity.status.label,
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontFamily: 'BebasNeue',
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              children: [
                _prospectCard(),
                const SizedBox(height: 18),
                _sectionTitle('CUÁNDO Y DÓNDE'),
                SizedBox(
                  height: 150,
                  child: Row(
                    children: [
                      Expanded(
                        child: _infoCard(
                          '${activity.date.day}',
                          'Fecha',
                          '${_days[activity.date.weekday - 1]} · ${_months[activity.date.month - 1]} ${activity.date.year}',
                          AppColors.homeBlueSection,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _infoCard(
                          _time.split(' ').first,
                          'Hora',
                          _time.split(' ').last,
                          AppColors.homeYellowCard,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 150,
                  child: Row(
                    children: [
                      Expanded(
                        child: _infoCard(
                          activity.location.toUpperCase(),
                          'Ubicación',
                          'Lugar de la actividad',
                          AppColors.homeOrangeSection,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _infoCard(
                          '${activity.reminderMinutes}',
                          'Recordatorio',
                          'minutos antes',
                          AppColors.homeGreenCard,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _sectionTitle('DESCRIPCIÓN'),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    activity.description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'SulphurPoint',
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: onComplete,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: AppColors.homeWarmText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 25),
                  label: Text(
                    activity.status == AgendaStatus.completed
                        ? 'COMPLETADA'
                        : 'COMPLETAR ACTIVIDAD',
                    style: const TextStyle(
                      fontFamily: 'BebasNeue',
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  _secondaryAction('EDITAR', Iconsax.edit_copy, onEdit),
                  const SizedBox(width: 9),
                  _secondaryAction(
                    'Cancelar',
                    Iconsax.calendar_remove_copy,
                    onReschedule,
                  ),
                  const SizedBox(width: 9),
                  _secondaryAction(
                    'Eliminar',
                    Iconsax.trash_copy,
                    onReschedule,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
