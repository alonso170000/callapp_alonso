class ProfileData {
  final String name;
  final String phone;
  final String email;

  const ProfileData({
    required this.name,
    required this.phone,
    required this.email,
  });

  ProfileData copyWith({String? name, String? phone, String? email}) =>
      ProfileData(
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
      );
}

const demoProfile = ProfileData(
  name: 'Leonardo Pérez Huerta',
  phone: '+52 9988776655',
  email: 'leonardo56@gmail.com',
);
