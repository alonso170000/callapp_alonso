import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/validators/prospect_validators.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';

class NewProspectSheet extends StatefulWidget {
  const NewProspectSheet({super.key});

  @override
  State<NewProspectSheet> createState() => _NewProspectSheetState();
}

class _NewProspectSheetState extends State<NewProspectSheet> {
  final _form = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{
    for (final name in [
      'Nombre',
      'Email',
      'Ciudad',
      'Teléfono',
      'Empresa donde trabaja',
      'Ocupación',
      'Comentarios del prospecto',
      'Producto',
      'Descripción de Lote',
    ])
      name: TextEditingController(),
    'Dimensión en m² (sin comas)': TextEditingController(text: '0'),
    'Precio completo del lote': TextEditingController(text: '0'),
  };
  final _qualification = <String, bool>{
    'Decisión': false,
    'Disposición': false,
    'Dinero': false,
    'Pasó a TO': false,
    'Discovery Completo': false,
  };
  String _origin = 'Facebook', _status = 'Nuevo';
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  int _hour = 0, _minute = 0;

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    String text(String name) => _fields[name]!.text.trim();
    Navigator.pop(
      context,
      ProspectRecord(
        name: text('Nombre'),
        email: text('Email'),
        city: text('Ciudad'),
        phone: text('Teléfono'),
        company: text('Empresa donde trabaja'),
        occupation: text('Ocupación'),
        origin: _origin,
        status: _status,
        temperature: 'Sin calificar',
        avatarColor: const Color(0xFF94E5EF),
        statusColor: const Color(0xFF67D9EC),
        daysSinceContact: 0,
        assignedAt: DateTime.now(),
        nextContact: DateTime(
          _date.year,
          _date.month,
          _date.day,
          _hour,
          _minute,
        ),
        comments: text('Comentarios del prospecto'),
        product: text('Producto'),
        lotDescription: text('Descripción de Lote'),
        dimension: double.parse(text('Dimensión en m² (sin comas)')),
        fullPrice: double.parse(text('Precio completo del lote')),
        decision: _qualification['Decisión']!,
        willingness: _qualification['Disposición']!,
        money: _qualification['Dinero']!,
        passedToTO: _qualification['Pasó a TO']!,
        discoveryComplete: _qualification['Discovery Completo']!,
      ),
    );
  }

  InputDecoration _decoration(String label) => const InputDecoration(
    filled: true,
    fillColor: AppColors.primaryColor,
    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(9)),
      borderSide: BorderSide.none,
    ),
    errorMaxLines: 2,
    prefixStyle: TextStyle(color: AppColors.homeBackground),
  );

  Widget _labeled(String label, {required Widget child}) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Text(label, style: const TextStyle(fontFamily: 'SulphurPoint')),
      ),
      child,
    ],
  );
  Widget _field(
    String name, {
    bool required = false,
    bool numeric = false,
    int lines = 1,
  }) => _labeled(
    '$name${required ? '*' : ''}',
    child: TextFormField(
      key: ValueKey('prospect-$name'),
      controller: _fields[name],
      style: const TextStyle(
        fontFamily: 'SulphurPoint',
        fontSize: 16,
        color: AppColors.homeBackground,
      ),
      cursorColor: AppColors.homeBackground,
      minLines: lines,
      maxLines: lines,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : name == 'Email'
          ? TextInputType.emailAddress
          : name == 'Teléfono'
          ? TextInputType.phone
          : lines > 1
          ? TextInputType.multiline
          : TextInputType.text,
      decoration: _decoration(
        '$name${required ? ' *' : ''}',
      ).copyWith(prefixText: name == 'Precio completo del lote' ? '\$ ' : null),
      validator: numeric
          ? ProspectValidators.number
          : name == 'Email'
          ? ProspectValidators.email
          : name == 'Teléfono'
          ? ProspectValidators.phone
          : required
          ? ProspectValidators.requiredText
          : null,
    ),
  );

  Widget _dateTimeButton(String label, VoidCallback onPressed) => FilledButton(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.primaryColor,
      foregroundColor: AppColors.homeBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      textStyle: const TextStyle(
        fontFamily: 'SulphurPoint',
        fontWeight: FontWeight.w700,
      ),
    ),
    onPressed: onPressed,
    child: Text(label),
  );
  Widget _heading(String title) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 2),
    child: Text(
      title,
      style: const TextStyle(
        fontFamily: 'SulphurPoint',
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
  Widget _dropdown<T>(
    String label,
    T value,
    List<T> values,
    ValueChanged<T> change, {
    String Function(T)? format,
  }) => _labeled(
    label,
    child: DropdownButtonFormField<T>(
      isExpanded: true,
      initialValue: value,
      dropdownColor: AppColors.primaryColor,
      borderRadius: BorderRadius.circular(9),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.homeBackground,
      ),
      style: const TextStyle(
        fontFamily: 'SulphurPoint',
        fontSize: 16,
        color: AppColors.homeBackground,
      ),
      decoration: _decoration(label),
      items: values
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(
                format?.call(item) ?? '$item',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) setState(() => change(value));
      },
    ),
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              children: [
                const SizedBox(width: 48),
                const Expanded(
                  child: Text(
                    'Nuevo prospecto',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'SulphurPoint',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 30),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 12),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _heading('Información del Contacto'),
                    for (final name in [
                      'Nombre',
                      'Email',
                      'Ciudad',
                      'Teléfono',
                    ])
                      _field(name, required: true),
                    _field('Empresa donde trabaja'),
                    _field('Ocupación'),
                    _heading('Origen y Estado'),
                    _dropdown('Origen', _origin, [
                      'Facebook',
                      'WhatsApp',
                      'Referido',
                      'Sitio web',
                    ], (v) => _origin = v),
                    _dropdown('Status*', _status, [
                      'Nuevo',
                      'Contactado y validado',
                      'Seguimiento',
                      'Cotización',
                      'Negociación',
                      'Venta realizada',
                      'Atrasados',
                    ], (v) => _status = v),
                    _heading('Califica tu lead'),
                    for (final label in _qualification.keys)
                      _QualificationToggle(
                        label: label,
                        value: _qualification[label]!,
                        onChanged: (value) =>
                            setState(() => _qualification[label] = value),
                      ),
                    const SizedBox(height: 16),
                    _field('Comentarios del prospecto', lines: 3),
                    _heading('Información del Producto'),
                    _field('Producto', required: true),
                    _field('Descripción de Lote'),
                    _field('Dimensión en m² (sin comas)', numeric: true),
                    _field('Precio completo del lote', numeric: true),
                    _heading('Siguiente llamada programada'),
                    _labeled(
                      'Fecha/hora',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _dateTimeButton(
                            '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}',
                            () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _date,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (mounted && date != null) {
                                setState(() => _date = date);
                              }
                            },
                          ),
                          _dateTimeButton(
                            '${(_hour % 12 == 0 ? 12 : _hour % 12)}:${_minute.toString().padLeft(2, '0')} ${_hour < 12 ? 'AM' : 'PM'}',
                            () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(
                                  hour: _hour,
                                  minute: _minute,
                                ),
                              );
                              if (mounted && time != null) {
                                setState(() {
                                  _hour = time.hour;
                                  _minute = time.minute;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.homeBackground,
              border: Border(
                top: BorderSide(
                  color: AppColors.primaryColor.withValues(alpha: 0.12),
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF696969),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                      textStyle: const TextStyle(fontFamily: 'BebasNeue'),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('save-prospect'),
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF008FA0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                      textStyle: const TextStyle(fontFamily: 'BebasNeue'),
                    ),
                    child: const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _QualificationToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _QualificationToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    toggled: value,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'SulphurPoint',
                    fontSize: 16,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              SizedBox(
                width: 56,
                height: 48,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 48,
                    height: 22,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: value
                          ? const Color(0xFF4EA58B)
                          : const Color(0xFFA94E52),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 180),
                      alignment: value
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 20,
                        height: 16,
                        decoration: BoxDecoration(
                          color: value
                              ? const Color(0xFFADFADE)
                              : const Color(0xFFF7AAAA),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Icon(
                          value ? Icons.check_rounded : Icons.close_rounded,
                          size: 16,
                          color: value
                              ? AppColors.primaryColor
                              : const Color(0xFF802B30),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
