import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_detail_widgets.dart';

class ProspectDiscoveryForm extends StatefulWidget {
  final ValueChanged<String> onSaved;

  const ProspectDiscoveryForm({super.key, required this.onSaved});

  @override
  State<ProspectDiscoveryForm> createState() => _ProspectDiscoveryFormState();
}

class _ProspectDiscoveryFormState extends State<ProspectDiscoveryForm> {
  String _property = 'Departamento';
  String _location = 'Quintana Roo';
  String _purpose = 'Vivienda';
  String _payment = 'Contado';
  String _investmentTime = '6 meses';
  String _keyFactor = 'Plusvalía';
  String _previousExperience = 'Positivo';
  String _lot = 'Seleccione un lote';
  String _decisionMaker = 'Pareja';
  String _rating = 'Seleccione';
  String _closer = 'Seleccione';
  bool _knowsArea = true;
  bool _boughtBefore = true;
  bool _acceptsPromotions = true;
  bool _sendToCloser = true;

  final _areaNotes = TextEditingController();
  final _budget = TextEditingController();
  final _otherFactor = TextEditingController();
  final _whereBought = TextEditingController();
  final _experienceReason = TextEditingController();
  final _lotSize = TextEditingController();
  final _webPrice = TextEditingController();
  final _additionalNotes = TextEditingController();
  Map<String, Object?>? _saved;

  @override
  void dispose() {
    _areaNotes.dispose();
    _budget.dispose();
    _otherFactor.dispose();
    _whereBought.dispose();
    _experienceReason.dispose();
    _lotSize.dispose();
    _webPrice.dispose();
    _additionalNotes.dispose();
    super.dispose();
  }

  InputDecoration _decoration() => InputDecoration(
    filled: true,
    fillColor: const Color(0xFF38A58B),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
  );

