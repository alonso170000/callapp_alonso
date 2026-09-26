import 'package:callerapp_frontend/presentation/models/prospect_history_models.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_detail_widgets.dart';
import 'package:flutter/material.dart';

class ProspectHistory extends StatelessWidget {
  final List<ProspectHistoryComment> comments;
  final ProspectDiscoverySummary discoverySummary;
  final List<ProspectEmailHistoryEntry> emails;
  final List<ProspectCallHourEntry> callHours;
  final List<String> sessionEntries;

  const ProspectHistory({
    super.key,
    required this.comments,
    required this.discoverySummary,
    required this.emails,
    required this.callHours,
    this.sessionEntries = const [],
  });

  static const _panelColor = Color(0xFF713080);
  static const _contentColor = Color(0xFFE3B3FF);
  static const _fieldColor = Color(0xFF9139A8);

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  String _time(DateTime value) {
    final hour = value.hour > 12 ? value.hour - 12 : value.hour;
    final suffix = value.hour >= 12 ? 'pm' : 'am';
    return '${hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}$suffix';
  }

  Widget _resultBadge(ProspectContactResult result) {
    final (label, color) = switch (result) {
      ProspectContactResult.answered => ('Contestó', const Color(0xFF83F58F)),
      ProspectContactResult.unanswered => (
        'No Contestó',
        const Color(0xFFFF9CA2),
      ),
      ProspectContactResult.appointment => (
        'Cita programada',
        const Color(0xFF8EE9F5),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: const Color(0xFF75334F)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _commentCard(ProspectHistoryComment comment) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(8, 10, 8, 7),
    decoration: BoxDecoration(
      color: const Color(0xFFF0D1FF),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 4,
          runSpacing: 4,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEF86),
                border: Border.all(color: const Color(0xFF776315)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.phone_in_talk, size: 15),
            ),
            ...comment.results.map(_resultBadge),
          ],
        ),
        const SizedBox(height: 7),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: _fieldColor,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            comment.comment,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '${_date(comment.createdAt)}    ${_time(comment.createdAt)}',
          style: const TextStyle(fontSize: 9),
        ),
      ],
    ),
  );

  Widget _summaryField(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 2),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: _fieldColor,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ),
      ],
    ),
  );

  Widget _emailHistory() => ProspectDetailPanel(
    title: 'Historial de correos',
    color: _panelColor,
    nested: true,
    initiallyExpanded: true,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: _contentColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: emails
            .map(
              (email) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0D1FF),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.mail_outline,
                        color: _fieldColor,
                        size: 20,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              email.templateName,
                              style: const TextStyle(
                                fontFamily: 'BebasNeue',
                                fontSize: 14,
                                color: _panelColor,
                              ),
                            ),
                            Text(
                              email.description,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${_date(email.sentAt)}\n${email.sentAt.hour.toString().padLeft(2, '0')}:'
                        '${email.sentAt.minute.toString().padLeft(2, '0')}',
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    ),
  );

  Color _hourColor(int weekday, int hour) {
    for (final entry in callHours) {
      if (entry.weekday == weekday && entry.hour == hour) {
        return entry.status == ProspectCallHourStatus.answered
            ? const Color(0xFF43C756)
            : const Color(0xFFF04C55);
      }
    }
    return _fieldColor;
  }

  Widget _legend(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 11, height: 11, color: color),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12)),
    ],
  );

  Widget _callHistory() {
    const days = ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sa', 'Do'];
    return ProspectDetailPanel(
      title: 'Historial de llamadas por horario',
      color: _panelColor,
      nested: true,
      initiallyExpanded: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(8, 9, 8, 10),
        decoration: BoxDecoration(
          color: _contentColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _periodLabel('2026'),
                const SizedBox(width: 6),
                _periodLabel('Octubre'),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 39,
                    decoration: BoxDecoration(
                      color: _fieldColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Icon(Icons.chevron_left, color: Colors.white, size: 20),
                        Flexible(
                          child: Text(
                            'Semana 12 - 18',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'D Í A   D E   L A   S E M A N A',
              style: TextStyle(fontSize: 8, letterSpacing: 1.5),
            ),
            Row(
              children: [
                const SizedBox(width: 29),
                ...days.map(
                  (day) => Expanded(
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
            for (var hour = 0; hour < 24; hour++)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 29,
                      child: Text(
                        hour.toString().padLeft(2, '0'),
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                    const SizedBox(width: 4),
                    for (var weekday = 1; weekday <= 7; weekday++)
                      Expanded(
                        child: Container(
                          height: 17,
                          margin: const EdgeInsets.only(right: 2),
                          decoration: BoxDecoration(
                            color: _hourColor(weekday, hour),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 15,
              runSpacing: 5,
              children: [
                _legend(const Color(0xFF43C756), 'Atendida'),
                _legend(const Color(0xFFF04C55), 'Rechazada'),
                _legend(_fieldColor, 'Sin actividad'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _periodLabel(String text) => Container(
    height: 39,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: _fieldColor,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: const TextStyle(color: Colors.white, fontSize: 13),
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ProspectDetailPanel(
        title: 'Historial de comentarios',
        color: _panelColor,
        nested: true,
        initiallyExpanded: true,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _contentColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              for (var index = 0; index < comments.length; index++) ...[
                _commentCard(comments[index]),
                if (index < comments.length - 1) const SizedBox(height: 9),
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: 10),
      ProspectDetailPanel(
        title: 'Resumen de discovery',
        color: _panelColor,
        nested: true,
        initiallyExpanded: true,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
          decoration: BoxDecoration(
            color: _contentColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              _summaryField('Decisión', discoverySummary.decision),
              _summaryField('Disposición', discoverySummary.disposition),
              _summaryField('Dinero', discoverySummary.money),
              _summaryField('Pasó a TO', discoverySummary.transferredTo),
              _summaryField('Discovery Completo', discoverySummary.completed),
            ],
          ),
        ),
      ),
      const SizedBox(height: 10),
      _emailHistory(),
      const SizedBox(height: 10),
      _callHistory(),
      if (sessionEntries.isNotEmpty) ...[
        const SizedBox(height: 10),
        ProspectDetailPanel(
          title: 'Registros de esta sesión',
          color: _panelColor,
          nested: true,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _contentColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sessionEntries
                  .map((entry) => Text('• $entry'))
                  .toList(),
            ),
          ),
        ),
      ],
    ],
  );
}
