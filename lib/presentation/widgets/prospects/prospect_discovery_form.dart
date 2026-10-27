import 'dart:convert';

import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:callerapp_frontend/services/prospects_service.dart';
import 'package:callerapp_frontend/repositories/prospects_repository.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_detail_widgets.dart';
import 'package:callerapp_frontend/resources/styles/app_palette.dart';

class ProspectDiscoveryForm extends StatefulWidget {
  final ValueChanged<String> onSaved;
  final int? prospectId;
  final ProspectRecord? prospect;
  final ProspectsService? prospectsService;
  final ProspectsRepository? repository;
  final bool readOnly;

  const ProspectDiscoveryForm({
    super.key,
    required this.onSaved,
    this.prospectId,
    this.prospect,
    this.prospectsService,
    this.repository,
    this.readOnly = false,
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
  String? _previousExperience;
  final Set<String> _decisionMakers = {};
  int? _selectedLotId;
  int? _selectedDevelopmentId;
  int? _selectedCloserId;
  bool _knowsArea = false;
  bool _boughtBefore = false;
  bool _acceptsPromotions = true;
  bool _hasSpecificLot = false;
  bool _sendToCloser = false;

  final _areaNotes = TextEditingController();
  final _budget = TextEditingController();
  final _otherFactor = TextEditingController();
  final _whereBought = TextEditingController();
  final _experienceReason = TextEditingController();
  final _participantsOther = TextEditingController();
  final _additionalNotes = TextEditingController();
  late final ProspectsService _service;
  late final ProspectsRepository _repository;
  List<Map<String, dynamic>> _lots = const [];
  List<Map<String, dynamic>> _developments = const [];
  List<Map<String, dynamic>> _closers = const [];
  Map<String, Object?>? _saved;
  bool _showNeedErrors = false;
  bool _showPaymentErrors = false;
  bool _showMotivatorErrors = false;
  bool _showExperienceErrors = false;
  bool _showProcessErrors = false;
  bool _loading = false;
  bool _lotsLoading = false;
  bool _developmentsLoading = false;
  bool _closersLoading = false;
  bool _showCloserError = false;
  String? _savingSection;
  String? _serviceError;
  String? _lotsError;

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
  static const _experienceOptions = [
    'Muy buena',
    'Buena',
    'Regular',
    'Mala',
    'Muy mala',
  ];
  static const _experienceCodes = {
    'Muy buena': 'muy_buena',
    'Buena': 'buena',
    'Regular': 'regular',
    'Mala': 'mala',
    'Muy mala': 'muy_mala',
  };
  static const _participantOptions = [
    'Pareja',
    'Padres',
    'Socio',
    'Familia',
    'Asesor',
    'Solo decide él/ella',
    'Otro',
  ];
  static const _participantCodes = {
    'Pareja': 'pareja',
    'Padres': 'padres',
    'Socio': 'socio',
    'Familia': 'familia',
    'Asesor': 'asesor',
    'Solo decide él/ella': 'solo',
    'Otro': 'otro',
  };

  @override
  void initState() {
    super.initState();
    _service = widget.prospectsService ?? ProspectsService();
    _repository = widget.repository ?? ProspectsRepository(service: _service);
    if (widget.prospectId != null) {
      _loadDiscovery();
      _loadDevelopments();
      _loadClosers();
    }
  }

  @override
  void dispose() {
    _areaNotes.dispose();
    _budget.dispose();
    _otherFactor.dispose();
    _whereBought.dispose();
    _experienceReason.dispose();
    _participantsOther.dispose();
    _additionalNotes.dispose();
    if (widget.prospectsService == null) _service.dispose();
    if (widget.repository == null) _repository.dispose();
    super.dispose();
  }

  InputDecoration _decoration() => InputDecoration(
    filled: true,
    fillColor: AppColors.discoveryField,
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
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: AppPalette.of(context).textColor,
          ),
        ),
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
      dropdownColor: AppColors.discoveryField,
      icon: const Icon(
        Icons.keyboard_arrow_down,
        color: AppColors.discoveryFieldText,
      ),
      style: const TextStyle(
        color: AppColors.discoveryFieldText,
        fontFamily: 'SulphurPoint',
        fontSize: 16,
      ),
      decoration: _decoration().copyWith(errorText: errorText),
      hint: const Text(
        'Seleccione una opción',
        style: TextStyle(color: AppColors.discoveryFieldHint),
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
                checkmarkColor: AppColors.discoveryFieldText,
                selectedColor: AppColors.discoveryFieldSelected,
                backgroundColor: AppColors.discoveryField,
                side: BorderSide.none,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                labelStyle: const TextStyle(
                  color: AppColors.discoveryFieldText,
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
      style: const TextStyle(color: AppColors.discoveryFieldText),
      decoration: _decoration().copyWith(
        prefixText: prefixText,
        prefixStyle: const TextStyle(color: AppColors.discoveryFieldText),
        errorText: errorText,
      ),
    ),
  );

  Widget _readOnlyRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.discoveryFieldText,
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.discoveryFieldText,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: AppPalette.of(context).textColor,
                ),
              ),
            ),
            Semantics(
              toggled: value,
              label: label,
              child: InkWell(
                onTap: _savingSection == null ? () => onChanged(!value) : null,
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
                        ? AppColors.discoverySave
                        : AppColors.discoveryCancel,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Container(
                    width: 27,
                    decoration: BoxDecoration(
                      color: value
                          ? AppColors.discoveryToggleOnThumb
                          : AppColors.discoveryToggleOffThumb,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      value ? Icons.check : Icons.close,
                      size: 17,
                      color: AppColors.textDarkColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buttons(String section, VoidCallback cancel, VoidCallback save) =>
      widget.readOnly
      ? const SizedBox.shrink()
      : Row(
          children: [
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.discoveryCancel,
                  foregroundColor: Colors.white,
                ),
                onPressed: _savingSection == null ? cancel : null,
                child: const Text('CANCELAR'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.discoverySave,
                  foregroundColor: Colors.white,
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
    // Compatibilidad con registros previos que guardaron la etiqueta visible.
    final text = value?.toString().trim().toLowerCase();
    if (text == null || text.isEmpty) return null;
    for (final entry in codes.entries) {
      if (entry.key.toLowerCase() == text) return entry.key;
    }
    return null;
  }

  Future<void> _loadDevelopments() async {
    setState(() => _developmentsLoading = true);
    try {
      final developments = await _service.availableDevelopments();
      if (!mounted) return;
      setState(() {
        _developments = developments;
        if (_selectedDevelopmentId == null && developments.length == 1) {
          _selectedDevelopmentId = developments.single['id'] as int;
        } else if (_selectedDevelopmentId != null &&
            !developments.any((item) => item['id'] == _selectedDevelopmentId)) {
          _selectedDevelopmentId = null;
          _selectedLotId = null;
        }
      });
      if (_selectedDevelopmentId != null) await _loadLots();
    } on ProspectsException catch (error) {
      if (mounted) setState(() => _serviceError = error.message);
    } finally {
      if (mounted) setState(() => _developmentsLoading = false);
    }
  }

  Future<void> _loadLots() async {
    final developmentId = _selectedDevelopmentId;
    if (developmentId == null) {
      setState(() => _lots = const []);
      return;
    }
    setState(() {
      _lotsLoading = true;
      _lotsError = null;
    });
    try {
      final lots = await _service.availableLots(developmentId);
      if (mounted) setState(() => _lots = lots);
    } on ProspectsException catch (error) {
      if (mounted) setState(() => _lotsError = error.message);
    } finally {
      if (mounted) setState(() => _lotsLoading = false);
    }
  }

  Future<void> _loadClosers() async {
    setState(() => _closersLoading = true);
    try {
      final closers = await _service.availableClosers();
      if (mounted) setState(() => _closers = closers);
    } on ProspectsException catch (error) {
      if (mounted) setState(() => _serviceError = error.message);
    } finally {
      if (mounted) setState(() => _closersLoading = false);
    }
  }

  Map<String, dynamic>? get _selectedLot {
    for (final lot in _lots) {
      if (lot['id'] == _selectedLotId) return lot;
    }
    return null;
  }

  String _lotLabel(Map<String, dynamic> lot) =>
      'Lote ${lot['numero_lote'] ?? lot['id']}';

  String _money(Object? value) {
    final amount = double.tryParse('$value');
    if (amount == null) return 'No disponible';
    final fixed = amount.toStringAsFixed(2);
    final parts = fixed.split('.');
    final digits = parts.first;
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
      buffer.write(digits[index]);
    }
    return '\$ $buffer.${parts.last}';
  }

  String _dimensions(Object? value) {
    final size = double.tryParse('$value');
    if (size == null) return 'No disponible';
    final text = size == size.roundToDouble()
        ? size.toStringAsFixed(0)
        : size.toStringAsFixed(2);
    return '$text m²';
  }

  Future<void> _loadDiscovery() async {
    setState(() {
      _loading = true;
      _serviceError = null;
    });
    try {
      final data = await _repository.loadDiscovery(widget.prospectId!);
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
        _boughtBefore =
            data['ha_comprado_inmuebles'] == true ||
            data['ha_comprado_inmuebles'] == 1;
        _whereBought.text = data['donde_comprado'] as String? ?? '';
        _previousExperience = _labelForCode(
          _experienceCodes,
          data['experiencia_previa'],
        );
        _experienceReason.text = data['detalles_experiencia'] as String? ?? '';
        _acceptsPromotions = data['acepta_promociones'] != false;
        final lotId = int.tryParse('${data['terreno_interes_id']}');
        _selectedLotId = lotId;
        _hasSpecificLot = lotId != null;
        _decisionMakers
          ..clear()
          ..addAll(
            _listValue(data['participantes_decision'])
                .map((value) => _labelForCode(_participantCodes, value))
                .whereType<String>(),
          );
        _participantsOther.text = data['participantes_otro'] as String? ?? '';
        _additionalNotes.text = data['notas_adicionales'] as String? ?? '';
        _selectedDevelopmentId = int.tryParse(
          '${data['desarrollo_interes_id']}',
        );
        _selectedCloserId = int.tryParse('${data['cerrador_id']}');
        _sendToCloser = _selectedCloserId != null;
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
          'boughtBefore': _boughtBefore,
          'whereBought': _whereBought.text,
          'previousExperience': _previousExperience,
          'experienceReason': _experienceReason.text,
          'acceptsPromotions': _acceptsPromotions,
          'hasSpecificLot': _hasSpecificLot,
          'selectedLotId': _selectedLotId,
          'selectedDevelopmentId': _selectedDevelopmentId,
          'decisionMakers': _decisionMakers.toList(),
          'participantsOther': _participantsOther.text,
          'additionalNotes': _additionalNotes.text,
          'selectedCloserId': _selectedCloserId,
          'sendToCloser': _sendToCloser,
        };
      });
      if (_selectedDevelopmentId != null) await _loadLots();
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
      final payload = <String, dynamic>{'seccion': section, ...fields};
      final prospect = widget.prospect;
      final result = prospect == null
          ? null
          : await _repository.saveDiscoverySection(prospect, payload);
      if (prospect == null) {
        await _service.saveDiscoverySection(widget.prospectId!, payload);
        await _repository.rememberDiscovery(widget.prospectId!, payload);
      }
      if (mounted && result?.isPending == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cambios guardados. Se sincronizarán cuando haya conexión.',
            ),
          ),
        );
      }
      return true;
    } on ProspectsException catch (error) {
      if (mounted) setState(() => _serviceError = error.message);
      return false;
    } finally {
      if (mounted) setState(() => _savingSection = null);
    }
  }

  double? get _budgetValue => double.tryParse(_budget.text.trim());

  Future<void> _saveCloserAssignment() async {
    setState(() => _showCloserError = true);
    if (_sendToCloser && _selectedCloserId == null) return;
    final saved = await _persist('asignacion_cerrador', {
      'cerrador_id': _sendToCloser ? _selectedCloserId : null,
    });
    if (!saved || !mounted) return;
    _saved = {
      ...?_saved,
      'sendToCloser': _sendToCloser,
      'selectedCloserId': _selectedCloserId,
    };
    setState(() => _showCloserError = false);
    _notify('Asignación a cerrador');
  }

  void _restoreCloserAssignment() => setState(() {
    _sendToCloser = (_saved?['sendToCloser'] as bool?) ?? false;
    _selectedCloserId = _saved?['selectedCloserId'] as int?;
    _showCloserError = false;
  });

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

  Future<void> _saveExperience() async {
    setState(() => _showExperienceErrors = true);
    if (_boughtBefore && _previousExperience == null) return;
    final saved = await _persist('experiencia_previa', {
      'ha_comprado_inmuebles': _boughtBefore,
      'donde_comprado': _boughtBefore ? _whereBought.text.trim() : null,
      'experiencia_previa': _boughtBefore
          ? _experienceCodes[_previousExperience]
          : null,
      'detalles_experiencia': _boughtBefore
          ? _experienceReason.text.trim()
          : null,
    });
    if (!saved || !mounted) return;
    _saved = {
      ...?_saved,
      'boughtBefore': _boughtBefore,
      'whereBought': _boughtBefore ? _whereBought.text.trim() : '',
      'previousExperience': _boughtBefore ? _previousExperience : null,
      'experienceReason': _boughtBefore ? _experienceReason.text.trim() : '',
    };
    _notify('Experiencia previa');
  }

  void _restoreExperience() => setState(() {
    _boughtBefore = (_saved?['boughtBefore'] as bool?) ?? false;
    _whereBought.text = (_saved?['whereBought'] as String?) ?? '';
    _previousExperience = _saved?['previousExperience'] as String?;
    _experienceReason.text = (_saved?['experienceReason'] as String?) ?? '';
    _showExperienceErrors = false;
  });

  Future<void> _saveProcess() async {
    setState(() => _showProcessErrors = true);
    final needsDevelopment = _selectedDevelopmentId == null;
    final needsLot = _hasSpecificLot && _selectedLot == null;
    final needsOther =
        _decisionMakers.contains('Otro') &&
        _participantsOther.text.trim().isEmpty;
    if (needsDevelopment || _decisionMakers.isEmpty || needsLot || needsOther) {
      return;
    }
    final saved = await _persist('proceso_seguimiento', {
      'acepta_promociones': _acceptsPromotions,
      'desarrollo_interes_id': _selectedDevelopmentId,
      'terreno_interes_id': _hasSpecificLot ? _selectedLotId : null,
      'participantes_decision': _decisionMakers
          .map((participant) => _participantCodes[participant])
          .whereType<String>()
          .toList(),
      'participantes_otro': _decisionMakers.contains('Otro')
          ? _participantsOther.text.trim()
          : null,
      'notas_adicionales': _additionalNotes.text.trim(),
    });
    if (!saved || !mounted) return;
    _saved = {
      ...?_saved,
      'acceptsPromotions': _acceptsPromotions,
      'hasSpecificLot': _hasSpecificLot,
      'selectedLotId': _hasSpecificLot ? _selectedLotId : null,
      'selectedDevelopmentId': _selectedDevelopmentId,
      'decisionMakers': _decisionMakers.toList(),
      'participantsOther': _decisionMakers.contains('Otro')
          ? _participantsOther.text.trim()
          : '',
      'additionalNotes': _additionalNotes.text.trim(),
    };
    _notify('Proceso y seguimiento');
  }

  void _restoreProcess() {
    setState(() {
      _acceptsPromotions = (_saved?['acceptsPromotions'] as bool?) ?? true;
      _selectedDevelopmentId = _saved?['selectedDevelopmentId'] as int?;
      _hasSpecificLot = (_saved?['hasSpecificLot'] as bool?) ?? false;
      _selectedLotId = _saved?['selectedLotId'] as int?;
      _decisionMakers
        ..clear()
        ..addAll((_saved?['decisionMakers'] as List<String>?) ?? const []);
      _participantsOther.text = (_saved?['participantsOther'] as String?) ?? '';
      _additionalNotes.text = (_saved?['additionalNotes'] as String?) ?? '';
      _showProcessErrors = false;
    });
    _loadLots();
  }

  @override
  Widget build(BuildContext context) => AbsorbPointer(
    absorbing: widget.readOnly,
    child: Column(
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
          color: AppColors.discoveryHeader,
          nested: true,
          initiallyExpanded: true,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppPalette.of(context).discoverySurfaceFill,
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
          color: AppColors.discoveryHeader,
          nested: true,
          initiallyExpanded: true,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppPalette.of(context).discoverySurfaceFill,
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
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
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
          color: AppColors.discoveryHeader,
          nested: true,
          initiallyExpanded: true,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppPalette.of(context).discoverySurfaceFill,
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
                    _otherFactor.text =
                        (_saved?['otherFactor'] as String?) ?? '';
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
          color: AppColors.discoveryHeader,
          nested: true,
          initiallyExpanded: true,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppPalette.of(context).discoverySurfaceFill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _toggle(
                  '¿Ha comprado inmuebles antes?',
                  _boughtBefore,
                  (value) => setState(() => _boughtBefore = value),
                ),
                if (_boughtBefore) ...[
                  _text('¿Dónde?', _whereBought),
                  _select(
                    '¿Qué experiencia tuvo? *',
                    _previousExperience,
                    _experienceOptions,
                    (value) => _previousExperience = value,
                    errorText:
                        _showExperienceErrors && _previousExperience == null
                        ? 'Seleccione la experiencia que tuvo.'
                        : null,
                  ),
                  if (_previousExperience != null)
                    _text('¿Por qué?', _experienceReason),
                ],
                _buttons(
                  'experiencia_previa',
                  _restoreExperience,
                  _saveExperience,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        ProspectDetailPanel(
          title: 'Proceso y seguimiento',
          color: AppColors.discoveryHeader,
          nested: true,
          initiallyExpanded: true,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppPalette.of(context).discoverySurfaceFill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _toggle(
                  '¿Acepta promociones?',
                  _acceptsPromotions,
                  (value) => setState(() => _acceptsPromotions = value),
                ),
                _label(
                  'Desarrollo de interés *',
                  DropdownButtonFormField<int>(
                    key: ValueKey(
                      'desarrollo-$_selectedDevelopmentId-${_developments.length}',
                    ),
                    initialValue:
                        _developments.any(
                          (development) =>
                              development['id'] == _selectedDevelopmentId,
                        )
                        ? _selectedDevelopmentId
                        : null,
                    isExpanded: true,
                    dropdownColor: AppColors.discoveryField,
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.discoveryFieldText,
                    ),
                    style: const TextStyle(
                      color: AppColors.discoveryFieldText,
                      fontFamily: 'SulphurPoint',
                      fontSize: 16,
                    ),
                    decoration: _decoration().copyWith(
                      errorText:
                          _showProcessErrors && _selectedDevelopmentId == null
                          ? 'Seleccione un desarrollo.'
                          : null,
                      suffixIcon: _developments.length == 1
                          ? const Icon(
                              Icons.lock_outline,
                              color: AppColors.discoveryFieldText,
                              size: 18,
                            )
                          : null,
                    ),
                    hint: Text(
                      _developmentsLoading
                          ? 'Cargando desarrollos...'
                          : 'Seleccionar desarrollo',
                      style: const TextStyle(
                        color: AppColors.discoveryFieldHint,
                      ),
                    ),
                    items: _developments
                        .map(
                          (development) => DropdownMenuItem<int>(
                            value: development['id'] as int,
                            child: Text(development['nombre'] as String),
                          ),
                        )
                        .toList(),
                    onChanged: _developmentsLoading || _developments.length <= 1
                        ? null
                        : (value) {
                            setState(() {
                              _selectedDevelopmentId = value;
                              _selectedLotId = null;
                              _lots = const [];
                            });
                            _loadLots();
                          },
                  ),
                ),
                _toggle(
                  '¿Tiene interés en un lote específico?',
                  _hasSpecificLot,
                  (value) => setState(() {
                    _hasSpecificLot = value;
                    if (!value) _selectedLotId = null;
                  }),
                ),
                if (_hasSpecificLot && _selectedDevelopmentId != null) ...[
                  if (_lotsLoading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: LinearProgressIndicator(),
                    ),
                  if (_lotsError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _lotsError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (!_lotsLoading &&
                      _selectedLotId != null &&
                      _selectedLot == null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'El lote guardado ya no está disponible. Selecciona otro.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  _label(
                    'Seleccionar lote *',
                    DropdownButtonFormField<int>(
                      key: ValueKey('lote-$_selectedLotId-${_lots.length}'),
                      initialValue: _selectedLot?['id'] as int?,
                      isExpanded: true,
                      dropdownColor: AppColors.discoveryField,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.discoveryFieldText,
                      ),
                      style: const TextStyle(
                        color: AppColors.discoveryFieldText,
                        fontFamily: 'SulphurPoint',
                        fontSize: 16,
                      ),
                      decoration: _decoration().copyWith(
                        errorText:
                            _showProcessErrors &&
                                _hasSpecificLot &&
                                _selectedLot == null
                            ? 'Seleccione el lote de interés.'
                            : null,
                      ),
                      hint: Text(
                        _lots.isEmpty
                            ? 'No hay lotes disponibles'
                            : 'Seleccione un lote',
                        style: const TextStyle(
                          color: AppColors.discoveryFieldHint,
                        ),
                      ),
                      items: _lots
                          .map(
                            (lot) => DropdownMenuItem<int>(
                              value: lot['id'] as int,
                              child: Text(_lotLabel(lot)),
                            ),
                          )
                          .toList(),
                      onChanged: _lots.isEmpty
                          ? null
                          : (value) => setState(() => _selectedLotId = value),
                    ),
                  ),
                  if (_selectedLot case final lot?)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.discoveryField,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          _readOnlyRow(
                            'Desarrollo',
                            '${lot['desarrollo_nombre'] ?? _service.activeDevelopment?['nombre'] ?? 'No disponible'}',
                          ),
                          _readOnlyRow(
                            'Número de lote',
                            '${lot['numero_lote']}',
                          ),
                          _readOnlyRow(
                            'Dimensiones',
                            _dimensions(lot['dimensiones_m2']),
                          ),
                          _readOnlyRow('Precio actual', _money(lot['precio'])),
                        ],
                      ),
                    ),
                ],
                _multiSelectChips(
                  '¿Quién más interviene en la decisión? *',
                  _participantOptions,
                  _decisionMakers,
                  errorText: _showProcessErrors && _decisionMakers.isEmpty
                      ? 'Seleccione al menos un participante.'
                      : null,
                ),
                if (_decisionMakers.contains('Otro'))
                  _text(
                    'Especificar *',
                    _participantsOther,
                    errorText:
                        _showProcessErrors &&
                            _participantsOther.text.trim().isEmpty
                        ? 'Especifique quién más interviene.'
                        : null,
                  ),
                _text('Notas adicionales', _additionalNotes),
                _buttons('proceso_seguimiento', _restoreProcess, _saveProcess),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        ProspectDetailPanel(
          title: 'Asignación a cerrador',
          color: AppColors.discoveryHeader,
          nested: true,
          initiallyExpanded: true,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppPalette.of(context).discoverySurfaceFill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _toggle(
                  '¿Enviar a cerrador?',
                  _sendToCloser,
                  (value) => setState(() {
                    _sendToCloser = value;
                    if (!value) {
                      _selectedCloserId = null;
                      _showCloserError = false;
                    }
                  }),
                ),
                if (_sendToCloser)
                  _label(
                    'Nombre del cerrador',
                    DropdownButtonFormField<int>(
                      key: ValueKey(
                        'cerrador-$_selectedCloserId-${_closers.length}',
                      ),
                      initialValue:
                          _closers.any(
                            (closer) => closer['id'] == _selectedCloserId,
                          )
                          ? _selectedCloserId
                          : null,
                      isExpanded: true,
                      dropdownColor: AppColors.discoveryField,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.discoveryFieldText,
                      ),
                      style: const TextStyle(
                        color: AppColors.discoveryFieldText,
                        fontFamily: 'SulphurPoint',
                        fontSize: 16,
                      ),
                      decoration: _decoration().copyWith(
                        errorText: _showCloserError && _selectedCloserId == null
                            ? 'Seleccione un cerrador.'
                            : null,
                      ),
                      hint: Text(
                        _closersLoading
                            ? 'Cargando cerradores...'
                            : _closers.isEmpty
                            ? 'No hay cerradores disponibles'
                            : 'Seleccionar cerrador',
                        style: const TextStyle(
                          color: AppColors.discoveryFieldHint,
                        ),
                      ),
                      items: _closers
                          .map(
                            (closer) => DropdownMenuItem<int>(
                              value: closer['id'] as int,
                              child: Text(closer['nombre_completo'] as String),
                            ),
                          )
                          .toList(),
                      onChanged: _closersLoading || _closers.isEmpty
                          ? null
                          : (value) =>
                                setState(() => _selectedCloserId = value),
                    ),
                  ),
                _buttons(
                  'asignacion_cerrador',
                  _restoreCloserAssignment,
                  _saveCloserAssignment,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