  Widget _label(String text, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 3),
        child,
      ],
    ),
  );

  Widget _select(
    String label,
    String value,
    List<String> values,
    ValueChanged<String> change,
  ) => _label(
    label,
    DropdownButtonFormField<String>(
      key: ValueKey('$label-$value'),
      initialValue: value,
      isExpanded: true,
      dropdownColor: const Color(0xFF38A58B),
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
      style: const TextStyle(
        color: Colors.white,
        fontFamily: 'SulphurPoint',
        fontSize: 16,
      ),
      decoration: _decoration(),
      items: values
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: (item) => setState(() => change(item!)),
    ),
  );

  Widget _text(String label, TextEditingController controller) => _label(
    label,
    TextField(
      controller: controller,
      minLines: 1,
      maxLines: 3,
      style: const TextStyle(color: Colors.white),
      decoration: _decoration(),
    ),
  );

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
            Semantics(
              toggled: value,
              label: label,
              child: InkWell(
                onTap: () => onChanged(!value),
                borderRadius: BorderRadius.circular(7),
                child: Container(
                  width: 62,
                  height: 28,
                  alignment: value
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: value
                        ? const Color(0xFF4CA382)
                        : const Color(0xFFB5484D),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Container(
                    width: 27,
                    decoration: BoxDecoration(
                      color: value
                          ? const Color(0xFFA8F7D3)
                          : const Color(0xFFFFB1B1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(value ? Icons.check : Icons.close, size: 17),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buttons(VoidCallback cancel, VoidCallback save) => Row(
    children: [
      Expanded(
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFB5484D),
          ),
          onPressed: cancel,
          child: const Text('CANCELAR'),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF4CA382),
          ),
          onPressed: save,
          child: const Text('GUARDAR'),
        ),
      ),
    ],
  );

  void _notify(String section) {
    widget.onSaved('Discovery · $section');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$section guardado en esta vista.')));
  }

  void _restoreNeed() => setState(() {
    _property = (_saved?['property'] as String?) ?? 'Departamento';
    _location = (_saved?['location'] as String?) ?? 'Quintana Roo';
    _purpose = (_saved?['purpose'] as String?) ?? 'Vivienda';
    _knowsArea = (_saved?['knowsArea'] as bool?) ?? true;
    _areaNotes.text = (_saved?['areaNotes'] as String?) ?? '';
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ProspectDetailPanel(
        title: 'Necesidad y objetivo',
        color: const Color(0xFF438E72),
        nested: true,
        initiallyExpanded: true,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFADFAC4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              _select('¿Qué tipo de propiedad busca?', _property, [
                'Departamento',
                'Casa',
                'Terreno',
                'Local comercial',
                'Solo inversión',
              ], (value) => _property = value),
              _select('¿Ubicación preferida?', _location, [
                'Quintana Roo',
                'Yucatán',
              ], (value) => _location = value),
              _select('¿Para qué fin?', _purpose, [
                'Vivienda',
                'Inversión',
                'Segunda residencia',
                'Retiro',
                'Negocio',
                'Negocio',
                'Renta vacacional',
                'Solo para madurar su dinero y revender',
              ], (value) => _purpose = value),
              _toggle(
                '¿Usted conoce la zona?',
                _knowsArea,
                (value) => setState(() => _knowsArea = value),
              ),
              _text('¿Qué conoce de la zona?', _areaNotes),
              _buttons(_restoreNeed, () {
                _saved = {
                  ...?_saved,
                  'property': _property,
                  'location': _location,
                  'purpose': _purpose,
                  'knowsArea': _knowsArea,
                  'areaNotes': _areaNotes.text,
                };
                _notify('Necesidad y objetivo');
              }),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      ProspectDetailPanel(
        title: 'Capacidad y forma de pago',
        color: const Color(0xFF438E72),
        nested: true,
        initiallyExpanded: true,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFADFAC4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              _text('¿Cuál es su presupuesto?', _budget),
              _select('¿Forma de pago preferida?', _payment, [
                'Contado',
                'Crédito con la empresa',
                'Crédito bancario',
              ], (value) => _payment = value),
              _select(
                '¿Tiempo estimado para utilizar su inversión?',
                _investmentTime,
                ['Inmediato', '6 meses', '2 años', '2 años en adelante'],
                (value) => _investmentTime = value,
              ),
              _buttons(
                () => setState(() {
                  _budget.text = (_saved?['budget'] as String?) ?? '';
                  _payment = (_saved?['payment'] as String?) ?? 'Contado';
                  _investmentTime =
                      (_saved?['investmentTime'] as String?) ?? '6 meses';
                }),
                () {
                  _saved = {
                    ...?_saved,
                    'budget': _budget.text,
                    'payment': _payment,
                    'investmentTime': _investmentTime,
                  };
                  _notify('Capacidad y forma de pago');
                },
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      ProspectDetailPanel(
        title: 'Motivadores de compra',
        color: const Color(0xFF438E72),
        nested: true,
        initiallyExpanded: true,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFADFAC4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              _select('Factores clave', _keyFactor, [
                'Plusvalía',
                'Ubicación',
                'Seguridad',
                'Amenidades',
                'Cercanía al mar',
                'Exclusividad',
                'Cuidado del medio ambiente',
                'Certeza jurídica',
                'Retorno de inversión',
              ], (value) => _keyFactor = value),
              _text('Otro factor', _otherFactor),
              _buttons(
                () => setState(() {
                  _keyFactor = (_saved?['keyFactor'] as String?) ?? 'Plusvalía';
                  _otherFactor.text = (_saved?['otherFactor'] as String?) ?? '';
                }),
                () {
                  _saved = {
                    ...?_saved,
                    'keyFactor': _keyFactor,
                    'otherFactor': _otherFactor.text,
                  };
                  _notify('Motivadores de compra');
                },
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      ProspectDetailPanel(
        title: 'Experiencia previa',
        color: const Color(0xFF438E72),
        nested: true,
        initiallyExpanded: true,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFADFAC4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              _toggle(
                '¿Ha comprado inmuebles antes?',
                _boughtBefore,
                (value) => setState(() => _boughtBefore = value),
              ),
              _text('¿Dónde?', _whereBought),
              _select('¿Qué experiencia tuvo?', _previousExperience, [
                'Positivo',
                'Negativo',
              ], (value) => _previousExperience = value),
              _text('¿Por qué?', _experienceReason),
              _buttons(
                () => setState(() {
                  _boughtBefore = (_saved?['boughtBefore'] as bool?) ?? true;
                  _whereBought.text = (_saved?['whereBought'] as String?) ?? '';
                  _previousExperience =
                      (_saved?['previousExperience'] as String?) ?? 'Positivo';
                  _experienceReason.text =
                      (_saved?['experienceReason'] as String?) ?? '';
                }),
                () {
                  _saved = {
                    ...?_saved,
                    'boughtBefore': _boughtBefore,
                    'whereBought': _whereBought.text,
                    'previousExperience': _previousExperience,
                    'experienceReason': _experienceReason.text,
                  };
                  _notify('Experiencia previa');
                },
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      ProspectDetailPanel(
        title: 'Proceso y seguimiento',
        color: const Color(0xFF438E72),
        nested: true,
        initiallyExpanded: true,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFADFAC4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              _toggle(
                '¿Acepta promociones?',
                _acceptsPromotions,
                (value) => setState(() => _acceptsPromotions = value),
              ),
              _select('¿Lote seleccionado?', _lot, [
                'Seleccione un lote',
                'Lote 12',
                'Lote 23',
                'Lote 38',
              ], (value) => _lot = value),
              _text('M² (Tamaño)', _lotSize),
              _text('Precio web', _webPrice),
              _select('¿Quién más interviene en la decisión?', _decisionMaker, [
                'Pareja',
                'Socios',
                'Padres',
                'Hijos',
              ], (value) => _decisionMaker = value),
              _text('Notas adicionales', _additionalNotes),
              _buttons(
                () => setState(() {
                  _acceptsPromotions =
                      (_saved?['acceptsPromotions'] as bool?) ?? true;
                  _lot = (_saved?['lot'] as String?) ?? 'Seleccione un lote';
                  _lotSize.text = (_saved?['lotSize'] as String?) ?? '';
                  _webPrice.text = (_saved?['webPrice'] as String?) ?? '';
                  _decisionMaker =
                      (_saved?['decisionMaker'] as String?) ?? 'Pareja';
                  _additionalNotes.text =
                      (_saved?['additionalNotes'] as String?) ?? '';
                }),
                () {
                  _saved = {
                    ...?_saved,
                    'acceptsPromotions': _acceptsPromotions,
                    'lot': _lot,
                    'lotSize': _lotSize.text,
                    'webPrice': _webPrice.text,
                    'decisionMaker': _decisionMaker,
                    'additionalNotes': _additionalNotes.text,
                  };
                  _notify('Proceso y seguimiento');
                },
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      ProspectDetailPanel(
        title: 'Resultado del Discovery',
        color: const Color(0xFF438E72),
        nested: true,
        initiallyExpanded: true,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFADFAC4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              _select('Calificación del Prospecto', _rating, [
                'Seleccione',
                'Prospecto calificado',
                'Prospecto en seguimiento',
                'Prospecto descartado',
              ], (value) => _rating = value),
              _toggle(
                '¿Enviar a cerrador?',
                _sendToCloser,
                (value) => setState(() => _sendToCloser = value),
              ),
              _select('Nombre del cerrador', _closer, [
                'Seleccione',
                'Leonardo Pérez',
                'Ana Gómez',
                'Carlos Díaz',
              ], (value) => _closer = value),
              _buttons(
                () => setState(() {
                  _sendToCloser = (_saved?['sendToCloser'] as bool?) ?? true;
                  _rating = (_saved?['rating'] as String?) ?? 'Seleccione';
                  _closer = (_saved?['closer'] as String?) ?? 'Seleccione';
                }),
                () {
                  _saved = {
                    ...?_saved,
                    'sendToCloser': _sendToCloser,
                    'rating': _rating,
                    'closer': _closer,
                  };
                  _notify('Resultado del Discovery');
                },
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
