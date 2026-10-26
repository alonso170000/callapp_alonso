enum ProspectEmailTemplate {
  welcome('bienvenida', 'Correo de bienvenida'),
  second('segundo', 'Segundo correo'),
  reactivation('reactivacion', 'Correo de reactivación');

  const ProspectEmailTemplate(this.code, this.label);
  final String code;
  final String label;
}
