import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/models/guion_models.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_detail_widgets.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/script_step_view.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:callerapp_frontend/resources/styles/app_palette.dart';

class ScriptAccordion extends StatefulWidget {
  const ScriptAccordion({
    super.key,
    required this.guion,
    required this.index,
    required this.prospectName,
    required this.asesorName,
    this.desarrolloName,
  });
  final Guion guion;
  final int index;
  final String prospectName;
  final String asesorName;
  final String? desarrolloName;
  @override
  State<ScriptAccordion> createState() => _ScriptAccordionState();
}

class _ScriptAccordionState extends State<ScriptAccordion> {
  final List<int> _history = [];
  int? _currentId;
  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void didUpdateWidget(covariant ScriptAccordion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.guion.id != widget.guion.id ||
        oldWidget.guion.pasos != widget.guion.pasos) {
      _restart(notify: false);
    }
  }

  void _restart({bool notify = true}) {
    void action() {
      _history.clear();
      _currentId = widget.guion.pasoInicial?.id;
    }
    if (notify && mounted) {
      setState(action);
    } else {
      action();
    }
  }

  void _push(int id) => setState(() {
    if (_currentId != null) {
      _history.add(_currentId!);
    }
    _currentId = id;
  });
  void _back() => setState(() => _currentId = _history.removeLast());
  @override
  Widget build(BuildContext context) {
    final paso = _currentId == null
        ? null
        : widget.guion.pasoPorId(_currentId!);
    return ProspectDetailPanel(
      title: widget.guion.titulo,
      color: AppColors.scriptPanel,
      nested: true,
      initiallyExpanded: widget.index == 0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          color: AppPalette.of(context).scriptSurfaceFill,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.guion.subtitulo case final subtitle?) ...[
              Text(
                subtitle,
                style: TextStyle(
                  color: AppPalette.of(context).scriptSurfaceInk,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (paso == null)
              Center(
                child: Column(
                  children: [
                    const Text('No se encontró el paso del guion.'),
                    TextButton(
                      onPressed: _restart,
                      child: const Text('Volver al inicio'),
                    ),
                  ],
                ),
              )
            else
              ScriptStepView(
                paso: paso,
                canGoBack: _history.isNotEmpty,
                onBack: _back,
                onNavigate: _push,
                onRestart: _restart,
                prospectName: widget.prospectName,
                asesorName: widget.asesorName,
                desarrolloName: widget.desarrolloName,
              ),
          ],
        ),
      ),
    );
  }
}
