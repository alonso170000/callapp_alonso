import 'package:flutter/material.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:callerapp_frontend/resources/styles/styles.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';

class AgendaActivityTile extends StatelessWidget {
  final AgendaActivity activity;
  final VoidCallback onTap;

  const AgendaActivityTile({
    super.key,
    required this.activity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (activity.status) {
      AgendaStatus.completed => AppColors.homeGreenCard,
      AgendaStatus.overdue => AppColors.homeRedSection,
      AgendaStatus.pending => AppColors.homeYellowCard,
    };
    final hour = activity.date.hour % 12;
    final time =
        '${(hour == 0 ? 12 : hour).toString().padLeft(2, '0')}:${activity.date.minute.toString().padLeft(2, '0')}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 58,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '$time\n${activity.date.hour < 12 ? 'AM' : 'PM'}',
              style: const TextStyle(
                fontFamily: 'SulphurPoint',
                color: AppColors.primaryColor,
                fontSize: 14,
                height: 1,
              ),
            ),
          ),
        ),
        Expanded(
          child: Material(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(15),
            elevation: 2,
            shadowColor: AppColors.primaryColor.withValues(alpha: 0.2),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          activity.title,
                          style: agendaHeadingStyle.copyWith(color: color),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            activity.status.label,
                            style: const TextStyle(
                              fontFamily: 'SulphurPoint',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.homeBackground),
                      ),
                      child: Text(
                        activity.prospect,
                        style: const TextStyle(
                          fontFamily: 'BebasNeue',
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      activity.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'SulphurPoint',
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    if (activity.tags.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: activity.tags
                            .map(
                              (tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                color: tag == 'CALIENTE'
                                    ? const Color(0xFFFF4655)
                                    : tag == 'LOTE'
                                    ? AppColors.homeWarmText
                                    : const Color(0xFFEAA4EE),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontFamily: 'BebasNeue',
                                    fontSize: 13,
                                    color: tag == 'CALIENTE'
                                        ? Colors.white
                                        : AppColors.primaryColor,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
