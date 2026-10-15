import 'package:callerapp_frontend/presentation/screens/screens.dart';
import 'package:flutter/material.dart';
import 'package:callerapp_frontend/services/prospects_service.dart';
import 'package:callerapp_frontend/presentation/models/prospect_history_models.dart';

import 'prospect_detail_widgets.dart';
import 'prospect_history.dart';

class ProspectCommentsPanel extends StatefulWidget {
  const ProspectCommentsPanel({
    super.key,
    required this.prospectId,
    this.loadComments,
  });
  final int prospectId;
  final Future<List<ProspectHistoryComment>> Function()? loadComments;
  @override
  State<ProspectCommentsPanel> createState() => ProspectCommentsPanelState();
}

class ProspectCommentsPanelState extends State<ProspectCommentsPanel> {
  Future<void> refresh() async {
    final comments = _load();
    setState(() {
      _comments = comments;
    });
    try {
      await comments;
    } catch (_) {
      /* FutureBuilder displays the error. */
    }
  }

  final _service = ProspectsService();
  late Future<List<ProspectHistoryComment>> _comments;
  Future<List<ProspectHistoryComment>> _load() =>
      widget.loadComments?.call() ?? _service.contactHistory(widget.prospectId);
  @override
  void initState() {
    super.initState();
    _comments = _load();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ProspectDetailPanel(
    title: 'Historial de contactos previos',
    color: const Color(0xFF713080),
    nested: true,
    initiallyExpanded: true,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFE3B3FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: FutureBuilder<List<ProspectHistoryComment>>(
        future: _comments,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.authPanelTop),
            );
          }
          if (snapshot.hasError) {
            return Column(
              children: [
                Text(
                  snapshot.error is ProspectsException
                      ? (snapshot.error as ProspectsException).message
                      : 'No se pudo cargar el historial.',
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _comments = _load();
                  }),
                  child: const Text('Reintentar'),
                ),
              ],
            );
          }
          final comments = snapshot.data ?? [];
          if (comments.isEmpty) {
            return const Text(
              'Sin comentarios registrados.',
              style: TextStyle(color: Colors.black, fontFamily: 'SulphurPoint'),
            );
          }
          return Column(
            children: [
              for (final comment in comments)
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: ProspectHistoryCommentCard(comment: comment),
                ),
            ],
          );
        },
      ),
    ),
  );
}
