import 'dart:convert';

import 'package:callerapp_frontend/services/prospects_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_detail_widgets.dart';

class ProspectDiscoveryForm extends StatefulWidget {
  final ValueChanged<String> onSaved;
  final int? prospectId;
  final ProspectsService? prospectsService;

  const ProspectDiscoveryForm({
    super.key,
    required this.onSaved,
    this.prospectId,
    this.prospectsService,
  });

  @override
  State<ProspectDiscoveryForm> createState() => _ProspectDiscoveryFormState();
}

class _ProspectDiscoveryFormState extends State<ProspectDiscoveryForm> {
  String? _property;
  final Set<String> _locations = {};
  String? _purpose;
  String? _payment;
  String? _investmentTime;
  final Set<String> _keyFactors = {};
  String _previousExperience = 'Positivo';
  String _lot = 'Seleccione un lote';
  String _decisionMaker = 'Pareja';
  String _rating = 'Seleccione';
  String _closer = 'Seleccione';
  bool _knowsArea = false;
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
  late final ProspectsService _service;
  Map<String, Object?>? _saved;
  bool _showNeedErrors = false;
  bool _showPaymentErrors = false;
  bool _showMotivatorErrors = false;
  bool _loading = false;
  String? _savingSection;
  String? _serviceError;

  static const _locationOptions = ['Quintana Roo', 'Yucatán'];
  static const _keyFactorOptions = [
    'Plusvalía',
    'Precio',
    'Seguridad',
    'Ubicación',
    'Amenidades',
    'Cercanía al mar',
    'Exclusividad',
    'Cuidado del medio ambiente',
    'Certeza jurídica',
    'Retorno de inversión',
    'Otro',
  ];
  static const _propertyCodes = {
    'Departamento': 'departamento',
    'Casa': 'casa',
    'Terreno': 'terreno',
    'Local comercial': 'local_comercial',
    'Solo inversión': 'inversion',
  };
  static const _paymentCodes = {
    'Contado': 'contado',
    'Crédito con la empresa': 'credito_empresa',
    'Crédito bancario': 'credito_bancario',
  };
  static const _investmentCodes = {
    'Inmediato': 'inmediato',
    '6 meses': 'meses',
    '2 años': 'anos',
    '2 años en adelante': 'anos',
  };
  static const _factorCodes = {
    'Plusvalía': 'plusvalia',
    'Precio': 'precio',
    'Seguridad': 'seguridad',
    'Ubicación': 'ubicacion',
    'Amenidades': 'amenidades',
    'Cercanía al mar': 'cercania_mar',
    'Exclusividad': 'exclusividad',
    'Cuidado del medio ambiente': 'medio_ambiente',
    'Certeza jurídica': 'certeza_juridica',
    'Retorno de inversión': 'retorno_inversion',
    'Otro': 'otro',
  };

