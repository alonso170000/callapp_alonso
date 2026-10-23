import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/validators/profile_validators.dart';
import 'package:callerapp_frontend/repositories/prospects_repository.dart';
import 'package:callerapp_frontend/services/prospects_service.dart';
import 'package:callerapp_frontend/resources/styles/app_palette.dart';

class ProspectDataForm extends StatefulWidget {
  final ProspectRecord prospect;
  final ValueChanged<String> onSaved;
  final ProspectsService? prospectsService;
  final ProspectsRepository? repository;

  const ProspectDataForm({
    super.key,
    required this.prospect,
    required this.onSaved,
    this.prospectsService,
    this.repository,
  });

  @override
  State<ProspectDataForm> createState() => _ProspectDataFormState();
}

class _ProspectDataFormState extends State<ProspectDataForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.prospect.name);
  late final _city = TextEditingController(text: widget.prospect.city);
  late final _phone = TextEditingController(text: widget.prospect.phone);
  late final _email = TextEditingController(text: widget.prospect.email);
  late final _company = TextEditingController(text: widget.prospect.company);
  late final _occupation = TextEditingController(
    text: widget.prospect.occupation,
  );
  late final _origin = TextEditingController(text: widget.prospect.origin);
  Map<String, String>? _saved;
  int? _savedDevelopmentId, _savedLotId;
  late final ProspectsService _service;
  late final ProspectsRepository _repository;
  List<Map<String, dynamic>> _developments = const [];
  List<Map<String, dynamic>> _lots = const [];
  late int? _developmentId = widget.prospect.interestDevelopmentId;
  late int? _lotId = widget.prospect.interestLotId;
  bool _loading = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = widget.prospectsService ?? ProspectsService();
    _repository = widget.repository ?? ProspectsRepository(service: _service);
    _loadInterests();
  }

  Future<void> _loadInterests() async {
    setState(() => _loading = true);
    try {
      final developments = await _repository.loadDevelopments();
      if (!mounted) return;
      _developmentId ??= developments.length == 1
          ? developments.single['id'] as int
          : null;
      final lots = _developmentId == null
          ? <Map<String, dynamic>>[]
          : await _repository.loadLots(_developmentId!);
      if (mounted) {
        setState(() {
          _developments = developments;
          _lots = lots;
        });
      }
    } on ProspectsException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<TextEditingController> get _controllers => [
    _name,
    _city,
    _phone,
    _email,
    _company,
    _occupation,
    _origin,
  ];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    if (widget.prospectsService == null) _service.dispose();
    if (widget.repository == null) _repository.dispose();
    super.dispose();
  }

  InputDecoration _decoration() => InputDecoration(
    filled: true,
    fillColor: const Color(0xFFAD393E),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    errorStyle: TextStyle(color: AppPalette.of(context).fieldErrorInk),
  );

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: AppPalette.of(context).textColor,
          ),
        ),
        const SizedBox(height: 3),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          readOnly: readOnly,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: _decoration(),
        ),
      ],
    ),
  );

  Widget _dropdown(
    String label,
    int? value,
    List<Map<String, dynamic>> items,
    String Function(Map<String, dynamic>) text,
    ValueChanged<int?>? changed,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: AppPalette.of(context).textColor,
          ),
        ),
        const SizedBox(height: 3),
        DropdownButtonFormField<int>(
          initialValue: items.any((item) => item['id'] == value) ? value : null,
          isExpanded: true,
          decoration: _decoration(),
          dropdownColor: const Color(0xFFAD393E),
          style: const TextStyle(color: Colors.white, fontSize: 18),
          items: items
              .map(
                (item) => DropdownMenuItem<int>(
                  value: item['id'] as int,
                  child: Text(
                    text(item),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'SulphurPoint',
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: changed,
        ),
      ],
    ),
  );

  void _cancel() => setState(() {
    _name.text = _saved?['name'] ?? widget.prospect.name;
    _city.text = _saved?['city'] ?? widget.prospect.city;
    _phone.text = _saved?['phone'] ?? widget.prospect.phone;
    _email.text = _saved?['email'] ?? widget.prospect.email;
    _company.text = _saved?['company'] ?? widget.prospect.company;
    _occupation.text = _saved?['occupation'] ?? widget.prospect.occupation;
    _origin.text = _saved?['origin'] ?? widget.prospect.origin;
    _developmentId =
        _savedDevelopmentId ?? widget.prospect.interestDevelopmentId;
    _lotId = _savedLotId ?? widget.prospect.interestLotId;
    _formKey.currentState?.reset();
  });

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.prospect.id == null ||
        widget.prospect.channelId == null ||
        widget.prospect.statusId == null ||
        _developmentId == null) {
      setState(
        () => _error =
            'Faltan datos de catálogo para guardar. Actualiza el prospecto.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final qualification = widget.prospect.qualification
          .where((value) => value.trim().isNotEmpty)
          .toList();
      final fields = <String, dynamic>{
        'nombre': _name.text.trim(),
        'ciudad': _city.text.trim(),
        'telefono_normalizado': _phone.text.replaceAll(RegExp(r'\D'), ''),
        'correo': _email.text.trim(),
        'nombre_compania': _company.text.trim(),
        'ocupacion': _occupation.text.trim(),
        'canal_id': widget.prospect.channelId,
        'estatus_id': widget.prospect.statusId,
        'campania_id': widget.prospect.campaignId,
        'comentario': widget.prospect.comments,
        if (qualification.isNotEmpty) 'calificacion': qualification,
        'desarrollo_interes_id': _developmentId,
        'lote_id': _lotId,
      };
      final optimistic = widget.prospect.copyWith(
        name: _name.text.trim(),
        city: _city.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        company: _company.text.trim(),
        occupation: _occupation.text.trim(),
        interestDevelopmentId: _developmentId,
        interestLotId: _lotId,
      );
      final result =
          widget.repository == null && widget.prospectsService != null
          ? null
          : await _repository.update(
              widget.prospect,
              fields,
              optimisticProspect: optimistic,
            );
      if (result == null) {
        await _service.update(widget.prospect.id!, fields);
      }
      _saved = {
        'name': _name.text.trim(),
        'city': _city.text.trim(),
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'company': _company.text.trim(),
        'occupation': _occupation.text.trim(),
        'origin': _origin.text.trim(),
      };
      _savedDevelopmentId = _developmentId;
      _savedLotId = _lotId;
      if (!mounted) return;
      widget.onSaved('Prospecto · Datos actualizados');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result?.isPending == true
                ? 'Datos guardados. Se sincronizarán cuando haya conexión.'
                : 'Datos del prospecto actualizados.',
          ),
        ),
      );
    } on ProspectsException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
      color: AppPalette.of(context).dataSurfaceFill,
      borderRadius: BorderRadius.circular(11),
    ),
    child: Form(
      key: _formKey,
      child: Column(
        children: [
          _field(
            'Nombre',
            _name,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'El nombre es obligatorio'
                : null,
          ),
          _field('Ciudad', _city),
          _field(
            'Teléfono',
            _phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d+\s()-]')),
            ],
            validator: (value) =>
                ProfileValidators.field(value, field: 'Teléfono'),
          ),
          _field(
            'Email',
            _email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) =>
                ProfileValidators.field(value, field: 'Correo'),
          ),
          _field('Empresa', _company),
          _field('Ocupación', _occupation),
          _field(
            'Origen del prospecto',
            _origin,
            readOnly: true,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'El origen es obligatorio'
                : null,
          ),
          if (_loading) const LinearProgressIndicator(),
          _dropdown(
            'Desarrollo de interés',
            _developmentId,
            _developments,
            (item) => item['nombre'] as String,
            _developments.length <= 1 || _saving
                ? null
                : (value) async {
                    setState(() {
                      _developmentId = value;
                      _lotId = null;
                      _lots = const [];
                    });
                    if (value != null) {
                      try {
                        final lots = await _repository.loadLots(value);
                        if (mounted) setState(() => _lots = lots);
                      } on ProspectsException catch (error) {
                        if (mounted) setState(() => _error = error.message);
                      }
                    }
                  },
          ),
          _dropdown(
            'Lote de interés',
            _lotId ?? 0,
            [
              {'id': 0, 'numero_lote': null},
              ..._lots,
            ],
            (item) => item['id'] == 0
                ? 'Sin lote seleccionado'
                : 'Lote ${item['numero_lote']}',
            _saving
                ? null
                : (value) => setState(() => _lotId = value == 0 ? null : value),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFAC4549),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _saving ? null : _cancel,
                  child: const Text('CANCELAR'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4CA382),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'GUARDANDO…' : 'GUARDAR'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
