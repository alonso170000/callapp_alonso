class ProfileData {
  final String name;
  final String phone;
  final String email;
  final String rol;

  const ProfileData({
    required this.name,
    required this.phone,
    required this.email,
    required this.rol,
  });

  ProfileData copyWith({String? name, String? phone, String? email, String? rol}) =>
      ProfileData(
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        rol: rol ?? this.rol,
      );
}

const demoProfile = ProfileData(
  name: 'Leonardo Pérez Huerta',
  phone: '+52 9988776655',
  email: 'leonardo56@gmail.com',
  rol: 'Desarrollador',
);