  @override
  void initState() {
    super.initState();
    _service = widget.prospectsService ?? ProspectsService();
    if (widget.prospectId != null) _loadDiscovery();
  }

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
    if (widget.prospectsService == null) _service.dispose();
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
    String? value,
    List<String> values,
    ValueChanged<String> change, {
    String? errorText,
  }) => _label(
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
      decoration: _decoration().copyWith(errorText: errorText),
      hint: const Text(
        'Seleccione una opción',
        style: TextStyle(color: Colors.white70),
      ),
      items: values
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: (item) => setState(() => change(item!)),
    ),
  );

  Widget _multiSelectChips(
    String label,
    List<String> options,
    Set<String> selected, {
    String? errorText,
  }) => _label(
    label,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.start,
            spacing: 7,
            runSpacing: 7,
            children: options.map((option) {
              final isSelected = selected.contains(option);
              return FilterChip(
                label: Text(option),
                selected: isSelected,
                showCheckmark: true,
                checkmarkColor: Colors.white,
                selectedColor: const Color(0xFF287965),
                backgroundColor: const Color(0xFF38A58B),
                side: BorderSide.none,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                labelStyle: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'SulphurPoint',
                ),
                onSelected: _savingSection != null
                    ? null
                    : (value) => setState(() {
                        value ? selected.add(option) : selected.remove(option);
                        if (option == 'Otro' && !value) _otherFactor.clear();
                      }),
              );
            }).toList(),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 5),
          Text(
            errorText,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
        ],
      ],
    ),
  );

  Widget _text(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? prefixText,
    String? errorText,
  }) => _label(
    label,
    TextField(
      controller: controller,
      minLines: 1,
      maxLines: 3,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white),
      decoration: _decoration().copyWith(
        prefixText: prefixText,
        prefixStyle: const TextStyle(color: Colors.white),
        errorText: errorText,
      ),
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

  Widget _buttons(
    String section,
    VoidCallback cancel,
    VoidCallback save,
  ) => Row(
    children: [
      Expanded(
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFB5484D),
          ),
          onPressed: _savingSection == null ? cancel : null,
          child: const Text('CANCELAR'),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF4CA382),
          ),
          onPressed: _savingSection == null ? save : null,
          child: _savingSection == section
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('GUARDAR'),
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
    _property = _saved?['property'] as String?;
    _locations
      ..clear()
      ..addAll((_saved?['locations'] as List<String>?) ?? const []);
    _purpose = _saved?['purpose'] as String?;
    _knowsArea = (_saved?['knowsArea'] as bool?) ?? false;
    _areaNotes.text = (_saved?['areaNotes'] as String?) ?? '';
    _showNeedErrors = false;
  });

  List<String> _listValue(Object? value) {
    final decoded = value is String
        ? () {
            try {
              return jsonDecode(value);
            } on FormatException {
              return <Object?>[value];
            }
          }()
        : value;
    return decoded is List
        ? decoded.whereType<String>().toList(growable: false)
        : const [];
  }

  String? _labelForCode(Map<String, String> codes, Object? value) {
    for (final entry in codes.entries) {
      if (entry.value == value) return entry.key;
    }
    return null;
  }

  Future<void> _loadDiscovery() async {
    setState(() {
      _loading = true;
      _serviceError = null;
    });
    try {
      final data = await _service.discovery(widget.prospectId!);
      if (!mounted || data == null) return;
      setState(() {
        _property = _labelForCode(_propertyCodes, data['tipo_propiedad']);
        _locations
          ..clear()
          ..addAll(_listValue(data['ubicacion']));
        _purpose = data['motivo_propiedad'] as String?;
        _knowsArea = data['conoce_zona'] == true || data['conoce_zona'] == 1;
        _areaNotes.text = data['notas_zona'] as String? ?? '';
        _budget.text = data['presupuesto']?.toString() ?? '';
        _payment = _labelForCode(_paymentCodes, data['forma_pago']);
        _investmentTime = _labelForCode(
          _investmentCodes,
          data['tiempo_inversion'],
        );
        _keyFactors
          ..clear()
          ..addAll(
            _listValue(data['motivo_compra'])
                .map((value) => _labelForCode(_factorCodes, value))
                .whereType<String>(),
          );
        _otherFactor.text = data['otro_motivo_compra'] as String? ?? '';
        _saved = {
          'property': _property,
          'locations': _locations.toList(),
          'purpose': _purpose,
          'knowsArea': _knowsArea,
          'areaNotes': _areaNotes.text,
          'budget': _budget.text,
          'payment': _payment,
          'investmentTime': _investmentTime,
          'keyFactors': _keyFactors.toList(),
          'otherFactor': _otherFactor.text,
        };
      });
    } on ProspectsException catch (error) {
      if (mounted) setState(() => _serviceError = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _persist(String section, Map<String, dynamic> fields) async {
    if (widget.prospectId == null) return true;
    setState(() {
      _savingSection = section;
      _serviceError = null;
    });
    try {
      await _service.saveDiscoverySection(widget.prospectId!, {
        'seccion': section,
        ...fields,
      });
      return true;
    } on ProspectsException catch (error) {
      if (mounted) setState(() => _serviceError = error.message);
      return false;
    } finally {
      if (mounted) setState(() => _savingSection = null);
    }
  }

  double? get _budgetValue => double.tryParse(_budget.text.trim());

  Future<void> _saveNeed() async {
    setState(() => _showNeedErrors = true);
    if (_property == null || _locations.isEmpty || _purpose == null) return;
    final saved = await _persist('necesidad_objetivo', {
      'tipo_propiedad': _propertyCodes[_property],
      'ubicacion': _locations.toList(),
      'motivo_propiedad': _purpose,
      'conoce_zona': _knowsArea,
      'notas_zona': _knowsArea ? _areaNotes.text.trim() : null,
    });
    if (!saved || !mounted) return;
    _saved = {
      ...?_saved,
      'property': _property,
      'locations': _locations.toList(),
      'purpose': _purpose,
      'knowsArea': _knowsArea,
      'areaNotes': _knowsArea ? _areaNotes.text.trim() : '',
    };
    _notify('Necesidad y objetivo');
  }

  Future<void> _savePayment() async {
    setState(() => _showPaymentErrors = true);
    if (_budgetValue == null || _budgetValue! <= 0 || _payment == null) return;
    final saved = await _persist('capacidad_pago', {
      'presupuesto': _budgetValue,
      'forma_pago': _paymentCodes[_payment],
      'tiempo_inversion': _investmentCodes[_investmentTime],
    });
    if (!saved || !mounted) return;
    _saved = {
      ...?_saved,
      'budget': _budget.text,
      'payment': _payment,
      'investmentTime': _investmentTime,
    };
    _notify('Capacidad y forma de pago');
  }

  Future<void> _saveMotivators() async {
    setState(() => _showMotivatorErrors = true);
    if (_keyFactors.isEmpty ||
        (_keyFactors.contains('Otro') && _otherFactor.text.trim().isEmpty)) {
      return;
    }
    final saved = await _persist('motivadores_compra', {
      'motivo_compra': _keyFactors
          .map((factor) => _factorCodes[factor])
          .whereType<String>()
          .toList(),
      'otro_motivo_compra': _keyFactors.contains('Otro')
          ? _otherFactor.text.trim()
          : null,
    });
    if (!saved || !mounted) return;
    _saved = {
      ...?_saved,
      'keyFactors': _keyFactors.toList(),
      'otherFactor': _keyFactors.contains('Otro')
          ? _otherFactor.text.trim()
          : '',
    };
    _notify('Motivadores de compra');
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (_loading) const LinearProgressIndicator(),
      if (_serviceError != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            _serviceError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
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
              _select(
                '¿Qué tipo de propiedad busca? *',
                _property,
                [
                  'Departamento',
                  'Casa',
                  'Terreno',
                  'Local comercial',
                  'Solo inversión',
                ],
                (value) => _property = value,
                errorText: _showNeedErrors && _property == null
                    ? 'Seleccione un tipo de propiedad.'
                    : null,
              ),
              _multiSelectChips(
                '¿Ubicación preferida? *',
                _locationOptions,
                _locations,
                errorText: _showNeedErrors && _locations.isEmpty
                    ? 'Seleccione al menos una ubicación.'
                    : null,
              ),
              _select(
                '¿Para qué fin? *',
                _purpose,
                [
                  'Vivienda',
                  'Inversión',
                  'Segunda residencia',
                  'Retiro',
                  'Negocio',
                  'Renta vacacional',
                  'Solo para madurar su dinero y revender',
                ],
                (value) => _purpose = value,
                errorText: _showNeedErrors && _purpose == null
                    ? 'Seleccione el objetivo de compra.'
                    : null,
              ),
              _toggle(
                '¿Usted conoce la zona?',
                _knowsArea,
                (value) => setState(() => _knowsArea = value),
              ),
              if (_knowsArea) _text('¿Qué conoce de la zona?', _areaNotes),
              _buttons('necesidad_objetivo', _restoreNeed, _saveNeed),
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
              _text(
                '¿Cuál es su presupuesto? *',
                _budget,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                prefixText: r'$ ',
                errorText:
                    _showPaymentErrors &&
                        (_budgetValue == null || _budgetValue! <= 0)
                    ? 'Ingrese un presupuesto mayor a cero.'
                    : null,
              ),
              _select(
                '¿Forma de pago preferida? *',
                _payment,
                ['Contado', 'Crédito con la empresa', 'Crédito bancario'],
                (value) => _payment = value,
                errorText: _showPaymentErrors && _payment == null
                    ? 'Seleccione una forma de pago.'
                    : null,
              ),
              _select(
                '¿Tiempo estimado para utilizar su inversión?',
                _investmentTime,
                ['Inmediato', '6 meses', '2 años', '2 años en adelante'],
                (value) => _investmentTime = value,
              ),
              _buttons(
                'capacidad_pago',
                () => setState(() {
                  _budget.text = (_saved?['budget'] as String?) ?? '';
                  _payment = _saved?['payment'] as String?;
                  _investmentTime = _saved?['investmentTime'] as String?;
                  _showPaymentErrors = false;
                }),
                _savePayment,
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
              _multiSelectChips(
                'Selección múltiple *',
                _keyFactorOptions,
                _keyFactors,
                errorText: _showMotivatorErrors && _keyFactors.isEmpty
                    ? 'Seleccione al menos un factor.'
                    : null,
              ),
              if (_keyFactors.contains('Otro'))
                _text(
                  'Otro factor *',
                  _otherFactor,
                  errorText:
                      _showMotivatorErrors && _otherFactor.text.trim().isEmpty
                      ? 'Especifique el otro factor.'
                      : null,
                ),
              _buttons(
                'motivadores_compra',
                () => setState(() {
                  _keyFactors
                    ..clear()
                    ..addAll(
                      (_saved?['keyFactors'] as List<String>?) ?? const [],
                    );
                  _otherFactor.text = (_saved?['otherFactor'] as String?) ?? '';
                  _showMotivatorErrors = false;
                }),
                _saveMotivators,
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
                'experiencia_previa',
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
                'proceso_seguimiento',
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
                'resultado_discovery',
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
