import 'package:flutter/material.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:callerapp_frontend/resources/styles/styles.dart';
import 'package:callerapp_frontend/presentation/models/profile_models.dart';

class ProfileIdentity extends StatelessWidget {
  final ProfileData profile;
  const ProfileIdentity({super.key, required this.profile});

  Widget _badge(String text, {double size = 17, Color color = Colors.white}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text.toUpperCase(),
          textAlign: TextAlign.center,
          style: profileHeading.copyWith(fontSize: size, color: color),
        ),
      );

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const CircleAvatar(
        radius: 54,
        backgroundColor: Color(0xFFE9573F),
        child: Icon(
          Icons.person_rounded,
          size: 88,
          color: AppColors.homeWarmText,
        ),
      ),
      _badge(
        profile.name.split(' ').take(2).join(' '),
        size: 30,
        color: AppColors.homeWarmText,
      ),
      const SizedBox(height: 9),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 5,
        runSpacing: 5,
        children: [
          _badge(profile.name),
          _badge(profile.email),
          _badge(profile.phone, color: AppColors.homeWarmText),
        ],
      ),
    ],
  );
}
