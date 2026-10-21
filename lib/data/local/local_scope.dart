/// Ámbito de los datos locales: un usuario dentro de un desarrollo.
///
/// Todas las tablas de caché y la bandeja de notificaciones se aíslan con esta
/// clave para que nunca se mezclen datos entre cuentas o desarrollos.
class LocalScope {
  const LocalScope({required this.userId, required this.developmentId});

  final int userId;
  final int developmentId;

  @override
  bool operator ==(Object other) =>
      other is LocalScope &&
      other.userId == userId &&
      other.developmentId == developmentId;

  @override
  int get hashCode => Object.hash(userId, developmentId);

  @override
  String toString() => 'LocalScope($userId, $developmentId)';
}
